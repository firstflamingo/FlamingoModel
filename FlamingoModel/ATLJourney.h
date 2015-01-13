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
//  ATLJourney.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 31-07-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLEntry.h"

@class ATLJourneyElement, ATLTravelSection, ATLTrajectory, ATLVisit, ATLTransfer, ATLService, ATLStation;

/**
 ATLJourney is a model class representing a journey.
 It bundles a number of travelSections that the journey is composed of.
 */
@interface ATLJourney : ATLEntry

#pragma mark - managing the journey

@property (nonatomic) NSDate *departure;
@property (nonatomic) NSDate *arrival;
@property (nonatomic, retain) NSString *title;

- (void)extendToStation:(ATLStation*)station;

#pragma mark - managing times
/**
 Estimated Time of Departure, as stored in the ATLJourney instance.
 Must give the same result as journey.estimatedDeparture
 @returns the time the journey starts
 */
@property (nonatomic, retain) NSDate * timeOfDeparture;
/**
 Estimated Time of Arrival, as stored in the ATLJourney instance.
 Must give the same result as journey.estimatedArrival
 @returns the time the journey ends
 */
@property (nonatomic, retain) NSDate * timeOfArrival;
/**
 Sets the stored time values (timeOfDeparture, timeOfArrival) to the calculated values (estimatedDeparture, estimatedArrival)
 */
@property (nonatomic, readonly) NSTimeInterval duration;

- (void)recalculateTimesForeward:(BOOL)forewardDirection;

#pragma mark - managing Elements
/**
 @returns the number of elements contained by the journey
 */
@property (nonatomic, readonly) NSUInteger nrOfElements;
/**
 @returns a set with the travelsections of the journey
 */
@property (nonatomic, retain) NSSet *elements;
/**
 @returns a sorted array with the travelsections of the journey
 */
@property (nonatomic, strong) NSArray *arrangedElements;
/**
 Remove all elements from the journey - thus completely resetting the journey
 @param timestamp the time at which the action took place
 */
- (void)clearJourneyAtTime:(NSDate*)timestamp;

- (ATLJourneyElement*)objectAtIndexedSubscript:(NSUInteger)i;

#pragma mark - managing the current position
/**
 Index of the current element
 */
@property (nonatomic) int16_t positionIndex;
/**
 Updates the currentIndex to set value and updates element status accordingly
 @param newIndex the new value for currentIndex
 @param timestamp the time at which the transition took place
 */
- (void)setPositionIndex:(NSInteger)newIndex atTime:(NSDate*)timestamp;
/**
 Notifies the journey that its positionIndex will be updated. Must be called before changing the index.
 */
- (void)willUpdatePosition;
/**
 Notifies the journey that its positionIndex has been changed. Must be called after changing the index.
 */
- (void)didUpdatePosition;


#pragma mark - managing Visits
/**
 @returns the number of visits contained by the journey
 */
@property (nonatomic, readonly) NSUInteger nrOfVisits;
/**
 Provides the visit at the requested visitIndex, or nil if the index is out of range.
 */
- (ATLVisit*)visitAtIndex:(NSUInteger)index;
/**
 @returns the visit where the journey starts
 */
@property (nonatomic, readonly) ATLVisit *origin;
/**
 @returns the visit where the journey ends
 */
@property (nonatomic, readonly) ATLVisit *destination;

@property (nonatomic, readonly) ATLTransfer *firstTransfer;
@property (nonatomic, readonly) ATLTransfer *lastTransferWithStation;

/**
 Adds a visit at the indicated position. Pre-existing sections and visits at this, or a higher, position will be deleted. The journey will update its internal counting. This is the designated way to add visits.
 @param visit the new visit
 @param index the position where the new visit must be inserted
 */
- (void)addVisit:(ATLVisit*)visit atIndex:(NSUInteger)index;
/**
 Removes a visit, and all following elements, at given index from the journey and from the context
 */
- (void)removeVisitAtIndex:(NSUInteger)index;
/**
 Causes the journey to propagate the update message to its delegate
 */
- (void)updateVisit:(ATLVisit*)visit;

- (void)enumerateVisits:(void (^)(ATLVisit *))block;

- (void)enumerateTransfers:(void (^)(ATLTransfer *))block;

#pragma mark - managing travelSections
/**
 @returns the number of travelSections contained by the journey
 */
@property (nonatomic, readonly) NSUInteger nrOfTravelSections;
/**
 Provides the travelSection at the requested sectionIndex, or nil if the index is out of range.
 */
- (ATLTravelSection*)sectionAtIndex:(NSUInteger)index;
/**
 @returns the first section of the journey
 */
@property (nonatomic, readonly) ATLTravelSection *firstSection;
/**
 @returns the last section of the journey
 */
@property (nonatomic, readonly) ATLTravelSection *lastSection;
/**
 Adds a section at the indicated position. Pre-existing sections and visits at this, or a higher, position will be deleted. The journey will update its internal counting. This is the designated way to add sections.
 @param section the new travelSection
 @param index the position where the new section must be inserted
 */
- (void)addTravelSection:(ATLTravelSection *)section atIndex:(NSUInteger)index;
/**
 Removes a travelSection, and all following elements, at the given index from the journey and from the context
 */
- (void)removeTravelSectionAtIndex:(NSUInteger)index;
/**
 Causes the journey to propagate an update message to its delegate.
 */
- (void)updateTravelSection:(ATLTravelSection*)travelSection;
/**
 The missions that are visible to the user in this journey.
 */
@property (nonatomic, readonly) NSArray *visibleMissions;

- (void)enumerateTravelSections:(void (^)(ATLTravelSection *, BOOL *))block;

- (void)enumerateTrajectories:(void (^)(ATLTrajectory *, BOOL *))block;

@property (nonatomic, readonly) BOOL hasTrajectories;

#pragma mark -  Map Overlays

- (NSArray*)routeOverlays;

@end

@interface ATLJourney (CoreDataGeneratedAccessors)

- (void)addElementsObject:(ATLJourneyElement *)value;
- (void)removeElementsObject:(ATLJourneyElement *)value;
- (void)addElements:(NSSet *)values;
- (void)removeElements:(NSSet *)values;

@end

NSArray *shortestServicePath(ATLStation *origin, ATLStation *destination);

