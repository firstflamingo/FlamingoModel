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
//  ATLTravelSection.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 31-07-14.
//

#import "ATLTravelSection.h"
#import "ATLJourney.h"
#import "ATLVisit.h"


@implementation ATLTravelSection

#pragma mark - Relations of the section

- (ATLVisit *)origin
{
    return (ATLVisit*)self.previousElement;
}

- (void)updateOrigin
{
    //empty: to be implemented in subclasses
}

- (ATLVisit *)destination
{
    return (ATLVisit*)self.nextElement;
}

- (void)updateDestination
{
    //empty: to be implemented in subclasses
}

- (BOOL)canSelectLocation:(ATLStation *)location
{
    return NO;
}

- (void)selectDestination:(ATLVisit *)destination At:(NSDate*)timestamp
{
    [self.journey addVisit:destination atIndex:(self.order + 1) / 2];
}

- (NSDate *)timeOfDeparture
{
    return self.origin.timeOfDeparture;
}

- (void)setTimeOfDeparture:(NSDate *)timeOfDeparture
{
    self.origin.timeOfDeparture = timeOfDeparture;
}

- (NSDate *)timeOfArrival
{
    return self.destination.timeOfArrival;
}

- (void)setTimeOfArrival:(NSDate *)timeOfArrival
{
    self.destination.timeOfArrival = timeOfArrival;
}

- (NSDate *)endTime
{
    return self.estimatedArrival;
}

- (NSArray *)visibleMissions
{
    // To be overwritten in subclasses
    return @[];
}

- (NSString *)serviceName
{
    return @"service";
}

@end
