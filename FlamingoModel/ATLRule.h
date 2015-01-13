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
//  ATLRule.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 24-06-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLEntry.h"

typedef NS_OPTIONS(uint16_t, ATLWeekdays) {
    noRegularWeekday = 0,
    runsOnMonday = 1 << 0,
    runsOnTuesday = 1 << 1,
    runsOnWednesday = 1 << 2,
    runsOnThursday = 1 << 3,
    runsOnFriday = 1 << 4,
    runsOnSaturday = 1 << 5,
    runsOnSunday = 1 << 6
};

@interface ATLRule : ATLEntry

@property (nonatomic) int32_t block;
@property (nonatomic, retain) NSString * headsign;
@property (nonatomic) int32_t number;
@property (nonatomic) int16_t offset;
@property (nonatomic) BOOL upDirection;
@property (nonatomic) ATLWeekdays weekdays;

// Deduced properties
@property (nonatomic, readonly) int baseNumber;
@property (nonatomic, readonly) int ordinal;
@property (nonatomic, readonly) NSString *seriesID;
@property (nonatomic, readonly) NSUInteger occurrences;
@property (nonatomic, readonly) NSString *offsetString;
@property (nonatomic, readonly) NSString *weekdaysString;

+ (NSArray*)arrangeRules:(NSSet*)rules inUpDirection:(BOOL)upDirection;

@end

int numberOfSetBits(int i);
NSString* stringFromWeekdays(ATLWeekdays weekdays);
