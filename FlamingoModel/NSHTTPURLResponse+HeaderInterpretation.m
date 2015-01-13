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
//  NSHTTPURLResponse+HeaderInterpretation.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 21-04-14.
//

#import "NSHTTPURLResponse+HeaderInterpretation.h"

@implementation NSHTTPURLResponse (HeaderInterpretation)

- (FFEDataType)dataType
{
    NSString *value = [self allHeaderFields][@"Content-Type"];
    if (value) {
        NSArray *comps = [value componentsSeparatedByString:@";"];
        NSArray *subComps = [comps[0] componentsSeparatedByString:@"/"];
        if ([subComps[0] isEqualToString:@"application"] && [subComps count] >= 2) {
            if ([subComps[1] isEqualToString:@"xml"]) {
                return DataTypeXML;
            } else if ([subComps[1] isEqualToString:@"json"]) {
                return DataTypeJSON;
            }
        }
    }
    return DataTypeUnknown;
}

- (NSDate *)date
{
    NSString *string = [self allHeaderFields][@"Date"];
    if (string) {
        return [self dateFromRFC1123String:string];
    }
    return nil;
}

- (NSDate *)lastModified
{
    NSString *string = [self allHeaderFields][@"Last-Modified"];
    if (string) {
        return [self dateFromRFC1123String:string];
    }
    return nil;
}

- (NSDate*)dateFromRFC1123String:(NSString*)string
{
    if(string == nil)
        return nil;
    
    static NSDateFormatter *rfc1123 = nil;
    if(rfc1123 == nil) {
        rfc1123 = [[NSDateFormatter alloc] init];
        rfc1123.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        rfc1123.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        rfc1123.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss z";
    }
    return [rfc1123 dateFromString:string];
}

@end
