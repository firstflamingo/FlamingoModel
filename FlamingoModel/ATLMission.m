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
//  ATLMission.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 08-08-14.
//

#import "ATLMission.h"
#import "ATLService.h"
#import "ATLServiceRule.h"
#import "ATLServicePoint.h"
#import "ATLStop.h"
#import "ATLStation.h"
#import "ATLTrajectory.h"

#import "NSDate+Formatters.h"

@implementation ATLMission

@dynamic timeOfDeparture;
@dynamic timeOfArrival;
@dynamic serviceRules;
@dynamic selectingTrajectories;
@dynamic trajectories;
@dynamic stops;

- (NSString *)description
{
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"<ATLMission %@ on %@>\nservice rules:\n", self.id_, self.departure.nlDateString];
    for (ATLServiceRule *rule in self.arrangedServiceRules) {
        [string appendFormat:@"\t%@\n", rule];
    }
    [string appendString:@"stops:\n"];
    for (ATLStop *stop in self.arrangedStops) {
        [string appendFormat:@"\t%@\n", stop];
    }
    return string;
}

- (NSArray *)arrangedServiceRules
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"departure" ascending:YES];
    return [self.serviceRules sortedArrayUsingDescriptors:@[sort]];
}

- (int32_t)block
{
    ATLServiceRule *rule = [self.serviceRules anyObject];
    return rule.block;
}

- (BOOL)sameTrainAsMission:(ATLMission*)otherMission
{
    return (self == otherMission || self.block == otherMission.block);
}

#pragma mark - Managing stops

@synthesize arrangedStops = _arrangedStops;

- (NSArray *)arrangedStops
{
    if (!_arrangedStops) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"plannedArrival" ascending:YES];
        self.arrangedStops = [self.stops sortedArrayUsingDescriptors:@[sort]];
    }
    return _arrangedStops;
}

- (ATLStop*)objectAtIndexedSubscript:(NSUInteger)index
{
    return self.arrangedStops[index];
}

- (ATLStop *)firstStop
{
    return self[0];
}

- (ATLStop *)lastStop
{
    return [self.arrangedStops lastObject];
}

- (NSDate *)departure
{
    return self.firstStop.plannedDeparture;
}

- (NSDate *)arrival
{
    return self.lastStop.plannedArrival;
}

- (ATLStop *)stopAtStation:(ATLStation *)station
{
    for (ATLStop *stop in self.stops) {
        if (stop.station == station) {
            return stop;
        }
    }
    return nil;
}

- (ATLServiceRule *)serviceRuleAtStation:(ATLStation *)station
{
    for (ATLServiceRule *rule in [self.arrangedServiceRules reverseObjectEnumerator]) {
        if ([rule callsAtStation:station]) {
            return rule;
        }
    }
    return nil;
}

- (NSArray *)borderStationsBetweenStart:(ATLStation *)start andEnd:(ATLStation *)end
{
    if ([self.serviceRules count] == 1) {
        return @[];
    }
    
    BOOL flagStart = NO;
    BOOL flagEnd = NO;
    BOOL boarded = NO;
    NSMutableArray *stations = [NSMutableArray array];
    for (ATLServiceRule *rule in self.arrangedServiceRules) {
        ATLStation *currentStation;
        for (ATLServicePoint *point in rule.servicePointEnumerator) {
            currentStation = (ATLStation*)point.location;
            if (flagStart) {
                boarded = YES;
                if (currentStation == end) {
                    flagEnd = YES;
                    break;
                }
            } else {
                if (currentStation == start) {
                    flagStart = YES;
                }
            }
        }
        if (flagEnd) {
            break;
        } else {
            if (boarded) {
                [stations addObject:currentStation];
            }
        }
    }
    return stations;
}

- (void)enumerateStationsAfterStation:(ATLStation *)station withBlock:(void (^)(ATLStation *, ATLService *))block
{
    BOOL flagStart = NO;
    ATLStation *currentStation = nil;
    for (ATLServiceRule *rule in self.arrangedServiceRules) {
        for (ATLServicePoint *point in rule.servicePointEnumerator) {
            if (currentStation == (ATLStation*)point.location) {
                continue;
            }
            currentStation = (ATLStation*)point.location;
            if ([currentStation isKindOfClass:[ATLStation class]]) {
                if (flagStart) {
                    block(currentStation, rule.service);
                } else {
                    if (currentStation == station) {
                        flagStart = YES;
                    }
                }
            }
        }
    }
}

@end
