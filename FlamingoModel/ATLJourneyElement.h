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
//  ATLJourneyElement.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 31-07-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum {
    ATLElementStatusExpected = 0,
    ATLElementStatusPresent,
    ATLElementStatusCompleted
} ATLElementStatus;

@class ATLJourney;

@interface ATLJourneyElement : NSManagedObject

#pragma mark - Status and relations
/**
 The journey to which the element belongs.
 */
@property (nonatomic, retain) ATLJourney *journey;
/**
 The status of the element, indicating whether the element is traveled in future, present or past.
 */
@property (nonatomic, assign) ATLElementStatus status;
/**
 The position of the element within its journey
 */
@property (nonatomic) int16_t order;
/**
 Previous element in the journey or nil if not available.
 */
@property (nonatomic, readonly) ATLJourneyElement *previousElement;
/**
 Next element in the journey or nil if not available.
 */
@property (nonatomic, readonly) ATLJourneyElement *nextElement;
/**
 Notify the system that the element was passed. This will change the status of the element and all previous elements to competed.
 */
- (void)passedBy;

@property (nonatomic, readonly) BOOL isDummyElement;

#pragma mark - Managing time
/**
 Estimated Time of Departure of this element. The default implementation returns nil, the getter has to be overwritten by subclasses.
 */
@property (nonatomic, readonly) NSDate *estimatedDeparture;
/**
 Estimated Time of Arrival of this element. The default implementation returns nil, the getter has to be overwritten by subclasses.
 */
@property (nonatomic, readonly) NSDate *estimatedArrival;
/**
 The time when this element ends, either arrival or departure.
 */
@property (nonatomic, readonly) NSDate *endTime;

- (void)recalculateTimesForeward:(BOOL)forewardDirection;

@end
