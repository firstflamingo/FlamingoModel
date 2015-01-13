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
//  NSManagedObjectContext+FFEUtilities.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 14-05-14.
//

#import <CoreData/CoreData.h>

@protocol FFESyncing;

@interface NSManagedObjectContext (FFEUtilities)

#pragma mark - Inserting new objects
/**
 Convenience method to create managed objects
 @param type an NSString indicating the type (class) of the desired object
 @returns the newly created managed object
 */
- (NSManagedObject *)createManagedObjectOfType:(NSString *)type;

- (id)createManagedObjectOfClass:(Class)objectClass;

#pragma mark - Finding existing objects

- (id <FFESyncing>)objectOfClass:(Class)objectClass withModelID:(NSString*)identifier create:(BOOL)create;
- (NSArray *)allObjectsOfClass:(Class)objectClass;
- (NSManagedObject*)fetchUniqueInstanceOfType: (NSString*)type withPredicate: (NSPredicate*)predicate;
- (NSArray*)fetchInstancesOfType: (NSString*)type withPredicate: (NSPredicate*)predicate;

@end
