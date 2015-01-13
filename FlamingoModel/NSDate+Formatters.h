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
//  NSDate+NSDate_Formatters.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 01-08-14.
//

#import <Foundation/Foundation.h>

@interface NSDate (Formatters)

+ (NSCalendar*)nlCalendar;
+ (NSDate*)dateFromMachineString:(NSString*)string;

@property (nonatomic, readonly) NSString *nlTimeString;
@property (nonatomic, readonly) NSString *nlDateString;
@property (nonatomic, readonly) NSString *nlDateTimeString;
@property (nonatomic, readonly) NSString *eightDigitDateString;

@property (nonatomic, readonly) int inMinutes;
@property (nonatomic, readonly) int weekdayMask;
- (NSDate*)dateByReplacingTimeWith:(int)minutes;

@end
