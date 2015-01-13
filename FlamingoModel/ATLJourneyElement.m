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
//  ATLJourneyElement.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 31-07-14.
//

#import "ATLJourneyElement.h"
#import "ATLJourney.h"

@interface ATLJourneyElement ()

@property (nonatomic) int16_t statusInt;

@end


@implementation ATLJourneyElement

#pragma mark - Status and relations

@dynamic journey;

@dynamic statusInt;

- (void)setStatus:(ATLElementStatus)newStatus
{
    self.statusInt = (int16_t)newStatus;
}

- (ATLElementStatus)status
{
    return (ATLElementStatus)self.statusInt;
}

@dynamic order;

- (ATLJourneyElement *)previousElement
{
    NSInteger index = self.order - 1;
    if (index >= 0) {
        return self.journey.arrangedElements[index];
    }
    return nil;
}

- (ATLJourneyElement *)nextElement
{
    NSUInteger index = self.order + 1;
    if (index < self.journey.nrOfElements) {
        return self.journey.arrangedElements[index];
    }
    return nil;
}

- (void)passedBy
{
    if (self.status != ATLElementStatusCompleted) {
        self.status = ATLElementStatusCompleted;
        [self.previousElement passedBy];
    }
}

- (BOOL)isDummyElement
{
    return YES;
}

#pragma mark - Managing time

// To be implemented in subclasses

- (NSDate *)estimatedDeparture
{
    return nil;
}

- (NSDate *)estimatedArrival
{
    return nil;
}

- (NSDate *)endTime
{
    return nil;
}

- (void)recalculateTimesForeward:(BOOL)forewardDirection
{
    NSLog(@"recalculate times for %@", self);
    ATLJourneyElement *element;
    if (forewardDirection) {
        element = self.nextElement;
    } else {
        element = self.previousElement;
    }
    if (element) {
        [element recalculateTimesForeward:forewardDirection];
    } else {
        [self.journey recalculateTimesForeward:forewardDirection];
    }
}

@end
