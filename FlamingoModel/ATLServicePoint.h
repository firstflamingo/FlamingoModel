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
//  ATLServicePoint.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 08-08-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLTimePoint.h"

@class ATLLocation, ATLService, ATLServiceRule;

@interface ATLServicePoint : NSManagedObject

@property (nonatomic) float km;
@property (nonatomic) ATLMinutes upArrival;
@property (nonatomic) ATLMinutes upDeparture;
@property (nonatomic, retain) NSString * upPlatform;
@property (nonatomic) ATLMinutes downArrival;
@property (nonatomic) ATLMinutes downDeparture;
@property (nonatomic, retain) NSString * downPlatform;
@property (nonatomic) int16_t options;
@property (nonatomic, retain) NSSet *destinationRules;
@property (nonatomic, retain) ATLLocation *location;
@property (nonatomic, retain) NSSet *noStopRules;
@property (nonatomic, retain) NSSet *originRules;
@property (nonatomic, retain) ATLService *service;

- (void)setUpArrival:(ATLMinutes)arrival departure:(ATLMinutes)departure;
- (void)setDownArrival:(ATLMinutes)arrival departure:(ATLMinutes)departure;
- (void)clearSchedule;

@property (nonatomic, readonly) NSString *locationCode;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) BOOL referesToStation;
@property (nonatomic, readonly) BOOL infraDirection;
@property (nonatomic, readonly) NSString *xmlString, *xmlItemReference, *xmlUpSchedule, *xmlDownSchedule;
- (void)appendDataToXMLString:(NSMutableString*)output;

@end

@interface ATLServicePoint (CoreDataGeneratedAccessors)

- (NSString *)upDescription;
- (NSString *)downDescription;

- (void)addDestinationRulesObject:(ATLServiceRule *)value;
- (void)removeDestinationRulesObject:(ATLServiceRule *)value;
- (void)addDestinationRules:(NSSet *)values;
- (void)removeDestinationRules:(NSSet *)values;

- (void)addNoStopRulesObject:(ATLServiceRule *)value;
- (void)removeNoStopRulesObject:(ATLServiceRule *)value;
- (void)addNoStopRules:(NSSet *)values;
- (void)removeNoStopRules:(NSSet *)values;

- (void)addOriginRulesObject:(ATLServiceRule *)value;
- (void)removeOriginRulesObject:(ATLServiceRule *)value;
- (void)addOriginRules:(NSSet *)values;
- (void)removeOriginRules:(NSSet *)values;

@end
