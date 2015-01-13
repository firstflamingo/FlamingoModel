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
//  ATLDataController.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 06-03-12.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>

#import "FFEDataController.h"

#define TESTING_ENVIRONMENT

@class ATLEntry, ATLRoute, ATLLocation, ATLMission, ATLStation, ATLJunction, ATLSeries, ATLService, ATLJourney;

@interface ATLDataController : FFEDataController

#pragma mark - Connecting to server

@property (nonatomic, strong) Class userClass;

#pragma mark - Inserting new objects

- (void)searchAndAddRoutesForItem:(ATLLocation*)item;
- (void)addJunctionsToRoute:(ATLRoute*)route;

#pragma mark - Accessing existing objects

- (NSManagedObject *)elementOfType:(NSString *)type withName:(NSString *)name;
- (NSManagedObject *)elementOfType:(NSString *)type withIdentifier:(NSString *)identifier;
- (NSSet *)routesAtCoordinate:(CLLocationCoordinate2D)coordinate;
- (ATLStation *)stationClosestToCoordinate:(CLLocationCoordinate2D)coordinate;
- (NSSet *)stationsWithinRange:(double)distanceInMeters ofCoordinate:(CLLocationCoordinate2D)coordinate;

/**
 Provides a journey that is occuring, or will occur within an hour of the given date
 @param date the moment in time at which the journey should
 @returns the requested RAJourney object or nil if not available
 */
- (ATLJourney *)journeyAtDate:(NSDate *)date;

- (NSArray *)subroutesBetweenLowerLeft:(CLLocationCoordinate2D)lowerLeft
                         andUpperRight:(CLLocationCoordinate2D)upperRight
                      importanceFilter:(int)importance;
- (NSArray *)routeItemsWithConnections:(NSUInteger)nrOfConnections;
- (NSArray *)orphanedPositions;
- (NSArray *)servicesAtRouteItem:(ATLLocation*)item;

- (ATLJunction *)findOrCreateJunctionBetweenRoute:(ATLRoute*)route1 andRoute:(ATLRoute*)route2;

#pragma mark - Changing exitsing objects

- (void)repositionRouteItems;
- (void)removeAllMissionRules;

#pragma mark - Finding shortest path

@property (strong) NSMutableSet *unexaminedNodes, *visitedNodes;
- (NSArray*)shortestDistancePathFrom:(ATLLocation*)origin to:(ATLLocation*)destination;

#pragma mark - Inserting parsed wikipedia properties

@property (strong) ATLEntry *currentObject;
@property (strong) NSURL *imagesDirectory;

@end
