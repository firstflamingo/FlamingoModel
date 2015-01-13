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
//  FFECatalog.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 09-05-14.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FFESyncing.h"


@interface FFECatalog : NSManagedObject <FFESyncing>

@property (nonatomic, retain) NSString * catalogedType;
@property (nonatomic, retain) NSDate * lastClientModification;
@property (nonatomic, retain) NSDate * lastServerModification;

@property (nonatomic) Class catalogedClass;

@property (nonatomic, readonly) NSMutableSet *remoteNewbieIDs;
@property (nonatomic, readonly) NSMutableSet *localNewbies;
@property (nonatomic, readonly) NSMutableSet *conflictingNewbies;
@property (nonatomic, readonly) NSMutableSet *remoteUpdates;
@property (nonatomic, readonly) NSMutableSet *localUpdates;
@property (nonatomic, readonly) NSMutableSet *conflictingUpdates;
@property (nonatomic, readonly) NSMutableSet *localZombies;
@property (nonatomic, readonly) NSMutableSet *remoteZombieIDs;

@property (nonatomic, readonly) NSDictionary *changesDict;

- (void)processLocalChanges;
- (void)processUpdates:(NSArray *)updatesArray;
- (void)resolveConflictsWithInstruction:(FFESyncInstruction)instruction;

@end
