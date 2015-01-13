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
//  ATLRoute.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import "ATLEntry.h"
#import "ATLLocation.h"
#import "ATLNode.h"

typedef void (^ATLCoordinateInstructions)(CLLocationCoordinate2D a, CLLocationCoordinate2D b, CLLocationCoordinate2D c);

typedef enum {
    pointA,
    pointB,
    pointC
} PointType;

typedef struct {
    CLLocationCoordinate2D coordinate;
    double heading;
} ATLGeoReference;

typedef struct {
    double minLon, minLat, maxLon, maxLat;
} ATLBounds;

ATLBounds ATLBoundsMakeInitial(CLLocationCoordinate2D initialCoordinate);
void ATLBoundsExtend(ATLBounds *bounds, CLLocationCoordinate2D coordinate);

@class ATLRoutePosition, ATLSubRoute, ATLRouteOverlay, ATLLocation, ATLNode;

@interface ATLRoute : ATLEntry

// Core Data properties
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *destination;
@property (nonatomic, retain) NSArray *heartLine;
@property (nonatomic, retain) NSString *origin;
@property (nonatomic, retain) NSSet *positions;
@property (nonatomic, retain) NSSet *subRoutes;

// Accessing the heartline
@property (nonatomic, readonly) NSUInteger nrOfNodes;
@property (nonatomic, readonly) ATLNode *firstNode, *lastNode;
- (ATLNode *)nodeAtIndex:(NSUInteger)index;

// Derived points
- (CLLocationCoordinate2D)coordinateAAtIndex:(NSUInteger)index;
- (CLLocationCoordinate2D)coordinateBAtIndex:(NSUInteger)index;
- (CLLocationCoordinate2D)coordinateCAtIndex:(NSUInteger)index;

// Calculating route length
@property (nonatomic, readonly) double start_km, end_km;
@property (nonatomic, readonly) double length;
@property (nonatomic, readonly) NSString *lengthString;

- (PolarSize)polarSizeBetweenIndex:(NSUInteger)indexA andIndex:(NSUInteger)indexB;
- (double)lengthOfSegmentAtIndex:(NSUInteger)index;
- (double)lengthOfCurveAtIndex:(NSUInteger)index;
- (void)updateRoutePositioning;
- (void)updateItemPositioning;

// Querying the route
- (RoutePosition)projectionOfCoordinate:(CLLocationCoordinate2D)coordinate withAccuracy:(double)accuracy;
- (ATLGeoReference)geoReferenceForPosition:(double)km;

// Managing subroutes
- (ATLRouteOverlay*)overlayBetweenKM:(float)startKM andKM:(float)endKM;
- (ATLSubRoute*)subRouteNamed:(NSString *)name;
- (void)setBoundsForSubroute:(ATLSubRoute*)subroute;

// Managing route items
- (ATLLocation*)locationAtPosition:(float)km;
- (void)insertLocation:(ATLLocation*)item atPosition:(float)km;

@end

@interface ATLRoute (CoreDataGeneratedAccessors)

- (void)addPositionsObject:(ATLRoutePosition *)value;
- (void)removePositionsObject:(ATLRoutePosition *)value;
- (void)addPositions:(NSSet *)values;
- (void)removePositions:(NSSet *)values;

- (void)addSubRoutesObject:(ATLSubRoute *)value;
- (void)removeSubRoutesObject:(ATLSubRoute *)value;
- (void)addSubRoutes:(NSSet *)values;
- (void)removeSubRoutes:(NSSet *)values;

@end
