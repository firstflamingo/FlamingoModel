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
//  ATLImporterTests.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 24-06-14.
//

#import <XCTest/XCTest.h>
#import "ATLDataController.h"
#import "ATLScheduleImporter.h"
#import "ATLFileImporter.h"

#import "ATLJunction.h"
#import "ATLStation.h"
#import "ATLService.h"
#import "ATLServicePoint.h"
#import "ATLServiceRule.h"
#import "ATLSeries.h"
#import "ATLMissionRule.h"
#import "ATLTimePath.h"
#import "ATLTimePoint.h"
#import "ATLCalendarRule.h"

#import "NSManagedObjectContext+FFEUtilities.h"

@interface ATLImporterTests : XCTestCase

@property (nonatomic, strong) ATLDataController *dataController;
@property (nonatomic, strong) ATLScheduleImporter *importer;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

@end

@implementation ATLImporterTests

- (void)setUp
{
    [super setUp];
    self.dataController = [ATLDataController testingInstance];
    self.dataController.testingDate = [NSDate date];
    self.importer = [ATLScheduleImporter new];
    self.managedObjectContext = self.dataController.managedObjectContext;
    self.importer.managedObjectContext = self.managedObjectContext;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTrainTypeFilter
{
    XCTAssertTrue([self.importer shouldImportTrainType:@"52-ST"], @"");
    XCTAssertTrue([self.importer shouldImportTrainType:@"100-SPR"], @"");
    XCTAssertTrue([self.importer shouldImportTrainType:@"100-IC"], @"");
    XCTAssertTrue([self.importer shouldImportTrainType:@"200-HSN"], @"");
    XCTAssertFalse([self.importer shouldImportTrainType:@"911-ST"], @"");
    XCTAssertFalse([self.importer shouldImportTrainType:@"100-ICE"], @"");
}

- (void)testTimePoint
{
    ATLTimePoint *timePoint1 = [ATLTimePoint new];
    [timePoint1 fillWithDictionary:@{@"A": @"14:21:00", @"V": @"14:23:00", @"O": @(9), @"P": @"14", @"S": @"nl.ut"}];
    XCTAssertEqual(timePoint1.arrival, 861, @"");
    XCTAssertEqual(timePoint1.departure, 863, @"");
    XCTAssertEqualObjects(timePoint1.stationCode, @"ut", @"");
    XCTAssertEqualObjects(timePoint1.platform, @"14", @"");
    XCTAssertEqual(timePoint1.options, pointOptionsCanDropOff | pointOptionsCoordinateAgency, @"");
    XCTAssertTrue(timePoint1.canDropOff, @"");
    XCTAssertFalse(timePoint1.canPickUp, @"");
    XCTAssertEqual(timePoint1.hash_, 1837601190, @"");

    ATLTimePoint *timePoint2 = [ATLTimePoint new];
    [timePoint2 fillWithDictionary:@{@"A": @"14:21:00", @"V": @"14:23:00", @"O": @(9), @"P": @"14", @"S": @"nl.ut"}];
    XCTAssertTrue([timePoint1 isEqualToPoint:timePoint2], @"");
    
    ATLTimePoint *timePoint3 = [ATLTimePoint new];
    [timePoint3 fillWithDictionary:@{@"A": @"14:21:00", @"V": @"14:23:00", @"O": @(6), @"P": @"14", @"S": @"nl.ut"}];
    XCTAssertFalse([timePoint1 isEqualToPoint:timePoint3], @"");
    XCTAssertEqual(timePoint3.options, pointOptionsCanPickUp | pointOptionsCoordinateDriver, @"");
}

- (void)testCalendarExceptions
{
    NSURL *bundleURL = [[NSBundle bundleForClass:[self class]] bundleURL];
    [self.importer importContentsOfDirectory:[bundleURL URLByAppendingPathComponent:@"Contents/Resources" isDirectory:YES]
               intoManagedObjectContext:self.managedObjectContext withOptions:includeCalendarExceptions];
    
    NSDate *mar01 = [self.importer dateForIdentifier:@"20140301"];
    XCTAssertNotNil(mar01, @"");
    NSDate *mar31 = [self.importer dateForIdentifier:@"20140331"];
    XCTAssertNotNil(mar31, @"");
    NSDate *apr01 = [self.importer dateForIdentifier:@"20140401"];
    XCTAssertNil(apr01, @"");
    NSSet *allMondays = [self.importer allDatesOnWeekday:0];
    XCTAssertEqual([allMondays count], 5, @"");
    XCTAssertFalse([allMondays containsObject:mar01], @"");
    XCTAssertTrue([allMondays containsObject:mar31], @"");
    
    ATLMissionRule *trip1 = [self.managedObjectContext objectOfClass:[ATLMissionRule class] withModelID:@"10000|1|3047" create:NO];
    XCTAssertEqualObjects(trip1.headsign, @"Nijmegen", @"");
    XCTAssertEqual(trip1.weekdays, 1 << 5, @"");
    XCTAssertEqual([trip1.notRunningDates count], 0, @"");
    XCTAssertEqual([trip1.runningDates count], 0, @"");
    ATLMissionRule *trip2 = [self.managedObjectContext objectOfClass:[ATLMissionRule class] withModelID:@"10017|2|3049" create:NO];
    XCTAssertEqual(trip2.weekdays, 1 << 6, @"");
    XCTAssertEqual([trip2.notRunningDates count], 1, @"");
    XCTAssertEqual([trip2.runningDates count], 0, @"");
    ATLMissionRule *trip3 = [self.managedObjectContext objectOfClass:[ATLMissionRule class] withModelID:@"10018|3|3049" create:NO];
    XCTAssertEqual(trip3.weekdays, 0, @"");
    XCTAssertEqual([trip3.notRunningDates count], 0, @"");
    XCTAssertEqual([trip3.runningDates count], 1, @"");
    
    XCTAssertEqual([[self.managedObjectContext allObjectsOfClass:[ATLTimePath class]] count], 2, @"");
    
    ATLTimePath *path1 = trip1.timePath;
    XCTAssertEqual([path1.timePoints count], 18, @"");
    ATLTimePoint *point1 = path1.firstPoint;
    XCTAssertEqualObjects(point1.stationCode, @"hdr", @"");
}

- (void)testMissionAggregation
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    // Import service ic.j and series nl.030 nl.031 from xml file
    [[ATLFileImporter new] importContentsOfURL:[bundle URLForResource:@"t2_data" withExtension:@"xml"]
                      intoManagedObjectContext:self.managedObjectContext];
    XCTAssertEqual([[self.managedObjectContext allObjectsOfClass:[ATLJunction class]] count], 2);
    XCTAssertEqual([[self.managedObjectContext allObjectsOfClass:[ATLStation class]] count], 6);
    XCTAssertEqual([[self.managedObjectContext allObjectsOfClass:[ATLService class]] count], 1);
    XCTAssertEqual([[self.managedObjectContext allObjectsOfClass:[ATLSeries class]] count], 2);

    // Import unpretending calendar, running "all days"
    [self.importer importContentsOfURL:[bundle URLForResource:@"feed_info" withExtension:@"txt"] forStep:readInfo];
    [self.importer importContentsOfURL:[bundle URLForResource:@"t2_calendar_dates" withExtension:@"txt"] forStep:readCalendar];
    XCTAssertEqual([(ATLCalendarRule*)self.importer.calendarRules[@"NS:0"] weekdays], 127);

    // Import sample missions: 3047 (hdr - nm), 3049 (asd - ah), 3051 (hdr - nm), 3147 (shl - nm)
    [self.importer importContentsOfURL:[bundle URLForResource:@"t2_trips" withExtension:@"txt"] forStep:readTrips];
    XCTAssertEqual([[self.managedObjectContext allObjectsOfClass:[ATLMissionRule class]] count], 6);
    [self.importer importContentsOfURL:[bundle URLForResource:@"t2_stop_times" withExtension:@"txt"] forStep:readStopTimes];
    XCTAssertEqual([self.importer.timePaths count], 5);
    
    ATLMissionRule *mission3047 = [self.managedObjectContext objectOfClass:[ATLMissionRule class] withModelID:@"3047" create:NO];
    XCTAssertEqualObjects(mission3047.offsetString, @"12:00");
    ATLMissionRule *mission3049 = [self.managedObjectContext objectOfClass:[ATLMissionRule class] withModelID:@"3049" create:NO];
    XCTAssertEqualObjects(mission3049.offsetString, @"13:30");
    XCTAssertNotEqual(mission3047.timePath, mission3049.timePath);
    ATLMissionRule *mission3051 = [self.managedObjectContext objectOfClass:[ATLMissionRule class] withModelID:@"3051" create:NO];
    XCTAssertEqualObjects(mission3051.offsetString, @"13:00");
    XCTAssertEqual(mission3047.timePath, mission3051.timePath);
    ATLMissionRule *mission3147 = [self.managedObjectContext objectOfClass:[ATLMissionRule class] withModelID:@"3147" create:NO];
    XCTAssertEqualObjects(mission3147.offsetString, @"13:00");
    
    // Synchronize offsets: mission 3049 must be adapted
    ATLSeries *series030 = [self.managedObjectContext objectOfClass:[ATLSeries class] withModelID:@"nl.030" create:NO];
    [series030 syncOffsets];
    XCTAssertEqualObjects(mission3049.offsetString, @"12:30");
    
    // Fill schedule for service J
    ATLService *serviceJ = [self.managedObjectContext objectOfClass:[ATLService class] withModelID:@"ic.j" create:NO];
    [serviceJ fillSchedule];
    XCTAssertEqual([(ATLServicePoint*)serviceJ.arrangedServicePoints[0] upDeparture], 38); // Utrecht
    XCTAssertEqual([(ATLServicePoint*)serviceJ.arrangedServicePoints[2] upDeparture], 46); // Driebergen
    XCTAssertEqual([(ATLServicePoint*)serviceJ.arrangedServicePoints[3] upDeparture], 56); // De Klomp
    XCTAssertEqual([(ATLServicePoint*)serviceJ.arrangedServicePoints[4] upDeparture], 62); // Ede-Wageningen
    XCTAssertEqual([(ATLServicePoint*)serviceJ.arrangedServicePoints[5] upDeparture], 79); // Arnhem
    XCTAssertEqual([(ATLServicePoint*)serviceJ.arrangedServicePoints[7] upArrival], 92); // Nijmegen
    
    ATLServiceRule *rule3047 = [self.managedObjectContext objectOfClass:[ATLServiceRule class] withModelID:@"ic.j_3047_7f" create:NO];
    ATLServicePoint *noStopPoint = [rule3047.noStopPoints anyObject];
    XCTAssertEqualObjects(noStopPoint.locationCode, @"db");
    ATLServiceRule *rule3147 = [self.managedObjectContext objectOfClass:[ATLServiceRule class] withModelID:@"ic.j_3147_3f" create:NO];
    noStopPoint = [rule3147.noStopPoints anyObject];
    XCTAssertEqualObjects(noStopPoint.locationCode, @"klp");
    ATLServiceRule *rule3147zo = [self.managedObjectContext objectOfClass:[ATLServiceRule class] withModelID:@"ic.j_3147_40" create:NO];
    XCTAssertEqual([rule3147zo.noStopPoints count], 2);
}

@end
