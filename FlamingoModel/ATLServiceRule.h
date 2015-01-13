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
//  ATLServiceRule.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 24-06-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLRule.h"

@class ATLService, ATLServicePoint, ATLStation, ATLStop, ATLMission, ATLTimePath;

@interface ATLServiceRule : ATLRule

@property (nonatomic, retain) ATLServicePoint *originPoint;
@property (nonatomic, retain) ATLServicePoint *destinationPoint;
@property (nonatomic, retain) NSSet *noStopPoints;
@property (nonatomic, retain) NSSet *instantatedMissions;
@property (nonatomic, retain) ATLService *service;

@property (nonatomic, strong) NSString * destinationCode;
@property (nonatomic, strong) NSString * originCode;
@property (nonatomic, readonly) NSString *trajectoryString;
@property (nonatomic, readonly) int16_t departure;
@property (nonatomic, readonly) int16_t arrival;


@property (nonatomic, readonly) id servicePointEnumerator;
- (void)createIdentifier;
- (ATLMission *)missionAtDate:(NSDate *)date;
- (void)verifyStopsWithTimePath:(ATLTimePath*)timePath;
- (BOOL)callsAtStation:(ATLStation*)station;
@property (nonatomic, readonly) NSArray *stationIDs;

@end

@interface ATLServiceRule (CoreDataGeneratedAccessors)

- (void)addInstantatedMissionsObject:(NSManagedObject *)value;
- (void)removeInstantatedMissionsObject:(NSManagedObject *)value;
- (void)addInstantatedMissions:(NSSet *)values;
- (void)removeInstantatedMissions:(NSSet *)values;

- (void)addNoStopPointsObject:(NSManagedObject *)value;
- (void)removeNoStopPointsObject:(NSManagedObject *)value;
- (void)addNoStopPoints:(NSSet *)values;
- (void)removeNoStopPoints:(NSSet *)values;

@end

@interface ATLDeparture : NSObject

- (instancetype)initWithPoint:(ATLServicePoint*)point rule:(ATLServiceRule*)rule atDate:(NSDate*)date;

@property (nonatomic, strong) ATLServicePoint *servicePoint;
@property (nonatomic, strong) ATLServiceRule *serviceRule;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDate *plannedDeparture;

@property (nonatomic, readonly) NSString *destination;
@property (nonatomic, readonly) ATLMission *mission;
@property (nonatomic, readonly) NSString *platform;
@property (nonatomic, readonly) int32_t block;

@end