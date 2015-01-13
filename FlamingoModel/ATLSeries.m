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
//  ATLSeries.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 17-10-12.
//

#import "ATLSeries.h"

#import "ATLSeriesRef.h"
#import "ATLMissionRule.h"
#import "ATLTimePath.h"

@implementation ATLSeries

@dynamic seriesRefs;
@dynamic missionRules;

@synthesize upMissionRules = _upMissionRules;
@synthesize downMissionRules = _downMissionRules;

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %@, %d missionRules, %d linked services>",
            NSStringFromClass([self class]), self.id_, (int)[self.missionRules count], (int)[self.seriesRefs count]];
}

- (NSArray *)upMissionRules
{
    if (!_upMissionRules) {
        NSSet *filteredMissionRules = [self.missionRules filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"upDirection == YES"]];
        NSSortDescriptor *sortByNumber = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
        NSSortDescriptor *sortByWeekdays = [NSSortDescriptor sortDescriptorWithKey:@"weekdays" ascending:YES];
        _upMissionRules = [filteredMissionRules sortedArrayUsingDescriptors:@[sortByNumber, sortByWeekdays]];
    }
    return _upMissionRules;
}

- (NSArray *)downMissionRules
{
    if (!_downMissionRules) {
        NSSet *filteredMissionRules = [self.missionRules filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"upDirection == NO"]];
        NSSortDescriptor *sortByNumber = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
        NSSortDescriptor *sortByWeekdays = [NSSortDescriptor sortDescriptorWithKey:@"weekdays" ascending:YES];
        _downMissionRules = [filteredMissionRules sortedArrayUsingDescriptors:@[sortByNumber, sortByWeekdays]];
    }
    return _downMissionRules;
}

- (void)syncOffsets
{
    NSLog(@"sync offsets for series %@", self.id_);
    [self syncOffsetsForMissionRules:self.upMissionRules];
    [self syncOffsetsForMissionRules:self.downMissionRules];
}

- (void)syncOffsetsForMissionRules:(NSArray *)missionRules
{
    int lowestConstant = 30000;
    for (ATLMissionRule *missionRule in missionRules) {
        int constant =  missionRule.offset - (15 * missionRule.ordinal);
        if (constant < lowestConstant) {
            lowestConstant = constant;
        }
    }
    for (ATLMissionRule *missionRule in missionRules) {
        int correction = missionRule.offset - (15 * missionRule.ordinal) - lowestConstant;
        [missionRule.timePath correctOffsetWith:-correction];
    }
}

#pragma mark - XML representation

- (NSString*)xmlString
{
    NSString *name = [[NSStringFromClass([self class]) substringFromIndex:3] lowercaseString];
    NSMutableString *theString = [[NSMutableString alloc] initWithCapacity:50];
    [theString appendFormat:@"<%@", name];
    [self appendAttributesToXMLString:theString];
    [theString appendString:@">\n"];
    [self appendDataToXMLString:theString];
    [theString appendFormat:@"</%@>\n", name];
    return theString;
}

- (NSString *)xmlReferenceString
{
    return [NSString stringWithFormat:@"<%@ id=\"%@\"/>\n",
            NSStringFromClass([self class]), self.id_];
}

- (void)appendAttributesToXMLString:(NSMutableString*)output
{
    [output appendFormat:@" id=\"%@\"", self.id_];
}

- (void)appendDataToXMLString:(NSMutableString *)output
{
    [output appendFormat:@"\t<serviceRefs>\n"];
    for (ATLSeriesRef *ref in self.seriesRefs) {
        [output appendString:ref.xmlServiceRef];
    }
    [output appendFormat:@"\t</serviceRefs>\n"];
}

@end
