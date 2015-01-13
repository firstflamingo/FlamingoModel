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
//  ATLMissionRule.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 24-06-14.
//

#import "ATLMissionRule.h"
#import "ATLSeries.h"
#import "ATLTimePath.h"


@implementation ATLMissionRule

@dynamic notRunningDates;
@dynamic runningDates;
@dynamic trainType;
@dynamic series;
@dynamic timePath;


- (NSString *)trajectoryString
{
    return [NSString stringWithFormat:@"%@-%@", self.timePath.originCode, self.timePath.destinationCode];
}


@end
