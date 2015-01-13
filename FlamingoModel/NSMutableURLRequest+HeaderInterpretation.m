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
//  NSMutableURLRequest+HeaderInterpretation.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 07-05-14.
//

#import "NSMutableURLRequest+HeaderInterpretation.h"

NSString *stringForDataType(FFEDataType type);
NSString *stringForDataTypes(NSArray* dataTypes);

@implementation NSMutableURLRequest (HeaderInterpretation)

- (void)setContentType:(FFEDataType)type
{
    [self setValue:stringForDataType(type) forHTTPHeaderField:@"Content-Type"];
}

- (void)setAccept:(NSArray *)types
{
    [self setValue:stringForDataTypes(types) forHTTPHeaderField:@"Accept"];
}

- (void)setIfModifiedSince:(NSDate *)dateValue
{
    [self setValue:[self rfc1123StringFromDate:dateValue] forHTTPHeaderField:@"If-Modified-Since"];
}

- (void)setIfUnmodifiedSince:(NSDate *)dateValue
{
    [self setValue:[self rfc1123StringFromDate:dateValue] forHTTPHeaderField:@"If-Unmodified-Since"];
}

- (NSString*)rfc1123StringFromDate:(NSDate*)date
{
    static NSDateFormatter *df = nil;
    if(df == nil) {
        df = [[NSDateFormatter alloc] init];
        df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
    }
    return [df stringFromDate:date];
}

@end

NSString *stringForDataType(FFEDataType type)
{
    switch (type) {
        case DataTypeXML:
            return @"application/xml";
            
        case DataTypeJSON:
            return @"application/json";
            
        default:
            return @"";
    }
}

NSString *stringForDataTypes(NSArray* dataTypes)
{
    NSMutableArray *stringTypes = [NSMutableArray arrayWithCapacity:[dataTypes count]];
    for (NSNumber *dataType in dataTypes) {
        FFEDataType type = [dataType intValue];
        [stringTypes addObject:stringForDataType(type)];
    }
    return [stringTypes componentsJoinedByString:@", "];
}

