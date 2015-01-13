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
//  ATLTimePoint.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 23-06-14.
//

#import "ATLTimePoint.h"

#define ARRIVAL_KEY @"A"
#define DEPARTURE_KEY @"V"
#define STATION_ID_KEY @"S"
#define PLATFORM_KEY @"P"
#define OPTIONS_KEY @"O"

@implementation ATLTimePoint

- (instancetype)initWithArrival:(ATLMinutes)arrival departure:(ATLMinutes)departure stationID:(NSString *)stationID
                       platform:(NSString *)platform options:(ATLTimePointOptions)options
{
    self = [super init];
    if (self) {
        self.arrival = arrival;
        self.departure = departure;
        self.stationID = stationID;
        self.platform = platform;
        self.options = options;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.arrival = [aDecoder decodeIntForKey:ARRIVAL_KEY];
        self.departure = [aDecoder decodeIntForKey:DEPARTURE_KEY];
        self.stationID = [aDecoder decodeObjectForKey:STATION_ID_KEY];
        self.platform = [aDecoder decodeObjectForKey:PLATFORM_KEY];
        self.options = [aDecoder decodeIntForKey:OPTIONS_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:self.arrival forKey:ARRIVAL_KEY];
    [aCoder encodeInt:self.departure forKey:DEPARTURE_KEY];
    [aCoder encodeObject:self.stationID forKey:STATION_ID_KEY];
    [aCoder encodeObject:self.platform forKey:PLATFORM_KEY];
    [aCoder encodeInt:self.options forKey:OPTIONS_KEY];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %@ A%@ V%@ [%u]>",
            NSStringFromClass([self class]), self.stopLocation, self.arrivalString, self.departureString, self.options];
}

#pragma mark - Time properties

- (NSString *)arrivalString
{
    return stringFromMinutes(self.arrival);
}

- (void)setArrivalString:(NSString *)arrivalString
{
    self.arrival = minutesFromString(arrivalString);
}

- (NSString *)departureString
{
    return stringFromMinutes(self.departure);
}

- (void)setDepartureString:(NSString *)departureString
{
    self.departure = minutesFromString(departureString);
}

#pragma mark - Location properties

- (NSString *)stationCode
{
    NSArray *comps = [self.stationID componentsSeparatedByString:@"."];
    NSAssert([comps count] == 2, @"stationID mist be in format like nl.xxx");
    return comps[1];
}

- (void)setStationCode:(NSString *)stationCode
{
    self.stationID = [NSString stringWithFormat:@"nl.%@", stationCode];
}

- (NSString *)stopLocation
{
    return [NSString stringWithFormat:@"%@|%@", self.stationCode, self.platform];
}

- (void)setStopLocation:(NSString *)stopLocation
{
    NSArray *comps = [stopLocation componentsSeparatedByString:@"|"];
    NSAssert([comps count] == 2, @"stopLoction must be in format like xx|xx");
    self.stationCode = comps[0];
    self.platform = comps[1];
}

#pragma mark - Options

- (BOOL)canDropOff
{
    return self.options & pointOptionsCanDropOff;
}

- (void)setCanDropOff:(BOOL)canDropOff
{
    if (canDropOff) {
        self.options |= pointOptionsCanDropOff;
    } else {
        self.options &= ~pointOptionsCanDropOff;
    }
}

- (BOOL)canPickUp
{
    return self.options & pointOptionsCanPickUp;
    
}

- (void)setCanPickUp:(BOOL)canPickUp
{
    if (canPickUp) {
        self.options |= pointOptionsCanPickUp;
    } else {
        self.options &= ~pointOptionsCanPickUp;
    }
}

- (BOOL)changeDirection
{
    return self.options & pointOptionsChangeDirection;
}

- (void)setChangeDirection:(BOOL)changeDirection
{
    if (changeDirection) {
        self.options |= pointOptionsChangeDirection;
    } else {
        self.options &= ~pointOptionsChangeDirection;
    }
}

#pragma mark - Reading methods

- (void)fillWithDictionary:(NSDictionary *)dictionary
{
    self.arrivalString = dictionary[ARRIVAL_KEY];
    self.departureString = dictionary[DEPARTURE_KEY];
    self.options = [dictionary[OPTIONS_KEY] intValue];
    self.platform = dictionary[PLATFORM_KEY];
    self.stationID = dictionary[STATION_ID_KEY];
}

#pragma mark - Writing methods

- (NSString *)xmlAttributes
{
    return [NSString stringWithFormat:@"A=\"%@\" V=\"%@\" O=\"%u\" P=\"%@\" S=\"%@\"",
            self.arrivalString, self.departureString, self.options, self.platform, self.stationID];
}

- (NSDictionary *)contentDictionary
{
    return @{ARRIVAL_KEY: self.arrivalString,
             DEPARTURE_KEY: self.departureString,
             OPTIONS_KEY: @(self.options),
             PLATFORM_KEY: self.platform,
             STATION_ID_KEY: self.stationID};
}

#pragma mark - Comparison

- (uint32_t)hash_ {
    
    uint32_t ha1 = (self.arrival << 20) + (self.departure << 10) + self.options;
    return ha1 ^ (uint32_t)[self.stopLocation hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[ATLTimePoint class]]) {
        return NO;
    }
    
    return [self isEqualToPoint:(ATLTimePoint *)object];
}

- (BOOL)isEqualToPoint:(ATLTimePoint *)point
{
    if (!point) {
        return NO;
    }
    BOOL haveEqualStations = (!self.stationID && !point.stationID) || [self.stationID isEqualToString:point.stationID];
    BOOL haveEqualPlatforms = (!self.platform && !point.platform) || [self.platform isEqualToString:point.platform];
    return haveEqualStations && haveEqualPlatforms &&
    (self.arrival == point.arrival) && (self.departure == point.departure) && (self.options == point.options);
}

@end

ATLMinutes minutesFromString(NSString *string)
{
    NSArray *components = [string componentsSeparatedByString:@":"];
    return 60 * [components[0] intValue] + [components[1] intValue];
}

NSString *stringFromMinutes(ATLMinutes minutes)
{
    return [NSString stringWithFormat:@"%02d:%02d", minutes / 60, minutes % 60];
}

