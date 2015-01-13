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
//  ATLRouteOverlay.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 15-07-14.
//

#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>

typedef void (^ATLMapPointInstructions)(MKMapPoint a, MKMapPoint b, MKMapPoint c);

@interface ATLRouteOverlay : NSObject <MKOverlay> {
    MKMapPoint *mapPointA, *mapPointB, *mapPointC;
}

// Object lifecycle
- (id)initWithNrOfNodes:(int)number;

@property (nonatomic, strong) NSManagedObjectID *parentID;
@property (nonatomic, assign) unsigned char importance;
@property (nonatomic, assign) int16_t icGroup;
@property (nonatomic, assign) int16_t regionGroup;
@property (nonatomic, assign) int16_t serviceGroup;

// Geometric properties
@property (nonatomic, assign) int nrOfNodes;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) MKMapRect boundingMapRect;
@property (nonatomic, readonly) MKCoordinateRegion coordinateRegion;
- (void)setBoundsWithLowerLeft:(CLLocationCoordinate2D)lowerLeft upperRight:(CLLocationCoordinate2D)upperRight;
- (void)setCoordinateA:(CLLocationCoordinate2D)a coordinateB:(CLLocationCoordinate2D)b
           coordinateC:(CLLocationCoordinate2D)c atIndex:(int)index;
- (void)performOnAllMapPoints:(ATLMapPointInstructions)instructions;

// Debugging
- (void)logData;

@end
