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
//  NSManagedObjectContext+FFEUtilities.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 14-05-14.
//

#import "NSManagedObjectContext+FFEUtilities.h"
#import "FFESyncing.h"

@implementation NSManagedObjectContext (FFEUtilities)


#pragma mark - Inserting new objects

- (NSManagedObject *)createManagedObjectOfType:(NSString *)type
{
    NSDictionary *entities = [self.persistentStoreCoordinator.managedObjectModel entitiesByName];
    return [[NSManagedObject alloc] initWithEntity:entities[type] insertIntoManagedObjectContext:self];
}

- (id)createManagedObjectOfClass:(Class)objectClass
{
    NSDictionary *entities = [self.persistentStoreCoordinator.managedObjectModel entitiesByName];
    return [[NSManagedObject alloc] initWithEntity:entities[NSStringFromClass(objectClass)] insertIntoManagedObjectContext:self];
}


#pragma mark - Finding existing objects

- (id <FFESyncing>)objectOfClass:(Class)objectClass withModelID:(NSString *)identifier create:(BOOL)create
{
    NSManagedObject <FFESyncing>*object = nil;
    if (identifier) {
        NSString *type = NSStringFromClass(objectClass);
        NSPredicate *predicate = [objectClass predicateWithModelID:identifier];
        object = (NSManagedObject <FFESyncing>*)[self fetchUniqueInstanceOfType:type withPredicate:predicate];
    }
    if (create && !object) {
        object = (NSManagedObject <FFESyncing>*)[self createManagedObjectOfClass:objectClass];
        object.modelID = identifier;
    }
    return object;
}

- (NSArray *)allObjectsOfClass:(Class)objectClass
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(objectClass)];
	return [self executeFetchRequest:request error:NULL];
}

- (NSManagedObject*)fetchUniqueInstanceOfType:(NSString*)type withPredicate:(NSPredicate*)predicate
{
    NSArray *result = [self fetchInstancesOfType:type withPredicate:predicate];
    if ([result count] == 1) {
        return result[0];
    } else {
        return nil;
    }
}

- (NSArray*)fetchInstancesOfType:(NSString*)type withPredicate:(NSPredicate*)predicate
{
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:type];
	[request setPredicate:predicate];
	return [self executeFetchRequest:request error:NULL];
}

@end
