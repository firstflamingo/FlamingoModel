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
//  ATLStation.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

#import "ATLLocation.h"
#import "ATLAlias.h"

typedef enum {
    neutralStation,
    oneStepStation,
    moreStepStation,
    openStation,
    intermediateStation,
    transferStation,
    arrivalStation,
    departureStation,
    startStation
} ATLStationRole;

@interface ATLStation : ATLLocation <MKAnnotation>

// Core Data properties
@property (nonatomic, retain) NSString *name;
@property (nonatomic) int16_t importance;
@property (nonatomic, retain) NSString *displayName;
@property (nonatomic) int16_t labelAngle;
@property (nonatomic, retain) NSString *wikiString;
@property (nonatomic, retain) NSString *openedString;
@property (nonatomic) int16_t icGroup;
@property (nonatomic) int16_t regionGroup;

@property (nonatomic, retain) NSSet *aliases;

// Managing aliases
- (void)setAliasesWithNames:(NSMutableSet *)newNames;
- (ATLAlias*)createAliasWithName:(NSString*)name;

@property (nonatomic, readonly) NSString *icGroupName;
@property (nonatomic, readonly) NSString *regionGroupName;

// Connecting with Wikipedia
@property (nonatomic, readonly) NSURL *wikiURL, *mWikiURL;

// Support for current journey
@property (nonatomic, assign) ATLStationRole stationRole;
@property (nonatomic, assign) int16_t arrivalGroup;
@property (nonatomic, assign) int16_t departureGroup;
@property (nonatomic, assign) double proximity;

// Timetable support
- (BOOL)hasDirectConnectionWithStation:(ATLStation*)otherStation;
- (NSArray*)departuresAfter:(NSDate*)startTime;

@end

@interface ATLStation (CoreDataGeneratedAccessors)

- (void)addAliasesObject:(ATLAlias *)value;
- (void)removeAliasesObject:(ATLAlias *)value;
- (void)addAliases:(NSSet *)values;
- (void)removeAliases:(NSSet *)values;

@end
