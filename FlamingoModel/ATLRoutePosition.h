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
//  ATLRoutePosition.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>

@class ATLRoute, ATLLocation;

@interface ATLRoutePosition : NSManagedObject

@property (nonatomic) float km;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic, retain) ATLLocation *location;
@property (nonatomic, retain) ATLRoute *route;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;


// XML reperesentation
- (NSString*)xmlRouteRef;
- (NSString*)xmlItemRef;

@end
