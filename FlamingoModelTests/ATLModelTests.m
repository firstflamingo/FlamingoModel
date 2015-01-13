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
//  ATLModelTests.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 01-03-12.
//

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>

#import "ATLDataController.h"

#import "ATLSeries.h"
#import "ATLSeriesRef.h"
#import "ATLService.h"
#import "ATLRoute.h"
#import "ATLServicePoint.h"
#import "ATLSubRoute.h"
#import "ATLRoutePosition.h"
#import "ATLStation.h"
#import "ATLJunction.h"
#import "ATLOrganization.h"
#import "ATLPathNode.h"
#import "ATLAlias.h"
#import "ATLJourney.h"

#import "NSDate+Formatters.h"
#import "NSManagedObjectContext+FFEUtilities.h"

@interface ATLModelTests : XCTestCase

@property (strong) ATLDataController *dataController;

@end


@implementation ATLModelTests

@synthesize dataController = _dataController;

- (void)setUp
{
    [super setUp];
    self.dataController = [ATLDataController testingInstance];
    self.dataController.testingDate = [NSDate dateFromMachineString:@"2013-09-05 15:20:00 +0100"];
}

- (void)tearDown
{
    self.dataController = nil;
    [super tearDown];
}

- (void)testATLBounds
{
    ATLBounds bounds = ATLBoundsMakeInitial(CLLocationCoordinate2DMake(52.0, 4.0));
    ATLBoundsExtend(&bounds, CLLocationCoordinate2DMake(53.0, 3.0));
    XCTAssertEqual(bounds.minLat, 52.0);
    XCTAssertEqual(bounds.maxLat, 53.0);
    XCTAssertEqual(bounds.minLon, 3.0);
    XCTAssertEqual(bounds.maxLon, 4.0);
}

- (void)testAliasSetting
{
    XCTAssertNotNil(self.dataController.managedObjectContext, @"managedObjectContext must exist");
    ATLStation *station = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    [station setValue:@"Amsterdam Centraal" forKey:@"name"];
    XCTAssertEqualObjects([station valueForKey:@"name"], @"Amsterdam Centraal", @"properties must be set");
    
    [station createAliasWithName:@"Amsterdam"];
    XCTAssertEqual([station.aliases count], 1, @"");
    [station createAliasWithName:@"A'dam"];
    XCTAssertEqual([station.aliases count], 2, @"");
    NSMutableSet *newNames = [NSMutableSet setWithArray:@[@"Amsterdam", @"Amsterdam C.", @"Amsterdam Centrum"]];
    [station setAliasesWithNames:newNames];
    [self.dataController saveContext];
    XCTAssertEqual([station.aliases count], 3, @"");
}

- (void)testContentDictionary
{
    NSDictionary *dictionary = @{@"id": @"nl.test", @"names": @[@"Utrecht Overvecht", @"Overvecht"], @"displayIndex": @(1),
                                 @"labelAngle": @(60), @"importance": @(1), @"wikiString": @"nl:Station Utrecht Overvecht",
                                 @"openedString": @"1970"};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:NULL];
    
    ATLStation *station = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    [station fillWithData:data ofType:DataTypeJSON];
    [self.dataController saveContext];
    
    XCTAssertEqualObjects([station contentDictionary], dictionary, @"");
    XCTAssertEqualObjects(station.name, @"Utrecht Overvecht", @"");
    XCTAssertEqualObjects(station.displayName, @"Overvecht", @"");
}

- (void)testRAInterface
{
    NSDate *now = [NSDate date];
    XCTAssertTrue(ABS([now timeIntervalSinceDate:self.dataController.lastUpdated]) < 1, @"");
    
    ATLStation *ut = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    ut.id_ = @"nl.ut";
    ut.name = @"Utrecht";
    
    ATLRoute *route = (ATLRoute*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLRoute"];
    ATLRoutePosition *position = (ATLRoutePosition*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLRoutePosition"];
    position.route = route;
    position.location = ut;
    position.km = 10.0;
    
    CLLocationCoordinate2D ut_coord;
    ut_coord.latitude = 52.0;
    ut_coord.longitude = 4.0;
    position.coordinate = ut_coord;
    XCTAssertEqual([self.dataController.managedObjectContext objectOfClass:[ATLStation class] withModelID:@"nl.ut" create:NO], ut, @"");
    XCTAssertEqual(ut.coordinate.latitude, 52.0, @"");
    
    ATLStation *ht = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    ht.id_ = @"nl.ht";
    ht.name = @"Den Bosch";
    XCTAssertEqual([self.dataController.managedObjectContext objectOfClass:[ATLStation class] withModelID:@"nl.ht" create:NO], ht, @"");
    
    NSSet *nearbyStations = [self.dataController stationsWithinRange:500.0 ofCoordinate:ut_coord];
    XCTAssertEqual([nearbyStations count], (NSUInteger)1, @"");
    XCTAssertEqual([nearbyStations anyObject], ut, @"");
    
    ATLService *service = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    service.id_ = @"nl.a1";
    service.shortName = @"A1";
    service.longName = @"Treindienst A1";
    
    ATLServicePoint *rp_ut = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    rp_ut.service = service;
    rp_ut.location = ut;
    rp_ut.km = 0.0;
    ATLServicePoint *rp_ht = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    rp_ht.service = service;
    rp_ht.location = ht;
    rp_ht.km = 50.0;

    XCTAssertEqual([ut.services anyObject], service, @"");
    XCTAssertEqualObjects(service.shortName, @"A1", @"");
    XCTAssertEqualObjects(service.longName, @"Treindienst A1", @"");
    XCTAssertEqualObjects(service.firstStationID, @"nl.ut", @"");
    XCTAssertEqualObjects(service.firstStationName, @"Utrecht", @"");
    XCTAssertEqualObjects(service.lastStationID, @"nl.ht", @"");
    XCTAssertEqualObjects(service.lastStationName, @"Den Bosch", @"");
}

- (void)testDistancePathFinding
{
    ATLRoute *route1 = (ATLRoute*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLRoute"];
    route1.name = @"route1";
    ATLRoute *route2 = (ATLRoute*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLRoute"];
    route2.name = @"route2";
    ATLRoute *route3 = (ATLRoute*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLRoute"];
    route3.name = @"route3";
    ATLRoute *route4 = (ATLRoute*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLRoute"];
    route4.name = @"route4";
    ATLRoute *route5 = (ATLRoute*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLRoute"];
    route5.name = @"route5";
    
    ATLStation *station1 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station1.name = @"station1";
    [route2 insertLocation:station1 atPosition:0.0];
    [route5 insertLocation:station1 atPosition:5.0];
    
    ATLStation *station2 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station2.name = @"station2";
    [route1 insertLocation:station2 atPosition:0.0];
    [route5 insertLocation:station2 atPosition:25.0];
    
    ATLStation *station3 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station3.name = @"station3";
    [route1 insertLocation:station3 atPosition:6.0];
    
    ATLStation *station4 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station4.name = @"station4";
    [route2 insertLocation:station4 atPosition:105.0];
    
    ATLStation *station5 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station5.name = @"station5";
    [route4 insertLocation:station5 atPosition:2.0];
    
    ATLJunction *junction1 = (ATLJunction*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLJunction"];
    junction1.id_ = @"nl.j1";
    [route2 insertLocation:junction1 atPosition:1.0];
    [route3 insertLocation:junction1 atPosition:1.0];
    junction1.sameDirection = NO;
    
    ATLJunction *junction2 = (ATLJunction*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLJunction"];
    junction2.id_ = @"nl.j2";
    [route1 insertLocation:junction2 atPosition:5.0];
    [route3 insertLocation:junction2 atPosition:0.0];
    junction2.sameDirection = NO;
    
    ATLJunction *junction3 = (ATLJunction*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLJunction"];
    junction3.id_ = @"nl.j3";
    [route1 insertLocation:junction3 atPosition:11.0];
    [route2 insertLocation:junction3 atPosition:101.0];
    junction3.sameDirection = YES;
    
    XCTAssertEqual((int)[route1.positions count], 4, @"");
    XCTAssertEqual((int)[route2.positions count], 4, @"");
    XCTAssertEqual((int)[route3.positions count], 2, @"");
    XCTAssertEqual((int)[route4.positions count], 1, @"");
    
    ATLPathNode *pathNode = [[ATLPathNode alloc] initWithParent:junction1];
    XCTAssertEqual(pathNode, junction1.pathNode, @"");
    [pathNode disconnectNode];
    XCTAssertNil(junction1.pathNode, @"must be weak connection");
    
    
    NSArray *route_1_5 = [self.dataController shortestDistancePathFrom:station1 to:station5];
    XCTAssertNil(route_1_5, @"");
    
    NSArray *route_1_4 = [self.dataController shortestDistancePathFrom:station1 to:station4];
    ATLPathNode *lastStep = [route_1_4 lastObject];
    XCTAssertEqualWithAccuracy(lastStep.distance, 12.0, 0.1, @"");
    
    NSArray *route_1_3 = [self.dataController shortestDistancePathFrom:station1 to:station3];
    lastStep = [route_1_3 lastObject];
    XCTAssertEqualWithAccuracy(lastStep.distance, 3.0, 0.1, @"");
    
    NSArray *route_1_2 = [self.dataController shortestDistancePathFrom:station1 to:station2];
    lastStep = [route_1_2 lastObject];
    XCTAssertEqualWithAccuracy(lastStep.distance, 20.0, 0.1, @"");
}

- (void)testServicePathFinding
{
    ATLStation *station1 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station1.id_ = @"1";
    station1.name = @"station1";
    ATLStation *station2 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station2.id_ = @"2";
    station2.name = @"station2";
    ATLStation *station3 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station3.id_ = @"3";
    station3.name = @"station3";
    ATLStation *station4 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station4.id_ = @"4";
    station4.name = @"station4";
    ATLStation *station5 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station5.id_ = @"5";
    station5.name = @"station5";
    ATLStation *station6 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station6.id_ = @"6";
    station6.name = @"station6";
    ATLStation *station7 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station7.id_ = @"7";
    station7.name = @"station7";
    ATLStation *station8 = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    station8.id_ = @"8";
    station8.name = @"station8";
    
    ATLService *serviceA1 = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    serviceA1.shortName = @"A1";
    serviceA1.baseFrequency = 4.0;
    [serviceA1 insertLocation:station1 atKM:0.0];
    [serviceA1 insertLocation:station2 atKM:10.0];
    
    [serviceA1.arrangedServicePoints[0] setUpArrival:5 departure:5];
    [serviceA1.arrangedServicePoints[1] setUpArrival:15 departure:16];
    [serviceA1.arrangedServicePoints[1] setDownArrival:15 departure:16];
    [serviceA1.arrangedServicePoints[0] setDownArrival:26 departure:26];
    
    ATLService *serviceA2 = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    serviceA2.shortName = @"A2";
    serviceA2.baseFrequency = 2.0;
    [serviceA2 insertLocation:station2 atKM:0.0];
    [serviceA2 insertLocation:station3 atKM:10.0];
    
    [serviceA2.arrangedServicePoints[0] setUpArrival:15 departure:16];
    [serviceA2.arrangedServicePoints[1] setUpArrival:26 departure:26];
    [serviceA2.arrangedServicePoints[1] setDownArrival:5 departure:5];
    [serviceA2.arrangedServicePoints[0] setDownArrival:15 departure:16];
    [serviceA1 connectToNextService:serviceA2];
    
    ATLService *serviceA3 = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    serviceA3.shortName = @"A3";
    serviceA3.baseFrequency = 2.0;
    [serviceA3 insertLocation:station2 atKM:0.0];
    [serviceA3 insertLocation:station5 atKM:10.0];
    
    [serviceA3.arrangedServicePoints[0] setUpArrival:30 departure:31];
    [serviceA3.arrangedServicePoints[1] setUpArrival:41 departure:41];
    [serviceA3.arrangedServicePoints[1] setDownArrival:20 departure:20];
    [serviceA3.arrangedServicePoints[0] setDownArrival:30 departure:31];
    [serviceA1 connectToNextService:serviceA3];
    
    XCTAssertEqual((int)[serviceA1.nextServices count], 2, @"");
    XCTAssertEqual((int)[serviceA3.previousServices count], 1, @"");
    
    ATLService *serviceB = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    serviceB.shortName = @"B";
    serviceB.baseFrequency = 2.0;
    [serviceB insertLocation:station1 atKM:0.0];
    [serviceB insertLocation:station5 atKM:20.0];
    [serviceB insertLocation:station6 atKM:35.0];
    XCTAssertEqual((int)[serviceB.servicePoints count], 3, @"");
    
    [serviceB.arrangedServicePoints[0] setUpArrival:0 departure:0];
    [serviceB.arrangedServicePoints[1] setUpArrival:25 departure:26];
    [serviceB.arrangedServicePoints[2] setUpArrival:41 departure:41];
    [serviceB.arrangedServicePoints[2] setDownArrival:0 departure:0];
    [serviceB.arrangedServicePoints[1] setDownArrival:15 departure:16];
    [serviceB.arrangedServicePoints[0] setDownArrival:41 departure:41];
    
    ATLService *serviceC = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    serviceC.shortName = @"C";
    serviceC.baseFrequency = 2.0;
    [serviceC insertLocation:station3 atKM:0.0];
    [serviceC insertLocation:station4 atKM:10.0];
    XCTAssertEqual((int)[serviceC.servicePoints count], 2, @"");
    
    [serviceC.arrangedServicePoints[0] setUpArrival:0 departure:0];
    [serviceC.arrangedServicePoints[1] setUpArrival:10 departure:10];
    [serviceC.arrangedServicePoints[1] setDownArrival:0 departure:0];
    [serviceC.arrangedServicePoints[0] setDownArrival:10 departure:10];

    ATLService *serviceD = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    serviceD.shortName = @"D";
    serviceD.baseFrequency = 2.0;
    [serviceD insertLocation:station6 atKM:0.0];
    [serviceD insertLocation:station7 atKM:20.0];
    
    [serviceD.arrangedServicePoints[0] setUpArrival:0 departure:0];
    [serviceD.arrangedServicePoints[1] setUpArrival:20 departure:20];
    [serviceD.arrangedServicePoints[1] setDownArrival:0 departure:0];
    [serviceD.arrangedServicePoints[0] setDownArrival:20 departure:20];
    
    NSArray *route_1_2 = shortestServicePath(station1, station2);
    ATLPathNode *lastStep = [route_1_2 lastObject];
    XCTAssertEqualWithAccuracy(lastStep.distance, 17.5, 0.1, @"");
    
    NSArray *route_1_4 = shortestServicePath(station1, station4);
    lastStep = [route_1_4 lastObject];
    XCTAssertEqualWithAccuracy(lastStep.distance, 61.0, 0.1, @"");
    
    NSArray *route_4_1 = shortestServicePath(station4, station1);
    lastStep = [route_4_1 lastObject];
    XCTAssertEqualWithAccuracy(lastStep.distance, 61.0, 0.1, @"");
    
    NSArray *route_1_5 = shortestServicePath(station1, station5);
    lastStep = [route_1_5 lastObject];
    XCTAssertEqualWithAccuracy(lastStep.distance, 36.0, 0.1, @"");
    
    NSArray *route_1_7 = shortestServicePath(station1, station7);
    lastStep = [route_1_7 lastObject];
    XCTAssertEqualWithAccuracy(lastStep.distance, 91.0, 0.1, @"");
    
    NSArray *route_1_8 = shortestServicePath(station1, station8);
    XCTAssertNil(route_1_8, @"");
    
    NSArray *route_4_7 = shortestServicePath(station4, station7);
    lastStep = [route_4_7 lastObject];
    XCTAssertEqualWithAccuracy(lastStep.distance, 140.0, 0.1, @"");
    
//    ATLJourney *journey = (ATLJourney*)[self.dataController createManagedObjectOfType:@"ATLJourney"];
//    [journey extendToStation:station4];
//    [journey extendToStation:station2];
//    XCTAssertEqual(journey.nrOfVisits, 3, @"");
//    XCTAssertEqual(journey.nrOfTravelSections, 2, @"");
//    [journey extendToStation:station7];
//    XCTAssertEqual(journey.nrOfVisits, 6, @"");
//    XCTAssertEqual(journey.nrOfTravelSections, 5, @"");
}

@end
