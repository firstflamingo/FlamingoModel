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
//  ATLTimePath.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 26-06-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ATLMissionRule, ATLTimePoint;

@interface ATLTimePath : NSManagedObject

@property (nonatomic) uint32_t hash_;
@property (nonatomic, retain) NSData *timePointsData;
@property (nonatomic, retain) NSSet *missionRules;

@property (nonatomic, readonly) NSArray *timePoints;
@property (nonatomic, readonly) ATLTimePoint *firstPoint;
@property (nonatomic, readonly) ATLTimePoint *lastPoint;
@property (nonatomic, readonly) NSString *originCode;
@property (nonatomic, readonly) NSString *destinationCode;

+ (int16_t)normalizePointsArray:(NSArray*)array;
+ (uint32_t)hashForPointsArray:(NSArray*)array;
- (void)correctOffsetWith:(int)correction;
- (BOOL)callsAtStationWithID:(NSString*)stationID;
- (NSArray*)stationIDsFromID:(NSString*)firstID toID:(NSString*)lastID;

@end

@interface ATLTimePath (CoreDataGeneratedAccessors)

- (void)addMissionRulesObject:(ATLMissionRule *)value;
- (void)removeMissionRulesObject:(ATLMissionRule *)value;
- (void)addMissionRules:(NSSet *)values;
- (void)removeMissionRules:(NSSet *)values;

@end
