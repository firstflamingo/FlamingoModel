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
//  ATLTimePoint.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 23-06-14.
//

#import <Foundation/Foundation.h>

typedef int16_t ATLMinutes;

ATLMinutes minutesFromString(NSString *string);
NSString *stringFromMinutes(ATLMinutes minutes);

typedef NS_OPTIONS(uint16_t, ATLTimePointOptions) {
    pointOptionsNone = 0,
    pointOptionsCanDropOff = 1 << 0,
    pointOptionsCanPickUp = 1 << 1,
    pointOptionsCoordinateDriver = 1 << 2,
    pointOptionsCoordinateAgency = 1 << 3,
    pointOptionsChangeDirection = 1 << 4
};

@interface ATLTimePoint : NSObject <NSCoding>

// Object lifecycle
- (instancetype)initWithArrival:(ATLMinutes)arrival
                      departure:(ATLMinutes)departure
                      stationID:(NSString*)stationID
                       platform:(NSString*)platform
                        options:(ATLTimePointOptions)options;

// Time properties
@property (nonatomic, assign) ATLMinutes arrival;
@property (nonatomic, assign) ATLMinutes departure;
@property (nonatomic, strong) NSString *arrivalString;
@property (nonatomic, strong) NSString *departureString;

// Location properties
@property (nonatomic, strong) NSString *stationID;
@property (nonatomic, strong) NSString *platform;
@property (nonatomic) NSString *stationCode;
@property (nonatomic) NSString *stopLocation;

// Options
@property (nonatomic, assign) ATLTimePointOptions options;
@property (nonatomic, assign) BOOL canDropOff;
@property (nonatomic, assign) BOOL canPickUp;
@property (nonatomic, assign) BOOL changeDirection;

// Reading methods
- (void)fillWithDictionary:(NSDictionary *)dictionary;

// Writing methods
@property (nonatomic, readonly) NSString *xmlAttributes;
@property (nonatomic, readonly) NSDictionary *contentDictionary;

// Comparison
- (uint32_t)hash_;
- (BOOL)isEqualToPoint:(ATLTimePoint *)point;

@end
