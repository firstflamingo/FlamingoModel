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
//  ATLJunction.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 08-08-12.
//

#import "ATLJunction.h"


@implementation ATLJunction

@dynamic sameDirection;

- (NSString *)statusString
{
    if (![self respondsToSelector:@selector(sameDirection)]) {
        return @"no direction has been defined";
    }
    
    if (self.sameDirection) {
        return @"routes in same direction";
    } else {
        return @"routes in opposed direction";
    }
}

- (NSString *)symbolName
{
    return @"junction";
}

- (ATLRoute *)routeJoinedTo:(ATLRoute *)route
{
    BOOL knownRoute = NO;
    ATLRoute *otherRoute = nil;
    for (ATLRoutePosition *position in self.routePositions) {
        if (position.route == route) {
            knownRoute = YES;
        } else {
            otherRoute = position.route;
        }
    }
    if (knownRoute) {
        return otherRoute;
    } else {
        return nil;
    }
}

- (void)toggleDirection
{
    self.sameDirection = !self.sameDirection;
}

#pragma mark - XML representation

- (void)appendAttributesToXMLString:(NSMutableString *)output
{
    [super appendAttributesToXMLString:output];
    [output appendFormat:@" sameDirection=\"%@\"", self.sameDirection ? @"yes" : @"no"];
}

@end
