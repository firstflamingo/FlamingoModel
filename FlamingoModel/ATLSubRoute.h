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
//  ATLSubRoute.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLRoute.h"

@class ATLRouteOverlay;

@interface ATLSubRoute : NSManagedObject

// Core Data properties
@property (nonatomic, retain) ATLRoute *route;

@property (nonatomic) float start;
@property (nonatomic) float end;
@property (nonatomic) double maxLat;
@property (nonatomic) double maxLon;
@property (nonatomic) double minLat;
@property (nonatomic) double minLon;

@property (nonatomic, retain) NSString * name;
@property (nonatomic) int16_t importance;
@property (nonatomic) int16_t gauge;
@property (nonatomic) int16_t electrification;
@property (nonatomic) int16_t nrOfTracks;
@property (nonatomic) int16_t speed;
@property (nonatomic, retain) NSString * signaling;
@property (nonatomic, retain) NSString *openedString;
@property (nonatomic) int16_t icGroup;
@property (nonatomic) int16_t regionGroup;

// Map Overlay

@property (nonatomic, strong) ATLRouteOverlay *overlay;

// Derived properties
@property (nonatomic, assign) float startKm;
@property (nonatomic, assign) float endKm;
@property (nonatomic, readonly) CLLocationCoordinate2D lowerLeft;
@property (nonatomic, readonly) CLLocationCoordinate2D upperRight;

@property (nonatomic, assign) NSString *gaugeString;
@property (nonatomic, assign) NSString *electrificationString;
@property (nonatomic, assign) NSString *nrOfTracksString;
@property (nonatomic, assign) NSString *speedString;

@property (nonatomic, readonly) NSString *icGroupName;
@property (nonatomic, readonly) NSString *regionGroupName;

- (void)copyPropertiesFromSubroute:(ATLSubRoute*)otherSubroute;

// XML representation

- (NSString*)xmlString;

@end
