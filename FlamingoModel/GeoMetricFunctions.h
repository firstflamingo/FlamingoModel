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
//  GeoMetricFunctions.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 06-03-12.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define VER_SCALE           111195.0
#define COORD_ACCURACY      1e-07
#define SMALL_VALUE         1e-08
#define INVALID_KM          -99999.9
#define INVALID_POSITION    routePositionMake(INVALID_KM, 0.0)

typedef struct {
    double deltaLon;
    double deltaLat;
} CoordinateSize;

typedef struct {
    CLLocationCoordinate2D origin;
    CoordinateSize size;
} CoordinateRect;

typedef struct {
	double angle;
	double length;
} PolarSize;

typedef struct {
    double km;              // longitudinal position in km
    double transversal;     // transversal position in m
} RoutePosition;

typedef enum {
    downStream = -1,
    upStream = 1
} RouteDirection;

// Creating and logging geographical coordinates
CoordinateSize coordinateSizeMake(double deltaLon, double deltaLat);
CoordinateRect coordinateRectMake(double longitude, double latitude, double deltaLon, double deltaLat);
PolarSize polarSizeMake(double angle, double length);
RoutePosition routePositionMake(double km, double transversal);
BOOL validPosition(RoutePosition position);
void logCLLocationCoordinate2D(NSString *label, CLLocationCoordinate2D coord);
void logCoordinateSize(NSString *label, CoordinateSize size);
void logCoordinateRect(NSString *label, CoordinateRect rect);
void logPolarSize(NSString *label, PolarSize size);
void logRoutePosition(NSString *label, RoutePosition position);

// Calculating distance
double rangeMinusPiPlusPi(double anAngle);
double capInCurveDirection(double anAngle);
CGFloat pythagoras(CGSize size);
CGFloat distanceBetween(CGPoint point1, CGPoint point2);
double horScaleForLatitude(double latitude);
CGSize cartesianSizeFromLine(CGPoint point1, CGPoint point2);
CGSize cartesianSizeFromPolar(PolarSize polar);
CoordinateSize coordinateSizeFromLine(CLLocationCoordinate2D point1, CLLocationCoordinate2D point2);
CoordinateRect coordinateRectFromCorners(CLLocationCoordinate2D downCorner, CLLocationCoordinate2D upCorner);
PolarSize polarSizeFromCartesian(CGSize size);
PolarSize polarSizeFromLine(CGPoint point1, CGPoint point2);
