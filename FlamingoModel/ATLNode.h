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
//  ATLNode.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 05-03-12.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "GeoMetricFunctions.h"

@class ATLRoute;

@interface ATLNode : NSObject <NSCoding>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) int radius;
@property (nonatomic, assign) float km_a;
@property (nonatomic, assign) float km_b;

// object lifecycle
- (id)initWithLatitude:(double)lat longitude:(double)lon radius:(int)r km_a:(float)a km_b:(float)b;

// transformations relative to self
- (CGSize)meterSizeFromCoordinateSize:(CoordinateSize) coordSize;
- (CoordinateSize)coordinateSizeFromMeterSize:(CGSize) meterSize;
- (PolarSize)polarSizeBetween:(CLLocationCoordinate2D)coord1 and:(CLLocationCoordinate2D)coord2;

// XML representation
- (NSString*)xmlString;

@end
