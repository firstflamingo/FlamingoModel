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
//  ATLPathItem.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 19-08-12.
//

#import "ATLPathNode.h"
#import "ATLLocation.h"
#import "ATLRoute.h"
#import "ATLService.h"

@implementation ATLPathNode

- (id)initWithParent:(ATLLocation*)parent
{
    self = [super init];
    if (self) {
        self.parent = parent;
        parent.pathNode = self;
        self.distance = 1E308;
    }
    return self;
}

- (void)disconnectNode
{
    self.parent.pathNode = nil;
}

- (BOOL)validPosition:(ATLRoutePosition *)position
{
    switch (self.searchDirection) {
        case up:
            return position.km > [self.parent kmPositionInRoute:self.route];
        case down:
            return position.km < [self.parent kmPositionInRoute:self.route];
        default:
            return YES;
    }
}

- (NSString *)description
{
    NSString *routeOrService = nil;
    if (self.route) {
        routeOrService = [NSString stringWithFormat:@" route: %@",  self.route.name];
    } else if (self.service) {
        routeOrService = [NSString stringWithFormat:@" service: %@",  self.service.shortName];
    } else {
        routeOrService = @"";
    }
    return [NSString stringWithFormat:@"<ATLPathNode %@ d: %.1f%@>", self.parent.id_, self.distance, routeOrService];
}

@end
