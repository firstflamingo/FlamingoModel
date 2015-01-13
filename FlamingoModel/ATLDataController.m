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
//  ATLDataController.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 06-03-12.
//

#import "ATLDataController.h"

#import "ATLMission.h"
#import "ATLStop.h"
#import "ATLService.h"
#import "ATLServicePoint.h"
#import "ATLServiceRule.h"
#import "ATLSubRoute.h"
#import "ATLOrganization.h"
#import "ATLStation.h"
#import "ATLJunction.h"
#import "ATLPathNode.h"
#import "ATLSeries.h"
#import "ATLCatalog.h"
#import "ATLJourney.h"
#import "ATLVisit.h"
#import "ATLTransfer.h"

#import "NSManagedObjectContext+FFEUtilities.h"
#import "NSDate+Formatters.h"

#define SEARCH_MARGIN 1000
#define ONE_HOUR 3600.0

@implementation ATLDataController

#pragma mark - Configuration

- (NSString *)modelName
{
    return @"ATLModel";
}

- (NSString *)realm
{
    return @"backoffice02@firstflamingo.com";
}

- (Class)catalogClass
{
    return [ATLCatalog class];
}

- (Class)accountClass
{
    return self.userClass;
}

- (NSString *)serviceName
{
#ifdef TESTING_ENVIRONMENT
    return @"localhost_port11084";
#else
    return @"ffe-backoffice-02";
#endif
}

- (NSURL *)remoteHost
{
#ifdef TESTING_ENVIRONMENT
    return [NSURL URLWithString:@"http://localhost:11084"];
#else
    return [NSURL URLWithString:@"http://ffe-backoffice-02.appspot.com"];
#endif
}

#pragma mark - Inserting new Objects

- (void)searchAndAddRoutesForItem:(ATLLocation *)item
{
    for (ATLRoute *route in [self routesAtCoordinate:item.coordinate]) {
        if (![item isConnectedToRoute:route]) {
            RoutePosition routePosition = [route projectionOfCoordinate:item.coordinate withAccuracy:100];
            if (validPosition(routePosition)) {
                ATLRoutePosition *atlasPosition = (ATLRoutePosition*)[self.managedObjectContext createManagedObjectOfType:@"ATLRoutePosition"];
                atlasPosition.km = routePosition.km;
                atlasPosition.location = item;
                atlasPosition.route = route;
            }
        }
    }
}

- (void)addJunctionsToRoute:(ATLRoute *)originalRoute
{
    NSSet *nodes = [NSSet setWithObjects:originalRoute.firstNode, originalRoute.lastNode, nil];
    for (ATLNode *node in nodes) {
        ATLRoute *connectedRoute = nil;
        RoutePosition connectPosition = routePositionMake(INVALID_KM, SEARCH_MARGIN);
        for (ATLRoute *foundRoute in [self routesAtCoordinate:node.coordinate]) {
            RoutePosition foundPosition = [foundRoute projectionOfCoordinate:node.coordinate withAccuracy:200];
            if (validPosition(foundPosition) && fabs(foundPosition.transversal) < fabs(connectPosition.transversal)) {
                connectedRoute = foundRoute;
                connectPosition = foundPosition;
            }
        }
        if (connectedRoute) {
            ATLJunction *junction = (ATLJunction*)[self.managedObjectContext createManagedObjectOfType:@"ATLJunction"];
            ATLGeoReference original = [originalRoute geoReferenceForPosition:node.km_a];
            ATLGeoReference connected = [connectedRoute geoReferenceForPosition:connectPosition.km];
            junction.sameDirection = (BOOL)(fabs(rangeMinusPiPlusPi(original.heading - connected.heading)) < M_PI_2);
            [originalRoute insertLocation:junction atPosition:node.km_b];
            [connectedRoute insertLocation:junction atPosition:connectPosition.km];
            for (ATLRoutePosition *position in junction.routePositions) {
                position.coordinate = connected.coordinate;
            }
        }
    }
}

#pragma mark - Accessing existing objects

- (NSManagedObject *)elementOfType:(NSString *)type withName:(NSString *)name
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name = %@)", name];
    return [self.managedObjectContext fetchUniqueInstanceOfType:type withPredicate:predicate];
}

- (NSManagedObject *)elementOfType:(NSString *)type withIdentifier:(NSString *)identifier
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(id_ = %@)", identifier];
    return [self.managedObjectContext fetchUniqueInstanceOfType:type withPredicate:predicate];
}

- (NSSet *)routesAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    // Search routes within reach of the coordinate
    NSMutableSet *routes = [NSMutableSet setWithCapacity:10];
    NSPredicate *predicate = [self searchPredicateForArea:YES withinRange:SEARCH_MARGIN fromCoordinate:coordinate];
    
    for (ATLSubRoute *subroute in [self.managedObjectContext fetchInstancesOfType:@"ATLSubRoute" withPredicate:predicate]) {
        [routes addObject:subroute.route];
    }
    return routes;
}

- (ATLStation *)stationClosestToCoordinate:(CLLocationCoordinate2D)coordinate
{
    ATLStation *closestStation = nil;
    double closestDistance = 1E308;
    for (ATLStation *station in [self stationsWithinRange:5000 ofCoordinate:coordinate]) {
        CoordinateSize coordSize = coordinateSizeFromLine(coordinate, station.coordinate);
        CGSize meterSize = CGSizeMake(coordSize.deltaLon * horScaleForLatitude(coordinate.latitude), coordSize.deltaLat * VER_SCALE);
        double distance = pythagoras(meterSize);
        if (distance < closestDistance) {
            closestStation = station;
            closestDistance = distance;
        }
    }
    return closestStation;
}

- (NSSet *)stationsWithinRange:(double)distanceInMeters ofCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSPredicate *predicate = [self searchPredicateForArea:NO withinRange:distanceInMeters fromCoordinate:coordinate];
    NSArray *closePositions = [self.managedObjectContext fetchInstancesOfType:@"ATLRoutePosition" withPredicate:predicate];
    NSMutableSet *foundStations = [NSMutableSet setWithCapacity:5];
    for (ATLRoutePosition *position in closePositions) {
        ATLLocation *location = position.location;
        if ([location isKindOfClass:[ATLStation class]]) {
            [foundStations addObject:location];
        }
    }
    return foundStations;
}

- (NSPredicate *)searchPredicateForArea:(BOOL)isArea
                            withinRange:(double)distanceInMeters
                         fromCoordinate:(CLLocationCoordinate2D)coordinate
{
    double deltaLon = distanceInMeters / horScaleForLatitude(coordinate.latitude);
    double deltaLat = distanceInMeters / VER_SCALE;
    NSNumber *minLon = @(coordinate.longitude - deltaLon);
    NSNumber *maxLon = @(coordinate.longitude + deltaLon);
    NSNumber *minLat = @(coordinate.latitude - deltaLat);
    NSNumber *maxLat = @(coordinate.latitude + deltaLat);
    if (isArea) {
        return [NSPredicate predicateWithFormat:
                @"(minLon < %@) AND (maxLon > %@) AND (minLat < %@) AND (maxLat > %@)", maxLon, minLon, maxLat, minLat];
    } else {
        return [NSPredicate predicateWithFormat:
                @"(longitude < %@) AND (longitude > %@) AND (latitude < %@) AND (latitude > %@)", maxLon, minLon, maxLat, minLat];
    }
}

- (ATLJourney *)journeyAtDate:(NSDate *)date
{
    NSDate *limit = [date dateByAddingTimeInterval:ONE_HOUR];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(timeOfDeparture <= %@) AND (timeOfArrival >= %@)", limit, date];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATLJourney"];
    [request setPredicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timeOfDeparture" ascending:YES];
    [request setSortDescriptors:@[sort]];
    
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:NULL];
    if ([result count] > 0) {
        return result[0];
    } else {
        return nil;
    }
}

- (NSArray *)subroutesBetweenLowerLeft:(CLLocationCoordinate2D)lowerLeft
                         andUpperRight:(CLLocationCoordinate2D)upperRight
                      importanceFilter:(int)importance
{
	NSNumber *minLat = @(lowerLeft.latitude);
    NSNumber *minLon = @(lowerLeft.longitude);
	NSNumber *maxLat = @(upperRight.latitude);
	NSNumber *maxLon = @(upperRight.longitude);
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
//	 @"(minLat > %@) AND (minLon > %@) AND (maxLat < %@) AND (maxLon < %@) AND (importance <= %d)",
                              @"(importance <= %d)",
	 maxLat, maxLon, minLat, minLon, importance];
    return [self.managedObjectContext fetchInstancesOfType:@"ATLSubRoute" withPredicate:predicate];
}

- (NSArray *)routeItemsWithConnections:(NSUInteger)nrOfConnections
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"positions.@count == %d", nrOfConnections];
    return [self.managedObjectContext fetchInstancesOfType:@"ATLLocation" withPredicate:predicate];
}

- (NSArray *)orphanedPositions
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"route = %@ or item = %@", nil, nil];
    return [self.managedObjectContext fetchInstancesOfType:@"ATLRoutePosition" withPredicate:predicate];
}

- (NSArray *)servicesAtRouteItem:(ATLLocation *)location
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"id_" ascending:YES];
    return [location.services sortedArrayUsingDescriptors:@[sort]];
}

- (ATLJunction *)findOrCreateJunctionBetweenRoute:(ATLRoute *)route1 andRoute:(ATLRoute *)route2
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY positions.route = %@ and ANY positions.route = %@", route1, route2];
    ATLJunction *junction = (ATLJunction*)[self.managedObjectContext fetchUniqueInstanceOfType:@"ATLJunction" withPredicate:predicate];
    if (!junction) {
        junction = (ATLJunction*)[self.managedObjectContext createManagedObjectOfType:@"ATLJunction"];
        ATLRoutePosition *position1 = (ATLRoutePosition*)[self.managedObjectContext createManagedObjectOfType:@"ATLRoutePosition"];
        position1.route = route1;
        position1.location = junction;
        ATLRoutePosition *position2 = (ATLRoutePosition*)[self.managedObjectContext createManagedObjectOfType:@"ATLRoutePosition"];
        position2.route = route2;
        position2.location = junction;
    }
    return junction;
}

#pragma mark - Changing exitsing objects

- (void)repositionRouteItems
{
    for (ATLLocation *item in [self routeItemsWithConnections:1]) {
        ATLRoutePosition *position = [item.routePositions anyObject];
        ATLGeoReference reference = [position.route geoReferenceForPosition:position.km];
        if (CLLocationCoordinate2DIsValid(reference.coordinate)) {
            NSLog(@"position %@ (%.6f, %.6f) >>> (%.6f, %.6f)",
                  item.id_, item.coordinate.latitude, item.coordinate.longitude, reference.coordinate.latitude, reference.coordinate.longitude);
            position.coordinate = reference.coordinate;
        }
    }
}

- (void)removeAllMissionRules
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATLMissionRule"];
	NSArray *expiredObjects = [self.managedObjectContext executeFetchRequest:request error:NULL];
    NSLog(@"Remove %d mission rules", (int)[expiredObjects count]);
    for (NSManagedObject *expiredObject in expiredObjects) {
        [self.managedObjectContext deleteObject:expiredObject];
    }
    request = [NSFetchRequest fetchRequestWithEntityName:@"ATLTimePath"];
	expiredObjects = [self.managedObjectContext executeFetchRequest:request error:NULL];
    NSLog(@"Remove %d time paths", (int)[expiredObjects count]);
    for (NSManagedObject *expiredObject in expiredObjects) {
        [self.managedObjectContext deleteObject:expiredObject];
    }
}

#pragma mark - Finding shortest path

-(NSArray *)shortestDistancePathFrom:(ATLLocation *)origin to:(ATLLocation *)destination
{
    self.unexaminedNodes = [NSMutableSet setWithCapacity:100];
    self.visitedNodes = [NSMutableSet setWithCapacity:50];
    
    // Set initial nodes for each route of the origin
    for (ATLRoute *route in origin.routes) {
        ATLPathNode *pathItem = [[ATLPathNode alloc] initWithParent:origin];
        pathItem.route = route;
        pathItem.searchDirection = both;
        pathItem.distance = 0;
        [self.unexaminedNodes addObject:pathItem];
    }
    
    while ([self.unexaminedNodes count] > 0) {
        
        // Search the unexamined node with shortest distance to origin
        ATLPathNode *currentNode = nil;
        double currentDistance = 1E308;
        for (ATLPathNode *testNode in self.unexaminedNodes) {
            if (testNode.distance < currentDistance) {
                currentNode = testNode;
                currentDistance = testNode.distance;
            }
        }
        currentNode.visited = YES;
        [self.visitedNodes addObject:currentNode];
        [self.unexaminedNodes removeObject:currentNode];
        
        // Break loop if that node is the destination
        if (currentNode.parent == destination) break;
        
        // Examine all neighbors on the same route and set their distance from origin
        double current_km = [currentNode.parent kmPositionInRoute:currentNode.route];
        for (ATLRoutePosition *position in currentNode.route.positions) {
            if ([currentNode validPosition:position]) {
                ATLLocation *item = position.location;
                if (!item.pathNode.visited && ([item isKindOfClass:[ATLJunction class]] || item == destination)) {
                    ATLPathNode *neighborNode = item.pathNode;
                    if (!neighborNode) {
                        neighborNode = [[ATLPathNode alloc] initWithParent:item];
                        [self.unexaminedNodes addObject:neighborNode];
                    }
                    double newDistance = currentDistance + fabs(position.km - current_km);
                    if (neighborNode.distance > newDistance) {
                        neighborNode.distance = newDistance;
                        neighborNode.previousNode = currentNode;
                        if ([item isKindOfClass:[ATLJunction class]]) {
                            neighborNode.route = [(ATLJunction*)item routeJoinedTo:currentNode.route];
                            ATLSearchDirection direction = currentNode.searchDirection;
                            if (!direction) direction = position.km > current_km ? up : down;
                            neighborNode.searchDirection = [(ATLJunction*)item sameDirection] ? direction : -direction;
                        } else {
                            neighborNode.route = currentNode.route;
                        }
                    }
                }
            }
        }
    }
    
    // Compose array with the found path
    NSMutableArray *result = nil;
    if (destination.pathNode) {
        result = [NSMutableArray arrayWithCapacity:20];
        ATLPathNode *node = destination.pathNode;
        while (node) {
            [result insertObject:node atIndex:0];
            node = node.previousNode;
        }
    }
    
    // Cleanup
    for (ATLPathNode *node in self.unexaminedNodes) {
        [node disconnectNode];
    }
    self.unexaminedNodes = nil;
    for (ATLPathNode *node in self.visitedNodes) {
        [node disconnectNode];
    }
    self.visitedNodes = nil;
    return result;
}

#pragma mark - Inserting parsed Wikipedia properties
@synthesize currentObject = _currentObject;
@synthesize imagesDirectory = _imagesDirectory;

@end

