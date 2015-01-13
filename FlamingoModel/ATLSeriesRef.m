//  Copyright (c) 2012-2015 First Flamingo Enterprise B.V.
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
//  ATLSeriesRef.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 17-10-12.
//

#import "ATLSeriesRef.h"
#import "ATLSeries.h"
#import "ATLService.h"

@implementation ATLSeriesRef

@dynamic upCorrection;
@dynamic downCorrection;
@dynamic sameDirection;
@dynamic series;
@dynamic service;


#pragma mark - Translating indexes

- (ATLService *)previousService
{
    return nil;
}

- (ATLService *)nextService
{
    return nil;
}

#pragma mark - XML representation

- (NSArray *)refArray
{
    return @[self.series.id_, @(self.sameDirection)];
}

- (NSString *)xmlSeriesRef
{
    return [NSString stringWithFormat:@"\t\t<ref series=\"%@\" same=\"%d\" up=\"%d\" down=\"%d\"/>\n",
            self.series.id_, self.sameDirection, self.upCorrection, self.downCorrection];
}

- (NSString *)xmlServiceRef
{
    return [NSString stringWithFormat:@"\t\t<ref service=\"%@\" same=\"%d\" up=\"%d\" down=\"%d\"/>\n",
            self.service.id_, self.sameDirection, self.upCorrection, self.downCorrection];
}

@end
