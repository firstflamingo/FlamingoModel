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
//  ATLRouteItem.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import "ATLEntry.h"
#import "ATLRoutePosition.h"

#if TARGET_OS_MAC

#import <Cocoa/Cocoa.h>
#define ROUTE_ITEM_UTI      @"nl.firstflamingo.railatlas.routeitem"

#endif

@class ATLRoute, ATLPathNode;

@interface ATLLocation : ATLEntry

#if TARGET_OS_MAC
<NSPasteboardWriting, NSPasteboardReading, FFESyncing>
#endif

// Inherent properties
@property (nonatomic, retain) NSSet *routePositions;
@property (nonatomic, retain) NSSet *servicePoints;

@property (nonatomic, readonly) NSSet *routes;
@property (nonatomic, readonly) NSString *statusString;
@property (nonatomic, readonly) NSString *symbolName;

// deduced properties
@property (nonatomic, assign) NSString *country;
@property (nonatomic, assign) NSString *code;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) double latitude, longitude;

// Path finding
@property (weak) ATLPathNode *pathNode;

// Relating to services
@property (nonatomic, readonly) NSSet *services;

// Relating to routes
- (ATLRoute*)commonRouteWithItem:(ATLLocation*)item;
- (double)kmPositionInRoute:(ATLRoute*)route;
- (BOOL)isOnRoute:(ATLRoute*)route;
- (BOOL)isConnectedToRoute:(ATLRoute*)route;

// Date representation
+ (NSString*)stringFromDate:(NSDate*)date;
+ (NSDate*)dateFromString:(NSString*)string;


@end

@interface ATLLocation (CoreDataGeneratedAccessors)

- (void)addRoutePositionsObject:(ATLRoutePosition *)value;
- (void)removeRoutePositionsObject:(ATLRoutePosition *)value;
- (void)addRoutePositions:(NSSet *)values;
- (void)removeRoutePositions:(NSSet *)values;

@end

