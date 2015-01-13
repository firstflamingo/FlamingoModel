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
//  ATLPathItem.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 19-08-12.
//

#import <Foundation/Foundation.h>

typedef enum {
    down = -1,
    both = 0,
    up = 1
} ATLSearchDirection;


@class ATLRoute, ATLService, ATLLocation, ATLRoutePosition;

@interface ATLPathNode : NSObject

@property (strong) ATLLocation *parent;
@property (weak) ATLRoute *route;
@property (weak) ATLService *service;
@property (nonatomic, assign) ATLSearchDirection searchDirection;
@property (nonatomic, assign) double distance;
@property (nonatomic, assign) BOOL visited;
@property (weak) ATLPathNode *previousNode;

- (id)initWithParent:(ATLLocation*)parent;
- (void)disconnectNode;
- (BOOL)validPosition:(ATLRoutePosition*)position;

@end
