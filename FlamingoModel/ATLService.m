//  Copyright (c) 2012-2015 First Flamingo Enterprise B.V.
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
//  ATLService.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 17-10-12.
//

#import "ATLService.h"

#import "ATLSeriesRef.h"
#import "ATLMissionRule.h"
#import "ATLTimePath.h"
#import "ATLServiceRef.h"
#import "ATLStation.h"
#import "ATLJunction.h"
#import "ATLServicePoint.h"
#import "ATLTimePoint.h"
#import "ATLOrganization.h"
#import "ATLServiceRule.h"
#import "ATLRoute.h"
#import "ATLRouteOverlay.h"

#import "NSManagedObjectContext+FFEUtilities.h"
#import "NSDate+Formatters.h"

#if TARGET_OS_IPHONE
#import "UIColor+ColorCreation.h"
#endif

double waitingTimeForFrequency(double frequency);

typedef void (^serviceInstructions)(ATLService *service);
typedef void (^seriesInstructions)(ATLSeries *series);
typedef void (^routeInstructions)(ATLRoute *route, NSInteger direction, double offset, double min_km, double max_km);
typedef void (^routeSectionInstructions)(ATLRoute *route, float start, float end);


@interface NSMutableDictionary (HistogramWritingMethods)

- (void)addMeasurementAtLabel:(NSString*)label entry:(id)entry amount:(NSInteger)count;
- (void)addAmount:(NSInteger)amount forEntry:(id)entry;

@end

@interface NSDictionary (HistogramReadingMethods)

- (int)occurrencesForLabel:(NSString*)label;
- (id)mostCommonEntryForLabel:(NSString*)label;
- (id)mostCommonEntry;
- (double)avarageValueForLabel:(NSString*)label;
- (double)avarageValue;

@end

@implementation ATLService

@dynamic baseFrequency;
@dynamic offPeakFrequency;
@dynamic peakFrequency;
@dynamic expressService;
@dynamic group;
@dynamic imageName;
@dynamic shortName;
@dynamic longName;

@dynamic seriesRefs;
@dynamic serviceOperator;
@dynamic grantor;
@dynamic servicePoints;
@dynamic previousServiceRefs;
@dynamic nextServiceRefs;
@dynamic serviceRules;

- (NSString *)description
{
    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"<%@ %@, %ld serviceRules, %ld linked series>",
     NSStringFromClass([self class]), self.id_, (unsigned long)[self.serviceRules count], (unsigned long)[self.seriesRefs count]];
    [description appendString:@"\nservicePoints:"];
    if ([self.upServiceRules count] > 0) {
        for (ATLServicePoint *point in self.arrangedServicePoints) {
            [description appendFormat:@"\n\t%@", point.upDescription];
        }
        [description appendString:@"\nup serviceRules:"];
        for (ATLServiceRule *rule in self.upServiceRules) {
            [description appendFormat:@"\n\t%@", rule];
        }
    }
    if ([self.downServiceRules count] > 0) {
        for (ATLServicePoint *point in [self.arrangedServicePoints reverseObjectEnumerator]) {
            [description appendFormat:@"\n\t%@", point.downDescription];
        }
        [description appendString:@"\ndown serviceRules:"];
        for (ATLServiceRule *rule in self.downServiceRules) {
            [description appendFormat:@"\n\t%@", rule];
        }
    }
    return description;
}

#pragma mark - Service identity

- (NSString *)origin
{
    return self.firstStation.name;
}

- (NSString *)destination
{
    return self.lastStation.name;
}

- (NSString *)previousOrigins
{
    NSMutableString *string = [NSMutableString stringWithCapacity:20];
    __block BOOL first = YES;
    [self enumeratePreviousServices:^(ATLService *service){
        if (first) {
            first = NO;
        } else {
            [string appendString:@" / "];
        }
        [string appendString:service.firstStation.displayName];
        NSString *deeper = service.previousOrigins;
        if ([deeper length] > 0) {
            [string appendFormat:@" - %@", deeper];
        }
    }];
    return string;
}

- (NSString *)nextDestinations
{
    NSMutableString *string = [NSMutableString stringWithCapacity:20];
    __block BOOL first = YES;
    [self enumerateNextServices:^(ATLService *service){
        if (first) {
            first = NO;
        } else {
            [string appendString:@" / "];
        }
        [string appendString:service.lastStation.displayName];
        NSString *deeper = service.nextDestinations;
        if ([deeper length] > 0) {
            [string appendFormat:@" - %@", deeper];
        }
    }];
    return string;
}

- (NSString *)groupName
{
    return [ATLEntry nameForGroup:self.group];
}

- (NSString *)groupCode
{
    return [ATLEntry codeForGroup:self.group];
}

- (NSAttributedString *)attributedName
{
    NSString *name;
    if (self.group <= 4) {
        name = [NSString stringWithFormat:@"%@ (%@, lijn %@)", self.longName, self.groupName, self.shortName];
    } else {
        name = [NSString stringWithFormat:@"%@ (lijn %@ in %@)", self.longName, self.shortName, self.groupName];
    }
    NSMutableAttributedString *attributedName = [[NSMutableAttributedString alloc] initWithString:name];
    
#if TARGET_OS_IPHONE
    [attributedName addAttribute:NSForegroundColorAttributeName
                           value:[UIColor colorForGroup:self.group]
                           range:NSMakeRange([self.longName length], [name length] - [self.longName length])];
#endif
    
    return attributedName;
}

#pragma mark - Accessing references to series

- (NSSet *)seriesSet
{
    NSMutableSet *resultSet = [NSMutableSet setWithCapacity:3];
    [self enumerateSeries:^(ATLSeries *series){
        [resultSet addObject:series];
    }];
    return resultSet;
}

- (NSArray *)seriesReferences
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.seriesRefs count]];
    for (ATLSeriesRef *ref in self.seriesRefs) {
        [array addObject:ref.refArray];
    }
    return array;
}

- (NSSet *)commonSeriesWithService:(ATLService *)otherService
{
    NSMutableSet *resultSet = [NSMutableSet setWithCapacity:3];
    [resultSet setSet:self.seriesSet];
    [resultSet intersectSet:otherService.seriesSet];
    return resultSet;
}

- (void)fillSchedule
{
    NSSet *serviceRules = [self.serviceRules copy];
    for (ATLServiceRule *serviceRule in serviceRules) {
        serviceRule.service = nil;
        [self.managedObjectContext deleteObject:serviceRule];
    }
    [self fillScheduleInUpDirection:YES];
    [self fillScheduleInUpDirection:NO];
    self.upServiceRules = nil;
    self.downServiceRules = nil;
}

- (void)fillScheduleInUpDirection:(BOOL)upDirection
{
    NSMutableDictionary *arrivalHist = [NSMutableDictionary dictionaryWithCapacity:30];
    NSMutableDictionary *departureHist = [NSMutableDictionary dictionaryWithCapacity:30];
    NSMutableDictionary *platformHist = [NSMutableDictionary dictionaryWithCapacity:30];
    
    for (ATLSeriesRef *ref in self.seriesRefs) {
        BOOL seriesDirection = ref.sameDirection ? upDirection : !upDirection;
        NSArray *missionRules = [ATLRule arrangeRules:ref.series.missionRules inUpDirection:seriesDirection];
        ATLServiceRule *previousRule = nil;
        int correction = upDirection ? ref.upCorrection : ref.downCorrection;
        
        for (ATLMissionRule *missionRule in missionRules) {
            NSString *originCode = nil, *destinationCode = nil;
            int amount = (int)missionRule.occurrences;
            for (ATLTimePoint *timePoint in missionRule.timePath.timePoints) {
                NSString *stationCode = timePoint.stationCode;
                if ([self containsLocationCode:stationCode]) {
                    if (originCode) {
                        destinationCode = stationCode;
                    } else {
                        originCode = stationCode;
                    }
                    [arrivalHist addMeasurementAtLabel:stationCode entry:@(timePoint.arrival - correction) amount:amount];
                    [departureHist addMeasurementAtLabel:stationCode entry:@(timePoint.departure - correction) amount:amount];
                    [platformHist addMeasurementAtLabel:stationCode entry:timePoint.platform amount:amount];
                }
            }
            if (destinationCode) {
                ATLMinutes correctedOffset = missionRule.offset + correction;
                NSString *originID = [NSString stringWithFormat:@"nl.%@", originCode];
                NSString *destinationID = [NSString stringWithFormat:@"nl.%@", destinationCode];
                if (previousRule &&
                    previousRule.number == missionRule.number &&
                    previousRule.offset == correctedOffset &&
                    [previousRule.stationIDs isEqualToArray:[missionRule.timePath stationIDsFromID:originID toID:destinationID]])
                {
                    previousRule.weekdays |= missionRule.weekdays;
                    [previousRule createIdentifier];
                    
                } else {
                    ATLServiceRule *serviceRule = (ATLServiceRule*)[self.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
                    serviceRule.service = self;
                    serviceRule.number = missionRule.number;
                    serviceRule.block = missionRule.block;
                    serviceRule.upDirection = upDirection;
                    serviceRule.offset = correctedOffset;
                    serviceRule.weekdays = missionRule.weekdays;
                    serviceRule.headsign = missionRule.headsign;
                    serviceRule.originCode = originCode;
                    serviceRule.destinationCode = destinationCode;
                    [serviceRule createIdentifier];
                    [serviceRule verifyStopsWithTimePath:missionRule.timePath];
                    previousRule = serviceRule;
                }
            }
        }
    }
    for (ATLServicePoint *servicePoint in self.servicePoints) {
        NSString *stationCode = servicePoint.location.code;
        if ([servicePoint.location isKindOfClass:[ATLStation class]] && [arrivalHist occurrencesForLabel:stationCode] > 0) {
            int16_t difference;
            if (upDirection) {
                servicePoint.upPlatform = [platformHist mostCommonEntryForLabel:stationCode];
                servicePoint.upArrival = roundl([arrivalHist avarageValueForLabel:stationCode]);
                servicePoint.upDeparture = roundl([departureHist avarageValueForLabel:stationCode]);
                difference = ABS([[departureHist mostCommonEntryForLabel:stationCode] intValue] - servicePoint.upDeparture);
            } else {
                servicePoint.downPlatform = [platformHist mostCommonEntryForLabel:stationCode];
                servicePoint.downArrival = roundl([arrivalHist avarageValueForLabel:stationCode]);
                servicePoint.downDeparture = roundl([departureHist avarageValueForLabel:stationCode]);
                difference = ABS([[departureHist mostCommonEntryForLabel:stationCode] intValue] - servicePoint.downDeparture);
            }
            if (difference >= 5) {
                NSLog(@"WARNING: difference = %d for %@ in direction %d", difference, stationCode, upDirection);
            }
        }
    }
}

#pragma mark - Accessing serviceRules
@synthesize upServiceRules = _upServiceRules;
@synthesize downServiceRules = _downServiceRules;

- (NSArray *)upServiceRules
{
    if (!_upServiceRules) {
        self.upServiceRules = [ATLRule arrangeRules:self.serviceRules inUpDirection:YES];
    }
    return _upServiceRules;
}

- (NSArray *)downServiceRules
{
    if (!_downServiceRules) {
        self.downServiceRules = [ATLRule arrangeRules:self.serviceRules inUpDirection:NO];
    }
    return _downServiceRules;
}

- (void)clearServiceRules
{
    for (NSArray *array in @[self.upServiceRules, self.downServiceRules]) {
        for (ATLServiceRule *rule in array) {
            [self removeServiceRulesObject:rule];
            [self.managedObjectContext deleteObject:rule];
        }
    }
    self.upServiceRules = nil;
    self.downServiceRules = nil;
}

- (NSArray*)rulesWithStartOffset:(ATLMinutes)offset span:(ATLMinutes)span upDirection:(BOOL)upDirection
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATLServiceRule"];
    request.predicate = [NSPredicate predicateWithFormat:
                         @"service = %@ AND upDirection = %@ AND offset >= %@ AND offset <= %@",
                         self, @(upDirection), @(offset), @(offset + span)];
    return [self.managedObjectContext executeFetchRequest:request error:NULL];
}

- (NSArray *)rulesFromPoint:(ATLServicePoint *)startPoint toPoint:(ATLServicePoint *)endPoint
                  startTime:(NSDate *)startTime endTime:(NSDate *)endTime useDeparture:(BOOL)useDeparture
{
    BOOL upDirection = startPoint.km < endPoint.km;
    ATLMinutes offset = startTime.inMinutes;
    if (useDeparture) {
        offset -= upDirection ? startPoint.upDeparture : startPoint.downDeparture;
    } else {
        offset -= upDirection ? endPoint.upArrival : endPoint.downArrival;
    }
    ATLMinutes span = [endTime timeIntervalSinceDate:startTime] / 60;
    
    NSPredicate *filter;
    if (upDirection) {
        filter = [NSPredicate predicateWithFormat:
                     @"originPoint.km < %@ AND destinationPoint.km > %@ AND (weekdays & %@) > 0"
                     " AND !(ANY noStopPoints = %@) AND !(ANY noStopPoints = %@)",
                     @(startPoint.km + 0.1), @(endPoint.km - 0.1), @(startTime.weekdayMask),
                     startPoint, endPoint];
    } else {
        filter = [NSPredicate predicateWithFormat:
                     @"originPoint.km > %@ AND destinationPoint.km < %@ AND (weekdays & %@) > 0"
                     " AND !(ANY noStopPoints = %@) AND !(ANY noStopPoints = %@)",
                     @(startPoint.km - 0.1), @(endPoint.km + 0.1), @(startTime.weekdayMask),
                     startPoint, endPoint];
    }
	return [[self rulesWithStartOffset:offset span:span upDirection:upDirection] filteredArrayUsingPredicate:filter];
}

- (NSSet *)missionsFromStation:(ATLStation *)origin toStation:(ATLStation *)destination
                     startTime:(NSDate *)startTime endTime:(NSDate *)endTime useDeparture:(BOOL)useDeparture
{
    NSArray *rules = [self rulesFromPoint:[self servicePointForLocation:origin]
                                  toPoint:[self servicePointForLocation:destination]
                                startTime:startTime
                                  endTime:endTime
                             useDeparture:useDeparture];
    NSMutableSet *missions = [NSMutableSet setWithCapacity:[rules count]];
    for (ATLServiceRule *rule in rules) {
        [missions addObject:[rule missionAtDate:startTime]];
    }
    return missions;
}

- (NSSet *)departuresFromPoint:(ATLServicePoint *)point startTime:(NSDate *)startTime endTime:(NSDate *)endTime
{
    NSMutableSet *departures = [NSMutableSet set];
    ATLMinutes offset = startTime.inMinutes;
    ATLMinutes span = [endTime timeIntervalSinceDate:startTime] / 60.0;
    int weekdayMask = startTime.weekdayMask;
    
    NSArray *upRules = [self rulesWithStartOffset:offset - point.upDeparture span:span upDirection:YES];
    NSPredicate *upFilter = [NSPredicate predicateWithFormat:
                             @"originPoint.km < %@ AND destinationPoint.km > %@ AND (weekdays & %@) > 0"
                             " AND !(ANY noStopPoints = %@)",
                             @(point.km + 0.1), @(point.km + 0.1), @(weekdayMask), point];
    for (ATLServiceRule *rule in [upRules filteredArrayUsingPredicate:upFilter]) {
        [departures addObject:[[ATLDeparture alloc] initWithPoint:point rule:rule atDate:startTime]];
    }
    
    NSArray *downRules = [self rulesWithStartOffset:offset - point.downDeparture span:span upDirection:NO];
    NSPredicate *downFilter = [NSPredicate predicateWithFormat:
                               @"originPoint.km > %@ AND destinationPoint.km < %@ AND (weekdays & %@) > 0"
                               " AND !(ANY noStopPoints = %@)",
                               @(point.km - 0.1), @(point.km - 0.1), @(weekdayMask), point];
    for (ATLServiceRule *rule in [downRules filteredArrayUsingPredicate:downFilter]) {
        [departures addObject:[[ATLDeparture alloc] initWithPoint:point rule:rule atDate:startTime]];
    }
    
    return departures;
}

#pragma mark - Accessing servicePoints
@synthesize arrangedServicePoints = _arrangedServicePoints;

- (NSArray *)arrangedServicePoints
{
    if (!_arrangedServicePoints) {
        NSSortDescriptor *sortOnKM = [NSSortDescriptor sortDescriptorWithKey:@"km" ascending:YES];
        self.arrangedServicePoints = [self.servicePoints sortedArrayUsingDescriptors:@[sortOnKM]];
    }
    return _arrangedServicePoints;
}

- (BOOL)sorted
{
    return (BOOL)self.arrangedServicePoints;
}

- (void)setSorted:(BOOL)sorted
{
    if (!sorted) {
        self.arrangedServicePoints = nil;
    }
}

- (ATLServicePoint *)servicePointAtIndex:(NSUInteger)index
{
    return self.arrangedServicePoints[index];
}

- (ATLServicePoint *)firstServicePoint
{
    return [self servicePointAtIndex:0];
}

- (ATLServicePoint *)lastServicePoint
{
    return [self.arrangedServicePoints lastObject];
}

- (NSInteger)directionAtIndex:(NSInteger)index
{
    if (index < [self.servicePoints count] - 1) {
        ATLRoute *route = [self[index] commonRouteWithItem:self[index + 1]];
        if (route) {
            if ([self[index] kmPositionInRoute:route] > [self[index + 1] kmPositionInRoute:route]) {
                return -1;
            } else {
                return 1;
            }
        }
    }
    return 0;
}

- (ATLServicePoint *)servicePointForLocation:(ATLLocation *)location
{
    for (ATLServicePoint *servicePoint in self.servicePoints) {
        if (servicePoint.location == location) {
            return servicePoint;
        }
    }
    return nil;
}

- (ATLServicePoint *)servicePointWithCode:(NSString *)code
{
    for (ATLServicePoint *servicePoint in self.servicePoints) {
        if ([servicePoint.location.code isEqualToString:code]) {
            return servicePoint;
        }
    }
    return nil;
}

- (NSUInteger)indexOfServicePoint:(ATLServicePoint *)point
{
    for (NSUInteger i = 0; i < [self.arrangedServicePoints count]; i++) {
        if (self.arrangedServicePoints[i] == point) {
            return i;
        }
    }
    return NSNotFound;
}

- (BOOL)infraDirectionAtIndex:(NSUInteger)i
{
    ATLLocation *location0, *location1;
    if (i == 0) {
        location0 = self[0];
        location1 = self[1];
    } else {
        location0 = self[i - 1];
        location1 = self[i];
    }
    for (ATLRoute *route in location0.routes) {
        if ([location1 isOnRoute:route]) {
            return [location0 kmPositionInRoute:route] < [location1 kmPositionInRoute:route];
        }
    }
    NSLog(@"%s could not find an answer", __PRETTY_FUNCTION__);
    return YES;
}

#pragma mark - Accessing locations

- (ATLLocation *)objectAtIndexedSubscript:(NSUInteger)index
{
    if (index >= [self.servicePoints count]) return nil;
    return [self servicePointAtIndex:index].location;
}

- (NSUInteger)indexOfLocation:(ATLLocation *)location
{
    for (NSUInteger index = 0; index < [self.servicePoints count]; index++) {
        if (self[index] == location) return index;
    }
    return NSNotFound;
}

- (BOOL)containsLocation:(ATLLocation *)aLocation
{
    for (ATLServicePoint *servicePoint in self.servicePoints) {
        if (servicePoint.location == aLocation) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)containsLocationCode:(NSString *)code
{
    for (ATLServicePoint *servicePoint in self.servicePoints) {
        if ([servicePoint.location.code isEqualToString:code]) {
            return YES;
        }
    }
    return NO;
}

- (ATLStation *)firstStation
{
    return (ATLStation*)self[0];
}

- (NSSet *)intermediateStations
{
    NSMutableSet *stations = [NSMutableSet setWithCapacity:20];
    for (NSInteger i = 1; i < [self.servicePoints count] - 1; i++) {
        if ([self[i] isKindOfClass:[ATLStation class]]) {
            [stations addObject:self[i]];
        }
    }
    return stations;
}

- (ATLStation *)lastStation
{
    return (ATLStation *)self.lastServicePoint.location;
}

- (NSString *)firstStationID
{
    ATLStation *station = self.firstStation;
    if ([station isKindOfClass:[ATLStation class]]) {
        return station.id_;
    }
    return nil;
}

- (NSString *)lastStationID
{
    ATLStation *station = self.lastStation;
    if ([station isKindOfClass:[ATLStation class]]) {
        return station.id_;
    }
    return nil;
}

- (NSString *)firstStationName
{
    ATLStation *station = self.firstStation;
    if ([station isKindOfClass:[ATLStation class]]) {
        return station.name;
    }
    return nil;
}

- (NSString *)lastStationName
{
    ATLStation *station = self.lastStation;
    if ([station isKindOfClass:[ATLStation class]]) {
        return station.name;
    }
    return nil;
}

#pragma mark Editing locations

- (BOOL)insertLocation:(ATLLocation *)item
{
    if ([self containsLocation:item]) return NO;
    __block double insert_km = 0;
    
    if ([self.servicePoints count] == 1) {
        ATLRoute *route = [item commonRouteWithItem:self[0]];
        if (!route) return NO;
        insert_km = fabs([item kmPositionInRoute:route] - [self[0] kmPositionInRoute:route]);
        
    } else if ([self.servicePoints count] > 1) {
        __block BOOL success = NO;
        [self performOnRoutes:^(ATLRoute *route, NSInteger direction, double offset, double min_km, double max_km){
            if ([item isOnRoute:route]) {
                double item_km = direction * ([item kmPositionInRoute:route] - offset);
                if ((min_km < 0 || item_km >= min_km) && (max_km < 0 || item_km <= max_km)) {
                    insert_km = item_km;
                    success = YES;
                }
            }
        }];
        if (!success) return NO;
    }
    [self insertLocation:item atKM:insert_km];
    
    if (insert_km < 0) {
        for (ATLServicePoint *routePoint in self.servicePoints) {
            routePoint.km -= insert_km;
        }
    }
    self.sorted = NO;
    
    return YES;
}

- (ATLServicePoint*)insertLocation:(ATLLocation *)location atKM:(float)insert_km
{
    ATLServicePoint *newPoint = (ATLServicePoint*)[self.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];;
    newPoint.location = location;
    newPoint.service = self;
    newPoint.km = insert_km;
    return newPoint;
}

- (void)removeLocationAtIndex:(NSUInteger)index
{
    ATLRoutePosition *expiredItem = self.arrangedServicePoints[index];
    [self.managedObjectContext deleteObject:expiredItem];
    self.sorted = NO;
}

#pragma mark - Accessing connecting services

- (void)connectToNextService:(ATLService *)nextService
{
    ATLServiceRef *connection = (ATLServiceRef*)[self.managedObjectContext createManagedObjectOfType:@"ATLServiceRef"];
    connection.previousService = self;
    connection.nextService = nextService;
}

- (NSSet *)previousServices
{
    NSMutableSet *services = [NSMutableSet setWithCapacity:2];
    for (ATLServiceRef *ref in self.previousServiceRefs) {
        [services addObject:ref.previousService];
    }
    return services;
}

- (NSSet *)nextServices
{
    NSMutableSet *services = [NSMutableSet setWithCapacity:2];
    for (ATLServiceRef *ref in self.nextServiceRefs) {
        [services addObject:ref.nextService];
    }
    return services;
}

-(NSSet *)allPreviousServices
{
    NSMutableSet *services = [NSMutableSet setWithCapacity:10];
    [self enumeratePreviousServices:^(ATLService *service){
        [services addObject:service];
        [services unionSet:service.allPreviousServices];
    }];
    return services;
}

- (NSSet *)allNextServices
{
    NSMutableSet *services = [NSMutableSet setWithCapacity:10];
    [self enumerateNextServices:^(ATLService *service){
        [services addObject:service];
        [services unionSet:service.allNextServices];
    }];
    return services;
}

- (NSSet *)allPreviousFirstRouteItems
{
    NSMutableSet *routeItems = [NSMutableSet setWithCapacity:5];
    [self enumeratePreviousServices:^(ATLService *service){
        [routeItems addObject:service.firstStation];
        [routeItems unionSet:service.allPreviousFirstRouteItems];
    }];
    return routeItems;
}

- (NSSet *)allNextLastRouteItems
{
    NSMutableSet *routeItems = [NSMutableSet setWithCapacity:5];
    [self enumerateNextServices:^(ATLService *service){
        [routeItems addObject:service.lastStation];
        [routeItems unionSet:service.allNextLastRouteItems];
    }];
    return routeItems;
}

- (NSSet *)allPreviousIntermediateStations
{
    NSMutableSet *stations = [NSMutableSet setWithCapacity:30];
    [self enumeratePreviousServices:^(ATLService *service){
        [stations unionSet:service.intermediateStations];
        [stations unionSet:service.allPreviousIntermediateStations];
    }];
    return stations;
    
}

- (NSSet *)allNextIntermediateStations
{
    NSMutableSet *stations = [NSMutableSet setWithCapacity:5];
    [self enumerateNextServices:^(ATLService *service){
        [stations unionSet:service.intermediateStations];
        [stations unionSet:service.allNextIntermediateStations];
    }];
    return stations;
}


#pragma mark - Calculating travel time

- (double)waitingTimeAtRouteItem:(ATLLocation *)location fromService:(ATLService *)otherService
{
    float throughFrequency = 0;
    ATLMinutes stopTime = 0;
    if (location == self.firstStation) {
        for (ATLServiceRef *ref in self.previousServiceRefs) {
            if (ref.previousService == otherService) {
                throughFrequency = MIN(self.baseFrequency, otherService.baseFrequency);
                stopTime = self.firstServicePoint.upDeparture - self.firstServicePoint.upArrival;
            }
        }
    } else if (location == self.lastStation) {
        for (ATLServiceRef *ref in self.nextServiceRefs) {
            if (ref.nextService == otherService) {
                throughFrequency = MIN(self.baseFrequency, otherService.baseFrequency);
                stopTime = self.lastServicePoint.downDeparture - self.lastServicePoint.downArrival;
            }
        }
    }
    double waitingTime;
    if (throughFrequency > 0) {
        waitingTime = waitingTimeForFrequency(throughFrequency) - waitingTimeForFrequency(otherService.baseFrequency);
        waitingTime += stopTime;
    } else {
        waitingTime = waitingTimeForFrequency(self.baseFrequency);
    }
    return waitingTime;
}

- (double)travelTimeFrom:(ATLLocation *)origin to:(ATLLocation *)destination
{
    NSUInteger originIndex = [self indexOfLocation:origin];
    NSUInteger destinationIndex = [self indexOfLocation:destination];
    ATLServicePoint *originPoint = self.arrangedServicePoints[originIndex];
    ATLServicePoint *destinationPoint = self.arrangedServicePoints[destinationIndex];
    if (destinationIndex > originIndex) {
        return destinationPoint.upArrival - originPoint.upDeparture;
    } else {
        return destinationPoint.downArrival - originPoint.downDeparture;
    }
}

#pragma mark - Map Overlays

- (NSArray *)routeOverlays
{
    return [self routeOverlaysFromIndex:0 toIndex:[self.servicePoints count] - 1];
}

- (NSArray *)routeOverlaysFrom:(ATLLocation *)start to:(ATLLocation *)end
{
    NSUInteger startIndex = [self indexOfLocation:start], endIndex = [self indexOfLocation:end];
    if (startIndex == NSNotFound || endIndex == NSNotFound || startIndex == endIndex) return @[];
    if (startIndex > endIndex) {
        NSUInteger swap = startIndex;
        startIndex = endIndex;
        endIndex = swap;
    }
    return [self routeOverlaysFromIndex:startIndex toIndex:endIndex];
}

- (NSArray*)routeOverlaysFromIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex
{
    NSMutableArray *overlaysArray = [NSMutableArray arrayWithCapacity:10];
    [self fromIndex:startIndex toIndex:endIndex performOnSections:^(ATLRoute *route, float start, float end){
        ATLRouteOverlay *overlay = [route overlayBetweenKM:start andKM:end];
        overlay.parentID = self.objectID;
        overlay.importance = 1;
        overlay.serviceGroup = self.group;
        [overlaysArray addObject:overlay];
    }];
    return overlaysArray;
}

#pragma mark - Enumeration methods

- (void)enumeratePreviousServices:(serviceInstructions)instructions
{
    for (ATLService *service in self.previousServices) {
        instructions(service);
    }
}

- (void)enumerateNextServices:(serviceInstructions)instructions
{
    for (ATLService *service in self.nextServices) {
        instructions(service);
    }
}

- (void)enumerateSeries:(seriesInstructions)instructions
{
    for (ATLSeriesRef *ref in self.seriesRefs) {
        ATLSeries *series = ref.series;
        instructions(series);
    }
}

- (void)enumerateServicePoints:(servicePointInstructions)instructions
{
    for (ATLServicePoint *servicePoint in self.arrangedServicePoints) {
        instructions(servicePoint);
    }
}

- (void)enumerateLocations:(locationInstructions)instructions
{
    [self enumerateServicePoints:^(ATLServicePoint *routePoint){instructions(routePoint.location);}];
}

- (void)from:(ATLLocation *)start to:(ATLLocation *)end enumerateIntermediateStations:(stationInstructions)instructions
{
    NSUInteger startIndex = [self indexOfLocation:start], endIndex = [self indexOfLocation:end];
    if (startIndex == NSNotFound || endIndex == NSNotFound || startIndex == endIndex) return;
    if (startIndex < endIndex) {
        for (NSUInteger index = startIndex + 1; index < endIndex; index++) {
            ATLLocation *item = self[index];
            if ([item isKindOfClass:[ATLStation class]]) instructions((ATLStation*)item);
        }
    } else {
        for (NSUInteger index = startIndex - 1; index > endIndex; index--) {
            ATLLocation *item = self[index];
            if ([item isKindOfClass:[ATLStation class]]) instructions((ATLStation*)item);
        }
    }
}

- (void)fromIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex performOnSections:(routeSectionInstructions)instructions
{
    ATLRoute *route = [self[startIndex] commonRouteWithItem:self[startIndex + 1]];
    double start_km = [self[startIndex] kmPositionInRoute:route];
    double end_km = start_km;
    
    for (NSUInteger index = startIndex; index <= endIndex; index++) {
        ATLLocation *location = self[index];
        if ([location isKindOfClass:[ATLJunction class]]) {
            end_km = [location kmPositionInRoute:route];
            instructions(route, MIN(start_km, end_km), MAX(start_km, end_km));
            route = [(ATLJunction*)location routeJoinedTo:route];
            start_km = [location kmPositionInRoute:route];
        }
    }
    end_km = [self[endIndex] kmPositionInRoute:route];
    instructions(route, MIN(start_km, end_km), MAX(start_km, end_km));
}

#pragma mark Utility methods

- (void)performOnRoutes:(routeInstructions)instructions
{
    ATLRoute *route = [self[0] commonRouteWithItem:self[1]];
    ATLServicePoint *firstRoutePoint = self.arrangedServicePoints[0];
    NSInteger direction = [self directionAtIndex:0];
    double offset = [firstRoutePoint.location kmPositionInRoute:route];
    double min_km = -1, max_km = -1;
    
    for (ATLServicePoint *servicePoint in self.arrangedServicePoints) {
        ATLLocation *location = servicePoint.location;
        if ([location isKindOfClass:[ATLJunction class]]) {
            max_km = servicePoint.km;
            instructions(route, direction, offset, min_km, max_km);
            
            route = [(ATLJunction*)location routeJoinedTo:route];
            direction = [(ATLJunction*)location sameDirection] ? direction : -direction;
            offset = [servicePoint.location kmPositionInRoute:route] - direction * servicePoint.km;
            min_km = max_km;
            max_km = -1;
        }
    }
    instructions(route, direction, offset, min_km, max_km);
}


#pragma mark - XML representation

- (void)appendAttributesToXMLString:(NSMutableString *)output
{
    NSString *express = self.expressService ? @"yes" : @"no";
    [output appendFormat:@" id=\"%@\" express=\"%@\" group=\"%d\" short=\"%@\" long=\"%@\" image=\"%@\"",
     self.id_, express, self.group, self.shortName, self.longName, self.imageName];
}

- (void)appendDataToXMLString:(NSMutableString *)output
{
    [output appendFormat:@"\t<frequency peak=\"%.1f\" base=\"%.1f\" offPeak=\"%.1f\"/>\n",
     self.peakFrequency, self.baseFrequency, self.offPeakFrequency];
    if (self.serviceOperator) {
        [output appendFormat:@"\t<operator>\n\t\t%@\t</operator>\n", self.serviceOperator.xmlReferenceString];
    }
    if (self.grantor) {
        [output appendFormat:@"\t<grantor>\n\t\t%@\t</grantor>\n", self.grantor.xmlReferenceString];
    }
    [output appendFormat:@"\t<seriesRefs>\n"];
    for (ATLSeriesRef *ref in self.seriesRefs) {
        [output appendString:ref.xmlSeriesRef];
    }
    [output appendFormat:@"\t</seriesRefs>\n"];
    
    if ([self.previousServices count] > 0) {
        [output appendFormat:@"\t<previousServices>\n"];
        [self enumeratePreviousServices:^(ATLService *service){
            [output appendFormat:@"\t\t"];
            [output appendString:service.xmlReferenceString];
        }];
        [output appendFormat:@"\t</previousServices>\n"];
    }
    if ([self.nextServices count] > 0) {
        [output appendFormat:@"\t<nextServices>\n"];
        [self enumerateNextServices:^(ATLService *service){
            [output appendFormat:@"\t\t"];
            [output appendString:service.xmlReferenceString];
        }];
        [output appendFormat:@"\t</nextServices>\n"];
    }
    [output appendFormat:@"\t<locations>\n"];
    for (ATLServicePoint *servicePoint in self.arrangedServicePoints) {
        [output appendString:servicePoint.xmlItemReference];
    }
    [output appendFormat:@"\t</locations>\n"];
    [output appendFormat:@"\t<upSchedule>\n"];
    for (ATLServicePoint *servicePoint in self.arrangedServicePoints) {
        if ([servicePoint.location isKindOfClass:[ATLStation class]]) {
            [output appendString:servicePoint.xmlUpSchedule];
        }
    }
    [output appendFormat:@"\t</upSchedule>\n"];
    [output appendFormat:@"\t<downSchedule>\n"];
    for (NSInteger i = [self.arrangedServicePoints count] - 1; i >= 0; i--) {
        ATLServicePoint *servicePoint = self.arrangedServicePoints[i];
        if ([servicePoint.location isKindOfClass:[ATLStation class]]) {
            [output appendString:servicePoint.xmlDownSchedule];
        }
    }
    [output appendFormat:@"\t</downSchedule>\n"];
    [output appendFormat:@"\t<serviceRules>\n"];
    for (ATLServiceRule *serviceRule in self.upServiceRules) {
        [output appendString:serviceRule.xmlString];
    }
    for (ATLServiceRule *serviceRule in self.downServiceRules) {
        [output appendString:serviceRule.xmlString];
    }
    [output appendFormat:@"\t</serviceRules>\n"];
}

@end

#pragma mark - Categories on NSDictionary

@implementation NSMutableDictionary (HistogramWritingMethods)

- (void)addMeasurementAtLabel:(NSString *)label entry:(id)entry amount:(NSInteger)amount
{
    NSMutableDictionary *histogram = self[label];
    if (!histogram) {
        histogram = [NSMutableDictionary dictionaryWithCapacity:10];
        self[label] = histogram;
    }
    [histogram addAmount:amount forEntry:entry];
}

- (void)addAmount:(NSInteger)amount forEntry:(id)entry
{
    NSInteger counter;
    NSNumber *counterObj = self[entry];
    if (counterObj == nil) {
        counter = 0;
    } else {
        counter = [counterObj intValue];
    }
    self[entry] = @(counter + amount);
}

@end

@implementation NSDictionary (HistogramReadingMethods)

- (int)occurrencesForLabel:(NSString *)label
{
    NSDictionary *histogram = self[label];
    int occurrences = 0;
    for (NSNumber *amount in [histogram allValues]) {
        occurrences += [amount intValue];
    }
    return occurrences;
}

- (id)mostCommonEntryForLabel:(NSString*)label
{
    NSDictionary *histogram = self[label];
    return [histogram mostCommonEntry];
}

- (id)mostCommonEntry
{
    NSInteger highestAmount = 0;
    id mostCommonKey = nil;
    for (id key in [self allKeys]) {
        NSInteger amount = [self[key] integerValue];
        if (amount > highestAmount) {
            highestAmount = amount;
            mostCommonKey = key;
        }
    }
    return mostCommonKey;
}

- (double)avarageValueForLabel:(NSString *)label
{
    NSDictionary *histogram = self[label];
    return [histogram avarageValue];
}

- (double)avarageValue
{
    NSUInteger totalMeasurements = 0;
    double totalAmount = 0;
    for (NSNumber *key in [self allKeys]) {
        NSInteger measurements = [self[key] integerValue];
        totalMeasurements += measurements;
        totalAmount += [key doubleValue] * measurements;
    }
    return totalAmount / totalMeasurements;
}

@end


double waitingTimeForFrequency(double frequency)
{
    return 30 / frequency;
}
