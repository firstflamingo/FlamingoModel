//  Copyright (c) 2013-2015 First Flamingo Enterprise B.V.
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
//  FFEDataController.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 08-12-13.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FFESyncing.h"

extern NSString *const kFFEBasicsErrorDomain;

typedef enum {
    httpOK = 200,
    httpCreated = 201,
    httpNoContent = 204,
    httpNotModified = 304,
    httpBadRequest = 400,
    httpUnAuthorized = 401,
    httpNotFound = 404,
    httpMethodNotAllowed = 405,
    httpNotAcceptable = 406,
    httpConflict = 409,
    httpPreconditionFailed = 412,
    httpUnsupportedMedia = 415,
    httpUnprocessableEntity = 422
} FFEBasicsError;

@class FFEAccount;
@protocol FFEDataControllerDelegate;


/**
 FFE is an abstract class intended for subclassing by controller-classes for Core Data. It implements basic functionality for creating a store and creating managed objects and for testing. To make a subclass functional, at least the configuration methods modelName and storeURL must be implemented.
 FFEDataController is used in the following projects:
 - FFETableViews
 - RAModel
 If you modify the code, please test these projects.
 */
@interface FFEDataController : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

#pragma mark - Object lifecycle

/**
 Creates an FFEDataController with URL for the data store. This is the designated way to create an FFEdataController.
 @returns a new FFEDataController instance
 */
- (instancetype)initWithStoreURL:(NSURL *)url;

/**
 @returns the date when the datastore was last changed
 */
@property (nonatomic, readonly) NSDate *lastUpdated;

#pragma mark - Testing

/**
 Creates an FFEDataController with NSInMemoryStoreType, to be used in unit tests
 @returns a new FFEDataController instance
 */
+ (instancetype)testingInstance;

/**
 The testingDate i.e. the value to be considered "now" in a testing environment
 */
@property (nonatomic, strong) NSDate *testingDate;

/**
 @returns the date and time considered to be "now" i.e. current time in operational environment and testingDate in a testing environment.
 */
@property (nonatomic, readonly) NSDate *now;


#pragma mark - Configuration

@property (nonatomic, weak) id <FFEDataControllerDelegate> delegate;

/**
 The name of the model, should be defined by any subclass of FFEDataController.
 */
@property (nonatomic, readonly) NSString *modelName;

/**
 The URL of a remote server as used by the REST interface. Should be defined by any subclasses using remote sync.
 */
@property (nonatomic, readonly) NSURL *remoteHost;

/**
 Path for the command api of the server.
 */
@property (nonatomic, readonly) NSString *commandPath;

/**
 The security realm in whitch authentication with the server will happen.
 */
@property (nonatomic, readonly) NSString *realm;

/**
 The class used to manage credentials, this must be a subclass of FFEAccount.
 */
@property (nonatomic, readonly) Class accountClass;

/**
 The class used to store a catalog in the managedObjectContext, this must be either FFECatalog or a subclass of FFECatalog.
 This class must be included in the managedObjectModel
 */
@property (nonatomic, readonly) Class catalogClass;


#pragma mark - Core Data stack
/**
 RADataController owns the managed object context and keeps a strong reference to it.
 @returns the managed object context
 */
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


#pragma mark - Saving changes
/**
 Saves the managed object context.
 Aborts when the save operation causes an error, error resolving has not (yet) been implemented.
 */
- (void)saveContext;

#pragma mark - REST interface

@property (nonatomic, readonly) NSURLSession *remoteSession;

/**
 Stores the credentials for server authentication
 */
@property (nonatomic, strong) FFEAccount *account;



- (void)resetAccount;

/**
 Checks the current account by requesting current account info from the server
 */
- (void)checkAccount;

/**
 Creates an account at the server, if not already present.
 */
- (void)registerAccount;

/**
 Compares a catalog of local objects with a a catalog of remote objects and updates the differences.
 */
- (void)synchronizeClass:(Class)objectClass;

/**
 Sends a command to the server through the servers command api.
 */
- (void)sendServerCommand:(NSString*)command;

/**
 Gets a remote object that (presumably) does not exist locally. The object that is returned by the server will be stored locally.
 If a local object with the same type and identifier already exists it will be updated.
 @param class the class of the object
 @param identifier the id of the object
 */
- (void)getRemoteObjectOfClass:(Class)objectClass withID:(NSString *)modelID;

/**
 Puts a local object to the server, to update the remote object. The object can be modified by the server,
 server-side changes will be stored locally and returned in the completion block.
 @param object local object that will update the remote object
 */
- (void)updateRemoteObjectWith:(id <FFESyncing>)localObject;

/**
 Gets the remote counterpart of a local object from the server and uses the result to update the local object.
 If the remote counterpart does not exist (404 Not Found) the local object will be deleted.
 @param object local object that will be updated
 */
- (void)updateLocalObject:(id <FFESyncing>)localObject;

/**
 Deletes the remote counterpart of a local object. Upon success (200 OK) or when the remote object didn't exist (404 Not Found)
 the local object will be deleted as well.
 @param object to be deleted
 */
- (void)deleteRemoteAndLocalObject:(id <FFESyncing>)object;


- (void)deleteRemoteObjectOfClass:(Class)objectClass withID:(NSString *)modelID;

@end

@protocol FFEDataControllerDelegate <NSObject>

@optional

- (void)downloadsStartedByDataController:(FFEDataController*)controller;
- (void)downloadsEndedByDataController:(FFEDataController *)controller;
- (FFESyncInstruction)dataController:(FFEDataController*)controller willSyncChanges:(NSDictionary*)changesDict;
- (void)dataController:(FFEDataController*)controller downloadFailedWithError:(NSError*)error;

@end
