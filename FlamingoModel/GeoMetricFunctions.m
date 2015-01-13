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
//  GeoMetricFunctions.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 06-03-12.
//

#import "GeoMetricFunctions.h"

#pragma mark - Creating and logging geographical coordinates

CoordinateSize coordinateSizeMake(double deltaLon, double deltaLat)
{
    CoordinateSize size;
    size.deltaLon = deltaLon;
    size.deltaLat = deltaLat;
    return size;
}

CoordinateRect coordinateRectMake(double longitude, double latitude, double deltaLon, double deltaLat)
{
    CoordinateRect rect;
    rect.origin = CLLocationCoordinate2DMake(latitude, longitude);
    rect.size = coordinateSizeMake(deltaLon, deltaLat);
    return rect;
}

PolarSize polarSizeMake(double angle, double length)
{
    PolarSize size;
    size.angle = angle;
    size.length = length;
    return size;
}

RoutePosition routePositionMake(double km, double transversal)
{
    RoutePosition position;
    position.km = km;
    position.transversal = transversal;
    return position;
}

BOOL validPosition(RoutePosition position)
{
    return position.km > -99000.0;
}

void logCLLocationCoordinate2D(NSString *label, CLLocationCoordinate2D coord)
{
    NSLog(@"%@ (longitude: %.7f latitude: %.7f)", label, coord.longitude, coord.latitude);
}

void logCoordinateSize(NSString *label, CoordinateSize size)
{
    NSLog(@"%@ (deltaLon: %.7f deltaLat: %.7f)", label, size.deltaLon, size.deltaLat);
}

void logCoordinateRect(NSString *label, CoordinateRect rect)
{
    NSLog(@"%@ (longitude: %.7f latitude: %.7f) (deltaLon: %.7f deltaLat: %.7f)",
          label, rect.origin.longitude, rect.origin.latitude, rect.size.deltaLon, rect.size.deltaLat);
}

void logPolarSize(NSString *label, PolarSize size)
{
    NSLog(@"%@ (angle: %.4f length: %.1f m)", label, size.angle, size.length);
}

void logRoutePosition(NSString *label, RoutePosition position)
{
    NSLog(@"%@ km: %.3f, transversal: %.0fm)", label, position.km, position.transversal);
}

#pragma mark - Calculating distance

double rangeMinusPiPlusPi(double anAngle)
{
    while (anAngle > M_PI) {
        anAngle -= 2 * M_PI;
    }
    while (anAngle < -M_PI) {
        anAngle += 2 * M_PI;
    }
    return anAngle;
}

double capInCurveDirection(double anAngle)
{
    if (anAngle > 0) {
        return M_PI / 2;
    } else {
        return -M_PI / 2;
    }
}

CGFloat pythagoras(CGSize size)
{
	return sqrt( size.width * size.width + size.height * size.height );
}

CGFloat distanceBetween(CGPoint point1, CGPoint point2)
{
    return pythagoras(cartesianSizeFromLine(point1, point2));
}

double horScaleForLatitude(double latitude)
{
	return VER_SCALE * cos(latitude * M_PI / 180);
}

CGSize cartesianSizeFromLine(CGPoint point1, CGPoint point2)
{
	CGSize size;
	size.width = point2.x - point1.x;
	size.height = point2.y - point1.y;
	return size;
}

CGSize cartesianSizeFromPolar(PolarSize polar)
{
	CGSize result;
	result.width = polar.length * cos(polar.angle);
	result.height = polar.length * sin(polar.angle);
	return result;
}

CoordinateSize coordinateSizeFromLine(CLLocationCoordinate2D point1, CLLocationCoordinate2D point2)
{
	CoordinateSize size;
	size.deltaLon = point2.longitude - point1.longitude;
	size.deltaLat = point2.latitude - point1.latitude;
	return size;
}

CoordinateRect coordinateRectFromCorners(CLLocationCoordinate2D downCorner, CLLocationCoordinate2D upCorner)
{
	CoordinateSize delta = coordinateSizeFromLine(downCorner, upCorner);
	return coordinateRectMake(downCorner.longitude,
                              downCorner.latitude,
                              delta.deltaLon + SMALL_VALUE,
                              delta.deltaLat + SMALL_VALUE);
}

PolarSize polarSizeFromCartesian(CGSize size)
{
	PolarSize result = polarSizeMake(0, pythagoras(size));
    if (result.length > 0) {
        if (size.height > 0) {
            result.angle = acos(size.width/result.length);
        } else {
            result.angle = -acos(size.width/result.length);
        }
    }
	return result;
}

PolarSize polarSizeFromLine(CGPoint point1, CGPoint point2)
{
    return polarSizeFromCartesian(cartesianSizeFromLine(point1, point2));
}
