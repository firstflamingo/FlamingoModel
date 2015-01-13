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
//  ATLScheduleImporter.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 24-06-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_OPTIONS(uint16_t, ATLScheduleImportOptions) {
    noImportOptions = 0,
    includeCalendarExceptions = 1 << 0
};

typedef NS_ENUM(uint16_t, ATLScheduleImportStep) {
    readInfo,
    readCalendar,
    readTrips,
    readStopTimes,
    nrOfImportSteps
};

@interface ATLScheduleImporter : NSObject


#pragma mark - External interface

/**
 Instructs schedule importer to execute the import
 @param directory The directory where the GTFS files to be imported, are located
 @param managedObjectContext The managedObjectContext which is destination for the import
 @param options The options for the import
 */
- (void)importContentsOfDirectory:(NSURL*)directory
         intoManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                      withOptions:(ATLScheduleImportOptions)options;


#pragma mark - Testing interface

@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) ATLScheduleImportOptions options;

- (void)importContentsOfURL:(NSURL*)url forStep:(ATLScheduleImportStep)step;

@property (nonatomic, readonly) NSDictionary *calendarRules;
@property (nonatomic, readonly) NSArray *timePaths;

- (BOOL)shouldImportTrainType:(NSString*)trainType;
- (NSDate *)dateForIdentifier:(NSString *)identifier;
- (NSSet *)allDatesOnWeekday:(int)weekdayIndex;

@end

@interface NSDate (ATLScheduleImportMethods)

- (int)weekdayIndex;

@end