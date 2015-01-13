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
//  ATLJourney.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 31-07-14.
//

#import "ATLJourney.h"
#import "ATLJourneyElement.h"
#import "ATLVisit.h"
#import "ATLTransfer.h"
#import "ATLTravelSection.h"
#import "ATLTrajectory.h"
#import "ATLMission.h"
#import "ATLPathNode.h"
#import "ATLStation.h"
#import "ATLService.h"
#import "ATLServicePoint.h"

#import "NSManagedObjectContext+FFEUtilities.h"
#import "NSDate+Formatters.h"

#ifdef TRACE_ROUTE_FINDING
#define TraceLog(...) NSLog(@"%@", [NSString stringWithFormat:__VA_ARGS__])
#else
#define TraceLog(...) do { } while (0)
#endif


@interface ATLJourney ()

@property (nonatomic) int16_t statusInt;

@end

@implementation ATLJourney {
    int16_t _oldPositionIndex;
}

@dynamic statusInt;

#pragma mark - Object lifecycle

- (void)awakeFromInsert
{
    self.positionIndex = -1;
    self.timeOfDeparture = [NSDate date];
    self.timeOfArrival = [NSDate distantFuture];
    [self updateTitle];
}

- (NSString *)description
{
    NSMutableString *string = [NSMutableString string];
    [string appendString:@"<ATLJourney> data:\n"];
    [string appendFormat:@"V:\t%@\n", self.timeOfDeparture.nlDateTimeString];
    for (ATLJourneyElement *element in self.arrangedElements) {
        [string appendFormat:@"%d\t%@\n", element.order, element];
    }
    [string appendFormat:@"A:\t%@", self.timeOfArrival.nlDateTimeString];
    return string;
}

#pragma mark - managing the journey

@dynamic title;

- (NSDate *)departure
{
    return self.timeOfDeparture;
}

- (void)setDeparture:(NSDate *)departure
{
    self.timeOfDeparture = departure;
    self.origin.timeOfArrival = departure;
    [self.origin recalculateTimesForeward:YES];
}

- (NSDate *)arrival
{
    return self.timeOfArrival;
}

- (void)setArrival:(NSDate *)arrival
{
    if (self.destination) {
        self.timeOfArrival = arrival;
        self.destination.timeOfDeparture = arrival;
        [self.destination recalculateTimesForeward:NO];
    }
}

- (void)extendToStation:(ATLStation *)station
{
    if (!self.firstTransfer.station) {
        self.firstTransfer.station = station;
        [self updateTitle];
    } else {
        ATLTransfer *transfer = self.lastTransferWithStation;
        if ([station hasDirectConnectionWithStation:transfer.station]) {
            [self appendTrajectoryAtIndex:transfer.order / 2];
            [self appendTransferAtIndex:(transfer.order / 2) + 1 withStation:station];
            
        } else {
            NSArray *nodes = shortestServicePath(transfer.station, station);
            NSUInteger elementIndex = transfer.order / 2;
            for (NSUInteger i = 1; i < [nodes count]; i++) {
                ATLPathNode *node = nodes[i];
                [self appendTrajectoryAtIndex:elementIndex];
                elementIndex++;
                [self appendTransferAtIndex:elementIndex withStation:(ATLStation*)node.parent];
            }
        }
        NSLog(@"%@", self);
        [transfer recalculateTimesForeward:YES];
    }
}

- (void)updateTitle
{
    if (!self.origin.displayName) {
        self.title = @"Nieuwe reis";
    } else if (!self.destination.displayName) {
        self.title = [NSString stringWithFormat:@"%@ - ...", self.origin.displayName];
    } else {
        self.title = [NSString stringWithFormat:@"%@ - %@", self.origin.displayName, self.destination.displayName];
    }
}

#pragma mark - managing times

@dynamic timeOfDeparture;
@dynamic timeOfArrival;

- (NSTimeInterval)duration
{
    return [self.timeOfArrival timeIntervalSinceDate:self.timeOfDeparture];
}

- (void)recalculateTimesForeward:(BOOL)forewardDirection
{
    if (forewardDirection) {
        self.timeOfArrival = [[self.arrangedElements lastObject] endTime];
    } else {
        self.timeOfDeparture = [self.arrangedElements[0] timeOfDeparture];
    }
}

#pragma mark - managing Elements

- (NSUInteger)nrOfElements
{
    return [self.arrangedElements count];
}

@dynamic elements;

@synthesize arrangedElements = _arrangedElements;

- (NSArray *)arrangedElements
{
    if (!_arrangedElements) {
        self.arrangedElements = [self.elements sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]];
    }
    return _arrangedElements;
}

- (void)addElement:(ATLJourneyElement*)element AtIndex:(NSUInteger)index
{
    if (index % 2) {
        NSAssert([element isKindOfClass:[ATLTravelSection class]], @"All odd elements must be travelsections");
    } else {
        NSAssert([element isKindOfClass:[ATLVisit class]], @"All even elements must be visits");
    }
    [self removeElementsFromIndex:index withReplacement:element];
}

- (void)removeElementsFromIndex:(NSUInteger)index withReplacement:(ATLJourneyElement*)element
{
    NSAssert(index <= self.nrOfElements, @"Index must connect to existing array of elements");
    NSAssert((NSInteger)index > self.positionIndex, @"Cannot remove elements that are already visited");
    NSMutableSet *currentElements = [NSMutableSet setWithArray:self.arrangedElements];
    if (index < self.nrOfElements) {
        for (NSUInteger i = index; i < self.nrOfElements; i++) {
            // Delete pre-existing elements at a position equal or higher than index.
            [self.managedObjectContext deleteObject:self.arrangedElements[i]];
            [currentElements removeObject:self.arrangedElements[i]];
        }
    }
    if (element) {
        element.order = index;
        [self addElementsObject:element];
        [currentElements addObject:element];
    }
    self.arrangedElements = [currentElements sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]];
    [self updateTitle];
}

- (void)clearJourneyAtTime:(NSDate*)timestamp
{
    for (NSUInteger i = 0; i < self.nrOfElements; i++) {
        [self.managedObjectContext deleteObject:self.arrangedElements[i]];
    }
    self.arrangedElements = @[];
    self.positionIndex = -1;
    self.timeOfDeparture = timestamp;
    self.timeOfArrival = [NSDate distantFuture];
}

- (ATLJourneyElement *)objectAtIndexedSubscript:(NSUInteger)i
{
    if (i < [self.arrangedElements count]) {
        return self.arrangedElements[i];
    } else {
        return nil;
    }
}

#pragma mark - managing the current position

@dynamic positionIndex;

- (void)setPositionIndex:(NSInteger)newIndex atTime:(NSDate*)timestamp
{
    if (self.positionIndex == 0 && newIndex > 0) {
        self.origin.timeOfDeparture = timestamp;
        self.timeOfDeparture = self.origin.timeOfDeparture;
    }
    if (newIndex >= 0 && newIndex < self.nrOfElements) {
        self.positionIndex = newIndex;
        for (ATLJourneyElement *element in self.elements) {
            if (element.order < newIndex) {
                element.status = ATLElementStatusCompleted;
            } else if (element.order == newIndex) {
                element.status = ATLElementStatusPresent;
            } else {
                element.status = ATLElementStatusExpected;
            }
        }
    }
}

- (void)willUpdatePosition
{
    _oldPositionIndex = self.positionIndex;
}

- (void)didUpdatePosition
{
    if (self.positionIndex > _oldPositionIndex) {
        NSLog(@"did update position from %d to %d", _oldPositionIndex, self.positionIndex);
        NSInteger firstSection = _oldPositionIndex;
        if (firstSection % 2 == 0) {
            // oldPosition is a visit; refresh section before this visit, unless oldPosition is the first visit.
            firstSection /= 2;
            if (firstSection > 0) firstSection -= 1;
        } else {
            // oldPosition is a section; this will be the first section to refresh
            firstSection = (firstSection - 1) / 2;
        }
        NSInteger lastSection = self.positionIndex;
        if (lastSection % 2 == 0) {
            // positionIndex is a visit; refresh section before this visit, unless positionIndex is the first visit.
            lastSection /= 2;
            if (lastSection > 0) lastSection -= 1;
        } else {
            // positionIndex is a section; this will be the last section to refresh
            lastSection = (lastSection - 1) / 2;
        }
        NSRange range;
        range.location = firstSection;
        range.length = 1 + lastSection - firstSection;
        NSLog(@"update range: %lu - %lu", (unsigned long)range.location, (unsigned long)range.length);
    }
}

#pragma mark - managing Visits

- (NSUInteger)nrOfVisits
{
    return (self.nrOfElements / 2) + (self.nrOfElements % 2);
}

- (ATLVisit *)visitAtIndex:(NSUInteger)index
{
    if (index < self.nrOfVisits) {
        return self.arrangedElements[index * 2];
    }
    return nil;
}

- (ATLVisit *)origin
{
    if (self.nrOfVisits > 0) {
        return [self visitAtIndex:0];
    }
    return nil;
}

- (ATLVisit *)destination
{
    // if the last element is a visit, nrOfElements is odd
    if (self.nrOfElements % 2) {
        return [self visitAtIndex:self.nrOfVisits - 1];
    }
    return nil;
}

- (ATLTransfer *)firstTransfer
{
    for (NSUInteger i = 0; i < self.nrOfElements; i += 2) {
        ATLTransfer *transfer = (ATLTransfer*)self[i];
        if ([transfer isKindOfClass:[ATLTransfer class]]) {
            return transfer;
        }
    }
    return nil;
}

- (ATLTransfer *)lastTransferWithStation
{
    NSInteger highestIndex = self.nrOfElements - 1;
    for (NSInteger i = highestIndex - (highestIndex % 2); i >= 0; i -= 2) {
        ATLTransfer *transfer = (ATLTransfer*)self[i];
        NSAssert([transfer isKindOfClass:[ATLVisit class]], @"");
        if ([transfer isKindOfClass:[ATLTransfer class]] && transfer.station) {
            return transfer;
        }
    }
    return nil;
}

- (void)addVisit:(ATLVisit*)visit atIndex:(NSUInteger)index
{
    NSUInteger elementIndex = index * 2;
    if (elementIndex <= self.nrOfElements) {
        [self addElement:visit AtIndex:elementIndex];
        [visit.arrival updateDestination];
    }
}

- (void)removeVisitAtIndex:(NSUInteger)index
{
    NSUInteger elementIndex = index * 2;
    [self removeElementsFromIndex:elementIndex withReplacement:nil];
}

- (void)updateVisit:(ATLVisit *)visit
{
    NSUInteger sectionIndex = visit.order / 2;
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSetWithIndex:sectionIndex];
    if (sectionIndex > 0) {
        [indexSet addIndex:sectionIndex - 1];
    }
}

- (ATLTransfer *)appendTransferAtIndex:(NSUInteger)i withStation:(ATLStation*)station
{
    ATLTransfer *transfer = (ATLTransfer*)[self.managedObjectContext createManagedObjectOfType:@"ATLTransfer"];
    transfer.station = station;
    [self addVisit:transfer atIndex:i];
    return transfer;
}

- (void)enumerateVisits:(void (^)(ATLVisit *))block
{
    for (int i = 0; i < self.nrOfElements; i += 2) {
        block((ATLVisit*)self[i]);
    }
}

- (void)enumerateTransfers:(void (^)(ATLTransfer *))block
{
    [self enumerateVisits:^(ATLVisit *visit){
        if ([visit isKindOfClass:[ATLTransfer class]]) {
            block((ATLTransfer*)visit);
        }
    }];
}

#pragma mark - managing travelSections

- (NSUInteger)nrOfTravelSections
{
    return self.nrOfElements / 2;
}

- (ATLTravelSection *)sectionAtIndex:(NSUInteger)index
{
    if (index < self.nrOfTravelSections) {
        return self.arrangedElements[1 + index * 2];
    }
    return nil;
}

- (ATLTravelSection *)firstSection
{
    if (self.nrOfTravelSections > 0) {
        return [self sectionAtIndex:0];
    } else {
        return nil;
    }
}

- (ATLTravelSection *)lastSection
{
    if (self.nrOfTravelSections > 0) {
        return [self sectionAtIndex:self.nrOfTravelSections - 1];
    } else {
        return nil;
    }
}

- (void)addTravelSection:(ATLTravelSection *)section atIndex:(NSUInteger)index
{
    NSUInteger elementIndex = 1 + index * 2;
    if (elementIndex <= self.nrOfElements) {
        [self addElement:section AtIndex:elementIndex];
        [section updateOrigin];
        [section updateDestination];
    }
}

- (void)removeTravelSectionAtIndex:(NSUInteger)index
{
    NSUInteger elementIndex = 1 + index * 2;
    [self removeElementsFromIndex:elementIndex withReplacement:nil];
}

- (void)updateTravelSection:(ATLTravelSection *)travelSection
{
    NSIndexSet *indexSet = nil;
    if (travelSection) {
        indexSet = [NSIndexSet indexSetWithIndex:(travelSection.order - 1) / 2];
    }
}

- (NSArray *)visibleMissions
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:20];
    for (NSUInteger index = 0; index < self.nrOfTravelSections; index++) {
        ATLTravelSection *section = [self sectionAtIndex:index];
        for (ATLMission *mission in section.visibleMissions) {
            [array addObject:mission];
        }
    }
    return array;
}

- (void)appendTrajectoryAtIndex:(NSUInteger)i
{
    ATLTrajectory *trajectory = (ATLTrajectory*)[self.managedObjectContext createManagedObjectOfType:@"ATLTrajectory"];
    [self addTravelSection:trajectory atIndex:i];
}

- (void)enumerateTravelSections:(void (^)(ATLTravelSection *, BOOL *))block
{
    BOOL stop = NO;
    for (int i = 1; i < self.nrOfElements; i += 2) {
        block((ATLTravelSection*)self[i], &stop);
        if (stop) {
            break;
        }
    }
}

- (void)enumerateTrajectories:(void (^)(ATLTrajectory *, BOOL *))block
{
    [self enumerateTravelSections:^(ATLTravelSection *trajectory, BOOL *stop){
        if ([trajectory isKindOfClass:[ATLTrajectory class]]) {
            block((ATLTrajectory*)trajectory, stop);
        }
    }];
}

- (BOOL)hasTrajectories
{
    __block BOOL found = NO;
    [self enumerateTrajectories:^(ATLTrajectory *trajectory, BOOL *stop){
        found = YES;
        *stop = YES;
    }];
    return found;
}

#pragma mark -  Map Overlays

- (NSArray*)routeOverlays
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSUInteger i = 0; i < self.nrOfTravelSections; i++) {
        ATLTrajectory *trajectory = (ATLTrajectory*)[self sectionAtIndex:i];
        if ([trajectory isKindOfClass:[ATLTrajectory class]]) {
            [array addObjectsFromArray:trajectory.routeOverlays];
        }
    }
    return array;
}

@end

NSArray *shortestServicePath(ATLStation *origin, ATLStation *destination) {
    TraceLog(@"search service path from %@ to %@", origin.id_, destination.id_);
    NSMutableSet *unexaminedNodes = [NSMutableSet setWithCapacity:100];
    NSMutableSet *visitedNodes = [NSMutableSet setWithCapacity:50];
    
    // Set initial nodes for each route of the origin
    ATLPathNode *pathItem = [[ATLPathNode alloc] initWithParent:origin];
    pathItem.distance = 0;
    [unexaminedNodes addObject:pathItem];
    
    while ([unexaminedNodes count] > 0) {
        
        // Search the unexamined node with shortest distance to origin
        ATLPathNode *currentNode = nil;
        double currentResistance = 1E308;
        for (ATLPathNode *testNode in unexaminedNodes) {
            if (testNode.distance < currentResistance) {
                currentNode = testNode;
                currentResistance = testNode.distance;
            }
        }
        currentNode.visited = YES;
        [visitedNodes addObject:currentNode];
        [unexaminedNodes removeObject:currentNode];
        TraceLog(@"visited: %@", currentNode);
        
        // Break loop if that node is the destination
        ATLStation *currentItem = (ATLStation*)currentNode.parent;
        if (currentItem == destination) break;
        
        // Examine all other services departing from currentNode
        for (ATLService *service in currentItem.services) {
            if (service != currentNode.service) {
                
                // For each service examine all neighbor stations
                [service enumerateServicePoints:^(ATLServicePoint *point){
                    ATLLocation *neighbor = point.location;
                    if ([neighbor isKindOfClass:[ATLStation class]] && !neighbor.pathNode.visited) {
                        ATLPathNode *neighborNode = neighbor.pathNode;
                        if (!neighborNode) {
                            neighborNode = [[ATLPathNode alloc] initWithParent:neighbor];
                            [unexaminedNodes addObject:neighborNode];
                        }
                        double newResistance = currentResistance;
                        newResistance += [service waitingTimeAtRouteItem:currentItem fromService:currentNode.service];
                        newResistance += [service travelTimeFrom:currentItem to:neighbor];
                        if (newResistance < neighborNode.distance) {
                            neighborNode.distance = newResistance;
                            neighborNode.previousNode = currentNode;
                            neighborNode.service = service;
                        }
                    }
                }];
            }
        }
    }
    
    // Compose array with the found path
    NSMutableArray *result = nil;
    if (destination.pathNode) {
        result = [NSMutableArray arrayWithCapacity:20];
        ATLPathNode *node = destination.pathNode;
        while (node) {
            [result insertObject:node atIndex:0];
            node = node.previousNode;
        }
    }
    
    // Cleanup
    for (ATLPathNode *node in unexaminedNodes) {
        [node disconnectNode];
    }
    for (ATLPathNode *node in visitedNodes) {
        [node disconnectNode];
    }
    return result;
}

