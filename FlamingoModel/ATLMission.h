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
//  ATLMission.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 08-08-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLEntry.h"

@class ATLServiceRule, ATLStop, ATLTrajectory, ATLStation, ATLService;

@interface ATLMission : ATLEntry

@property (nonatomic, retain) NSDate * timeOfDeparture;
@property (nonatomic, retain) NSDate * timeOfArrival;

@property (nonatomic, retain) NSSet *serviceRules;
@property (nonatomic, retain) NSSet *selectingTrajectories;
@property (nonatomic, retain) NSSet *trajectories;
@property (nonatomic, retain) NSSet *stops;

@property (nonatomic, readonly) NSArray *arrangedServiceRules;

@property (nonatomic, readonly) int32_t block;
- (BOOL)sameTrainAsMission:(ATLMission*)otherMission;

/**
 @returns an array of stops, sorted by plannedArrival
 */
@property (nonatomic, strong) NSArray *arrangedStops;
/**
 An indexed subscript to the mission will return the stop at the indexed position.
 */
- (ATLStop*)objectAtIndexedSubscript:(NSUInteger)index;
/**
 The first stop of the mission
 */
@property (nonatomic, readonly) ATLStop *firstStop;
/**
 The last stop of the mission.
 */
@property (nonatomic, readonly) ATLStop *lastStop;

@property (nonatomic, readonly) NSDate *departure;
@property (nonatomic, readonly) NSDate *arrival;

- (ATLStop *)stopAtStation:(ATLStation*)station;
- (ATLServiceRule *)serviceRuleAtStation:(ATLStation*)station;

-(NSArray*)borderStationsBetweenStart:(ATLStation*)start andEnd:(ATLStation*)end;
- (void)enumerateStationsAfterStation:(ATLStation*)station withBlock:(void(^)(ATLStation *, ATLService *))block;

@end

@interface ATLMission (CoreDataGeneratedAccessors)

- (void)addServiceRulesObject:(ATLServiceRule *)value;
- (void)removeServiceRulesObject:(ATLServiceRule *)value;
- (void)addServiceRules:(NSSet *)values;
- (void)removeServiceRules:(NSSet *)values;

- (void)addSelectingTrajectoriesObject:(ATLTrajectory *)value;
- (void)removeSelectingTrajectoriesObject:(ATLTrajectory *)value;
- (void)addSelectingTrajectories:(NSSet *)values;
- (void)removeSelectingTrajectories:(NSSet *)values;

- (void)addTrajectoriesObject:(ATLTrajectory *)value;
- (void)removeTrajectoriesObject:(ATLTrajectory *)value;
- (void)addTrajectories:(NSSet *)values;
- (void)removeTrajectories:(NSSet *)values;

- (void)addStopsObject:(ATLStop *)value;
- (void)removeStopsObject:(ATLStop *)value;
- (void)addStops:(NSSet *)values;
- (void)removeStops:(NSSet *)values;

@end
