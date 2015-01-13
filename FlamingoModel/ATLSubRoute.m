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
//  ATLSubRoute.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import "ATLSubRoute.h"
#import "ATLRouteOverlay.h"


@implementation ATLSubRoute

@dynamic electrification;
@dynamic end;
@dynamic gauge;
@dynamic importance;
@dynamic maxLat;
@dynamic maxLon;
@dynamic minLat;
@dynamic minLon;
@dynamic name;
@dynamic nrOfTracks;
@dynamic openedString;
@dynamic signaling;
@dynamic speed;
@dynamic start;
@dynamic route;
@dynamic icGroup;
@dynamic regionGroup;

#pragma mark - Map Overlay
@synthesize overlay = _overlay;

- (ATLRouteOverlay *)overlay {
    if (!_overlay) {
        _overlay = [self.route overlayBetweenKM:self.start andKM:self.end];
        _overlay.importance = self.importance;
        _overlay.regionGroup = self.regionGroup;
        _overlay.icGroup = self.icGroup;
        _overlay.serviceGroup = groupNeutral;
        _overlay.parentID = [self objectID];
    }
    return _overlay;
}

#pragma mark - derived properties

- (float)startKm
{
    return self.start;
}

- (void)setStartKm:(float)startKm
{
    self.start = startKm;
    [self.route setBoundsForSubroute:self];
}

- (float)endKm
{
    return self.end;
}

- (void)setEndKm:(float)endKm
{
    self.end = endKm;
    [self.route setBoundsForSubroute:self];
}

- (CLLocationCoordinate2D)lowerLeft
{
    return CLLocationCoordinate2DMake(self.minLat, self.minLon);
}

- (CLLocationCoordinate2D)upperRight
{
    return CLLocationCoordinate2DMake(self.maxLat, self.maxLon);
}

- (NSString *)gaugeString
{
    return [NSString stringWithFormat:@"%d mm", self.gauge];
}

- (void)setGaugeString:(NSString *)gaugeString
{
    NSString *stripped = [gaugeString stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]];
    self.gauge = [stripped intValue];
}

- (NSString *)electrificationString
{
    switch (self.electrification) {
        case 1:
            return @"600 - 750 V third rail";
        case 2:
            return @"600 - 750 V overhead";
        case 3:
            return @"1500 V";
        case 4:
            return @"3000 V";
        case 5:
            return @"10 - 15 kV 16⅔ Hz";
        case 6:
            return @"25 kV";
        default:
            return @"None";
    }
}

- (void)setElectrificationString:(NSString *)electrificationString
{
    int value = [electrificationString intValue];
    if (value == 25) {
        self.electrification = 6;
    } else if (value >= 600 && value <= 750) {
        self.electrification = 2;
    } else if (value > 1000 && value < 3000) {
        // if value indicates a year instead of a voltage, 1500 V will be chosen
        self.electrification = 3;
    } else if (value == 3000) {
        self.electrification = 4;
    } else if (value >= 10E3 && value <= 15E3) {
        self.electrification = 5;
    } else if (value == 25E3) {
        self.electrification = 6;
    } else {
        self.electrification = 0;
    }
}

- (NSString *)nrOfTracksString
{
    return [NSString stringWithFormat:@"%d", self.nrOfTracks];
}

- (void)setNrOfTracksString:(NSString *)nrOfTracksString
{
    self.nrOfTracks = [nrOfTracksString intValue];
}

- (NSString *)speedString
{
    return [NSString stringWithFormat:@"%d km/h", self.speed];
}

- (void)setSpeedString:(NSString *)speedString
{
    self.speed = [speedString intValue];
}

- (NSString *)icGroupName
{
    if (self.icGroup < 0) {
        return @"---";
    } else {
        return [ATLEntry nameForGroup:self.icGroup];
    }
}

- (NSString *)regionGroupName
{
    if (self.regionGroup < 0) {
        return @"---";
    } else {
        return [ATLEntry nameForGroup:self.regionGroup];
    }
}

#pragma mark - other

- (void)copyPropertiesFromSubroute:(ATLSubRoute *)otherSubroute
{
    self.route = otherSubroute.route;
    
    self.importance = otherSubroute.importance;
    self.gauge = otherSubroute.gauge;
    self.electrification = otherSubroute.electrification;
    self.nrOfTracks = otherSubroute.nrOfTracks;
    self.speed = otherSubroute.speed;
    self.signaling = [otherSubroute.signaling copy];
    self.openedString = [otherSubroute.openedString copy];
}

#pragma mark - XML representation

- (NSString *)xmlString
{
    NSMutableString *output = [NSMutableString stringWithCapacity:50];
    [output appendFormat:@"\t<subRoute name=\"%@\" from=\"%.3f\" to=\"%.3f\" importance=\"%d\" corridor=\"%d\" region=\"%d\">\n",
     self.name, self.start, self.end, self.importance, self.icGroup, self.regionGroup];
    [output appendFormat:@"\t\t<bounds minLat=\"%.7f\" minLon=\"%.7f\" maxLat=\"%.7f\" maxLon=\"%.7f\"/>\n",
     self.minLat, self.minLon, self.maxLat, self.maxLon];
    [output appendFormat:@"\t\t<track tracks=\"%d\" gauge=\"%d\" speed=\"%d\"/>\n", self.nrOfTracks, self.gauge, self.speed];
    if (self.openedString) {
        [output appendFormat:@"\t\t<opened>%@</opened>\n", self.openedString];
    }
    [output appendFormat:@"\t\t<electrification>%@</electrification>\n", self.electrificationString];
    [output appendFormat:@"\t\t<signaling>%@</signaling>\n", self.signaling];
    [output appendString:@"\t</subRoute>\n"];
    return output;
}

@end
