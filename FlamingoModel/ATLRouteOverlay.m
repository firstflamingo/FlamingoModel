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
//  ATLRouteOverlay.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 15-07-14.
//

#import "ATLRouteOverlay.h"

@implementation ATLRouteOverlay

#pragma mark - Object lifecycle

- (id)init
{
    return [self initWithNrOfNodes:0];
}

- (id)initWithNrOfNodes:(int)number
{
    self = [super init];
    if (self) {
        self.nrOfNodes = number;
        mapPointA = malloc(number * sizeof(MKMapPoint));
        mapPointB = malloc(number * sizeof(MKMapPoint));
        mapPointC = malloc(number * sizeof(MKMapPoint));
    }
    return self;
}

- (void)dealloc
{
    free(mapPointA);
    free(mapPointB);
    free(mapPointC);
}

#pragma mark - Geometric properties

- (MKCoordinateRegion)coordinateRegion
{
    return MKCoordinateRegionForMapRect(self.boundingMapRect);
}

- (void)setBoundsWithLowerLeft:(CLLocationCoordinate2D)lowerLeft upperRight:(CLLocationCoordinate2D)upperRight
{
    self.coordinate = CLLocationCoordinate2DMake(lowerLeft.latitude + 0.5 * (upperRight.latitude - lowerLeft.latitude),
                                                 lowerLeft.longitude + 0.5 * (upperRight.longitude - lowerLeft.longitude));
    MKMapPoint upperLeft = MKMapPointForCoordinate(CLLocationCoordinate2DMake(upperRight.latitude, lowerLeft.longitude));
    MKMapPoint lowerRight = MKMapPointForCoordinate(CLLocationCoordinate2DMake(lowerLeft.latitude, upperRight.longitude));
    self.boundingMapRect = MKMapRectMake(upperLeft.x, upperLeft.y, lowerRight.x - upperLeft.x, lowerRight.y - upperLeft.y);
}

- (void)setCoordinateA:(CLLocationCoordinate2D)a coordinateB:(CLLocationCoordinate2D)b
           coordinateC:(CLLocationCoordinate2D)c atIndex:(int)index
{
    if (index < self.nrOfNodes) {
        mapPointA[index] = MKMapPointForCoordinate(a);
        mapPointB[index] = MKMapPointForCoordinate(b);
        mapPointC[index] = MKMapPointForCoordinate(c);
    } else {
        NSLog(@"RLARoute cannot set coordinates because index (%d) is larger than nr of nodes (%d).", index, self.nrOfNodes);
    }
}

- (void)performOnAllMapPoints:(ATLMapPointInstructions)instructions
{
    for (int i = 0; i < self.nrOfNodes; i++) {
        instructions(mapPointA[i], mapPointB[i], mapPointC[i]);
    }
}

- (BOOL)intersectsMapRect:(MKMapRect)mapRect
{
    return MKMapRectIntersectsRect(self.boundingMapRect, mapRect);
}

#pragma mark - Debugging

-(void)logData
{
    NSLog(@"nrOfNodes: %d", self.nrOfNodes);
    for (int i = 0; i < self.nrOfNodes; i++) {
        NSLog(@"A = (%.0f, %.0f)", mapPointA[i].x, mapPointA[i].y);
        NSLog(@"B = (%.0f, %.0f)", mapPointB[i].x, mapPointB[i].y);
        NSLog(@"C = (%.0f, %.0f)", mapPointC[i].x, mapPointC[i].y);
    }
}

@end
