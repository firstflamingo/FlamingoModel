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
//  ATLRoute.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import "ATLRoute.h"
#import "ATLSubRoute.h"
#import "ATLRouteOverlay.h"

typedef void (^ATLRangeInstructions)(ATLNode *node, CGSize delta);

@implementation ATLRoute

#pragma mark - Core Data properties

@dynamic name;
@dynamic destination;
@dynamic heartLine;
@dynamic origin;
@dynamic positions;
@dynamic subRoutes;

#pragma mark - FFESyncing methods

@synthesize lastClientModification, lastServerModification;

+ (NSString *)remotePath
{
    return @"atlas/route";
}

+ (NSArray *)acceptedDataTypes
{
    return @[@(DataTypeJSON)];
}

- (void)fillWithData:(NSData *)data ofType:(FFEDataType)type
{
}

- (NSData *)contentWithDataType:(FFEDataType)type
{
    return nil;
}

#pragma mark - Accessing the heartline

- (ATLNode *)firstNode
{
    [self willAccessValueForKey:@"firstNode"];
    ATLNode *node = [self nodeAtIndex:0];
    [self didAccessValueForKey:@"firstNode"];
    return node;
}

- (ATLNode *)lastNode
{
    [self willAccessValueForKey:@"lastNode"];
    ATLNode *node =  [self nodeAtIndex:self.nrOfNodes - 1];
    [self didAccessValueForKey:@"lastNode"];
    return node;
}

- (NSUInteger)nrOfNodes
{
    [self willAccessValueForKey:@"nrOfNodes"];
    NSUInteger number =  [self.heartLine count];
    [self didAccessValueForKey:@"nrOfNodes"];
    return number;
}

- (ATLNode *)nodeAtIndex:(NSUInteger)index
{
    return (self.heartLine)[index];
}

#pragma mark - Derived points

- (double)angleAtIndex:(NSInteger)index
{
    PolarSize next = [self polarSizeBetweenIndex:index andIndex:index + 1];
    PolarSize previous = [self polarSizeBetweenIndex:index andIndex:index - 1];
    return rangeMinusPiPlusPi(M_PI + next.angle - previous.angle);
}

- (CLLocationCoordinate2D)coordinateAAtIndex:(NSUInteger)index
{
    return [self derivedCoordinateAtIndex:index ofType:pointA];
}

- (CLLocationCoordinate2D)coordinateBAtIndex:(NSUInteger)index
{
    return [self derivedCoordinateAtIndex:index ofType:pointB];
}

- (CLLocationCoordinate2D)coordinateCAtIndex:(NSUInteger)index
{
    return [self derivedCoordinateAtIndex:index ofType:pointC];
}

#pragma mark Utility methods

- (CLLocationCoordinate2D)derivedCoordinateAtIndex:(NSInteger)index ofType:(PointType)type
{
    ATLNode *node = [self nodeAtIndex:index];
    CLLocationCoordinate2D coord = node.coordinate;
    if (node.radius == 0) return coord;
    
    PolarSize previousPolar = [self polarSizeBetweenIndex:index andIndex:index - 1];
    PolarSize nextPolar = [self polarSizeBetweenIndex:index andIndex:index + 1];
    PolarSize linePolar = (type == pointA) ? previousPolar : nextPolar;
    
    double angle = rangeMinusPiPlusPi(M_PI + nextPolar.angle - previousPolar.angle);
    double complementaryAngle;
    if (angle < 0) {
        complementaryAngle = -(M_PI + angle);
        angle = -angle;
    } else {
        complementaryAngle = (M_PI - angle);
    }
    
    switch (type) {
        case pointA:
        case pointB:
            linePolar.length = node.radius * tan(angle / 2);
            break;
            
        case pointC:
            linePolar.length = node.radius / cos(angle / 2);
            linePolar.angle += complementaryAngle / 2;
            break;
            
        default:
            NSLog(@"derivedPointInDirection:type: received unknown type: %d", type);
            break;
    }

    CoordinateSize delta = [node coordinateSizeFromMeterSize:cartesianSizeFromPolar(linePolar)];
    coord.latitude += delta.deltaLat;
    coord.longitude += delta.deltaLon;
    return coord;
}

#pragma mark - Calculating route length

- (double)start_km
{
    ATLNode *node = [self nodeAtIndex:0];
    return node.km_a;
}

- (double)end_km
{
    ATLNode *node = [self nodeAtIndex:self.nrOfNodes - 1];
    return node.km_b;
}

- (double)length
{
    ATLNode *firstNode = [self nodeAtIndex:0];
    ATLNode *lastNode = [self nodeAtIndex:self.nrOfNodes - 1];
    return lastNode.km_b - firstNode.km_a;
}

- (NSString *)lengthString
{
    if (self.heartLine) {
        return [NSString stringWithFormat:@"%.3f - %.3f", self.start_km, self.end_km];
    } else {
        return @"no heartline";
    }
}

- (PolarSize)polarSizeBetweenIndex:(NSUInteger)indexA andIndex:(NSUInteger)indexB
{
    NSInteger nrOfElements = self.nrOfNodes;
    if (indexA >= nrOfElements || indexB >= nrOfElements) return polarSizeMake(0, 0);
    
    ATLNode *nodeA = [self nodeAtIndex:indexA];
    ATLNode *nodeB = [self nodeAtIndex:indexB];
    
    return [nodeA polarSizeBetween:nodeA.coordinate and:nodeB.coordinate];
}

- (double)lengthOfSegmentAtIndex:(NSUInteger)index
{
    if (index < 1 || index >= self.nrOfNodes) return 0;
    ATLNode *node = [self nodeAtIndex:index];
    PolarSize polar = [node polarSizeBetween:[self coordinateBAtIndex:index - 1] and:[self coordinateAAtIndex:index]];
    return polar.length;
}

- (double)lengthOfCurveAtIndex:(NSUInteger)index
{
    if (index < 1 || index >= self.nrOfNodes) return 0;
    ATLNode *node = [self nodeAtIndex:index];
    return node.radius * fabs([self angleAtIndex:index]);
}

- (void)updateRoutePositioning
{
    ATLNode *node = [self nodeAtIndex:0];
    double routeLength = node.km_a;
    node.km_b = routeLength;
    for (NSUInteger i = 1; i < self.nrOfNodes; i++) {
        node = [self nodeAtIndex:i];
        routeLength += [self lengthOfSegmentAtIndex:i] / 1000;
        node.km_a = routeLength;
        routeLength += [self lengthOfCurveAtIndex:i] / 1000;
        node.km_b = routeLength;
    }
}

- (void)updateItemPositioning
{
    for (ATLRoutePosition *atlasPosition in self.positions) {
        RoutePosition routePosition = [self projectionOfCoordinate:atlasPosition.location.coordinate withAccuracy:100];
        if (validPosition(routePosition)) {
            NSLog(@"item %@: %.3f >>> %.3f", atlasPosition.location.id_, atlasPosition.km, routePosition.km);
            atlasPosition.km = routePosition.km;
        }
    }
}

#pragma mark - Querying the route

- (RoutePosition)projectionOfCoordinate:(CLLocationCoordinate2D)coordinate withAccuracy:(double)accuracy
{
    __block RoutePosition result = INVALID_POSITION;
    __block BOOL hit = NO;
    
    [self onSegmentWithinRange:accuracy
                  ofCoordinate:(CLLocationCoordinate2D)coordinate
                       perform:^(ATLNode *start, CGSize delta){
        hit = YES;
        result.km = start.km_b + (delta.width / 1000);
        result.transversal = delta.height;
    }];
    if (hit) return result;
    
    [self onCurveWithinRange:accuracy
                ofCoordinate:(CLLocationCoordinate2D)coordinate
                     perform:^(ATLNode *end, CGSize delta){
        hit = YES;
        result.km = end.km_a + (delta.width / 1000);
        result.transversal = delta.height;
    }];
    return result;
}

- (ATLGeoReference)geoReferenceForPosition:(double)km
{
    BOOL curve = NO;
    NSUInteger index = 0;
    return [self geoReferenceForPosition:km index:&index inCurve:&curve];
}

#pragma mark utility methods

- (NSUInteger)indexForPosition:(double)km inCurve:(BOOL *)curve
{
    for (NSUInteger i = 1; i < self.nrOfNodes; i++) {
        ATLNode *node = [self nodeAtIndex:i];
        if (km < node.km_a) {
            *curve = NO;
            return i;
        }
        if (km < node.km_b) {
            *curve = YES;
            return i;
        }
    }
    *curve = NO;
    return self.nrOfNodes - 1;
}

- (ATLGeoReference)geoReferenceForPosition:(double)km index:(NSUInteger *)index inCurve:(BOOL *)curve
{
    ATLGeoReference reference;
    reference.coordinate = CLLocationCoordinate2DMake(999, 999);
    reference.heading = 0;
    
    *index = [self indexForPosition:km inCurve:curve];
    if (*index > 0) {
        ATLNode *node = [self nodeAtIndex:*index];
        PolarSize linePolar;
        
        if (*curve) {
            double positionAngle = 1000 * (km - node.km_a) / node.radius;
            reference.coordinate = [self coordinateCAtIndex:*index];
            linePolar = [node polarSizeBetween:reference.coordinate and:[self coordinateAAtIndex:*index]];
            PolarSize endPolar = [node polarSizeBetween:reference.coordinate and:[self coordinateBAtIndex:*index]];
            double curveAngle = rangeMinusPiPlusPi(endPolar.angle - linePolar.angle);
            if (curveAngle < 0) {
                linePolar.angle -= positionAngle;
                reference.heading = rangeMinusPiPlusPi(linePolar.angle - M_PI_2);
            } else {
                linePolar.angle += positionAngle;
                reference.heading = rangeMinusPiPlusPi(linePolar.angle + M_PI_2);
            }
        } else {
            reference.coordinate = [self coordinateBAtIndex:*index - 1];
            linePolar = [node polarSizeBetween:reference.coordinate and:[self coordinateAAtIndex:*index]];
            linePolar.length -= 1000 * (node.km_a - km);
            reference.heading = linePolar.angle;
        }
        CoordinateSize delta = [node coordinateSizeFromMeterSize:cartesianSizeFromPolar(linePolar)];
        reference.coordinate.latitude += delta.deltaLat;
        reference.coordinate.longitude += delta.deltaLon;
    }
    return reference;
}

- (void)onSegmentWithinRange:(double)range ofCoordinate:(CLLocationCoordinate2D)hitCoord perform:(ATLRangeInstructions)instructions
{
    for (NSUInteger index = 0; index < self.nrOfNodes - 1; index++) {
        ATLNode *node = [self nodeAtIndex:index];
        CLLocationCoordinate2D startCoord = [self coordinateBAtIndex:index];
        PolarSize linePolar = [node polarSizeBetween:startCoord and:[self coordinateAAtIndex:index + 1]];
        PolarSize hitPolar = [node polarSizeBetween:startCoord and:hitCoord];
        
        if (hitPolar.length < linePolar.length) {
            hitPolar.angle -= linePolar.angle;
            CGSize delta = cartesianSizeFromPolar(hitPolar);
            if (delta.height > -range && delta.height < range && delta.width > 0) {
                instructions(node, delta);
                break;
            }
        }
    }
}

- (void)onCurveWithinRange:(double)range ofCoordinate:(CLLocationCoordinate2D)coordinate perform:(ATLRangeInstructions)instructions
{
    for (NSUInteger index = 1; index < self.nrOfNodes - 1; index++) {
        ATLNode *node = [self nodeAtIndex:index];
        int radius = node.radius;
        if (radius > 0) {
            PolarSize hitPolar = [node polarSizeBetween:[self coordinateCAtIndex:index] and:coordinate];
            if (hitPolar.length > radius - range && hitPolar.length < radius + range) {
                PolarSize linePolar = [node polarSizeBetween:[self coordinateBAtIndex:index - 1] and:[self coordinateAAtIndex:index]];
                double curveAngle = [self angleAtIndex:index];
                double capAngle = rangeMinusPiPlusPi( linePolar.angle - capInCurveDirection(curveAngle) );
                double angleDif = rangeMinusPiPlusPi( hitPolar.angle - capAngle );
                if ( (curveAngle > 0 && angleDif > 0 && angleDif < curveAngle) ||
                    (curveAngle < 0 && angleDif < 0 && angleDif > curveAngle)) {
                    CGSize delta;
                    delta.height = hitPolar.length - radius;
                    delta.width = fabs(angleDif) * radius;
                    instructions(node, delta);
                    break;
                }
            }
        }
    }
}

#pragma mark - Managing subroutes

- (ATLRouteOverlay *)overlayBetweenKM:(float)start andKM:(float)end
{
    int nrOfNodes = (int)[self nrOfNodesBetweenKM:start andKM:end];
    ATLRouteOverlay *overlay = [[ATLRouteOverlay alloc] initWithNrOfNodes:nrOfNodes];
    ATLBounds bounds = [self boundsForSectionBetweenKM:start andKM:end];
    [overlay setBoundsWithLowerLeft:CLLocationCoordinate2DMake(bounds.minLat, bounds.minLon)
                         upperRight:CLLocationCoordinate2DMake(bounds.maxLat, bounds.maxLon)];
    __block int index = 0;
    [self betweenKM:start andKM:end performOnAllNodes:^(CLLocationCoordinate2D a, CLLocationCoordinate2D b, CLLocationCoordinate2D c){
        [overlay setCoordinateA:a coordinateB:b coordinateC:c atIndex:index];
        index++;
    }];
    return overlay;
}

- (ATLSubRoute *)subRouteNamed:(NSString *)name
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATLSubRoute"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"route = %@ and name = %@", self, name];
    [request setPredicate:predicate];
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:NULL];
    NSAssert([result count] <= 1, @"Subroutes must not have the same name");
    
    if ([result count] == 1) {
        return result[0];
    } else {
        ATLSubRoute *subroute = (ATLSubRoute*)[[NSManagedObject alloc] initWithEntity:(self.entities)[@"ATLSubRoute"]
                                                       insertIntoManagedObjectContext:self.managedObjectContext];
        subroute.route = self;
        subroute.name = name;
        return subroute;
    }
}

- (void)setBoundsForSubroute:(ATLSubRoute *)subroute
{
    if (subroute.start < self.firstNode.km_a) subroute.start = self.firstNode.km_a;
    if (subroute.end > self.lastNode.km_b) subroute.end = self.lastNode.km_b;
    
    ATLBounds bounds = [self boundsForSectionBetweenKM:subroute.start andKM:subroute.end];
    subroute.minLat = bounds.minLat;
    subroute.minLon = bounds.minLon;
    subroute.maxLat = bounds.maxLat;
    subroute.maxLon = bounds.maxLon;
}

- (ATLBounds)boundsForSectionBetweenKM:(float)startKM andKM:(float)endKM
{
    NSAssert(startKM < endKM, @"start must be smaller than end in a subroute");
    
    BOOL curve = NO;
    NSUInteger index = 0;
    NSUInteger endIndex = 0;
    
    ATLGeoReference start = [self geoReferenceForPosition:startKM index:&index inCurve:&curve];
    ATLGeoReference end = [self geoReferenceForPosition:endKM index:&endIndex inCurve:&curve];
    ATLBounds bounds = ATLBoundsMakeInitial(start.coordinate);
    CLLocationCoordinate2D test = end.coordinate;
    
    while(YES) {
        ATLBoundsExtend(&bounds, test);
        if (index > endIndex) break;
        test = [self nodeAtIndex:index].coordinate;
        index++;
    }
    return bounds;
}

- (NSUInteger)nrOfNodesBetweenKM:(float)startKM andKM:(float)endKM
{
    BOOL startCurve = NO;
    NSUInteger startNode = [self indexForPosition:startKM inCurve:&startCurve];
    BOOL endCurve = NO;
    NSUInteger endNode = [self indexForPosition:endKM inCurve:&endCurve];
    
    if (startCurve) {
        return endNode - startNode + 1;
    } else {
        return endNode - startNode + 2;
    }
}

- (void)betweenKM:(float)startKM andKM:(float)endKM performOnAllNodes:(ATLCoordinateInstructions)instructions
{
    NSAssert(startKM < endKM, @"start must be smaller than end in a subroute");
    
    BOOL startCurve = NO;
    NSUInteger startNode = 0;
    ATLGeoReference start = [self geoReferenceForPosition:startKM index:&startNode inCurve:&startCurve];
    BOOL endCurve = NO;
    NSUInteger endNode = 0;
    ATLGeoReference end = [self geoReferenceForPosition:endKM index:&endNode inCurve:&endCurve];
    
    if (startCurve && startNode == endNode) {
        instructions(start.coordinate, end.coordinate, [self coordinateCAtIndex:startNode]);
    } else {
        
        NSUInteger node = startNode;
        if (startCurve) {
            instructions(start.coordinate, [self coordinateBAtIndex:startNode], [self coordinateCAtIndex:startNode]);
            node++;
        } else {
            instructions(start.coordinate, start.coordinate, start.coordinate);
        }
        while (node < endNode) {
            instructions([self coordinateAAtIndex:node], [self coordinateBAtIndex:node], [self coordinateCAtIndex:node]);
            node++;
        }
        if (endCurve) {
            instructions([self coordinateAAtIndex:endNode], end.coordinate, [self coordinateCAtIndex:endNode]);
        } else {
            instructions(end.coordinate, end.coordinate, end.coordinate);
        }
    }
}

#pragma mark - managing route items

- (ATLLocation *)locationAtPosition:(float)km
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATLRoutePosition"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"route = %@ and km = %@", self, @(km)];
    [request setPredicate:predicate];
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:NULL];
    if ([result count] == 1) {
        ATLRoutePosition *position = result[0];
        return position.location;
    } else {
        return nil;
    }
}

- (void)insertLocation:(ATLLocation *)location atPosition:(float)km
{
    ATLRoutePosition *position = [[ATLRoutePosition alloc] initWithEntity:self.entities[@"ATLRoutePosition"]
                                  insertIntoManagedObjectContext:self.managedObjectContext];
    position.location = location;
    position.route = self;
    position.km = km;
    
    ATLGeoReference geoRef = [self geoReferenceForPosition:km];
    position.coordinate = geoRef.coordinate;
}

#pragma mark - XML representation

- (void)appendAttributesToXMLString:(NSMutableString *)output
{
    [super appendAttributesToXMLString:output];
    [output appendFormat:@" name=\"%@\"", self.name];
}

- (void)appendDataToXMLString:(NSMutableString *)output
{
    [super appendDataToXMLString:output];
    [output appendFormat:@"<origin>%@</origin>\n", self.origin];
    [output appendFormat:@"<destination>%@</destination>\n", self.destination];
    if (self.heartLine) {
        [output appendString:@"<heartLine>\n"];
        for (ATLNode *node in self.heartLine) {
            [output appendString:[node xmlString]];
        }
        [output appendString:@"</heartLine>\n"];
    }
    if ([self.subRoutes count] > 0) {
        [output appendString:@"<subRoutes>\n"];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"start" ascending:YES];
        NSArray *sortedSubRoutes = [self.subRoutes sortedArrayUsingDescriptors:@[sort]];
        for (ATLSubRoute *subRoute in sortedSubRoutes) {
            [output appendString:[subRoute xmlString]];
        }
        [output appendString:@"</subRoutes>\n"];
    }
    if ([self.positions count] > 0) {
        [output appendString:@"<positions>\n"];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"km" ascending:YES];
        NSArray *sortedPositions = [self.positions sortedArrayUsingDescriptors:@[sort]];
        for (ATLRoutePosition *position in sortedPositions) {
            [output appendString:[position xmlItemRef]];
        }
        [output appendString:@"</positions>\n"];
    }
}

@end

ATLBounds ATLBoundsMakeInitial(CLLocationCoordinate2D initialCoordinate)
{
    return (ATLBounds){initialCoordinate.longitude, initialCoordinate.latitude, initialCoordinate.longitude, initialCoordinate.latitude};
}

void ATLBoundsExtend(ATLBounds *bounds, CLLocationCoordinate2D coordinate)
{
    if (bounds->minLat > coordinate.latitude) bounds->minLat = coordinate.latitude;
    if (bounds->minLon > coordinate.longitude) bounds->minLon = coordinate.longitude;
    if (bounds->maxLat < coordinate.latitude) bounds->maxLat = coordinate.latitude;
    if (bounds->maxLon < coordinate.longitude) bounds->maxLon = coordinate.longitude;
}
