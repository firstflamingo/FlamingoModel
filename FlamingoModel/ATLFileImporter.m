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
//  ATLFileImporter.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 01-10-14.
//

#import "ATLFileImporter.h"

#import "ATLRoute.h"
#import "ATLSubRoute.h"
#import "ATLStation.h"
#import "ATLJunction.h"
#import "ATLOrganization.h"
#import "ATLService.h"
#import "ATLServiceRef.h"
#import "ATLServicePoint.h"
#import "ATLServiceRule.h"
#import "ATLSeriesRef.h"

#import "NSManagedObjectContext+FFEUtilities.h"


@interface ATLFileImporter () <NSXMLParserDelegate>

@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) ATLEntry *currentEntry;

@property (nonatomic, readonly) ATLRoute *currentRoute;
@property (nonatomic, readonly) ATLStation *currentStation;
@property (nonatomic, readonly) ATLJunction *currentJunction;
@property (nonatomic, readonly) ATLOrganization *currentOrganization;
@property (nonatomic, readonly) ATLService *currentService;
@property (nonatomic, readonly) ATLSeries *currentSeries;

@property (nonatomic, strong) ATLSubRoute *currentSubRoute;
@property (nonatomic, strong) ATLServiceRule *currentServiceRule;
@property (nonatomic, strong) NSManagedObject *currentReference;
@property (nonatomic, strong) NSMutableString *characters;
@property (nonatomic, strong) NSMutableArray *currentHeartline;
@property (nonatomic, strong) NSMutableDictionary *currentLocations;
@property (nonatomic, assign) BOOL previousServices, nextServices;

@end


@implementation ATLFileImporter

- (void)importContentsOfURL:(NSURL *)url intoManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self.managedObjectContext = managedObjectContext;
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    parser.delegate = self;
    [parser parse];
}

#pragma mark - Current Entry

- (ATLRoute *)currentRoute
{
    if ([self.currentEntry isKindOfClass:[ATLRoute class]]) {
        return (ATLRoute*)self.currentEntry;
    } else {
        return nil;
    }
}

- (ATLStation *)currentStation
{
    if ([self.currentEntry isKindOfClass:[ATLStation class]]) {
        return (ATLStation*)self.currentEntry;
    } else {
        return nil;
    }
}

- (ATLJunction *)currentJunction
{
    if ([self.currentEntry isKindOfClass:[ATLJunction class]]) {
        return (ATLJunction*)self.currentEntry;
    } else {
        return nil;
    }
}

- (ATLOrganization *)currentOrganization
{
    if ([self.currentEntry isKindOfClass:[ATLOrganization class]]) {
        return (ATLOrganization*)self.currentEntry;
    } else {
        return nil;
    }
}

- (ATLService *)currentService
{
    if ([self.currentEntry isKindOfClass:[ATLService class]]) {
        return (ATLService*)self.currentEntry;
    } else {
        return nil;
    }
}

- (ATLSeries *)currentSeries
{
    if ([self.currentEntry isKindOfClass:[ATLSeries class]]) {
        return (ATLSeries*)self.currentEntry;
    } else {
        return nil;
    }
}

#pragma mark - Temporary variables

- (NSMutableString *)characters
{
    if (!_characters) {
        self.characters = [NSMutableString stringWithCapacity:15];
    }
    return _characters;
}

- (NSMutableArray *)currentHeartline
{
    if (!_currentHeartline) {
        self.currentHeartline = [NSMutableArray arrayWithCapacity:25];
    }
    return _currentHeartline;
}

- (NSMutableDictionary *)currentLocations
{
    if (!_currentLocations) {
        self.currentLocations = [NSMutableDictionary dictionaryWithCapacity:30];
    }
    return _currentLocations;
}

#pragma mark NSXMLParser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (!self.currentEntry)
    {
        if ([elementName isEqualToString:@"route"])
        {
            self.currentEntry = [self.managedObjectContext objectOfClass:[ATLRoute class]
                                                             withModelID:attributeDict[@"id"]
                                                                  create:YES];
            self.currentRoute.name = attributeDict[@"name"];
            NSLog(@"Import route %@", self.currentRoute.name);
        }
        else if ([elementName isEqualToString:@"junction"])
        {
            self.currentEntry = [self.managedObjectContext objectOfClass:[ATLJunction class]
                                                             withModelID:attributeDict[@"id"]
                                                                  create:YES];
            self.currentJunction.sameDirection = [attributeDict[@"sameDirection"] isEqualToString:@"yes"];
            NSLog(@"Import junction %@", self.currentJunction.id_);
        }
        else if ([elementName isEqualToString:@"station"])
        {
            self.currentEntry = [self.managedObjectContext objectOfClass:[ATLStation class]
                                                             withModelID:attributeDict[@"id"]
                                                                  create:YES];
            self.currentStation.name = attributeDict[@"name"];
            self.currentStation.importance = [attributeDict[@"importance"] integerValue];
            self.currentStation.icGroup = [attributeDict[@"corridor"] integerValue];
            self.currentStation.regionGroup = [attributeDict[@"region"] integerValue];
            NSLog(@"Import station %@", self.currentStation.name);
        }
        else if ([elementName isEqualToString:@"organization"])
        {
            self.currentEntry = [self.managedObjectContext objectOfClass:[ATLOrganization class]
                                                             withModelID:attributeDict[@"id"]
                                                                  create:YES];
            self.currentOrganization.name = attributeDict[@"name"];
        }
        else if ([elementName isEqualToString:@"service"])
        {
            self.currentEntry = [self.managedObjectContext objectOfClass:[ATLService class]
                                                             withModelID:attributeDict[@"id"]
                                                                  create:YES];
            self.currentService.expressService = [attributeDict[@"express"] isEqualToString:@"yes"];
            self.currentService.group = [attributeDict[@"group"] intValue];
            self.currentService.shortName = attributeDict[@"short"];
            self.currentService.longName = attributeDict[@"long"];
            self.currentService.imageName = attributeDict[@"image"];
            NSLog(@"Import service %@", self.currentService.id_);
        }
        else if ([elementName isEqualToString:@"series"])
        {
            self.currentEntry = [self.managedObjectContext objectOfClass:[ATLSeries class]
                                                             withModelID:attributeDict[@"id"]
                                                                  create:YES];
        }
    }
    else if ([elementName isEqualToString:@"name"] ||
             [elementName isEqualToString:@"wiki"] ||
             [elementName isEqualToString:@"icon"] ||
             [elementName isEqualToString:@"origin"] ||
             [elementName isEqualToString:@"destination"] ||
             [elementName isEqualToString:@"electrification"] ||
             [elementName isEqualToString:@"signaling"] ||
             [elementName isEqualToString:@"opened"])
    {
        [self.characters setString:@""];
    }
    else if (self.currentRoute)
    {
        if ([elementName isEqualToString:@"heartLine"])
        {
            [self.currentHeartline removeAllObjects];
        }
        else if ([elementName isEqualToString:@"node"])
        {
            ATLNode *node = [[ATLNode alloc] initWithLatitude:[attributeDict[@"lat"] doubleValue]
                                                    longitude:[attributeDict[@"lon"] doubleValue]
                                                       radius:[attributeDict[@"radius"] intValue]
                                                         km_a:[attributeDict[@"km_a"] floatValue]
                                                         km_b:[attributeDict[@"km_b"] floatValue]];
            [self.currentHeartline addObject:node];
        }
        else if ([elementName isEqualToString:@"subRoute"])
        {
            self.currentSubRoute = [self.managedObjectContext createManagedObjectOfClass:[ATLSubRoute class]];
            self.currentSubRoute.name = attributeDict[@"name"];
            self.currentSubRoute.start = [attributeDict[@"from"] floatValue];
            self.currentSubRoute.end = [attributeDict[@"to"] floatValue];
            self.currentSubRoute.importance = [attributeDict[@"importance"] intValue];
            self.currentSubRoute.icGroup = [attributeDict[@"corridor"] intValue];
            self.currentSubRoute.regionGroup = [attributeDict[@"region"] intValue];
        }
        else if ([elementName isEqualToString:@"bounds"])
        {
            self.currentSubRoute.minLat = [attributeDict[@"minLat"] doubleValue];
            self.currentSubRoute.minLon = [attributeDict[@"minLon"] doubleValue];
            self.currentSubRoute.maxLat = [attributeDict[@"maxLat"] doubleValue];
            self.currentSubRoute.maxLon = [attributeDict[@"maxLon"] doubleValue];
        }
        else if ([elementName isEqualToString:@"track"])
        {
            self.currentSubRoute.nrOfTracks = [attributeDict[@"tracks"] intValue];
            self.currentSubRoute.gauge = [attributeDict[@"gauge"] intValue];
            self.currentSubRoute.speed = [attributeDict[@"speed"] intValue];
        }
        else if ([elementName isEqualToString:@"ATLRoutePosition"])
        {
            ATLLocation *item = (ATLLocation*)[self.managedObjectContext objectOfClass:[ATLLocation class]
                                                                           withModelID:attributeDict[@"location"]
                                                                                create:NO];
            if (item) {
                [self.currentRoute insertLocation:item atPosition:[attributeDict[@"km"] floatValue]];
            }
        }
    }
    else if (self.currentStation)
    {
        if ([elementName isEqualToString:@"display"])
        {
            self.currentStation.labelAngle = [attributeDict[@"angle"] integerValue];
            [self.characters setString:@""];
        }
    }
    else if (self.currentService)
    {
        if ([elementName isEqualToString:@"frequency"])
        {
            self.currentService.peakFrequency = [attributeDict[@"peak"] floatValue];
            self.currentService.baseFrequency = [attributeDict[@"base"] floatValue];
            self.currentService.offPeakFrequency = [attributeDict[@"offPeak"] floatValue];
        }
        else if ([elementName isEqualToString:@"operator"] ||
                 [elementName isEqualToString:@"grantor"]) {
            self.currentReference = nil;
            
        }
        else if ([elementName isEqualToString:@"ATLOrganization"])
        {
            self.currentReference = [self.managedObjectContext objectOfClass:[ATLOrganization class]
                                                                 withModelID:attributeDict[@"id"]
                                                                      create:NO];
        }
        else if ([elementName isEqualToString:@"previousServices"])
        {
            self.previousServices = YES;
        }
        else if ([elementName isEqualToString:@"nextServices"])
        {
            self.nextServices = YES;
        }
        else if ([elementName isEqualToString:@"ATLService"])
        {
            ATLService *service = [self.managedObjectContext objectOfClass:[ATLService class] withModelID:attributeDict[@"id"] create:NO];
            if (service) {
                if (self.previousServices) {
                    ATLServiceRef *ref = [self.managedObjectContext createManagedObjectOfClass:[ATLServiceRef class]];
                    ref.previousService = service;
                    ref.nextService = self.currentService;
                } else if (self.nextServices) {
                    ATLServiceRef *ref = [self.managedObjectContext createManagedObjectOfClass:[ATLServiceRef class]];
                    ref.previousService = self.currentService;
                    ref.nextService = service;
                }
            }
        }
        else if ([elementName isEqualToString:@"locations"])
        {
            [self.currentLocations removeAllObjects];
        }
        else if ([elementName isEqualToString:@"junction"])
        {
            NSString *identifier = attributeDict[@"id"];
            ATLJunction *junction = (ATLJunction*)[self.managedObjectContext objectOfClass:[ATLJunction class]
                                                                               withModelID:identifier
                                                                                    create:NO];
            self.currentLocations[identifier] = [self.currentService insertLocation:junction atKM:[attributeDict[@"km"] floatValue]];
        }
        else if ([elementName isEqualToString:@"station"])
        {
            NSString *identifier = attributeDict[@"id"];
            ATLStation *station = (ATLStation*)[self.managedObjectContext objectOfClass:[ATLStation class]
                                                                            withModelID:identifier
                                                                                 create:NO];
            self.currentLocations[identifier] = [self.currentService insertLocation:station atKM:[attributeDict[@"km"] floatValue]];
            
        }
        else if ([elementName isEqualToString:@"up"])
        {
            NSString *referredStation = attributeDict[@"S"];
            if (referredStation) {
                ATLServicePoint *servicePoint = self.currentLocations[referredStation];
                servicePoint.options = [attributeDict[@"O"] intValue];
                servicePoint.upArrival = minutesFromString(attributeDict[@"A"]);
                servicePoint.upDeparture = minutesFromString(attributeDict[@"V"]);
                servicePoint.upPlatform = attributeDict[@"P"];
            }
        }
        else if ([elementName isEqualToString:@"down"])
        {
            NSString *referredStation = attributeDict[@"S"];
            if (referredStation) {
                ATLServicePoint *servicePoint = self.currentLocations[referredStation];
                servicePoint.options = [attributeDict[@"O"] intValue];
                servicePoint.downArrival = minutesFromString(attributeDict[@"A"]);
                servicePoint.downDeparture = minutesFromString(attributeDict[@"V"]);
                servicePoint.downPlatform = attributeDict[@"P"];
            }
        }
        else if ([elementName isEqualToString:@"ref"])
        {
            ATLSeries *series = [self.managedObjectContext objectOfClass:[ATLSeries class] withModelID:attributeDict[@"series"] create:NO];
            if (series) {
                ATLSeriesRef *ref = (ATLSeriesRef*)[self.managedObjectContext createManagedObjectOfType:@"ATLSeriesRef"];
                ref.service = self.currentService;
                ref.series = series;
            }
        }
        else if ([elementName isEqualToString:@"servicerule"])
        {
            self.currentServiceRule = [self.managedObjectContext createManagedObjectOfClass:[ATLServiceRule class]];
            self.currentServiceRule.service = self.currentService;
            [self.currentServiceRule fillWithDictionary:attributeDict];
        }
        else if ([elementName isEqualToString:@"nostop"])
        {
            ATLServicePoint *noStopPoint = [self.currentService servicePointWithCode:attributeDict[@"code"]];
            [self.currentServiceRule addNoStopPointsObject:noStopPoint];
        }
    }
    else if (self.currentSeries)
    {
        if ([elementName isEqualToString:@"ref"]) {
            ATLService *service = [self.managedObjectContext objectOfClass:[ATLService class]
                                                               withModelID:attributeDict[@"service"]
                                                                    create:NO];
            if (service) {
                ATLSeriesRef *ref = [self.managedObjectContext createManagedObjectOfClass:[ATLSeriesRef class]];
                ref.series = self.currentSeries;
                ref.service = service;
                ref.sameDirection = [attributeDict[@"same"] boolValue];
                ref.upCorrection = [attributeDict[@"up"] intValue];
                ref.downCorrection = [attributeDict[@"down"] intValue];
            }
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ((self.currentRoute && [elementName isEqualToString:@"route"]) ||
        (self.currentJunction && [elementName isEqualToString:@"junction"]) ||
        (self.currentStation && [elementName isEqualToString:@"station"]) ||
        (self.currentOrganization && [elementName isEqualToString:@"organization"]) ||
        (self.currentService && [elementName isEqualToString:@"service"]) ||
        (self.currentSeries && [elementName isEqualToString:@"series"]))
    {
        self.currentEntry = nil;
    }
    else if (self.currentRoute)
    {
        if ([elementName isEqualToString:@"origin"])
        {
            self.currentRoute.origin = [self.characters copy];
        }
        else if ([elementName isEqualToString:@"destination"])
        {
            self.currentRoute.destination = [self.characters copy];
        }
        else if ([elementName isEqualToString:@"heartLine"])
        {
            self.currentRoute.heartLine = [self.currentHeartline copy];
        }
        else if ([elementName isEqualToString:@"electrification"])
        {
            self.currentSubRoute.electrificationString = self.characters;
        }
        else if ([elementName isEqualToString:@"signaling"])
        {
            self.currentSubRoute.signaling = [self.characters copy];
        }
        else if ([elementName isEqualToString:@"opened"])
        {
            self.currentSubRoute.openedString = [self.characters copy];
        }
        else if ([elementName isEqualToString:@"subRoute"])
        {
            [self.currentRoute addSubRoutesObject:self.currentSubRoute];
        }
    }
    else if (self.currentStation)
    {
        if ([elementName isEqualToString:@"wiki"])
        {
            self.currentStation.wikiString = [self.characters copy];
        }
        else if ([elementName isEqualToString:@"opened"])
        {
            self.currentStation.openedString = [self.characters copy];
        }
        else if ([elementName isEqualToString:@"display"])
        {
            self.currentStation.displayName = [self.characters copy];
        }
        else if ([elementName isEqualToString:@"name"]) {
            ATLAlias *alias = [self.managedObjectContext createManagedObjectOfClass:[ATLAlias class]];
            alias.station = self.currentStation;
            alias.name = [self.characters copy];
        }
    }
    else if (self.currentOrganization)
    {
        if ([elementName isEqualToString:@"icon"])
        {
            self.currentOrganization.iconName = [self.characters copy];
        }
    }
    else if (self.currentService)
    {
        if ([elementName isEqualToString:@"operator"])
        {
            self.currentService.serviceOperator = (ATLOrganization*)self.currentReference;
        }
        else if ([elementName isEqualToString:@"grantor"])
        {
            self.currentService.grantor = (ATLOrganization*)self.currentReference;
        }
        else if ([elementName isEqualToString:@"previousServices"])
        {
            self.previousServices = NO;
        }
        else if ([elementName isEqualToString:@"nextServices"])
        {
            self.nextServices = NO;
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [self.characters appendString:string];
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    NSLog(@"validation error: %@", [validationError localizedDescription]);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    self.characters = nil;
    self.currentSubRoute = nil;
    self.currentHeartline = nil;
    self.currentLocations = nil;
    self.currentReference = nil;
}

@end
