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
//  ATLRule.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 24-06-14.
//

#import "ATLRule.h"
#import "ATLTimePoint.h"

@implementation ATLRule

@dynamic block;
@dynamic headsign;
@dynamic number;
@dynamic offset;
@dynamic upDirection;
@dynamic weekdays;


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %d to %@, offset: %@, runs on %@>",
            NSStringFromClass([self class]), self.number, self.headsign, self.offsetString, self.weekdaysString];
}

- (NSString *)offsetString
{
    return stringFromMinutes(self.offset);
}

- (NSString *)weekdaysString
{
    return stringFromWeekdays(self.weekdays);
}

- (int)baseNumber
{
    return self.number % 100000;
}

- (int)ordinal
{
    return self.number % 100;
}

- (NSString *)seriesID
{
    NSString *country;
    int seriesNumber;
    if (self.baseNumber < 500) {
        country = @"eu";
        seriesNumber = self.baseNumber / 10;
    } else {
        country = @"nl";
        seriesNumber = self.baseNumber / 100;
    }
    return [NSString stringWithFormat:@"%@.%03d", country, seriesNumber];
}

- (NSUInteger)occurrences
{
    return numberOfSetBits(self.weekdays);
}

+ (NSArray *)arrangeRules:(NSSet *)rules inUpDirection:(BOOL)upDirection
{
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"upDirection == %@", @(upDirection)];
    NSSet *filteredRules = [rules filteredSetUsingPredicate:filter];
    NSSortDescriptor *sortOffset = [NSSortDescriptor sortDescriptorWithKey:@"offset" ascending:YES];
    NSSortDescriptor *sortWeekdays = [NSSortDescriptor sortDescriptorWithKey:@"weekdays" ascending:YES];
    return [filteredRules sortedArrayUsingDescriptors:@[sortOffset, sortWeekdays]];
}

#pragma mark - Reading methods

- (void)fillWithDictionary:(NSDictionary *)dictionary
{
    self.id_ = dictionary[@"id"];
    self.number = [dictionary[@"nr"] intValue];
    self.block = [dictionary[@"b"] intValue];
    self.offset = minutesFromString(dictionary[@"o"]);
    self.upDirection = [dictionary[@"d"] isEqualToString:@"up"];
    self.weekdays = [dictionary[@"w"] intValue];
    self.headsign = dictionary[@"headsign"];
}

#pragma mark - Writing methods

- (void)appendAttributesToXMLString:(NSMutableString *)output
{
    [super appendAttributesToXMLString:output];
    NSString *direction = self.upDirection ? @"up" : @"down";
    [output appendFormat:@" nr=\"%d\" b=\"%d\" o=\"%@\" d=\"%@\" w=\"%d\" headsign=\"%@\"",
     self.number, self.block, self.offsetString, direction, self.weekdays, self.headsign];
}

@end


int numberOfSetBits(int i)
{
    i = i - ((i >> 1) & 0x55555555);
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
    return (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
}

NSString* stringFromWeekdays(ATLWeekdays weekdays)
{
    NSMutableString *string = [NSMutableString stringWithCapacity:7];
    if (weekdays & runsOnMonday) {
        [string appendString:@"M"];
    } else {
        [string appendString:@"_"];
    }
    if (weekdays & runsOnTuesday) {
        [string appendString:@"D"];
    } else {
        [string appendString:@"_"];
    }
    if (weekdays & runsOnWednesday) {
        [string appendString:@"W"];
    } else {
        [string appendString:@"_"];
    }
    if (weekdays & runsOnThursday) {
        [string appendString:@"D"];
    } else {
        [string appendString:@"_"];
    }
    if (weekdays & runsOnFriday) {
        [string appendString:@"V"];
    } else {
        [string appendString:@"_"];
    }
    if (weekdays & runsOnSaturday) {
        [string appendString:@"Z"];
    } else {
        [string appendString:@"_"];
    }
    if (weekdays & runsOnSunday) {
        [string appendString:@"Z"];
    } else {
        [string appendString:@"_"];
    }
    return string;
}
