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
//  ATLStop.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 08-08-14.
//

#import "ATLStop.h"
#import "ATLMission.h"
#import "ATLStation.h"
#import "ATLServicePoint.h"

#import "NSDate+Formatters.h"

@implementation ATLStop

@dynamic plannedArrival;
@dynamic plannedDeparture;
@dynamic estimatedArrival;
@dynamic estimatedDeparture;
@dynamic platform;
@dynamic platformChange;
@dynamic destination;
@dynamic alteredDestination;
@dynamic statusInt;
@dynamic mission;
@dynamic station;


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: [%d] %@-%@ %@ spoor %@>",
            NSStringFromClass([self class]), self.statusInt, self.arrivalString, self.departureString, self.stationName, self.platform];
}

- (void)setDelay:(float)delay
{
    self.delayAtArrival = delay;
    self.delayAtDeparture = delay;
}

- (float)delay
{
    return (self.delayAtArrival + self.delayAtDeparture) / 2;
}

- (void)setDelayAtArrival:(float)delayAtArrival
{
    self.estimatedArrival = [self.plannedArrival dateByAddingTimeInterval:delayAtArrival * 60.0];
}

- (float)delayAtArrival
{
    return [self.estimatedArrival timeIntervalSinceDate:self.plannedArrival] / 60.0;
}

- (void)setDelayAtDeparture:(float)delayAtDeparture
{
    self.estimatedDeparture = [self.plannedDeparture dateByAddingTimeInterval:delayAtDeparture * 60.0];
}

- (float)delayAtDeparture
{
    return [self.estimatedDeparture timeIntervalSinceDate:self.plannedDeparture] / 60.0;
}

- (NSString *)arrivalString
{
    return self.plannedArrival.nlTimeString;
}

- (NSString *)departureString
{
    return self.plannedDeparture.nlTimeString;
}

- (NSString *)stationName
{
    return self.station.name;
}

@end
