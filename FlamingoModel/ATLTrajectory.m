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
//  ATLTrajectory.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 01-08-14.
//

#import "ATLTrajectory.h"
#import "ATLMission.h"
#import "ATLService.h"
#import "ATLServiceRule.h"
#import "ATLVisit.h"
#import "ATLTransfer.h"
#import "ATLStation.h"
#import "ATLStop.h"
#import "ATLJourney.h"

#import "NSManagedObjectContext+FFEUtilities.h"
#import "NSDate+Formatters.h"

#define SEARCH_INTERVAL_BEFORE  3600.0
#define SEARCH_INTERVAL_AFTER   7200.0

typedef NS_OPTIONS(uint16_t, trajectoryDisplayOptions) {
    displayIntermediateStops = 1 << 0,
    displayAlternatives = 1 << 2
};

@implementation ATLTrajectory {
    NSUInteger _selectedWrapperIndex;
    trajectoryDisplayOptions _displayOptions;
}

@dynamic missions;
@dynamic selectedMission;

@synthesize arrangedMissionWrappers = _arrangedMissionWrappers;

- (NSString *)description
{
    NSMutableString *infoString = [NSMutableString string];
    switch ([self.availableServices count]) {
        case 0:
            break;
        case 1:
            [infoString appendString:@" service:"];
            break;
        default:
            [infoString appendString:@" services:"];
            break;
    }
    for (ATLService *service in self.availableServices) {
        [infoString appendFormat:@" %@", service.shortName];
    }
    NSMutableString *wrapperString = [NSMutableString string];
    if (_arrangedMissionWrappers) {
        [wrapperString appendString:@" wrappers:\n"];
        for (ATLMissionWrapper *wrapper in (_arrangedMissionWrappers)) {
            if (wrapper.mission == self.selectedMission) {
                [wrapperString appendString:@" ** selected ** "];
            }
            [wrapperString appendFormat:@"%@\n", wrapper];
        }
    }
    return [NSString stringWithFormat:@"<ATLTrajectory%@>%@", infoString, wrapperString];
}

- (BOOL)isDummyElement
{
    return NO;
}

#pragma mark - Managing the trajectory

- (ATLStation *)originStation
{
    if ([self.origin isKindOfClass:[ATLTransfer class]]) {
        return [(ATLTransfer*)self.origin station];
    }
    return nil;
}

- (NSDate *)estimatedDeparture
{
    return self.origin.timeOfDeparture;
}

- (ATLStation *)destinationStation
{
    if ([self.destination isKindOfClass:[ATLTransfer class]]) {
        return [(ATLTransfer*)self.destination station];
    }
    return nil;
}

- (void)setDestinationStation:(ATLStation *)destinationStation
{
    ATLTransfer *destination = (ATLTransfer*)self.destination;
    if ( !([destination isKindOfClass:[ATLTransfer class]] && destination.station == destinationStation) ) {
        
        ATLMission *mission = self.selectedMission;
        NSUInteger currentIndex = self.order / 2;
        NSMutableArray *trajectories = [NSMutableArray arrayWithObject:self];
        for (ATLStation *borderStation in [self.selectedMission borderStationsBetweenStart:self.originStation andEnd:destinationStation]) {
            currentIndex++;
            ATLTransfer *border = (ATLTransfer*)[self.managedObjectContext createManagedObjectOfType:@"ATLTransfer"];
            border.station = borderStation;
            [self.journey addVisit:border atIndex:currentIndex];

            ATLTrajectory *nextTrajectory = (ATLTrajectory*)[self.managedObjectContext createManagedObjectOfType:@"ATLTrajectory"];
            [self.journey addTravelSection:nextTrajectory atIndex:currentIndex];
            nextTrajectory.mission = mission;
            [trajectories addObject:nextTrajectory];
        }
        
        currentIndex++;
        destination = (ATLTransfer*)[self.managedObjectContext createManagedObjectOfType:@"ATLTransfer"];
        destination.station = destinationStation;
        [self.journey addVisit:destination atIndex:currentIndex];
        
        for (ATLTrajectory *trajectory in trajectories) {
            [trajectory searchMissionsForeward:YES];
            [trajectory selectMission:mission];
            trajectory.showAlternatives = YES;
            trajectory.showIntermediateStops = NO;
        }
    }
}

- (NSDate *)estimatedArrival
{
    return self.destination.timeOfArrival;
}

- (NSSet *)availableServices
{
    NSMutableSet *services = [self.originStation.services mutableCopy];
    [services intersectSet:self.destinationStation.services];
    return services;
}

- (float)peakFrequency
{
    float frequency = 0.0;
    for (ATLService *service in self.availableServices) {
        frequency += service.peakFrequency;
    }
    return frequency;
}

- (float)baseFrequency
{
    float frequency = 0.0;
    for (ATLService *service in self.availableServices) {
        frequency += service.baseFrequency;
    }
    return frequency;
}

- (float)offPeakFrequency
{
    float frequency = 0.0;
    for (ATLService *service in self.availableServices) {
        frequency += service.offPeakFrequency;
    }
    return frequency;
}

#pragma mark - Managing missions

- (NSArray *)arrangedMissionWrappers
{
    if (!_arrangedMissionWrappers) {
        NSMutableSet *wrappers = [NSMutableSet set];
        for (ATLMission *mission in self.missions) {
            ATLMissionWrapper *wrapper = [self wrapMission:mission];
            if (wrapper) {
                [wrappers addObject:wrapper];
            }
        }
        NSSortDescriptor *sortDeparture = [NSSortDescriptor sortDescriptorWithKey:@"plannedDeparture" ascending:YES];
        NSArray *sortedWrappers = [wrappers sortedArrayUsingDescriptors:@[sortDeparture]];
        NSMutableArray *checkedWrappers = [NSMutableArray arrayWithCapacity:[sortedWrappers count]];
        for (NSUInteger i = 0; i < [sortedWrappers count]; i++) {
            ATLMissionWrapper *wrapper = sortedWrappers[i];
            if (i < [sortedWrappers count] - 1) {
                ATLMissionWrapper *nextWrapper = sortedWrappers[i + 1];
                if ([nextWrapper.plannedArrival compare:wrapper.plannedArrival] == NSOrderedAscending) {
                    [self removeMissionsObject:wrapper.mission];
                    continue;
                }
            }
            [checkedWrappers addObject:wrapper];
            if (wrapper.mission == self.selectedMission) {
                _selectedWrapperIndex = [checkedWrappers count] - 1;
            }
        }
        self.arrangedMissionWrappers = checkedWrappers;
    }
    return _arrangedMissionWrappers;
}

- (void)searchMissionsForeward:(BOOL)forewardDirection
{
    [self removeMissions:self.missions];
    self.arrangedMissionWrappers = nil;
    NSDate *startTime, *endTime;
    if (forewardDirection) {
        startTime = [self.timeOfDeparture dateByAddingTimeInterval:-SEARCH_INTERVAL_BEFORE];
        endTime = [self.timeOfDeparture dateByAddingTimeInterval:SEARCH_INTERVAL_AFTER];
    } else {
        startTime = [self.timeOfArrival dateByAddingTimeInterval:-SEARCH_INTERVAL_BEFORE];
        endTime = [self.timeOfArrival dateByAddingTimeInterval:SEARCH_INTERVAL_AFTER];
    }
    
    for (ATLService *service in self.availableServices) {
        NSSet *missions = [service missionsFromStation:self.originStation
                                             toStation:self.destinationStation
                                             startTime:startTime
                                               endTime:endTime
                                          useDeparture:forewardDirection];
        [self addMissions:missions];
    }
}

- (void)selectMission:(ATLMission*)mission
{
    for (NSInteger i = 0; i < [self.arrangedMissionWrappers count]; i++) {
        ATLMissionWrapper *wrapper = self.arrangedMissionWrappers[i];
        if (wrapper.mission == mission) {
            [self selectWrapperAtIndex:i];
            break;
        }
    }
}

- (void)selectMissionForeward:(BOOL)forewardDirection
{
    if (forewardDirection) {
        for (NSInteger i = 0; i < [self.arrangedMissionWrappers count]; i++) {
            ATLMissionWrapper *wrapper = self.arrangedMissionWrappers[i];
            if ([self.timeOfDeparture compare:wrapper.estimatedDeparture] == NSOrderedAscending) {
                [self selectWrapperAtIndex:i];
                break;
            }
        }
    } else {
        for (NSInteger i = [self.arrangedMissionWrappers count] - 1; i >= 0; i--) {
            ATLMissionWrapper *wrapper = self.arrangedMissionWrappers[i];
            if ([self.timeOfArrival compare:wrapper.estimatedArrival] == NSOrderedDescending) {
                [self selectWrapperAtIndex:i];
                break;
            }
        }
    }
}

- (void)selectMissionAtRelativeIndex:(NSInteger)i
{
    [self selectWrapperAtIndex:_selectedWrapperIndex + i];
}

- (void)selectWrapperAtIndex:(NSInteger)i
{
    if (i >= 0 && i < [self.arrangedMissionWrappers count]) {
        _selectedWrapperIndex = i;
        ATLMissionWrapper *wrapper = self.arrangedMissionWrappers[i];
        self.selectedMission = wrapper.mission;
        self.timeOfDeparture = wrapper.estimatedDeparture;
        self.timeOfArrival = wrapper.estimatedArrival;
    }
}

- (void)recalculateTimesForeward:(BOOL)forewardDirection
{
    [self searchMissionsForeward:forewardDirection];
    [self selectMissionForeward:forewardDirection];
    [super recalculateTimesForeward:forewardDirection];
}

- (ATLStop *)stopAtIndex:(NSUInteger)i
{
    return [self.selectedMissionWrapper stopAtIndex:i];
}

#pragma mark -  Map Overlays

- (NSArray*)routeOverlays
{
    if (self.selectedMissionWrapper) {
        ATLStation *destination = self.destinationStation;
        
        if (destination) {
            ATLService *service = self.selectedMissionWrapper.service;
            return [service routeOverlaysFrom:self.originStation to:destination];
            
        } else {
            ATLStation *origin = self.originStation;
            destination = self.selectedMission.lastStop.station;
            NSMutableArray *overlays = [NSMutableArray arrayWithCapacity:5];
            for (ATLStation *borderStation in [self.selectedMission borderStationsBetweenStart:origin andEnd:destination]) {
                ATLService *service = [self.selectedMission serviceRuleAtStation:origin].service;
                [overlays addObjectsFromArray:[service routeOverlaysFrom:origin to:borderStation]];
                origin = borderStation;
            }
            ATLService *service = [self.selectedMission serviceRuleAtStation:origin].service;
            [overlays addObjectsFromArray:[service routeOverlaysFrom:origin to:destination]];
            return overlays;
        }
    } else {
        return @[];
    }
}

#pragma mark - Managing missions

- (ATLMission *)mission
{
    return self.selectedMission;
}

- (void)setMission:(ATLMission *)mission
{
    [self addMissionsObject:mission];
    self.arrangedMissionWrappers = @[[self wrapMission:mission]];
    [self selectWrapperAtIndex:0];
}

- (ATLMissionWrapper*)wrapMission:(ATLMission*)mission
{
    ATLMissionWrapper *wrapper = [[ATLMissionWrapper alloc] initWithTrajectory:self
                                                                       mission:mission
                                                                 originStation:self.originStation
                                                            destinationStation:self.destinationStation];
    return wrapper;
}

- (ATLMissionWrapper *)selectedMissionWrapper
{
    if ([self.missions count] > _selectedWrapperIndex) {
        return self.arrangedMissionWrappers[_selectedWrapperIndex];
    } else {
        return nil;
    }
}

- (ATLMissionWrapper *)wrapperAtRelativeIndex:(NSInteger)relativeIndex
{
    NSInteger i = _selectedWrapperIndex + relativeIndex;
    if (i >= 0 && i < [self.arrangedMissionWrappers count]) {
        return self.arrangedMissionWrappers[_selectedWrapperIndex + relativeIndex];
    } else {
        return nil;
    }
}

#pragma mark - Display options

- (BOOL)showAlternatives
{
    return _displayOptions & displayAlternatives;
}

- (void)setShowAlternatives:(BOOL)showAlternatives
{
    if (showAlternatives) {
        _displayOptions |= displayAlternatives;
    } else {
        _displayOptions &= ~displayAlternatives;
    }
}

- (BOOL)showIntermediateStops
{
    return _displayOptions & displayIntermediateStops;
}

- (void)setShowIntermediateStops:(BOOL)showIntermediateStops
{
    if (showIntermediateStops) {
        _displayOptions |= displayIntermediateStops;
    } else {
        _displayOptions &= ~displayIntermediateStops;
    }
}

- (void)toggleIntermediateStops
{
    self.showIntermediateStops = !self.showIntermediateStops;
}

@end

@implementation ATLMissionWrapper {
    ATLMission *_mission;
    NSUInteger _originIndex, _destinationIndex;
    ATLService *_service;
    BOOL _upDirection;
}

#pragma mark - Object lifecycle

- (instancetype)initWithTrajectory:(ATLTrajectory *)trajectory
                           mission:(ATLMission *)mission
                     originStation:(ATLStation *)originStation
                destinationStation:(ATLStation *)destinationStation
{
    self = [super init];
    if (self) {
        self.trajectory = trajectory;
        _mission = mission;
        BOOL found;
        [self setOriginStation:originStation found:&found];
        if (!found) {
            return nil;
        }
        [self setDestinationStation:destinationStation found:&found];
        if (!found) {
            return nil;
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<ATLMissionWrapper %@ %@>", self.plannedDeparture.nlTimeString, self.originStop.destination];
}

- (ATLMission *)mission
{
    return _mission;
}

#pragma mark - Managing origin and destination

- (ATLStation *)originStation
{
    return self.originStop.station;
}

- (void)setOriginStation:(ATLStation *)originStation
{
    BOOL found;
    [self setOriginStation:originStation found:&found];
    NSAssert(found, @"ATLMissionWrapper setOriginStation - station must be in mission.");
}

- (void)setOriginStation:(ATLStation *)originStation found:(BOOL*)found
{
    *found = NO;
    for (int i = 0; i < [self.mission.arrangedStops count]; i++) {
        ATLStop *stop = self.mission[i];
        if (stop.station == self.trajectory.originStation) {
            _originIndex = i;
            *found = YES;
            break;
        }
    }
}

- (ATLStation *)destinationStation
{
    return self.destinationStop.station;
}

- (void)setDestinationStation:(ATLStation *)destinationStation
{
    BOOL found;
    [self setDestinationStation:destinationStation found:&found];
    NSAssert(found, @"ATLMissionWrapper setDestinationStation - station must be in mission.");
}

- (void)setDestinationStation:(ATLStation *)destinationStation found:(BOOL*)found
{
    if (destinationStation) {
        *found = NO;
        for (NSUInteger i = _originIndex + 1; i < [self.mission.arrangedStops count]; i++) {
            ATLStop *stop = self.mission[i];
            if (stop.station == self.trajectory.destinationStation) {
                _destinationIndex = i;
                *found = YES;
                break;
            }
        }
    } else {
        _destinationIndex = [self.mission.arrangedStops count] - 1;
        *found = YES;
    }
}

- (ATLStop *)originStop
{
    return self.mission[_originIndex];
}

- (ATLStop *)destinationStop
{
    return self.mission[_destinationIndex];
}

#pragma mark - Managing intermediate stops

- (NSUInteger)nrOfStops
{
    return _destinationIndex - _originIndex + 1;
}

- (ATLStop *)stopAtIndex:(NSUInteger)i
{
    return self.mission[_originIndex + i];
}

- (void)enumerateIntermediateStops:(void(^)(ATLStop *))block
{
    for (int i = 1; i < self.nrOfStops - 1; i++) {
        block([self stopAtIndex:i]);
    }
}

#pragma mark - Derived properties

- (ATLService *)service
{
    if (!_service) {
        ATLServiceRule *rule = [self.mission serviceRuleAtStation:self.originStop.station];
        _service = rule.service;
        _upDirection = rule.upDirection;
    }
    return _service;
}

- (BOOL)upDirection
{
    if (!_service) {
        ATLServiceRule *rule = [self.mission serviceRuleAtStation:self.originStop.station];
        _service = rule.service;
        _upDirection = rule.upDirection;
    }
    return _upDirection;
}

- (NSDate *)plannedDeparture
{
    return self.originStop.plannedDeparture;
}

- (NSDate *)estimatedDeparture
{
    return self.originStop.estimatedDeparture;
}

- (NSDate *)plannedArrival
{
    return self.destinationStop.plannedArrival;
}

- (NSDate *)estimatedArrival
{
    return self.destinationStop.estimatedArrival;
}

- (NSString *)infoText
{
    if (self.trajectory.destination) {
        NSTimeInterval duration = [self.destinationStop.estimatedArrival timeIntervalSinceDate:self.originStop.estimatedDeparture];
        NSInteger nrOfIntermediateStops = _destinationIndex - _originIndex;
        NSString *intermediateStops;
        if (nrOfIntermediateStops == 1) {
            intermediateStops = @"1 halte";
        } else {
            intermediateStops = [NSString stringWithFormat:@"%d haltes", (int)nrOfIntermediateStops];
        }
        return [NSString stringWithFormat:@"%@, %.0f minuten", intermediateStops, duration / 60.0];
    } else {
        return @"Kies een uitstaphalte:";
    }
}

@end
