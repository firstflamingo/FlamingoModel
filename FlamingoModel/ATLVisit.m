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
//  ATLVisit.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 31-07-14.
//

#import "ATLVisit.h"
#import "ATLTravelSection.h"
#import "ATLJourney.h"

@implementation ATLVisit

@dynamic timeOfArrival;
@dynamic timeOfDeparture;

- (ATLTravelSection *)arrival
{
    return (ATLTravelSection*)self.previousElement;
}

- (ATLTravelSection *)departure
{
    return (ATLTravelSection*)self.nextElement;
}

- (NSDate *)estimatedArrival
{
    if (self.arrival && self.status == ATLElementStatusExpected) {
        return self.arrival.estimatedArrival;
        
    } else {
        return self.timeOfArrival;
    }
}

- (NSDate *)estimatedDeparture
{
    switch (self.status) {
        case ATLElementStatusExpected:
            return self.arrival.estimatedArrival;
            
        case ATLElementStatusPresent:
            return [NSDate date];
            
        case ATLElementStatusCompleted:
            return self.timeOfDeparture;
            
        default:
            return nil;
    }
}

- (NSDate *)referenceTime
{
    switch (self.status) {
        case ATLElementStatusExpected:
            return self.arrival.estimatedArrival;
            
        case ATLElementStatusPresent:
            return [NSDate date];
            
        case ATLElementStatusCompleted:
            return self.timeOfDeparture;
            
        default:
            return nil;
    }
}

- (NSDate *)endTime
{
    return self.estimatedDeparture;
}

- (void)simulateStartTime
{
    if (self.arrival) {
        self.timeOfArrival = self.estimatedArrival;
    }
}

- (void)recalculateTimesForeward:(BOOL)forewardDirection
{
    if (forewardDirection) {
        self.timeOfDeparture = self.timeOfArrival;
    } else {
        self.timeOfArrival = self.timeOfDeparture;
    }
    [super recalculateTimesForeward:forewardDirection];
}

- (NSString *)displayName
{
    return @"visit";
}

@end
