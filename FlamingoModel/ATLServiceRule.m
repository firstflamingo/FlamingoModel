//  Copyright (c) 2014-2015 First Flamingo Enterprise B.V.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  ATLServiceRule.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 24-06-14.
//

#import "ATLServiceRule.h"
#import "ATLService.h"
#import "ATLServicePoint.h"
#import "ATLStop.h"
#import "ATLMission.h"
#import "ATLStation.h"
#import "ATLTimePath.h"

#import "NSDate+Formatters.h"
#import "NSManagedObjectContext+FFEUtilities.h"

@implementation ATLServiceRule

@dynamic originPoint;
@dynamic destinationPoint;
@dynamic noStopPoints;
@dynamic instantatedMissions;
@dynamic service;

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@ %d %@-%@, offset: %@, runs on %@>",
            NSStringFromClass([self class]), self.number, self.originCode, self.destinationCode, self.offsetString, self.weekdaysString];
    if ([self.noStopPoints count] > 0) {
        [description appendString:@"\n\tdoes not call at: "];
        for (ATLServicePoint *point in self.noStopPoints) {
            [description appendFormat:@"%@ ", point.locationCode];
        }
    }
    return description;
}

- (NSString *)originCode
{
    return self.originPoint.locationCode;
}

- (void)setOriginCode:(NSString *)originCode
{
    self.originPoint = [self.service servicePointWithCode:originCode];
}

- (NSString *)destinationCode
{
    return self.destinationPoint.locationCode;
}

- (void)setDestinationCode:(NSString *)destinationCode
{
    self.destinationPoint = [self.service servicePointWithCode:destinationCode];
}

- (NSString *)trajectoryString
{
    return [NSString stringWithFormat:@"%@-%@", self.originCode, self.destinationCode];
}

- (int16_t)departure
{
    if (self.upDirection) {
        return self.offset + self.originPoint.upDeparture;
    } else {
        return self.offset + self.originPoint.downDeparture;
    }
}

- (int16_t)arrival
{
    if (self.upDirection) {
        return self.offset + self.destinationPoint.upArrival;
    } else {
        return self.offset + self.destinationPoint.downArrival;
    }
}

- (void)createIdentifier
{
    self.id_ = [NSString stringWithFormat:@"%@_%d_%x", self.service.id_, self.number, self.weekdays];
}

- (ATLMission *)missionAtDate:(NSDate *)date
{
    NSInteger baseNumber = self.number % 100000;
    NSString *country = baseNumber < 500 ? @"eu" : @"nl";
    NSString *identifier = [NSString stringWithFormat:@"%@.%d_%@", country, self.number, date.eightDigitDateString];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(id_ = %@)", identifier];
    ATLMission *mission = (ATLMission*)[self.managedObjectContext fetchUniqueInstanceOfType:@"ATLMission" withPredicate:predicate];
    
    if (!mission) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATLServiceRule"];
        request.predicate = [NSPredicate predicateWithFormat: @"number = %@ ", @(self.number)];
        NSArray *fetchedRules = [self.managedObjectContext executeFetchRequest:request error:NULL];
        NSPredicate *filter = [NSPredicate predicateWithFormat: @"(weekdays & %@) > 0", @(date.weekdayMask)];
        NSArray *rules = [fetchedRules filteredArrayUsingPredicate:filter];
        if ([rules count] > 0) {
            mission = (ATLMission*)[self.managedObjectContext createManagedObjectOfType:@"ATLMission"];
            mission.id_ = identifier;
            mission.serviceRules = [NSSet setWithArray:rules];
            NSMutableArray *stops = [NSMutableArray arrayWithCapacity:30];
            BOOL firstRule = YES;
            
            for (ATLServiceRule *rule in mission.arrangedServiceRules) {
                __block BOOL firstPoint = YES;
                [rule enumerateServicePoints:^(ATLServicePoint *servicePoint){
                    if ([servicePoint.location isKindOfClass:[ATLStation class]]) {
                        if (!firstRule && firstPoint) {
                            [rule useDepartureFromServicePoint:servicePoint forStop:[stops lastObject]];
                            
                        } else {
                            ATLStop *stop = [rule stopFromServicePoint:servicePoint atDate:date];
                            stop.mission = mission;
                            [stops addObject:stop];
                        }
                        firstPoint = NO;
                    }
                }];
                firstRule = NO;
            }
            mission.stops = [NSSet setWithArray:stops];
        }
        mission.timeOfDeparture = mission.firstStop.plannedDeparture;
        mission.timeOfArrival = mission.lastStop.plannedArrival;
    }
    return mission;
}

- (id)servicePointEnumerator
{
    return self.upDirection ? self.service.arrangedServicePoints : [self.service.arrangedServicePoints reverseObjectEnumerator];
}

- (void)verifyStopsWithTimePath:(ATLTimePath *)timePath
{
    id collection;
    if (self.upDirection) {
        collection = self.service.arrangedServicePoints;
    } else {
        collection = [self.service.arrangedServicePoints reverseObjectEnumerator];
    }
    BOOL flag = NO;
    for (ATLServicePoint *point in collection) {
        if ([point.location isKindOfClass:[ATLStation class]]) {
            if (flag) {
                if (point == self.destinationPoint) {
                    break;
                }
                if (![timePath callsAtStationWithID:point.location.id_]) {
                    [self addNoStopPointsObject:point];
                }
            } else {
                if (point == self.originPoint) {
                    flag = YES;
                }
            }
        }
    }
}

- (BOOL)callsAtStation:(ATLStation *)station
{
    BOOL passed = NO;
    for (ATLServicePoint *servicePoint in self.servicePointEnumerator) {
        if (servicePoint == self.originPoint) {
            passed = YES;
        }
        if (passed && servicePoint.location == station) {
            if ([self.noStopPoints containsObject:servicePoint]) {
                return NO;
            } else {
                return YES;
            }
        }
        if (servicePoint == self.destinationPoint) {
            break;
        }
    }
    return NO;
}

- (NSArray *)stationIDs
{
    NSMutableArray *stationIDs = [NSMutableArray arrayWithCapacity:30];
    [self enumerateServicePoints:^(ATLServicePoint *point){
        if ([point.location isKindOfClass:[ATLStation class]]) {
            [stationIDs addObject:point.location.id_];
        }
    }];
    return stationIDs;
}

- (void)enumerateServicePoints:(void (^)(ATLServicePoint *))handler
{
    BOOL passed = NO;
    for (ATLServicePoint *servicePoint in self.servicePointEnumerator) {
        if (servicePoint == self.originPoint) {
            passed = YES;
        }
        if (passed && ![self.noStopPoints containsObject:servicePoint]) {
            handler(servicePoint);
        }
        if (servicePoint == self.destinationPoint) {
            break;
        }
    }
}

- (ATLStop *)stopFromServicePoint:(ATLServicePoint *)servicePoint atDate:(NSDate *)date
{
    ATLStop *stop = (ATLStop*)[self.managedObjectContext createManagedObjectOfType:@"ATLStop"];
    stop.station = (ATLStation*)servicePoint.location;
    stop.destination = self.headsign;
    if (self.upDirection) {
        stop.plannedArrival = [date dateByReplacingTimeWith:self.offset + servicePoint.upArrival];
        stop.estimatedArrival = stop.plannedArrival;
        stop.plannedDeparture = [date dateByReplacingTimeWith:self.offset + servicePoint.upDeparture];
        stop.estimatedDeparture = stop.plannedDeparture;
        stop.platform = servicePoint.upPlatform;
    } else {
        stop.plannedArrival = [date dateByReplacingTimeWith:self.offset + servicePoint.downArrival];
        stop.estimatedArrival = stop.plannedArrival;
        stop.plannedDeparture = [date dateByReplacingTimeWith:self.offset + servicePoint.downDeparture];
        stop.estimatedDeparture = stop.plannedDeparture;
        stop.platform = servicePoint.downPlatform;
    }
    return stop;
}

- (void)useDepartureFromServicePoint:(ATLServicePoint *)servicePoint forStop:(ATLStop*)stop
{
    if (stop.station != (ATLStation*)servicePoint.location) {
        NSLog(@"Next serviceRule must start where previous ended: %@ != %@ for mission %@", stop.station, servicePoint.location, stop.mission);
        return;
    }
    
    NSDate *newDeparture = nil;
    NSString *platform = nil;
    if (self.upDirection) {
        newDeparture = [stop.plannedDeparture dateByReplacingTimeWith:self.offset + servicePoint.upDeparture];
        platform = servicePoint.upPlatform;
    } else {
        newDeparture = [stop.plannedDeparture dateByReplacingTimeWith:self.offset + servicePoint.downDeparture];
        platform = servicePoint.downPlatform;
    }
    if (ABS([newDeparture timeIntervalSinceDate:stop.plannedDeparture]) > 900.0 ||
        [newDeparture timeIntervalSinceDate:stop.plannedArrival] < 0) {
        NSLog(@"Replacing departure %@ by %@ was rejected for stop %@", stop.plannedDeparture, newDeparture, stop);
    } else {
        stop.plannedDeparture = newDeparture;
        stop.estimatedDeparture = newDeparture;
        stop.platform = platform;
    }
}

#pragma mark - Reading methods

- (void)fillWithDictionary:(NSDictionary *)dictionary
{
    [super fillWithDictionary:dictionary];
    self.originCode = dictionary[@"from"];
    self.destinationCode = dictionary[@"to"];
}

#pragma mark - Writing methods

- (void)appendAttributesToXMLString:(NSMutableString *)output
{
    [super appendAttributesToXMLString:output];
    [output appendFormat:@" from=\"%@\" to=\"%@\"", self.originCode, self.destinationCode];
}

- (BOOL)hasXMLData
{
    return [self.noStopPoints count] > 0;
}

- (void)appendDataToXMLString:(NSMutableString *)output
{
    for (ATLServicePoint *point in self.noStopPoints) {
        [output appendFormat:@"<nostop code=\"%@\"/>", point.location.code];
    }
}

@end

@implementation ATLDeparture

- (instancetype)initWithPoint:(ATLServicePoint *)point rule:(ATLServiceRule *)rule atDate:(NSDate *)date
{
    self = [super init];
    if (self) {
        self.servicePoint = point;
        self.serviceRule = rule;
        self.date = date;
        if (rule.upDirection) {
            self.plannedDeparture = [date dateByReplacingTimeWith:rule.offset + point.upDeparture];
        } else {
            self.plannedDeparture = [date dateByReplacingTimeWith:rule.offset + point.downDeparture];
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %@ %@ %@>",
            NSStringFromClass([self class]), self.serviceRule.id_, self.servicePoint.locationCode, self.plannedDeparture.nlTimeString];
}

- (NSString *)destination
{
    return self.serviceRule.headsign;
}

- (ATLMission *)mission
{
    return [self.serviceRule missionAtDate:self.date];
}

- (NSString *)platform
{
    if (self.serviceRule.upDirection) {
        return self.servicePoint.upPlatform;
    } else {
        return self.servicePoint.downPlatform;
    }
}

- (int32_t)block
{
    return self.serviceRule.block;
}

@end

