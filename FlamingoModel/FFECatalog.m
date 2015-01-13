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
//  FFECatalog.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 09-05-14.
//

#import "FFECatalog.h"

@interface FFECatalog ()

@property (nonatomic, readonly) NSArray *allLocalObjects;
@property (nonatomic, strong) NSMutableSet *preExistingLocalObjects;
@property (nonatomic, strong) NSMutableSet *remoteNewbieIDs;
@property (nonatomic, strong) NSMutableSet *localNewbies;
@property (nonatomic, strong) NSMutableSet *conflictingNewbies;
@property (nonatomic, strong) NSMutableSet *remoteUpdates;
@property (nonatomic, strong) NSMutableSet *localUpdates;
@property (nonatomic, strong) NSMutableSet *conflictingUpdates;
@property (nonatomic, strong) NSMutableSet *localZombies;
@property (nonatomic, strong) NSMutableSet *remoteZombieIDs;

@end

@implementation FFECatalog

#pragma mark Object lifecycle:

- (void)awakeFromInsert
{
    self.lastServerModification = [NSDate distantPast];
}

#pragma mark Identity of the object:

@dynamic catalogedType;

+ (NSString *)remotePath
{
    return @"rest";
}

- (NSString *)pathExtension
{
    NSURL *url = [NSURL URLWithString:[self.catalogedClass remotePath]];
    return [url lastPathComponent];
}

+ (NSPredicate *)predicateWithModelID:(NSString *)identifier
{
    return [NSPredicate predicateWithFormat:@"catalogedType == %@", identifier];
}

- (NSString *)modelID
{
    return self.catalogedType;
}

- (void)setModelID:(NSString *)modelID
{
    self.catalogedType = modelID;
}

- (Class)catalogedClass
{
    return NSClassFromString(self.catalogedType);
}

- (void)setCatalogedClass:(Class)catalogedClass
{
    self.catalogedType = NSStringFromClass(catalogedClass);
}

#pragma mark - Finding cataloged objects

- (NSManagedObject <FFESyncing> *)objectWithID:(NSString*)modelID
{
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:self.catalogedType];
	[request setPredicate:[self.catalogedClass predicateWithModelID:modelID]];
	NSArray *result = [self.managedObjectContext executeFetchRequest:request error:NULL];
    if ([result count] != 1) {
        return nil;
    }
    return result[0];
}

- (NSArray*)allLocalObjects
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:self.catalogedType];
	return [self.managedObjectContext executeFetchRequest:request error:NULL];
}

#pragma mark - Collections

@synthesize preExistingLocalObjects;
@synthesize remoteNewbieIDs, localNewbies, conflictingNewbies, remoteUpdates, localUpdates, conflictingUpdates, localZombies, remoteZombieIDs;

- (NSDictionary *)changesDict
{
    return @{@"remoteNewbieIDs": self.remoteNewbieIDs,
             @"localNewbies": self.localNewbies,
             @"conflictingNewbies": self.conflictingNewbies,
             @"remoteUpdates": self.remoteUpdates,
             @"localUpdates": self.localUpdates,
             @"conflictingUpdates": self.conflictingUpdates,
             @"localZombies": self.localZombies,
             @"remoteZombieIDs": self.remoteZombieIDs};
}

#pragma mark Keeping track of changes:

@dynamic lastClientModification;
@dynamic lastServerModification;


#pragma mark Reading and writing content:

+ (NSArray *)acceptedDataTypes
{
    return @[@(DataTypeJSON)];
}

- (NSData *)contentWithDataType:(FFEDataType)type
{
    return nil;
}

- (void)fillWithData:(NSData *)data ofType:(FFEDataType)type
{
    if (type == DataTypeJSON) {
        NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        NSAssert([array isKindOfClass:[NSArray class]], @"Must be array");
        [self processUpdates:array];
    }
}

- (void)processLocalChanges
{
    NSArray *currentObjects = self.allLocalObjects;
    self.preExistingLocalObjects = [NSMutableSet setWithArray:currentObjects];
    self.localNewbies = [NSMutableSet setWithCapacity:10];
    self.localZombies = [NSMutableSet setWithCapacity:1];
    self.localUpdates = [NSMutableSet setWithCapacity:20];
    self.remoteNewbieIDs = [NSMutableSet setWithCapacity:10];
    self.remoteZombieIDs = [NSMutableSet setWithCapacity:10];
    self.remoteUpdates = [NSMutableSet setWithCapacity:20];
    self.conflictingNewbies = [NSMutableSet setWithCapacity:5];
    self.conflictingUpdates = [NSMutableSet setWithCapacity:10];
    for (NSManagedObject <FFESyncing> *object in currentObjects) {
        if (object.lastServerModification == nil) {
            [self.preExistingLocalObjects removeObject:object];
            [self.localNewbies addObject:object];
        } else if([object.lastClientModification timeIntervalSinceDate:object.lastServerModification] > 0.95) {
            [self.localUpdates addObject:object];
        }
    }
}

- (void)processUpdates:(NSArray *)updatesArray
{
    [self processLocalChanges];
    
    if ([updatesArray count] > 0) {
        self.localZombies = [self.preExistingLocalObjects mutableCopy];
    } else {
        NSLog(@"Update canceled because updates array is empty");
        return;
    }
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss";
    }
    for (NSDictionary *item in updatesArray) {
        NSString *itemID = item[@"id"];
        NSManagedObject <FFESyncing> *object = [self objectWithID:itemID];
        NSDate *itemModified = [dateFormatter dateFromString:item[@"lm"]];
        if (object == nil) {
            if ([itemModified timeIntervalSinceDate:self.lastServerModification] > 0.95) {
                [self.remoteNewbieIDs addObject:itemID];
            } else {
                [self.remoteZombieIDs addObject:itemID];
            }
        } else {
            [self.localZombies removeObject:object];
            if (object.lastServerModification == nil) {
                [self.remoteNewbieIDs addObject:itemID];
                [self.conflictingNewbies addObject:object];
            } else if ([itemModified timeIntervalSinceDate:object.lastServerModification] > 0.95) {
                [self.remoteUpdates addObject:object];
                if([object.lastClientModification timeIntervalSinceDate:object.lastServerModification] > 0.95) {
                    [self.conflictingUpdates addObject:object];
                }
            }
        }
    }
}

- (void)resolveConflictsWithInstruction:(FFESyncInstruction)instruction
{
    switch (instruction) {
        case syncWithPrevailingServer:
            [self.localUpdates minusSet:self.conflictingUpdates];
            [self.conflictingUpdates removeAllObjects];
            [self.localNewbies minusSet:self.conflictingNewbies];
            [self.conflictingNewbies removeAllObjects];
            break;
            
        case syncWithPrevailingClient:
            [self.remoteUpdates minusSet:self.conflictingUpdates];
            [self.conflictingUpdates removeAllObjects];
            for (NSManagedObject <FFESyncing> *object in self.conflictingNewbies) {
                [self.remoteNewbieIDs removeObject:object.modelID];
            }
            [self.conflictingNewbies removeAllObjects];
            break;
            
        default:
            break;
    }
}

@end
