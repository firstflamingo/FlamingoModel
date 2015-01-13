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
//  ATLTrajectory.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 01-08-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLTravelSection.h"

@class ATLMission, ATLMissionWrapper, ATLService, ATLStation, ATLStop;

@interface ATLTrajectory : ATLTravelSection

@property (nonatomic, retain) NSSet *missions;
@property (nonatomic, retain) ATLMission *selectedMission;

#pragma mark - Managing the trajectory
/**
 The station where the trajectory starts.
 */
@property (nonatomic, readonly) ATLStation *originStation;
/**
 The station where the trajectory end, or nil if not available.
 */
@property (nonatomic, strong) ATLStation *destinationStation;

@property (nonatomic, readonly) NSSet *availableServices;
@property (nonatomic, readonly) float peakFrequency;
@property (nonatomic, readonly) float baseFrequency;
@property (nonatomic, readonly) float offPeakFrequency;

@property (nonatomic, strong) NSArray *arrangedMissionWrappers;

- (ATLStop*)stopAtIndex:(NSUInteger)i;

#pragma mark -  Map Overlays

- (NSArray*)routeOverlays;

#pragma mark - Managing missions

@property (nonatomic, strong) ATLMission *mission;
@property (nonatomic, readonly) ATLMissionWrapper *selectedMissionWrapper;
- (ATLMissionWrapper*)wrapperAtRelativeIndex:(NSInteger)i;
- (void)selectMissionAtRelativeIndex:(NSInteger)index;

#pragma mark - Display options

@property (nonatomic, assign) BOOL showAlternatives;
@property (nonatomic, assign) BOOL showIntermediateStops;
- (void)toggleIntermediateStops;

@end

@interface ATLTrajectory (CoreDataGeneratedAccessors)

- (void)addMissionsObject:(ATLMission *)value;
- (void)removeMissionsObject:(ATLMission *)value;
- (void)addMissions:(NSSet *)values;
- (void)removeMissions:(NSSet *)values;

@end

@interface ATLMissionWrapper : NSObject

// Object lifecycle
- (instancetype)initWithTrajectory:(ATLTrajectory*)trajectory
                           mission:(ATLMission*)mission
                     originStation:(ATLStation*)originStation
                destinationStation:(ATLStation*)destinationStation;

// Connecting trajectory with a mission
@property (nonatomic, weak) ATLTrajectory *trajectory;
@property (nonatomic, readonly) ATLMission *mission;

// Managing origin and destination
@property (nonatomic) ATLStation *originStation;
@property (nonatomic) ATLStation *destinationStation;
@property (nonatomic, readonly) ATLStop *originStop;
@property (nonatomic, readonly) ATLStop *destinationStop;

// Managing intermediate stops
@property (nonatomic, readonly) NSUInteger nrOfStops;
- (ATLStop*)stopAtIndex:(NSUInteger)i;
- (void)enumerateIntermediateStops:(void(^)(ATLStop *))block;

// Derived properties
@property (nonatomic, readonly) ATLService *service;
@property (nonatomic, readonly) BOOL upDirection;
@property (nonatomic, readonly) NSDate *plannedDeparture;
@property (nonatomic, readonly) NSDate *estimatedDeparture;
@property (nonatomic, readonly) NSDate *plannedArrival;
@property (nonatomic, readonly) NSDate *estimatedArrival;
@property (nonatomic, readonly) NSString *infoText;

@end
