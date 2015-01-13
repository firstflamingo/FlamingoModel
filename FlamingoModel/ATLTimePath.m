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
//  ATLTimePath.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 26-06-14.
//

#import "ATLTimePath.h"
#import "ATLMissionRule.h"
#import "ATLTimePoint.h"

@implementation ATLTimePath {
    NSArray *_timePoints;
}

@dynamic hash_;
@dynamic timePointsData;
@dynamic missionRules;

- (NSString *)description
{
    NSString *pathDescription = [NSString stringWithFormat:@"<%@ %u, %lu missionRules, %lu timePoints>",
            NSStringFromClass([self class]), self.hash_, (unsigned long)[self.missionRules count], (unsigned long)[self.timePoints count]];
    NSMutableString *string = [NSMutableString stringWithString:pathDescription];
    for (ATLTimePoint *point in self.timePoints) {
        [string appendFormat:@"\n\t\t%@", point];
    }
    return string;
}

- (NSArray *)timePoints
{
    if (!_timePoints) {
        NSData *data = self.timePointsData;
        if (data != nil) {
            _timePoints = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
    }
    return _timePoints;
}

- (ATLTimePoint *)firstPoint
{
    return [self.timePoints firstObject];
}

- (ATLTimePoint *)lastPoint
{
    return [self.timePoints lastObject];
}

- (NSString *)originCode
{
    return self.firstPoint.stationCode;
}

- (NSString *)destinationCode
{
    return self.lastPoint.stationCode;
}

+ (ATLMinutes)normalizePointsArray:(NSArray *)array
{
    ATLTimePoint *firstPoint = array[0];
    ATLMinutes departureMinute = firstPoint.departure % 30;
    while (departureMinute < 0) {
        departureMinute += 30;
    }
    ATLMinutes difference = firstPoint.departure - departureMinute;
    if (difference != 0) {
        for (ATLTimePoint *point in array) {
            point.arrival -= difference;
            point.departure -= difference;
        }
    }
    return difference;
}

+ (uint32_t)hashForPointsArray:(NSArray *)array
{
    // Based upon standard hash algorithm ~ http://stackoverflow.com/a/4393493/337735
    uint32_t result = 1;
    uint32_t prime = 31;
    for (ATLTimePoint *point in array) {
        result = prime * result + point.hash_;
    }
    return result;
}

- (void)correctOffsetWith:(int)correction
{
    for (ATLMissionRule *missionRule in self.missionRules) {
        missionRule.offset += correction;
    }
    for (ATLTimePoint *timePoint in self.timePoints) {
        timePoint.arrival -= correction;
        timePoint.departure -= correction;
    }
    self.timePointsData = [NSKeyedArchiver archivedDataWithRootObject:self.timePoints];
}

- (BOOL)callsAtStationWithID:(NSString *)stationID
{
    for (ATLTimePoint *point in self.timePoints) {
        if ([point.stationID isEqualToString:stationID]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray *)stationIDsFromID:(NSString *)firstID toID:(NSString *)lastID
{
    BOOL flag = NO;
    NSMutableArray *stationIDs = [NSMutableArray arrayWithCapacity:30];
    for (ATLTimePoint *point in self.timePoints) {
        if (flag) {
            [stationIDs addObject:point.stationID];
            if ([point.stationID isEqualToString:lastID]) {
                break;
            }
        } else {
            if ([point.stationID isEqualToString:firstID]) {
                [stationIDs addObject:point.stationID];
                flag = YES;
            }
        }
    }
    return stationIDs;
}

@end
