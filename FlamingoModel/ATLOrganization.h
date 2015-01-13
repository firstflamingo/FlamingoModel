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
//  ATLOrganization.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ATLEntry.h"

#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#endif

@class ATLService;

@interface ATLOrganization : ATLEntry

@property (nonatomic, retain) NSSet *concessions;
@property (nonatomic, retain) NSSet *operatedServices;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *iconName;
@property (nonatomic, retain) NSString *url;

#if TARGET_OS_IPHONE
@property (nonatomic, readonly) UIImage *icon;
#else
@property (nonatomic, readonly) NSImage *icon;
#endif

- (void)addRelation:(ATLEntry*)relation withKey:(NSString*)key;

@end

@interface ATLOrganization (CoreDataGeneratedAccessors)

- (void)addConcessionsObject:(ATLService *)value;
- (void)removeConcessionsObject:(ATLService *)value;
- (void)addConcessions:(NSSet *)values;
- (void)removeConcessions:(NSSet *)values;

- (void)addOperatedServicesObject:(ATLService *)value;
- (void)removeOperatedServicesObject:(ATLService *)value;
- (void)addOperatedServices:(NSSet *)values;
- (void)removeOperatedServices:(NSSet *)values;

@end
