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
//  NSDate+NSDate_Formatters.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 01-08-14.
//

#import "NSDate+Formatters.h"

@implementation NSDate (Formatters)

+ (NSCalendar *)nlCalendar
{
    static NSCalendar *calendar = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"nl_NL"];
        [calendar setLocale:locale];
        [calendar setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Amsterdam"]];
    });
    return calendar;
}

+ (NSDate *)dateFromMachineString:(NSString *)string
{
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss X"];
    });
    return [_dateFormatter dateFromString:string];
}

- (NSString *)nlTimeString
{
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"nl_NL"];
        [_dateFormatter setLocale:locale];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Amsterdam"]];
        [_dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    });
    return [_dateFormatter stringFromDate:self];
}

- (NSString *)nlDateString
{
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"nl_NL"];
        [_dateFormatter setLocale:locale];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Amsterdam"]];
        [_dateFormatter setDateStyle:NSDateFormatterLongStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    });
    return [_dateFormatter stringFromDate:self];
}

- (NSString *)nlDateTimeString
{
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"nl_NL"];
        [_dateFormatter setLocale:locale];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Amsterdam"]];
        [_dateFormatter setDateStyle:NSDateFormatterLongStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    });
    return [_dateFormatter stringFromDate:self];
}

- (NSString *)eightDigitDateString
{
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"nl_NL"];
        [_dateFormatter setLocale:locale];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Amsterdam"]];
        [_dateFormatter setDateFormat:@"yyyyMMdd"];
    });
    return [_dateFormatter stringFromDate:self];
}

- (int)inMinutes
{
    unsigned units = NSCalendarUnitHour | NSCalendarUnitMinute;
    NSDateComponents *dateComponents = [[NSDate nlCalendar] components:units fromDate:self];
    return 60 * (int)dateComponents.hour + (int)dateComponents.minute;
}

- (int)weekdayMask
{
    unsigned units = NSCalendarUnitWeekday;
    NSDateComponents *dateComponents = [[NSDate nlCalendar] components:units fromDate:self];
    return 1 << ((int)dateComponents.weekday + 5) % 7;
}

- (NSDate *)dateByReplacingTimeWith:(int)minutes
{
    unsigned units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *dateComponents = [[NSDate nlCalendar] components:units fromDate:self];
    dateComponents.minute = minutes;
    return [[NSDate nlCalendar] dateFromComponents:dateComponents];
}

@end
