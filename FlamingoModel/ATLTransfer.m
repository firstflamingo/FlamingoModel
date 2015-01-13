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
//  ATLTransfer.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 31-07-14.
//

#import "ATLTransfer.h"
#import "ATLStation.h"
#import "ATLTrajectory.h"
#import "ATLMission.h"
#import "ATLJourney.h"

#import "NSManagedObjectContext+FFEUtilities.h"
#import "NSDate+Formatters.h"

typedef NS_OPTIONS(uint16_t, transferDisplayOptions) {
    displayTimePicker = 1 << 0,
};

@implementation ATLTransfer {
    transferDisplayOptions _displayOptions;
}

@dynamic station;

- (NSString *)description
{
    return [NSString stringWithFormat:@"<ATLTransfer %@ A:%@ V:%@>", self.station.id_, self.timeOfArrival.nlTimeString, self.timeOfDeparture.nlTimeString];
}

- (NSString *)displayName
{
    return self.station.displayName;
}

- (ATLMission *)fromMission
{
    if ([self.arrival isKindOfClass:[ATLTrajectory class]]) {
        return [(ATLTrajectory*)self.arrival selectedMission];
    }
    return nil;
}

- (ATLMission *)toMission
{
    if ([self.departure isKindOfClass:[ATLTrajectory class]]) {
        return [(ATLTrajectory*)self.departure selectedMission];
    }
    return nil;
}

- (void)setToMission:(ATLMission *)toMission
{
    ATLTrajectory *departure = (ATLTrajectory*)self.departure;
    if ( !([departure isKindOfClass:[ATLTrajectory class]] && departure.selectedMission == toMission) ) {
        departure = (ATLTrajectory*)[self.managedObjectContext createManagedObjectOfType:@"ATLTrajectory"];
        [self.journey addTravelSection:departure atIndex:self.order / 2];
        departure.mission = toMission;
        departure.showIntermediateStops = YES;
    }
}

- (BOOL)changeTrains
{
    return ![self.fromMission sameTrainAsMission:self.toMission];
}

#pragma mark - Display options

- (BOOL)showTimePicker
{
    return _displayOptions & displayTimePicker;
}

- (void)setShowTimePicker:(BOOL)showTimePicker
{
    if (showTimePicker) {
        _displayOptions |= displayTimePicker;
    } else {
        _displayOptions &= ~displayTimePicker;
    }
}

- (void)toggleTimePicker
{
    self.showTimePicker = !self.showTimePicker;
}

@end
