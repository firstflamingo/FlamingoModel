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
//  ATLService.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 17-10-12.
//

#import "ATLSeries.h"

@class ATLSeriesRef, ATLServiceRef, ATLRoute, ATLServicePoint, ATLServiceRule, ATLLocation, ATLStation, ATLOrganization;

typedef void (^servicePointInstructions)(ATLServicePoint *routePoint);
typedef void (^locationInstructions)(ATLLocation *routeItem);
typedef void (^stationInstructions)(ATLStation *station);

@interface ATLService : ATLEntry

// Core Data Attributes
@property (nonatomic) float peakFrequency;
@property (nonatomic) float baseFrequency;
@property (nonatomic) float offPeakFrequency;
@property (nonatomic) BOOL expressService;
@property (nonatomic) int16_t group;
@property (nonatomic, retain) NSString *imageName;
@property (nonatomic, retain) NSString *shortName;
@property (nonatomic, retain) NSString *longName;

// Core Data Relations
@property (nonatomic, retain) NSSet *seriesRefs;
@property (nonatomic, retain) ATLOrganization *serviceOperator;
@property (nonatomic, retain) ATLOrganization *grantor;
@property (nonatomic, retain) NSSet *servicePoints;
@property (nonatomic, retain) NSSet *previousServiceRefs;
@property (nonatomic, retain) NSSet *nextServiceRefs;
@property (nonatomic, retain) NSSet *serviceRules;

// Service identity
@property (nonatomic, readonly) NSString *origin, *destination, *previousOrigins, *nextDestinations;
@property (nonatomic, readonly) NSString *groupName;
@property (nonatomic, readonly) NSString *groupCode;
@property (nonatomic, readonly) NSAttributedString *attributedName;

// Accessing references to series
@property (nonatomic, readonly) NSSet *seriesSet;
@property (nonatomic, readonly) NSArray *seriesReferences;
- (NSSet*)commonSeriesWithService:(ATLService*)otherService;
- (void)fillSchedule;

// Accessing serviceRules
@property (nonatomic, strong) NSArray *upServiceRules;
@property (nonatomic, strong) NSArray *downServiceRules;
- (void)clearServiceRules;
- (NSArray*)rulesFromPoint:(ATLServicePoint*)startPoint toPoint:(ATLServicePoint*)endPoint
                 startTime:(NSDate*)startTime endTime:(NSDate*)endTime useDeparture:(BOOL)useDeparture;
- (NSSet*)missionsFromStation:(ATLStation*)origin toStation:(ATLStation*)destination
                    startTime:(NSDate*)startTime endTime:(NSDate*)endTime useDeparture:(BOOL)useDeparture;
- (NSSet*)departuresFromPoint:(ATLServicePoint *)point startTime:(NSDate *)startTime endTime:(NSDate *)endTime;

// Accessing servicePoints
@property (nonatomic, strong) NSArray *arrangedServicePoints;
@property (assign) BOOL sorted;
@property (nonatomic, readonly) ATLServicePoint *firstServicePoint, *lastServicePoint;
- (ATLServicePoint *)servicePointAtIndex:(NSUInteger)index;
- (NSInteger)directionAtIndex:(NSInteger)index;
- (ATLServicePoint *)servicePointForLocation:(ATLLocation*)location;
- (ATLServicePoint *)servicePointWithCode:(NSString*)code;
- (NSUInteger)indexOfServicePoint:(ATLServicePoint*)point;
- (BOOL)infraDirectionAtIndex:(NSUInteger)i;

// Accessing locations
@property (nonatomic, readonly) ATLStation *firstStation, *lastStation;
@property (nonatomic, readonly) NSString *firstStationID, *lastStationID;
@property (nonatomic, readonly) NSString *firstStationName, *lastStationName;
@property (nonatomic, readonly) NSSet *intermediateStations;
- (NSUInteger)indexOfLocation:(ATLLocation*)item;
- (BOOL)containsLocation:(ATLLocation*)item;

// Editing locations
- (BOOL)insertLocation:(ATLLocation*)item;
- (ATLServicePoint*)insertLocation:(ATLLocation*)item atKM:(float)insert_km;
- (void)removeLocationAtIndex:(NSUInteger)index;

// Accessing connecting services
- (void) connectToNextService:(ATLService*)nextService;
@property (nonatomic, readonly) NSSet *previousServices, *nextServices;
@property (nonatomic, readonly) NSSet *allPreviousServices, *allNextServices;
@property (nonatomic, readonly) NSSet *allPreviousFirstRouteItems, *allNextLastRouteItems;
@property (nonatomic, readonly) NSSet *allPreviousIntermediateStations, *allNextIntermediateStations;

// Calculating travel time
- (double)waitingTimeAtRouteItem:(ATLLocation*)item fromService:(ATLService*)otherService;
- (double)travelTimeFrom:(ATLLocation*)origin to:(ATLLocation*)destination;

// Map Overlays
- (NSArray*)routeOverlays;
- (NSArray*)routeOverlaysFrom:(ATLLocation*)start to:(ATLLocation*)end;

// Enumeration methods
- (void)enumerateServicePoints:(servicePointInstructions)instructions;
- (void)enumerateLocations:(locationInstructions)instructions;
- (void)from:(ATLLocation*)start to:(ATLLocation*)end enumerateIntermediateStations:(stationInstructions)instructions;

@end

@interface ATLService (CoreDataGeneratedAccessors)

- (void)addSeriesRefsObject:(ATLSeriesRef *)value;
- (void)removeSeriesRefsObject:(ATLSeriesRef *)value;
- (void)addSeriesRefs:(NSSet *)values;
- (void)removeSeriesRefs:(NSSet *)values;

- (void)addServicePointsObject:(ATLServicePoint *)value;
- (void)removeServicePointsObject:(ATLServicePoint *)value;
- (void)addServicePoints:(NSSet *)values;
- (void)removeServicePoints:(NSSet *)values;

- (void)addPreviousServiceRefsObject:(ATLServiceRef *)value;
- (void)removePreviousServiceRefsObject:(ATLServiceRef *)value;
- (void)addPreviousServiceRefs:(NSSet *)values;
- (void)removePreviousServiceRefs:(NSSet *)values;

- (void)addNextServiceRefsObject:(ATLServiceRef *)value;
- (void)removeNextServiceRefsObject:(ATLServiceRef *)value;
- (void)addNextServiceRefs:(NSSet *)values;
- (void)removeNextServiceRefs:(NSSet *)values;

- (void)addServiceRulesObject:(ATLServiceRule *)value;
- (void)removeServiceRulesObject:(ATLServiceRule *)value;
- (void)addServiceRules:(NSSet *)values;
- (void)removeServiceRules:(NSSet *)values;

@end

