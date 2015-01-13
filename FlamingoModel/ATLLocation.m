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
//  ATLRouteItem.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import "ATLLocation.h"
#import "GeoMetricFunctions.h"
#import "ATLServicePoint.h"
#import "ATLSeries.h"

@implementation ATLLocation {
    CLLocationCoordinate2D _coordinate;
}

@dynamic routePositions;
@dynamic servicePoints;
@synthesize pathNode;

#pragma mark - Deduced properties

- (NSString *)title
{
    return @"Location";
}

- (NSString*)identifierStringComponent:(NSUInteger)index
{
    NSArray *components = [self.id_ componentsSeparatedByString:@"."];
    if ([components count] > index) {
        return components[index];
    }
    return nil;
}

- (NSString *)country
{
    NSString *country = [self identifierStringComponent:0];
    if (!country) country = @"nl";
    return country;
}

- (void)setCountry:(NSString *)country
{
    self.id_ = [NSString stringWithFormat:@"%@.%@", country, self.code];
}

- (NSString *)code
{
    NSString *code = [self identifierStringComponent:1];
    if (!code) code = [NSString stringWithFormat:@"%d", 1 + rand()%10000];
    return code;
}

- (void)setCode:(NSString *)code
{
    self.id_ = [NSString stringWithFormat:@"%@.%@", self.country, [code lowercaseString]];
}

- (CLLocationCoordinate2D)coordinate
{
    if (_coordinate.latitude == 0.0 && _coordinate.longitude == 0.0) {
        double lat_sum = 0;
        double lon_sum = 0;
        int counter = 0;
        for (ATLRoutePosition *position in self.routePositions) {
            lat_sum += position.latitude;
            lon_sum += position.longitude;
            counter ++;
        }
        _coordinate = CLLocationCoordinate2DMake(lat_sum/counter, lon_sum/counter);
    }
    return _coordinate;
}

- (double)latitude
{
    return self.coordinate.latitude;
}

- (double)longitude
{
    return self.coordinate.longitude;
}

- (NSSet *)routes
{
    NSMutableSet *theRoutes = [NSMutableSet setWithCapacity:5];
    for (ATLRoutePosition *position in self.routePositions) {
        [theRoutes addObject:position.route];
    }
    return theRoutes;
}

- (NSString *)statusString
{
    return @"";
}

- (NSString *)symbolName
{
    return @"item";
}

#pragma mark - NSPasteboard support

#if TARGET_OS_MAC
#pragma mark Pasteboard writing

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return @[ROUTE_ITEM_UTI];
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
    return 0;
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    return [[[self objectID] URIRepresentation] absoluteString];
}

#pragma mark  Pasteboard reading

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return @[ROUTE_ITEM_UTI];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    return NSPasteboardReadingAsString;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type
{
    self = propertyList;
    return self;
}
#endif

#pragma mark - Relating to services

- (NSSet *)services
{
    NSMutableSet *services = [NSMutableSet setWithCapacity:10];
    for (ATLServicePoint *servicePoint in self.servicePoints) {
        [services addObject:servicePoint.service];
    }
    return services;
}

#pragma mark - Relating to routes

- (ATLRoute *)commonRouteWithItem:(ATLLocation *)item
{
    for (ATLRoute *route in self.routes) {
        for (ATLRoute *otherRoute in item.routes) {
            if (route == otherRoute) return route;
        }
    }
    return nil;
}

- (double)kmPositionInRoute:(ATLRoute *)route
{
    for (ATLRoutePosition *position in self.routePositions) {
        if (position.route == route) {
            return position.km;
        }
    }
    return INVALID_KM;
}

- (BOOL)isOnRoute:(ATLRoute *)route
{
    for (ATLRoutePosition *position in self.routePositions) {
        if (position.route == route) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isConnectedToRoute:(ATLRoute *)route
{
    for (ATLRoutePosition *position in self.routePositions) {
        if (position.route == route) return YES;
    }
    return NO;
}

#pragma mark - Date representation

+ (NSString *)stringFromDate:(NSDate *)date
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay | NSCalendarUnitHour;
    NSDateComponents *components = [calendar components:unitFlags fromDate:date];
    NSUInteger precision = components.hour - 12;
    switch (precision) {
        case 0:
            return [NSString stringWithFormat:@"%d?", (int)components.year];
        case 1:
            return [NSString stringWithFormat:@"%d", (int)components.year];
        case 2:
            return [NSString stringWithFormat:@"%d-%02d", (int)components.year, (int)components.month];
        default:
            return [NSString stringWithFormat:@"%d-%02d-%02d", (int)components.year, (int)components.month, (int)components.day];
    }
}

+ (NSDate *)dateFromString:(NSString *)string
{
    NSUInteger precision = 0;
    NSRange range = [string rangeOfString:@"?" options:NSCaseInsensitiveSearch];
    if(range.location == NSNotFound) precision = 1;
    
    NSArray *components = [string componentsSeparatedByString:@"-"];
    NSUInteger year = [components[0] integerValue], month = 1, day = 1;
    if (precision == 1 && [components count] > 1) {
        month = [components[1] integerValue];
        precision = 2;
        if ([components count] > 2) {
            day = [components[2] integerValue];
            precision = 3;
        }
    }
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *date = [[NSDateComponents alloc] init];
    [date setDay:day];
    [date setMonth:month];
    [date setYear:year];
    [date setHour:12 + precision];
    [date setMinute:30];
    [date setSecond:0];
    return [calendar dateFromComponents:date];
}

#pragma mark - XML representation

- (void)appendDataToXMLString:(NSMutableString *)output
{
    [super appendDataToXMLString:output];
    if ([self.routePositions count] > 0) {
        [output appendString:@"<positions>\n"];
        for (ATLRoutePosition *position in self.routePositions) {
            [output appendString:[position xmlRouteRef]];
        }
        [output appendString:@"</positions>\n"];
    }
}

@end
