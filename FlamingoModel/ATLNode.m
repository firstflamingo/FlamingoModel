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
//  ATLNode.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 05-03-12.
//

#import "ATLNode.h"

@implementation ATLNode

@synthesize coordinate, radius, km_a, km_b;

- (id)initWithLatitude:(double)lat longitude:(double)lon radius:(int)r km_a:(float)a km_b:(float)b
{
    self = [super init];
    if (self) {
        self.coordinate = CLLocationCoordinate2DMake(lat, lon);
        self.radius = r;
        self.km_a = a;
        self.km_b = b;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.coordinate = CLLocationCoordinate2DMake([aDecoder decodeDoubleForKey:@"lat"], [aDecoder decodeDoubleForKey:@"lon"]);
        self.radius = [aDecoder decodeIntForKey:@"radius"];
        self.km_a = [aDecoder decodeFloatForKey:@"km_a"];
        self.km_b = [aDecoder decodeFloatForKey:@"km_b"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeDouble:self.coordinate.latitude forKey:@"lat"];
    [aCoder encodeDouble:self.coordinate.longitude forKey:@"lon"];
    [aCoder encodeInt:self.radius forKey:@"radius"];
    [aCoder encodeFloat:self.km_a forKey:@"km_a"];
    [aCoder encodeFloat:self.km_b forKey:@"km_b"];
}

#pragma mark - Transformations relative to self

- (CGSize)meterSizeFromCoordinateSize:(CoordinateSize)coordSize
{
    double horScale = horScaleForLatitude(self.coordinate.latitude);
    return CGSizeMake(coordSize.deltaLon * horScale, coordSize.deltaLat * VER_SCALE);
}

- (CoordinateSize)coordinateSizeFromMeterSize:(CGSize)meterSize
{
    double horScale = horScaleForLatitude(self.coordinate.latitude);
    return coordinateSizeMake(meterSize.width / horScale, meterSize.height / VER_SCALE);
}

- (PolarSize)polarSizeBetween:(CLLocationCoordinate2D)coord1 and:(CLLocationCoordinate2D)coord2
{
    CoordinateSize size = coordinateSizeFromLine(coord1, coord2);
    return polarSizeFromCartesian([self meterSizeFromCoordinateSize:size]);
}

#pragma mark - XML representation

- (NSString *)xmlString
{
    NSString *format = @"\t<node lat=\"%.7f\" lon=\"%.7f\" radius=\"%0d\" km_a=\"%.3f\" km_b=\"%.3f\"/>\n";
    return [NSString stringWithFormat:format, self.coordinate.latitude, self.coordinate.longitude, self.radius, self.km_a, self.km_b];
}

@end
