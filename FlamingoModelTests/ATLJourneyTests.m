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
//  ATLJourneyTests.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 31-07-14.
//

#import <XCTest/XCTest.h>

#import "ATLDataController.h"

#import "ATLStation.h"
#import "ATLService.h"
#import "ATLServicePoint.h"
#import "ATLServiceRule.h"
#import "ATLJourney.h"
#import "ATLVisit.h"
#import "ATLTransfer.h"
#import "ATLTravelSection.h"
#import "ATLTrajectory.h"
#import "ATLTimePoint.h"
#import "ATLMission.h"
#import "ATLStop.h"

#import "NSDate+Formatters.h"
#import "NSManagedObjectContext+FFEUtilities.h"

@interface ATLJourneyTests : XCTestCase

@property (strong) ATLDataController *dataController;

@end

@implementation ATLJourneyTests

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

- (void)testJourney
{
    NSDate *now = self.dataController.testingDate;
    
    // Create the journey
    ATLJourney *journey = (ATLJourney*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLJourney"];
    journey.timeOfDeparture = now;
    
    // Create a first visit and section
    ATLVisit *visit1 = (ATLVisit*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLVisit"];
    [journey addVisit:visit1 atIndex:0];
    ATLTravelSection *section1 = (ATLTravelSection*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLTravelSection"];
    [journey addTravelSection:section1 atIndex:0];

    [self.dataController saveContext];
    
    XCTAssertEqual(visit1.status, ATLElementStatusExpected, @"");
    XCTAssertEqualWithAccuracy([now timeIntervalSinceDate:journey.timeOfDeparture], 0.0, 1.0, @"");
    XCTAssertEqual(journey.nrOfTravelSections, (NSUInteger)1, @"Journey must contain one section");
    XCTAssertEqual(section1.status, ATLElementStatusExpected, @"");
    
    // Add section 2 (should be refused)
    ATLTravelSection *section2 = (ATLTravelSection*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLTravelSection"];
    [journey addTravelSection:section2 atIndex:1];
    XCTAssertEqual(journey.nrOfTravelSections, (NSUInteger)1, @"");
    XCTAssertNil(section2.origin, @"");
    
    // Add visit 2 and (again) section 2
    ATLVisit *visit2 = (ATLVisit*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLVisit"];
    [journey addVisit:visit2 atIndex:1];
    [journey addTravelSection:section2 atIndex:1];
    XCTAssertEqual(journey.nrOfTravelSections, (NSUInteger)2, @"");
    XCTAssertEqual(section2.origin, visit2, @"");
    
    // Add visit 3
    ATLVisit *visit3 = (ATLVisit*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLVisit"];
    [journey addVisit:visit3 atIndex:2];
    ATLTravelSection *section3 = (ATLTravelSection*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLTravelSection"];
    [journey addTravelSection:section3 atIndex:2];
    XCTAssertEqual(journey.nrOfTravelSections, (NSUInteger)3, @"");
    XCTAssertEqual(section3.origin, visit3, @"");
    
    // Replace section 2
    ATLTravelSection *section2bis = (ATLTravelSection*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLTravelSection"];
    [journey addTravelSection:section2bis atIndex:1];
    [self.dataController saveContext];
    XCTAssertEqual(journey.nrOfTravelSections, (NSUInteger)2, @"");
    XCTAssertEqual(section2bis.origin, visit2, @"");
    XCTAssertEqual([[self.dataController.managedObjectContext allObjectsOfClass:[ATLVisit class]] count], (NSUInteger) 2, @"");
    XCTAssertEqual([[self.dataController.managedObjectContext allObjectsOfClass:[ATLTravelSection class]] count], (NSUInteger) 2, @"");
    XCTAssertNil(section2bis.destination, @"");
    
    // Add and remove visit 3bis
    ATLVisit *visit3bis = (ATLVisit*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLVisit"];
    [journey addVisit:visit3bis atIndex:2];
    XCTAssertEqual(journey.nrOfVisits, (NSUInteger)3, @"");
    XCTAssertEqual(section2bis.destination, visit3bis, @"");
    [journey removeVisitAtIndex:2];
    [self.dataController saveContext];
    XCTAssertEqual(journey.nrOfVisits, (NSUInteger)2, @"");
    XCTAssertNil(section2bis.destination, @"");
    XCTAssertEqual([[self.dataController.managedObjectContext allObjectsOfClass:[ATLVisit class]] count], (NSUInteger) 2, @"");
    
    // remove section 2bis
    [journey removeTravelSectionAtIndex:1];
    [self.dataController saveContext];
    XCTAssertEqual(journey.nrOfTravelSections, (NSUInteger)1, @"");
    XCTAssertEqual([[self.dataController.managedObjectContext allObjectsOfClass:[ATLTravelSection class]] count], (NSUInteger) 1, @"");
    
    // Find the existing ATLJourney
    journey.timeOfArrival = [now dateByAddingTimeInterval:3600.0];
    [[journey visitAtIndex:1] setTimeOfArrival:[now dateByAddingTimeInterval:3600.0]];
    
    NSDate *checkDate = [now dateByAddingTimeInterval:1800.0];
    ATLJourney *foundJourney = [self.dataController journeyAtDate:checkDate];
    XCTAssertEqual(journey, foundJourney, @"Must find a journey in progress");
    
    checkDate = [now dateByAddingTimeInterval:-60.0];
    foundJourney = [self.dataController journeyAtDate:checkDate];
    XCTAssertEqual(journey, foundJourney, @"Must find an expected journey");
    
    // Delete the ATLJourney
    [self.dataController.managedObjectContext deleteObject:journey];
    [self.dataController saveContext];
    XCTAssertEqual([[self.dataController.managedObjectContext allObjectsOfClass:[ATLJourney class]] count], (NSUInteger) 0, @"the only ATLJourney must be gone");
    XCTAssertEqual([[self.dataController.managedObjectContext allObjectsOfClass:[ATLTravelSection class]] count], (NSUInteger) 0, @"section must be removed");
    XCTAssertEqual([[self.dataController.managedObjectContext allObjectsOfClass:[ATLVisit class]] count], (NSUInteger) 0, @"visit must be removed");
}

- (void)testTrajectory
{
    // Create sample stations
    ATLStation *utrecht = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    utrecht.id_ = @"nl.ut";
    utrecht.name = @"Utrecht Centraal";
    ATLStation *overvecht = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    overvecht.id_ = @"nl.uto";
    overvecht.name = @"Utrecht Overvecht";
    ATLStation *maarssen = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    maarssen.id_ = @"nl.mas";
    maarssen.name = @"Maarssen";
    
    // Create sample services
    ATLService *service1 = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    service1.id_ = @"ut.1";
    service1.shortName = @"1";
    ATLServicePoint *point1a = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    point1a.service = service1;
    point1a.location = maarssen;
    point1a.km = 4.990;
    ATLServicePoint *point1b = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    point1b.service = service1;
    point1b.location = utrecht;
    point1b.km = 12.392;
    ATLService *service5 = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    service5.id_ = @"ut.5";
    service5.shortName = @"5";
    ATLServicePoint *point5a = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    point5a.service = service5;
    point5a.location = overvecht;
    point5a.km = 14.267;
    ATLServicePoint *point5b = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    point5b.service = service5;
    point5b.location = utrecht;
    point5b.km = 17.444;
    ATLService *service8 = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    service8.id_ = @"ut.8";
    service8.shortName = @"8";
    ATLServicePoint *point8a = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    point8a.service = service8;
    point8a.location = utrecht;
    point8a.km = 0.000;
    ATLServicePoint *point8b = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    point8b.service = service8;
    point8b.location = overvecht;
    point8b.km = 3.177;
    
    // Create testing journey
    ATLJourney *journey = (ATLJourney*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLJourney"];
    ATLTransfer *origin = (ATLTransfer*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLTransfer"];
    origin.station = utrecht;
    [journey addVisit:origin atIndex:0];
    ATLTrajectory *trajectory = (ATLTrajectory*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLTrajectory"];
    [journey addTravelSection:trajectory atIndex:0];
    ATLTransfer *destination = (ATLTransfer*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLTransfer"];
    destination.station = overvecht;
    [journey addVisit:destination atIndex:1];
    XCTAssertEqual(journey.nrOfElements, 3, @"");

    NSSet *services = [trajectory availableServices];
    XCTAssertEqual([services count], 2, @"");
    XCTAssertTrue([services containsObject:service5], @"");
    XCTAssertTrue([services containsObject:service8], @"");
}

- (void)testServiceRules
{
    // Create sample stations
    ATLStation *utrecht = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    utrecht.id_ = @"nl.ut";
    utrecht.name = @"Utrecht Centraal";
    ATLStation *driebergen = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    driebergen.id_ = @"nl.db";
    driebergen.name = @"Driebergen Zeist";
    ATLStation *klomp = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    klomp.id_ = @"nl.klp";
    klomp.name = @"Veenendaal de Klomp";
    ATLStation *ede = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    ede.id_ = @"nl.ed";
    ede.name = @"Ede Wageningen";
    ATLStation *arnhem = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    arnhem.id_ = @"nl.ah";
    arnhem.name = @"Arnhem";
    
    ATLService *service = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    service.id_ = @"ic.j";
    
    ATLServicePoint *p_utrecht = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_utrecht.service = service;
    p_utrecht.location = utrecht;
    p_utrecht.km = 0.000;
    [p_utrecht setUpArrival:36 departure:38];
    [p_utrecht setDownArrival:67 departure:70];
    ATLServicePoint *p_driebergen = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_driebergen.service = service;
    p_driebergen.location = driebergen;
    p_driebergen.km = 11.241;
    [p_driebergen setUpArrival:46 departure:46];
    [p_driebergen setDownArrival:57 departure:57];
    ATLServicePoint *p_klomp = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_klomp.service = service;
    p_klomp.location = klomp;
    p_klomp.km = 33.119;
    [p_klomp setUpArrival:56 departure:56];
    [p_klomp setDownArrival:46 departure:46];
    ATLServicePoint *p_ede = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_ede.service = service;
    p_ede.location = ede;
    p_ede.km = 40.192;
    [p_ede setUpArrival:62 departure:62];
    [p_ede setDownArrival:41 departure:41];
    ATLServicePoint *p_arnhem = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_arnhem.service = service;
    p_arnhem.location = arnhem;
    p_arnhem.km = 56.504;
    [p_arnhem setUpArrival:74 departure:79];
    [p_arnhem setDownArrival:26 departure:31];
    
    ATLServiceRule *rule1 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule1.service = service;
    [rule1 fillWithDictionary:@{@"from": @"ut", @"to": @"ah", @"nr": @"3127", @"b": @"12336",
                                @"o": @"08:00", @"d": @"up", @"w": @"63", @"headsign": @"Arnhem"}];
    [rule1 addNoStopPointsObject:p_klomp];
    ATLServiceRule *rule2 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule2.service = service;
    [rule2 fillWithDictionary:@{@"from": @"ut", @"to": @"ah", @"nr": @"3027", @"b": @"11335",
                                @"o": @"08:15", @"d": @"up", @"w": @"127", @"headsign": @"Arnhem"}];
    [rule2 addNoStopPointsObject:p_driebergen];
    ATLServiceRule *rule3 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule3.service = service;
    [rule3 fillWithDictionary:@{@"from": @"ut", @"to": @"ed", @"nr": @"3129", @"b": @"12348",
                                @"o": @"08:30", @"d": @"up", @"w": @"63", @"headsign": @"Ede Wageningen"}];
    [rule3 addNoStopPointsObject:p_klomp];
    ATLServiceRule *rule4 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule4.service = service;
    [rule4 fillWithDictionary:@{@"from": @"ut", @"to": @"ah", @"nr": @"3029", @"b": @"11373",
                                @"o": @"08:45", @"d": @"up", @"w": @"127", @"headsign": @"Arnhem"}];
    [rule4 addNoStopPointsObject:p_driebergen];
    ATLServiceRule *rule5 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule5.service = service;
    [rule5 fillWithDictionary:@{@"from": @"ut", @"to": @"ah", @"nr": @"3131", @"b": @"12357",
                                @"o": @"09:00", @"d": @"up", @"w": @"63", @"headsign": @"Arnhem"}];
    [rule5 addNoStopPointsObject:p_klomp];
    ATLServiceRule *rule6 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule6.service = service;
    [rule6 fillWithDictionary:@{@"from": @"ut", @"to": @"ah", @"nr": @"3031", @"b": @"11399",
                                @"o": @"09:15", @"d": @"up", @"w": @"127", @"headsign": @"Arnhem"}];
    [rule6 addNoStopPointsObject:p_driebergen];
    ATLServiceRule *rule7 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule7.service = service;
    [rule7 fillWithDictionary:@{@"from": @"ah", @"to": @"ut", @"nr": @"3128", @"b": @"12337",
                                @"o": @"08:00", @"d": @"down", @"w": @"63", @"headsign": @"Utrecht C"}];
    [rule7 addNoStopPointsObject:p_klomp];
    ATLServiceRule *rule8 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule8.service = service;
    [rule8 fillWithDictionary:@{@"from": @"ah", @"to": @"ut", @"nr": @"3028", @"b": @"11336",
                                @"o": @"08:15", @"d": @"down", @"w": @"127", @"headsign": @"Utrecht C"}];
    [rule8 addNoStopPointsObject:p_driebergen];
    ATLServiceRule *rule9 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule9.service = service;
    [rule9 fillWithDictionary:@{@"from": @"ah", @"to": @"ut", @"nr": @"3130", @"b": @"12349",
                                @"o": @"08:30", @"d": @"down", @"w": @"63", @"headsign": @"Utrecht C"}];
    [rule9 addNoStopPointsObject:p_klomp];
    ATLServiceRule *rule10 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule10.service = service;
    [rule10 fillWithDictionary:@{@"from": @"ah", @"to": @"ut", @"nr": @"3030", @"b": @"11374",
                                @"o": @"08:45", @"d": @"down", @"w": @"127", @"headsign": @"Utrecht C"}];
    [rule10 addNoStopPointsObject:p_driebergen];
    ATLServiceRule *rule11 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule11.service = service;
    [rule11 fillWithDictionary:@{@"from": @"ah", @"to": @"ut", @"nr": @"3132", @"b": @"12358",
                                @"o": @"09:00", @"d": @"down", @"w": @"63", @"headsign": @"Utrecht C"}];
    [rule11 addNoStopPointsObject:p_klomp];
    ATLServiceRule *rule12 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule12.service = service;
    [rule12 fillWithDictionary:@{@"from": @"ah", @"to": @"ut", @"nr": @"3032", @"b": @"11400",
                                @"o": @"09:15", @"d": @"down", @"w": @"127", @"headsign": @"Utrecht C"}];
    [rule12 addNoStopPointsObject:p_driebergen];
    
    // test up direction on Monday
    NSDate *startTime = [NSDate dateFromMachineString:@"2014-08-04 08:50:00 +0200"];
    NSDate *endTime = [NSDate dateFromMachineString:@"2014-08-04 09:50:00 +0200"];
    
    // Must only find trains within the specified time span:
    NSArray *rules = [service rulesFromPoint:p_utrecht toPoint:p_ede startTime:startTime endTime:endTime useDeparture:YES];
    XCTAssertEqual([rules count], 4, @"");
    
    // Must not include train running to Ede:
    rules = [service rulesFromPoint:p_utrecht toPoint:p_arnhem startTime:startTime endTime:endTime useDeparture:YES];
    XCTAssertEqual([rules count], 3, @"");
    
    // Must not include trains that skip De Klomp:
    rules = [service rulesFromPoint:p_utrecht toPoint:p_klomp startTime:startTime endTime:endTime useDeparture:YES];
    XCTAssertEqual([rules count], 2, @"");
    
    // Test down direction on Sunday
    startTime = [NSDate dateFromMachineString:@"2014-08-03 08:50:00 +0200"];
    endTime = [NSDate dateFromMachineString:@"2014-08-03 09:50:00 +0200"];
    
    // Most not include trains that don't run on Sunday:
    rules = [service rulesFromPoint:p_ede toPoint:p_utrecht startTime:startTime endTime:endTime useDeparture:YES];
    XCTAssertEqual([rules count], 2, @"");
}

- (void)testmissionCreation
{
    // Create sample stations
    ATLStation *rotterdam = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    rotterdam.id_ = @"nl.rtd";
    rotterdam.name = @"Rotterdam Centraal";
    ATLStation *alexander = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    alexander.id_ = @"nl.rta";
    alexander.name = @"Rotterdam Alexander";
    ATLStation *gouda = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    gouda.id_ = @"nl.gd";
    gouda.name = @"Gouda";
    ATLStation *utrecht = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    utrecht.id_ = @"nl.ut";
    utrecht.name = @"Utrecht Centraal";
    ATLStation *amersfoort = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    amersfoort.id_ = @"nl.amf";
    amersfoort.name = @"Amersfoort";
    ATLStation *zwolle = (ATLStation*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLStation"];
    zwolle.id_ = @"nl.zl";
    zwolle.name = @"Zwolle";
    
    // Create sample service A
    ATLService *serviceA = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    serviceA.id_ = @"ic.a";
    ATLServicePoint *p_rotterdam = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_rotterdam.service = serviceA;
    p_rotterdam.location = rotterdam;
    p_rotterdam.km = 0.000;
    [p_rotterdam setUpArrival:05 departure:05];
    p_rotterdam.upPlatform = @"14";
    [p_rotterdam setDownArrival:55 departure:55];
    p_rotterdam.downPlatform = @"14";
    ATLServicePoint *p_alexander = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_alexander.service = serviceA;
    p_alexander.location = alexander;
    p_alexander.km = 9.814;
    [p_alexander setUpArrival:13 departure:13];
    p_alexander.upPlatform = @"1";
    [p_alexander setDownArrival:46 departure:46];
    p_alexander.downPlatform = @"2";
    ATLServicePoint *p_gouda = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_gouda.service = serviceA;
    p_gouda.location = gouda;
    p_gouda.km = 23.534;
    [p_gouda setUpArrival:23 departure:24];
    p_gouda.upPlatform = @"3";
    [p_gouda setDownArrival:36 departure:37];
    p_gouda.downPlatform = @"8";
    ATLServicePoint *p_utrecht1 = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_utrecht1.service = serviceA;
    p_utrecht1.location = utrecht;
    p_utrecht1.km = 55.938;
    [p_utrecht1 setUpArrival:43 departure:43];
    p_utrecht1.upPlatform = @"11a";
    [p_utrecht1 setDownArrival:11 departure:17];
    p_utrecht1.downPlatform = @"8";

    // Create sample service C
    ATLService *serviceC = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    serviceC.id_ = @"ic.c";
    ATLServicePoint *p_utrecht2 = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_utrecht2.service = serviceC;
    p_utrecht2.location = utrecht;
    p_utrecht2.km = 0.000;
    [p_utrecht2 setUpArrival:46 departure:50];
    p_utrecht2.upPlatform = @"11a";
    [p_utrecht2 setDownArrival:25 departure:29];
    p_utrecht2.downPlatform = @"8";
    ATLServicePoint *p_amersfoort1 = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_amersfoort1.service = serviceC;
    p_amersfoort1.location = amersfoort;
    p_amersfoort1.km = 20.981;
    [p_amersfoort1 setUpArrival:66 departure:68];
    p_amersfoort1.upPlatform = @"2b";
    [p_amersfoort1 setDownArrival:7 departure:10];
    p_amersfoort1.downPlatform = @"6a";

    // Create sample service D
    ATLService *serviceD = (ATLService*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLService"];
    serviceD.id_ = @"ic.d";
    ATLServicePoint *p_amersfoort2= (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_amersfoort2.service = serviceD;
    p_amersfoort2.location = amersfoort;
    p_amersfoort2.km = 0.000;
    [p_amersfoort2 setUpArrival:64 departure:67];
    p_amersfoort2.upPlatform = @"1";
    [p_amersfoort2 setDownArrival:112 departure:116];
    p_amersfoort2.downPlatform = @"6a";
    ATLServicePoint *p_zwolle = (ATLServicePoint*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServicePoint"];
    p_zwolle.service = serviceD;
    p_zwolle.location = zwolle;
    p_zwolle.km = 66.832;
    [p_zwolle setUpArrival:102 departure:102];
    p_zwolle.upPlatform = @"7";
    [p_zwolle setDownArrival:68 departure:78];
    p_zwolle.downPlatform = @"5a";
    
    // Create service rules
    ATLServiceRule *rule1 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule1.service = serviceA;
    [rule1 fillWithDictionary:@{@"from": @"rtd", @"to": @"ut", @"nr": @"519", @"b": @"4345",
                                @"o": @"06:00", @"d": @"up", @"w": @"31", @"headsign": @"Groningen"}];
    [rule1 createIdentifier];
    
    ATLServiceRule *rule2 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule2.service = serviceA;
    [rule2 fillWithDictionary:@{@"from": @"gd", @"to": @"ut", @"nr": @"519", @"b": @"4345",
                                @"o": @"06:00", @"d": @"up", @"w": @"32", @"headsign": @"Groningen"}];
    [rule2 createIdentifier];
    
    ATLServiceRule *rule3 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule3.service = serviceC;
    [rule3 fillWithDictionary:@{@"from": @"ut", @"to": @"amf", @"nr": @"519", @"b": @"4345",
                                @"o": @"06:00", @"d": @"up", @"w": @"127", @"headsign": @"Groningen"}];
    [rule3 createIdentifier];

    ATLServiceRule *rule4 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule4.service = serviceD;
    [rule4 fillWithDictionary:@{@"from": @"amf", @"to": @"zl", @"nr": @"519", @"b": @"4345",
                                @"o": @"06:00", @"d": @"up", @"w": @"127", @"headsign": @"Groningen"}];
    [rule4 createIdentifier];
    
    ATLServiceRule *rule5 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule5.service = serviceA;
    [rule5 fillWithDictionary:@{@"from": @"ut", @"to": @"rtd", @"nr": @"520", @"b": @"4353",
                                @"o": @"08:00", @"d": @"down", @"w": @"127", @"headsign": @"Rotterdam Centraal"}];
    [rule5 createIdentifier];
    
    ATLServiceRule *rule6 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule6.service = serviceC;
    [rule6 fillWithDictionary:@{@"from": @"amf", @"to": @"ut", @"nr": @"520", @"b": @"4353",
                                @"o": @"07:45", @"d": @"down", @"w": @"63", @"headsign": @"Rotterdam Centraal"}];
    [rule6 createIdentifier];
    
    ATLServiceRule *rule7 = (ATLServiceRule*)[self.dataController.managedObjectContext createManagedObjectOfType:@"ATLServiceRule"];
    rule7.service = serviceD;
    [rule7 fillWithDictionary:@{@"from": @"zl", @"to": @"amf", @"nr": @"520", @"b": @"4353",
                                @"o": @"06:00", @"d": @"down", @"w": @"63", @"headsign": @"Rotterdam Centraal"}];
    [rule7 createIdentifier];
    
    // Test mission creation for different days and directions
    NSDate *date = [NSDate dateFromMachineString:@"2014-08-02 06:00:00 +0200"];
    ATLMission *mission = [rule1 missionAtDate:date];
    XCTAssertEqual([mission.stops count], 4);
    ATLStop *s_amf = mission[2];
    XCTAssertEqual(s_amf.station, amersfoort);
    XCTAssertEqualObjects(s_amf.departureString, @"07:07");
    XCTAssertEqualObjects(s_amf.platform, @"1");
    
    date = [NSDate dateFromMachineString:@"2014-08-03 06:00:00 +0200"];
    mission = [rule1 missionAtDate:date];
    XCTAssertEqual([mission.stops count], 3);
    
    date = [NSDate dateFromMachineString:@"2014-08-04 06:00:00 +0200"];
    mission = [rule1 missionAtDate:date];
    XCTAssertEqual([mission.stops count], 6);
    
    NSSet *missions = [serviceC missionsFromStation:utrecht
                                          toStation:amersfoort
                                          startTime:[NSDate dateFromMachineString:@"2014-08-04 06:45:00 +0200"]
                                            endTime:[NSDate dateFromMachineString:@"2014-08-04 06:55:00 +0200"]
                                       useDeparture:YES];
    XCTAssertEqual([missions anyObject], mission);
    missions = [serviceC missionsFromStation:utrecht
                                   toStation:amersfoort
                                   startTime:[NSDate dateFromMachineString:@"2014-08-04 07:00:00 +0200"]
                                     endTime:[NSDate dateFromMachineString:@"2014-08-04 07:10:00 +0200"]
                                useDeparture:NO];
    XCTAssertEqual([missions anyObject], mission);
    
    date = [NSDate dateFromMachineString:@"2014-08-04 06:00:00 +0200"];
    mission = [rule5 missionAtDate:date];
    XCTAssertEqual([mission.stops count], 6);
    
    NSSet *departures = [serviceC departuresFromPoint:p_utrecht2
                                   startTime:[NSDate dateFromMachineString:@"2014-08-04 06:30:00 +0200"]
                                     endTime:[NSDate dateFromMachineString:@"2014-08-04 08:30:00 +0200"]];
    XCTAssertEqual([departures count], 1);
    
    NSArray *stops = [utrecht departuresAfter:[NSDate dateFromMachineString:@"2014-08-04 06:30:00 +0200"]];
    XCTAssertEqual([stops count], 2);

    
}

@end
