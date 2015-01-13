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
//  ATLTravelSection.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 31-07-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLJourneyElement.h"

@class ATLJourney, ATLVisit, ATLStation;

@interface ATLTravelSection : ATLJourneyElement

#pragma mark - Relations of the section
/**
 The visit where the travelsection originates.
 */
@property (nonatomic, readonly) ATLVisit *origin;
/**
 Updates the internal counting to match the selected origin.
 */
- (void)updateOrigin;
/**
 The visit where the travelsection will end.
 */
@property (nonatomic, readonly) ATLVisit *destination;


/**
 Updates the internal counting to match the selected destination.
 */
- (void)updateDestination;
/**
 Indicates whether a location can be assigned as an origin or destination, based upon the current content of the travelsection.
 @param location the location that should be selected
 @returns YES or NO
 */
- (BOOL)canSelectLocation:(ATLStation*)location;
/**
 Sets a visit as the destination of the travelsection and performs additional initialization. The location of the visit must be set before it is passed to this method.
 @param destination the ATLVisit object that should be set as destination
 @param timestamp the time when the destination was selected
 @returns YES if the operation was successful
 */
- (void)selectDestination:(ATLVisit *)destination At:(NSDate*)timestamp;

@property (nonatomic) NSDate *timeOfDeparture;
@property (nonatomic) NSDate *timeOfArrival;

/**
 The missions that are visible to the user in this journey.
 */
@property (nonatomic, readonly) NSArray *visibleMissions;

@property (nonatomic, readonly) NSString *serviceName;

@end
