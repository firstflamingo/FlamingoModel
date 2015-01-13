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
//  ATLMissionRule.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 24-06-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLRule.h"

@class ATLSeries, ATLTimePath;

@interface ATLMissionRule : ATLRule

@property (nonatomic, retain) id notRunningDates;
@property (nonatomic, retain) id runningDates;
@property (nonatomic, retain) NSString * trainType;
@property (nonatomic, retain) ATLSeries *series;
@property (nonatomic, retain) ATLTimePath *timePath;

@property (nonatomic, readonly) NSString *trajectoryString;

@end
