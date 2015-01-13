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
//  ATLStationOverlay.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 17-07-14.
//

#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>

//typedef enum {
//    neutralStation,
//    oneStepStation,
//    moreStepStation,
//    departureStation,
//    intermediateStation,
//    transferStation,
//    arrivalStation,
//    openStation
//} ATLStationRole;


@interface ATLStationAnnotation : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSManagedObjectID *parentID;
@property (nonatomic, assign) unsigned char importance;
//@property (nonatomic, assign) ATLStationRole stationRole;
@property (nonatomic, assign) int16_t arrivalGroup;
@property (nonatomic, assign) int16_t departureGroup;
@property (nonatomic, assign) int16_t icGroup;
@property (nonatomic, assign) int16_t regionGroup;

@end
