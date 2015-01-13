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
//  ATLStation.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import "ATLStation.h"
#import "ATLAlias.h"
#import "ATLRoute.h"
#import "ATLMission.h"
#import "ATLService.h"
#import "ATLServicePoint.h"
#import "ATLServiceRule.h"

#import "NSManagedObjectContext+FFEUtilities.h"

#define ICON_RADIUS 1800
#define CHAR_SIZE   1400

@implementation ATLStation

@dynamic name;
@dynamic importance;
@dynamic displayName;
@dynamic labelAngle;
@dynamic wikiString;
@dynamic openedString;
@dynamic icGroup;
@dynamic regionGroup;
@dynamic aliases;


- (NSString *)symbolName
{
    return [NSString stringWithFormat:@"station%d", self.importance];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %@ lC: %@ lS: %@>",
            NSStringFromClass([self class]), self.id_, self.lastClientModification, self.lastServerModification];
}

#pragma mark - managing Aliases

- (NSString *)title
{
    return [self.name copy];
}

- (void)setAliasesWithNames:(NSMutableSet *)newNames
{
    NSMutableSet *expiredAliases = [NSMutableSet setWithSet:self.aliases];
    for (ATLAlias *alias in self.aliases) {
        if ([newNames containsObject:alias.name]) {
            [expiredAliases removeObject:alias];
            [newNames removeObject:alias.name];
        }
    }
    for (ATLAlias *alias in expiredAliases) {
        [self.managedObjectContext deleteObject:alias];
    }
    for (NSString *string in newNames) {
        [self createAliasWithName:string];
    }
}

- (ATLAlias*)createAliasWithName:(NSString*)name
{
    NSDictionary *entities = [self.managedObjectModel entitiesByName];
    ATLAlias *alias = (ATLAlias*)[[NSManagedObject alloc] initWithEntity:entities[@"ATLAlias"]
                                          insertIntoManagedObjectContext:self.managedObjectContext];
    alias.station = self;
    alias.name = name;
    return alias;
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

#pragma mark - Connecting with Wikipedia

- (NSURL *)wikiURL
{
    return [self wikiURLWithFormat:@"http://%@.wikipedia.org/wiki/%@"];
}

- (NSURL *)mWikiURL
{
    return [self wikiURLWithFormat:@"http://%@.m.wikipedia.org/wiki/%@#content"];
}

- (NSURL *)wikiURLWithFormat:(NSString*)format
{
    NSArray *comps = [self.wikiString componentsSeparatedByString:@":"];
    NSString *lastPathComponent = [comps[1] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if (lastPathComponent) {
        NSString *path = [NSString stringWithFormat:format, comps[0], lastPathComponent];
        return [NSURL URLWithString:path];
    }
    return nil;
}

#pragma mark - Support for current journey

@synthesize stationRole;
@synthesize arrivalGroup;
@synthesize departureGroup;
@synthesize proximity;

#pragma mark - FFESyncing methods

+ (NSString *)remotePath
{
    return @"atlas/station";
}

+ (NSArray *)acceptedDataTypes
{
    return @[@(DataTypeJSON)];
}

- (void)fillWithData:(NSData *)data ofType:(FFEDataType)type
{
    if (type == DataTypeJSON) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        NSAssert([dict isKindOfClass:[NSDictionary class]], @"Must be dictionary");
        [self fillWithDictionary:dict];
    }
}

- (NSData *)contentWithDataType:(FFEDataType)type
{
    if (type == DataTypeJSON) {
        return [NSJSONSerialization dataWithJSONObject:self.contentDictionary options:0 error:NULL];
    } else {
        return nil;
    }
}

- (NSDictionary *)contentDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:7];
    dictionary[@"id"] = self.id_;
    dictionary[@"labelAngle"] = @(self.labelAngle);
    dictionary[@"importance"] = @(self.importance);
    
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:5];
    [names addObject:self.name];
    int displayIndex = 0;
    int i = 1;
    for (ATLAlias *alias in self.aliases) {
        [names addObject:alias.name];
        if ([alias.name isEqualToString:self.displayName]) {
            displayIndex = i;
        }
        i++;
    }
    if (displayIndex == 0 && ![self.displayName isEqualToString:self.name]) {
        [names addObject:self.displayName];
        displayIndex = i;
    }
    dictionary[@"names"] = names;
    dictionary[@"displayIndex"] = @(displayIndex);
    
    if (self.wikiString) {
        dictionary[@"wikiString"] = self.wikiString;
    }
    if (self.openedString) {
        dictionary[@"openedString"] = self.openedString;
    }
    if ([self.routePositions count] > 0) {
        NSMutableArray *positions = [NSMutableArray arrayWithCapacity:2];
        for (ATLRoutePosition *position in self.routePositions) {
            NSMutableDictionary *positionDict = [NSMutableDictionary dictionaryWithCapacity:5];
            positionDict[@"route"] = position.route.id_;
            positionDict[@"km"] = @(position.km);
            positionDict[@"lat"] = @(self.coordinate.latitude);
            positionDict[@"lon"] = @(self.coordinate.longitude);
            [positions addObject:positionDict];
        }
        dictionary[@"positions"] = positions;
    }
    return dictionary;
}

- (void)fillWithDictionary:(NSDictionary *)dictionary
{
    NSString *identifier = dictionary[@"id"];
    if (identifier) {
        self.id_ = identifier;
    }
    NSArray *names = dictionary[@"names"];
    if (names) {
        self.name = names[0];
        NSNumber *displayIndex = dictionary[@"displayIndex"];
        if (displayIndex) {
            int index = [displayIndex intValue];
            if (index < [names count]) {
                NSString *displayName = names[index];
                if ([displayName length] <= 20) {
                    self.displayName = names[index];
                }
            }
        }
        NSMutableSet *newAliases = [NSMutableSet setWithCapacity:5];
        for (int i = 1; i < [names count]; i++) {
            [newAliases addObject:names[i]];
        }
        [self setAliasesWithNames:newAliases];
    }
    NSNumber *labelAngle = dictionary[@"labelAngle"];
    if (labelAngle) {
        self.labelAngle = [labelAngle intValue];
    }
    NSNumber *importance = dictionary[@"importance"];
    if (importance) {
        self.importance = [importance intValue];
    }
    NSString *wikiString = dictionary[@"wikiString"];
    if (wikiString) {
        self.wikiString = wikiString;
    }
    NSString *openedString = dictionary[@"openedString"];
    if (openedString) {
        self.openedString = openedString;
    }
    NSArray *positions = dictionary[@"positions"];
    if (positions) {
        [self updatePositionsWithArray:positions];
    }
}

- (void)updatePositionsWithArray:(NSArray*)array
{
    NSMutableSet *oldPositions = [self.routePositions mutableCopy];
    for (NSDictionary *dictionary in array) {
        ATLRoute *route = (ATLRoute*)[self.managedObjectContext objectOfClass:[ATLRoute class] withModelID:dictionary[@"route"] create:YES];
        if (!route.name) {
            route.name = @"New route";
        }
        ATLRoutePosition *position = [self positionOnRoute:route];
        [oldPositions removeObject:position];
        position.km = [dictionary[@"km"] floatValue];
        position.coordinate = CLLocationCoordinate2DMake([dictionary[@"lat"] doubleValue], [dictionary[@"lon"] doubleValue]);
    }
    for (ATLRoutePosition *expiredPosition in oldPositions) {
        [self.managedObjectContext deleteObject:expiredPosition];
    }
}

- (ATLRoutePosition *)positionOnRoute:(ATLRoute*)route
{
    for (ATLRoutePosition *position in self.routePositions) {
        if (position.route == route) {
            return position;
        }
    }
    ATLRoutePosition *position = (ATLRoutePosition*)[self.managedObjectContext createManagedObjectOfType:@"ATLRoutePosition"];
    position.location = self;
    position.route = route;
    return position;
}

#pragma mark - XML representation

- (void)appendAttributesToXMLString:(NSMutableString *)output
{
    [super appendAttributesToXMLString:output];
    [output appendFormat:@" name=\"%@\" importance=\"%d\" corridor=\"%d\" region=\"%d\"", self.name, self.importance, self.icGroup, self.regionGroup];
}

- (void)appendDataToXMLString:(NSMutableString *)output
{
    [super appendDataToXMLString:output];
    if (self.displayName) {
        [output appendFormat:@"<display angle=\"%d\">%@</display>\n", self.labelAngle, self.displayName];
    }
    if (self.openedString) {
        [output appendFormat:@"<opened>%@</opened>\n", self.openedString];
    }
    if (self.wikiString && [self.wikiString length] > 3) {
        [output appendFormat:@"<wiki>%@</wiki>\n", self.wikiString];
    }
    if ([self.aliases count] > 0) {
        [output appendString:@"<aliases>\n"];
        for (ATLAlias *alias in self.aliases) {
            [output appendFormat:@"\t<name>%@</name>\n", alias.name];
        }
        [output appendString:@"</aliases>\n"];
    }
}

#pragma mark - Timetable support

- (BOOL)hasDirectConnectionWithStation:(ATLStation *)otherStation
{
    return [self.services intersectsSet:otherStation.services];
}

- (NSArray *)departuresAfter:(NSDate *)startTime
{
    float interval = 5.0 / [self.servicePoints count];
    if (interval < 0.5) {
        interval = 0.5;
    }
    NSDate *endTime = [startTime dateByAddingTimeInterval:3600 * interval];
    
    NSMutableSet *departures = [NSMutableSet set];
    for (ATLServicePoint *point in self.servicePoints) {
        for (ATLDeparture *departure in [point.service departuresFromPoint:point startTime:startTime endTime:endTime]) {
            [departures addObject:departure];
        }
    }
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"plannedDeparture" ascending:YES];
    return [departures sortedArrayUsingDescriptors:@[sort]];
}

@end
