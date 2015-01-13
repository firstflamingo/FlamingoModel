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
//  ATLVisit.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 31-07-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLJourneyElement.h"

@class ATLTravelSection;

@interface ATLVisit : ATLJourneyElement

/**
 The travelsection preceding the visit
 */
@property (nonatomic, readonly) ATLTravelSection *arrival;
/**
 The travelsection succeeding the visit
 */
@property (nonatomic, readonly) ATLTravelSection *departure;
/**
 Time of arrival, as stored in the visit
 */
@property (nonatomic, retain) NSDate *timeOfArrival;
/**
 Time of departure, as stored in the visit
 */
@property (nonatomic, retain) NSDate *timeOfDeparture;
/**
 The time that waiting time for a following trip should be referencing to.
 */
@property (nonatomic, readonly) NSDate *referenceTime;

@property (nonatomic, readonly) NSString *displayName;

@end
