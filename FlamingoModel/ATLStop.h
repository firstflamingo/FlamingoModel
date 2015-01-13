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
//  ATLStop.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 08-08-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ATLMission, ATLStation, ATLServicePoint;

@interface ATLStop : NSManagedObject

@property (nonatomic, retain) NSDate * plannedArrival;
@property (nonatomic, retain) NSDate * plannedDeparture;
@property (nonatomic, retain) NSDate * estimatedArrival;
@property (nonatomic, retain) NSDate * estimatedDeparture;
@property (nonatomic, retain) NSString * platform;
@property (nonatomic, retain) NSNumber * platformChange;
@property (nonatomic, retain) NSString * destination;
@property (nonatomic, retain) NSString * alteredDestination;
@property (nonatomic) int16_t statusInt;
@property (nonatomic, retain) ATLMission *mission;
@property (nonatomic, retain) ATLStation *station;

@property (nonatomic, assign) float delay;
@property (nonatomic, assign) float delayAtArrival;
@property (nonatomic, assign) float delayAtDeparture;

@property (nonatomic, readonly) NSString *arrivalString;
@property (nonatomic, readonly) NSString *departureString;
@property (nonatomic, readonly) NSString *stationName;

@end
