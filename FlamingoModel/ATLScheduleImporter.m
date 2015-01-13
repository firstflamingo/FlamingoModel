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
//  ATLScheduleImporter.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 24-06-14.
//

#import "ATLScheduleImporter.h"

#import "ATLCalendarRule.h"
#import "ATLMissionRule.h"
#import "ATLTimePath.h"
#import "ATLTimePoint.h"
#import "ATLSeries.h"

#import "CHCSVparser.h"
#import "NSManagedObjectContext+FFEUtilities.h"


#define TWELVE_HOURS        43200.0
#define TWENTYFOUR_HOURS    86400.0

typedef enum {
    feed_publisher_name,
    feed_publisher_url,
    feed_lang,
    feed_start_date,
    feed_end_date,
    feed_version
} GTFSInfoFields;

typedef enum {
    service_id,
    date_field,
    exception_type
} GTFSCalendarDatesFields;

typedef enum {
    route_reference,
    service_reference,
    trip_identifier,
    trip_headsign,
    direction_indicator,
    trip_short_name,
    block_reference,
    bikes_allowed
} GTFSTripFields;

typedef enum {
    trip_reference,
    arrival_time,
    departure_time,
    stop_reference,
    arrival_stop_id,
    stop_sequence,
    pickup_type,
    drop_off_type
} GTFSStopTimesFields;

typedef enum {
    regularStopHandling = 0,
    noStopHandling = 1,
    coordinateWithAgency = 2,
    coordinateWithDriver = 3
} GTFSStopHandling;

ATLTimePointOptions optionsFromStopHandling(GTFSStopHandling dropOffType, GTFSStopHandling pickUpType);

@interface ATLScheduleImporter () <CHCSVParserDelegate>

@end

@implementation ATLScheduleImporter {
    
    // Dates handling
    NSDate *_startDate, *_endDate;
    NSMutableDictionary *_datesByIdentifier;
    NSMutableArray *_allDatesOnWeekday;
    
    // Import flow
    ATLScheduleImportStep _importStep;
    
    // Intermediate results
    NSMutableArray *_foundData;
    NSMutableDictionary *_calendarRules;
    NSMutableDictionary *_seriesDict;
    NSMutableArray *_timePoints, *_datesOnWeekday;
    NSMutableDictionary *_timePaths;
    NSString *_identifier;
    ATLMissionRule *_missionRule;
}

#pragma mark - External interface

- (void)importContentsOfDirectory:(NSURL *)directory intoManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                      withOptions:(ATLScheduleImportOptions)options
{
    self.managedObjectContext = managedObjectContext;
    self.options = options;
    
    for (ATLScheduleImportStep step = 0; step < nrOfImportSteps; step++) {
        NSURL *fileURL = [directory URLByAppendingPathComponent:[self fileNameForStep:step]];
        [self importContentsOfURL:fileURL forStep:step];
    }
}

#pragma mark - Testing interface

- (void)importContentsOfURL:(NSURL *)url forStep:(ATLScheduleImportStep)step
{
    _importStep = step;
    CHCSVParser *parser = [[CHCSVParser alloc] initWithContentsOfCSVFile:url.path];
    parser.delegate = self;
    [parser parse];
}

- (NSDictionary *)calendarRules
{
    return _calendarRules;
}

- (NSArray *)timePaths
{
    return [_timePaths allValues];
}

#pragma mark - Dates handling

- (int)nrOfDays
{
    NSDate *endDate = [_endDate dateByAddingTimeInterval:TWELVE_HOURS];
    return ([endDate timeIntervalSinceDate:_startDate] / TWENTYFOUR_HOURS) + 1;
}

- (int)nrOfWeeks
{
    return self.nrOfDays / 7;
}

- (NSArray *)dateAndWeekdayForIdentifier:(NSString *)identifier
{
    if (!_datesByIdentifier) {
        [self generateDatesCollection];
    }
    return _datesByIdentifier[identifier];
}

- (int)weekdayIndexForIdentifier:(NSString *)identifier
{
    return [[self dateAndWeekdayForIdentifier:identifier][1] intValue];
}

- (NSDate *)dateForIdentifier:(NSString *)identifier
{
    return [self dateAndWeekdayForIdentifier:identifier][0];
}

- (NSSet *)allDatesOnWeekday:(int)weekdayIndex
{
    if (!_allDatesOnWeekday) {
        [self generateDatesCollection];
    }
    return _allDatesOnWeekday[weekdayIndex];
}

- (void)generateDatesCollection
{
    _datesByIdentifier = [NSMutableDictionary dictionaryWithCapacity:self.nrOfDays];
    _allDatesOnWeekday = [NSMutableArray arrayWithCapacity:7];
    for (int i = 0; i < 7; i++) {
        _allDatesOnWeekday[i] = [NSMutableSet setWithCapacity:self.nrOfWeeks + 1];
    }
    NSDate *date = _startDate;
    NSDate *endDate = [_endDate dateByAddingTimeInterval:TWELVE_HOURS];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyyMMdd";
    int weekday = date.weekdayIndex;
    
    while ([date compare:endDate] == NSOrderedAscending) {
        NSString *identifier = [df stringFromDate:date];
        _datesByIdentifier[identifier] = @[date, @(weekday)];
        [_allDatesOnWeekday[weekday] addObject:date];
        date = [date dateByAddingTimeInterval:TWENTYFOUR_HOURS];
        weekday++;
        if (weekday >=7) {
            weekday = 0;
        }
    }
}

#pragma mark - Import flow

- (BOOL)shouldImportTrainType:(NSString*)trainType
{
    NSArray *comps = [trainType componentsSeparatedByString:@"-"];
    switch ([comps[0] intValue]) {
        case 300: // Thalys
            return NO;
        case 310: // EETC
            return NO;
        case 910: // DB
            return NO;
        case 911: // Keolis
            return NO;
        case 920: // NMBS
            return NO;
    }
    if ([[comps[1] substringToIndex:1] isEqualToString:@"S"]) { // Stoptrein, Sneltrein, Sprinter
        return YES;
    }
    else if ([comps[1] isEqualToString:@"IC"]) { // Intercity
        return YES;
    }
    else if ([comps[1] isEqualToString:@"HSN"]) { // Intercity direct
        return YES;
    }
    return NO;
}

- (NSString*)fileNameForStep:(ATLScheduleImportStep)step
{
    switch (step) {
        case readInfo:
            return @"feed_info.txt";
            
        case readCalendar:
            return @"calendar_dates.txt";
            
        case readTrips:
            return @"trips.txt";
            
        case readStopTimes:
            return @"stop_times.txt";
            
        default:
            return nil;
    }
}

- (void)createCalendarRecord
{
    if (!_identifier) {
        return;
    }
    int criterium = (self.nrOfWeeks / 2) + 1;
    ATLWeekdays weekdays = noRegularWeekday;
    NSMutableSet *runningDates = [NSMutableSet setWithCapacity:52];
    NSMutableSet *notRunningDates = [NSMutableSet setWithCapacity:52];
    for (int i = 0; i < 7; i++) {
        if ([_datesOnWeekday[i] count] >= criterium) {
            weekdays |= 1 << i;
            NSMutableSet *exceptions = [[self allDatesOnWeekday:i] mutableCopy];
            [exceptions minusSet:_datesOnWeekday[i]];
            [notRunningDates unionSet:exceptions];
        } else {
            [runningDates unionSet:_datesOnWeekday[i]];
        }
        [_datesOnWeekday[i] removeAllObjects];
    }
    ATLCalendarRule *calendarRule = [ATLCalendarRule new];
    calendarRule.weekdays = weekdays;
    calendarRule.runningDates = runningDates;
    calendarRule.notRunningDates = notRunningDates;
    _calendarRules[_identifier] = calendarRule;
}

- (void)createTimePath
{
    if (!_identifier) {
        return;
    }
    if (_missionRule) {
        ATLMinutes offset = [ATLTimePath normalizePointsArray:_timePoints];
        uint32_t hash = [ATLTimePath hashForPointsArray:_timePoints];
        ATLTimePath *path = _timePaths[@(hash)];
        if (!path) {
            path = (ATLTimePath*)[self.managedObjectContext createManagedObjectOfType:@"ATLTimePath"];
            path.hash_ = hash;
            path.timePointsData = [NSKeyedArchiver archivedDataWithRootObject:_timePoints];
            _timePaths[@(hash)] = path;
        }
        _missionRule.offset = offset;
        _missionRule.timePath = path;
    }
    [_timePoints removeAllObjects];
}

#pragma mark - CHCSVParserDelegate methods

- (void)parserDidBeginDocument:(CHCSVParser *)parser
{
    _foundData = [NSMutableArray arrayWithCapacity:12];
    
    switch (_importStep) {
        case readCalendar:
            _calendarRules = [NSMutableDictionary dictionaryWithCapacity:5000];
            _datesOnWeekday = [NSMutableArray arrayWithCapacity:7];
            for (int i = 0; i < 7; i++) {
                _datesOnWeekday[i] = [NSMutableSet setWithCapacity:52];
            }
            break;
            
        case readTrips:
            _seriesDict = [NSMutableDictionary dictionaryWithCapacity:150];
            break;
            
        case readStopTimes:
            _timePoints = [NSMutableArray arrayWithCapacity:30];
            _timePaths = [NSMutableDictionary dictionaryWithCapacity:5000];
            break;
            
        default:
            break;
    }
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber
{
    [_foundData removeAllObjects];
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex
{
    [_foundData addObject:field];
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber
{
    if (recordNumber > 1 && [_foundData count] > 1) {
        static int progressCounter = 0;
        progressCounter++;
        if (progressCounter > 5000) {
            NSString *statusString = [NSString stringWithFormat:@"Import step %d at line %d", _importStep, (int)recordNumber];
            NSLog(@"%@", statusString);
            progressCounter = 0;
        }
        switch (_importStep) {
            case readInfo: {
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                df.timeZone = [NSTimeZone timeZoneWithAbbreviation: @"GMT"];
                df.dateFormat = @"yyyyMMdd";
                NSDate *roughDate = [df dateFromString:_foundData[feed_start_date]];
                _startDate = [roughDate dateByAddingTimeInterval:TWELVE_HOURS];
                roughDate = [df dateFromString:_foundData[feed_end_date]];
                _endDate = [roughDate dateByAddingTimeInterval:TWELVE_HOURS];
                break;
            }
                
            case readCalendar: {
                if ([_foundData[exception_type] isEqualToString:@"1"]) {
                    if (![_foundData[service_id] isEqualToString:_identifier]) {
                        [self createCalendarRecord];
                        _identifier = _foundData[service_id];
                    }
                    NSArray *dateAndWeekday = [self dateAndWeekdayForIdentifier:_foundData[date_field]];
                    int weekday = [dateAndWeekday[1] intValue];
                    [_datesOnWeekday[weekday] addObject: dateAndWeekday[0]];
                }
                break;
            }

            case readTrips:
                if ([self shouldImportTrainType:_foundData[route_reference]]) {
                    ATLCalendarRule *calendarRule = _calendarRules[_foundData[service_reference]];
                    if ((self.options & includeCalendarExceptions) || calendarRule.weekdays) {
                        ATLMissionRule *missionRule = (ATLMissionRule*)[self.managedObjectContext createManagedObjectOfType:@"ATLMissionRule"];
                        missionRule.id_ = _foundData[trip_identifier];
                        missionRule.number = [_foundData[trip_short_name] intValue];
                        missionRule.upDirection = ([_foundData[direction_indicator] intValue] == 1);
                        missionRule.block = [_foundData[block_reference] intValue];
                        missionRule.headsign = _foundData[trip_headsign];
                        missionRule.trainType = _foundData[route_reference];
                        
                        missionRule.weekdays = calendarRule.weekdays;
                        missionRule.runningDates = calendarRule.runningDates;
                        missionRule.notRunningDates = calendarRule.notRunningDates;
                        NSString *seriesID = missionRule.seriesID;
                        ATLSeries *series = _seriesDict[seriesID];
                        if (!series) {
                            series = [self.managedObjectContext objectOfClass:[ATLSeries class] withModelID:seriesID create:YES];
                            _seriesDict[seriesID] = series;
                        }
                        missionRule.series = series;
                    }
                }
                break;

            case readStopTimes:
                if (![_foundData[trip_reference] isEqualToString:_identifier]) {
                    [self createTimePath];
                    _identifier = _foundData[trip_reference];
                    _missionRule = [self.managedObjectContext objectOfClass:[ATLMissionRule class] withModelID:_identifier create:NO];
                }
                if (_missionRule) {
                    ATLTimePoint *timePoint = [ATLTimePoint new];
                    timePoint.arrivalString = _foundData[arrival_time];
                    timePoint.departureString = _foundData[departure_time];
                    timePoint.stopLocation = _foundData[stop_reference];
                    timePoint.options = optionsFromStopHandling([_foundData[drop_off_type] intValue], [_foundData[pickup_type] intValue]);
                    [_timePoints addObject:timePoint];
                }
                break;

            default:
                break;
        }
    }
}

- (void)parserDidEndDocument:(CHCSVParser *)parser
{
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    if (error) {
        NSLog(@"error: %@", error);
    }
    switch (_importStep) {
        case readCalendar:
            [self createCalendarRecord];
            _identifier = nil;
            _datesOnWeekday = nil;
            break;
            
        case readTrips:
            NSLog(@"calendarRules has %lu elements", (unsigned long)[_calendarRules count]);
            _calendarRules = nil;
            NSLog(@"seriesDict has %lu elements", (unsigned long)[_seriesDict count]);
            _seriesDict = nil;
            break;
            
        case readStopTimes:
            [self createTimePath];
            NSLog(@"timePaths has %lu elements", (unsigned long)[_timePaths count]);
            _identifier = nil;
            _missionRule = nil;
            _timePoints = nil;
            break;
            
        default:
            break;
    }
    _foundData = nil;
}

@end

@implementation NSDate (ATLScheduleImportMethods)

- (int)weekdayIndex
{
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"nl_NL"];
        formatter.dateFormat = @"e";
    }
    return [[formatter stringFromDate:self] intValue] - 1;
}

@end

ATLTimePointOptions optionsFromStopHandling(GTFSStopHandling dropOffType, GTFSStopHandling pickUpType)
{
    ATLTimePointOptions canDropOff = pointOptionsNone;
    ATLTimePointOptions canPickUp = pointOptionsNone;
    ATLTimePointOptions coordinateDriver = pointOptionsNone;
    ATLTimePointOptions coordinateAgency = pointOptionsNone;
    switch (dropOffType) {
        case regularStopHandling:
            canDropOff = pointOptionsCanDropOff;
            break;
        case coordinateWithAgency:
            canDropOff = pointOptionsCanDropOff;
            coordinateAgency = pointOptionsCoordinateAgency;
            break;
        case coordinateWithDriver:
            canDropOff = pointOptionsCanDropOff;
            coordinateDriver = pointOptionsCoordinateDriver;
            break;
        default:
            break;
    }
    switch (pickUpType) {
        case regularStopHandling:
            canPickUp = pointOptionsCanPickUp;
            break;
        case coordinateWithAgency:
            canPickUp = pointOptionsCanPickUp;
            coordinateAgency = pointOptionsCoordinateAgency;
            break;
        case coordinateWithDriver:
            canPickUp = pointOptionsCanPickUp;
            coordinateDriver = pointOptionsCoordinateDriver;
            break;
        default:
            break;
    }
    return canDropOff | canPickUp | coordinateDriver | coordinateAgency;
}

