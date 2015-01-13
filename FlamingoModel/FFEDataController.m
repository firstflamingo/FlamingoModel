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
//  FFEDataController.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 08-12-13.
//

#import "FFEDataController.h"
#import "NSMutableURLRequest+HeaderInterpretation.h"
#import "NSHTTPURLResponse+HeaderInterpretation.h"
#import "NSManagedObjectContext+FFEUtilities.h"
#import "FFEAccount.h"
#import "FFECatalog.h"

NSString *const kFFEBasicsErrorDomain = @"nl.firstflamingo.basics.error";

@interface FFEDataController  () <FFEAccountDelegate>

// Core Data stack
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSURL *storeURL;

// REST interface
@property (nonatomic, strong) NSURLSession *remoteSession;

// Download management
@property (nonatomic, strong) NSMutableDictionary *canceledRequests;
@property (nonatomic, strong) NSMutableSet *downloadingObjects;

@end


@implementation FFEDataController {
    BOOL _testing;
    BOOL _updatingFromServer;
}

#pragma mark - Object lifecycle

- (instancetype)initWithStoreURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _storeURL = url;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSDate *)lastUpdated
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if ([fileManager fileExistsAtPath:self.storeURL.path]) {
        return [fileManager attributesOfItemAtPath:self.storeURL.path error:&error][NSFileModificationDate];
    } else {
        return [NSDate date];
    }
}

#pragma mark - Testing

+ (instancetype)testingInstance
{
    id instance = [self new];
    [(FFEDataController*)instance beTestingInstance];
    return instance;
}

- (void)beTestingInstance
{
    _testing = YES;
}

- (NSDate *)now
{
    if (_testing) {
        NSAssert(self.testingDate != nil, @"In a testing environment a testingDate should be set.");
        return self.testingDate;
    } else {
        return [NSDate date];
    }
}

#pragma mark - Configuration

- (NSString *)modelName
{
    // intended for subclassing
    return nil;
}

- (NSString *)serviceName
{
    // intended for subclassing
    return nil;
}

- (NSURL *)remoteHost
{
    // intended for subclassing
    return nil;
}

- (NSString *)commandPath
{
    // intended for subclassing
    return nil;
}

- (NSString *)realm
{
    // intended for subclassing
    return nil;
}

- (Class)accountClass
{
    return [FFEAccount class];
}

- (Class)catalogClass
{
    return [FFECatalog class];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
            _managedObjectContext.propagatesDeletesAtEndOfEvent = YES;
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(contextWillSave:)
                                                         name:NSManagedObjectContextWillSaveNotification
                                                       object:_managedObjectContext];
        }
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"momd"];
        if (!modelURL) {
            modelURL = [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"mom"];
        }
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!_persistentStoreCoordinator) {
        
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSPersistentStore *store = nil;
        NSError *error = nil;
        
        if (_testing) {
            store = [_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                              configuration:nil
                                                                        URL:nil
                                                                    options:nil
                                                                      error:&error];
        } else {
            store = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                              configuration:nil
                                                                        URL:self.storeURL
                                                                    options:@{NSMigratePersistentStoresAutomaticallyOption : @YES,
                                                                              NSInferMappingModelAutomaticallyOption : @YES,
                                                                              NSSQLitePragmasOption : @{@"journal_mode" : @"DELETE"} }
                                                                      error:&error];
        }
        if (!store) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

#pragma mark - Saving changes

- (void)contextWillSave:(NSNotification*)notification
{
    if (!_updatingFromServer) {
        [self setLastModifiedFor:self.managedObjectContext.insertedObjects];
        [self setLastModifiedFor:self.managedObjectContext.updatedObjects];
    }
}

- (void)setLastModifiedFor:(NSSet*)collection
{
    for (id object in collection) {
        if ([object respondsToSelector:@selector(setLastClientModification:)]) {
            [object setLastClientModification:self.now];
        }
    }
}

- (void)saveContext
{
    if ([self.managedObjectContext hasChanges]) {
        NSLog(@"Save moc");
        NSError *error = nil;
        BOOL ok = [self.managedObjectContext save:&error];
        if (!ok) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    } else {
        NSLog(@"no changes to save");
    }
}

#pragma mark - REST Interface

- (NSURLSession *)remoteSession
{
    if (!_remoteSession) {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.remoteSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _remoteSession;
}

- (FFEAccount *)account
{
    if (!_account) {
        self.account = [[self.accountClass alloc] initWithDelegate:self];
    }
    return _account;
}

- (void)resetAccount
{
    [self.account resetAccount];
}

#pragma mark REST commands

- (void)checkAccount
{
    if (self.account.modelID) {
        [self updateLocalObject:self.account];
    } else {
        [self updateRemoteObjectWith:self.account];
    }
}

- (void)registerAccount
{
    if ([self.account.username isEqualToString:@"new_user"]) {
        [self updateRemoteObjectWith:self.account];
    }
}

- (void)synchronizeClass:(Class)objectClass
{
    NSManagedObject <FFESyncing>*catalog = [self.managedObjectContext objectOfClass:self.catalogClass
                                                                        withModelID:NSStringFromClass(objectClass)
                                                                             create:YES];
    [self updateLocalObject:catalog];
}

- (void)sendServerCommand:(NSString*)command
{
    NSURL *url = [self.remoteHost URLByAppendingPathComponent:self.commandPath];
    url = [url URLByAppendingPathComponent:command];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [self executeRequest:request withCompletionHandler:^(NSData *data, NSHTTPURLResponse *response){}];
}

#pragma mark commands for individual objects

- (void)getRemoteObjectOfClass:(Class)objectClass withID:(NSString *)modelID
{
    NSURL *url = [self.remoteHost URLByAppendingPathComponent:[objectClass remotePath]];
    url = [url URLByAppendingPathComponent:modelID];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request setAccept:[objectClass acceptedDataTypes]];
    
    [self executeRequest:request withCompletionHandler:^(NSData *data, NSHTTPURLResponse *response){
        [self updateObjectOfClass:objectClass remoteID:modelID withData:data response:response];
    }];
}

- (void)updateRemoteObjectWith:(id <FFESyncing>)localObject
{
    NSURL *url = [self.remoteHost URLByAppendingPathComponent:[[localObject class] remotePath]];
    NSString *method = nil;
    if (localObject.pathExtension) {
        method = @"PUT";
        url = [url URLByAppendingPathComponent:localObject.pathExtension];
    } else {
        method = @"POST";
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    [request setIfUnmodifiedSince:localObject.lastServerModification];
    FFEDataType dataType = [[[localObject class] acceptedDataTypes][0] intValue];
    [request setContentType:dataType];
    request.HTTPBody = [localObject contentWithDataType:dataType];
    NSLog(@"Send local data: %@", localObject);
    
    [self executeRequest:request withCompletionHandler:^(NSData *data, NSHTTPURLResponse *response){
        [self updateObject:localObject withData:data response:response];
    }];
}

- (void)updateLocalObject:(id <FFESyncing>)localObject
{
    NSURL *url = [self.remoteHost URLByAppendingPathComponent:[[localObject class] remotePath]];
    url = [url URLByAppendingPathComponent:localObject.pathExtension];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request setAccept:[[localObject class] acceptedDataTypes]];
    [request setIfModifiedSince:localObject.lastServerModification];
    
    [self executeRequest:request withCompletionHandler:^(NSData *data, NSHTTPURLResponse *response){
        [self updateObject:localObject withData:data response:response];
    }];
}

- (void)deleteRemoteAndLocalObject:(id <FFESyncing>)expiredObject
{
    NSURL *url = [self.remoteHost URLByAppendingPathComponent:[[expiredObject class] remotePath]];
    url = [url URLByAppendingPathComponent:expiredObject.pathExtension];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"DELETE";

    [self executeRequest:request withCompletionHandler:^(NSData *data, NSHTTPURLResponse *response){
        [self deleteObject:expiredObject withResponse:response];
    }];
}

- (void)deleteRemoteObjectOfClass:(Class)objectClass withID:(NSString *)modelID
{
    NSURL *url = [self.remoteHost URLByAppendingPathComponent:[objectClass remotePath]];
    url = [url URLByAppendingPathComponent:modelID];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"DELETE";
    [self executeRequest:request withCompletionHandler:^(NSData *data, NSHTTPURLResponse *response){}];
}

#pragma mark Utility methods

- (void)executeRequest:(NSURLRequest*)request withCompletionHandler:(void (^)(NSData *, NSHTTPURLResponse *))handler
{
    [self registerForDownload:request];
    NSString *logString = [NSString stringWithFormat:@"%@ - %@", request.HTTPMethod, request.URL.absoluteString];
    NSURLSessionDataTask *dataTask = [self.remoteSession dataTaskWithRequest:request
                                                           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSAssert([httpResponse isKindOfClass:[NSHTTPURLResponse class]], @"Must be http response");
            NSLog(@"%@ - response:%ld data:%lu", logString, (long)httpResponse.statusCode, (unsigned long)[data length]);
            handler(data, httpResponse);
        } else {
            if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == -999) {
                // If request was canceled, try to find the reason for cancelation
                NSLog(@"Search replacing error: %@", request.URL.absoluteString);
                NSError *replacingError = self.canceledRequests[request.URL.absoluteString];
                if (replacingError) {
                    error = replacingError;
                }
            }
            NSLog(@"%@ - error: %@", logString, error);
            if ([self.delegate respondsToSelector:@selector(dataController:downloadFailedWithError:)]) {
                [self.delegate dataController:self downloadFailedWithError:error];
            }
        }
        [self unregisterForDownload:request];
    }];
    [dataTask resume];
}

- (void)updateObjectOfClass:(Class)objectClass remoteID:(NSString*)remoteID withData:(NSData*)data response:(NSHTTPURLResponse*)response
{
    NSManagedObject* targetObject = [self.managedObjectContext objectOfClass:objectClass withModelID:remoteID create:YES];
    [self updateObject:(NSManagedObject<FFESyncing>*)targetObject withData:data response:response];
}

- (void)updateObject:(id <FFESyncing>)object withData:(NSData*)data response:(NSHTTPURLResponse*)response
{
    NSInteger status = response.statusCode;
    BOOL notModified = NO;
    if (status == 200 || status == 201) {
        NSDate *modificationDate = response.lastModified;
        if (object.lastServerModification == nil || [modificationDate timeIntervalSinceDate:object.lastServerModification] > 0.95) {
            NSLog(@"Update with remote data: %@", object);
            [object fillWithData:data ofType:response.dataType];
            [self saveObject:object withServerModification:response.lastModified];
            [self finishUpdateForObject:object];
        } else {
            notModified = YES;
        }
    } else if (status == 304) {
        notModified = YES;
    } else {
        if ([self.delegate respondsToSelector:@selector(dataController:downloadFailedWithError:)]) {
            [self.delegate dataController:self downloadFailedWithError:[self errorWithCode:(FFEBasicsError)status]];
        }
    }
    if (notModified) {
        NSLog(@"Object was not modified on server (status=%d)", (int)status);
        if ([object respondsToSelector:@selector(processLocalChanges)]) {
            [(id)object processLocalChanges];
            [self finishUpdateForObject:object];
        }
    }
}

- (void)deleteObject:(id <FFESyncing>)expiredObject withResponse:(NSHTTPURLResponse*)response
{
    NSInteger status = response.statusCode;
    if (status == 204 || status == 404) {
        if ([expiredObject isKindOfClass:[NSManagedObject class]]) {
            [self.managedObjectContext deleteObject: expiredObject];
            NSAssert([(NSManagedObject*)expiredObject isDeleted], @"");
            [self saveContext];
        } else if ([expiredObject isKindOfClass:[FFEAccount class]]) {
            [(FFEAccount*)expiredObject resetAccount];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(dataController:downloadFailedWithError:)]) {
            [self.delegate dataController:self downloadFailedWithError:[self errorWithCode:(FFEBasicsError)status]];
        }
    }
}

- (void)saveObject:(id <FFESyncing>)object withServerModification:(NSDate*)modificationDate
{
    NSAssert(modificationDate != nil, @"");
    _updatingFromServer = YES;
    object.lastClientModification = modificationDate;
    object.lastServerModification = modificationDate;
    if ([object isKindOfClass:[NSManagedObject class]]) {
        [self saveContext];
    } else if ([object isKindOfClass:[FFEAccount class]]) {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    _updatingFromServer = NO;
}

- (void)finishUpdateForObject:(NSManagedObject <FFESyncing> *)object
{
    if ([object isKindOfClass:[FFECatalog class]]) {
        FFECatalog *catalog = (FFECatalog*)object;
        FFESyncInstruction syncInstruction = syncWithPrevailingServer;
        if ([self.delegate respondsToSelector:@selector(dataController:willSyncChanges:)]) {
            syncInstruction = [self.delegate dataController:self willSyncChanges:catalog.changesDict];
        }
        [catalog resolveConflictsWithInstruction:syncInstruction];
        
        int newbiesCount = 0;
        
        if (syncInstruction) {
            for (NSManagedObject <FFESyncing> *object in catalog.remoteUpdates) {
                NSLog(@"update local object %@", object);
                [self updateLocalObject:object];
            }
            for (NSManagedObject <FFESyncing> *object in catalog.localUpdates) {
                NSLog(@"update remote object %@", object);
                [self updateRemoteObjectWith:object];
            }
            for (NSString *itemID in catalog.remoteNewbieIDs) {
                NSLog(@"new remote object %@", itemID);
                [self getRemoteObjectOfClass:catalog.catalogedClass withID:itemID];
            }
            for (NSManagedObject <FFESyncing> *object in catalog.localNewbies) {
                NSLog(@"new local object %@", object);
                [self updateRemoteObjectWith:object];
                
                newbiesCount++;
                if (newbiesCount > 20) {
                    break;
                }
            }
            for (NSString *itemID in catalog.remoteZombieIDs) {
                NSLog(@"delete remote object %@", itemID);
                [self deleteRemoteObjectOfClass:catalog.catalogedClass withID:itemID];
            }
            if ([catalog.localZombies count] > 0) {
                for (NSManagedObject <FFESyncing> *object in catalog.localZombies) {
                    NSLog(@"delete local object %@", object);
                    [self.managedObjectContext deleteObject:object];
                }
                [self saveContext];
            }
        }
    }
}

#pragma mark dealing with errors

- (NSMutableDictionary *)canceledRequests
{
    if (!_canceledRequests) {
        self.canceledRequests = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    return _canceledRequests;
}

- (NSError*)errorWithCode:(FFEBasicsError)errorCode
{
    NSString *localizedDescription;
    switch (errorCode) {
        case httpUnAuthorized:
            localizedDescription = @"Authorization failed";
            break;
        default:
            localizedDescription = [NSString stringWithFormat:@"Error with code %d", errorCode];
            break;
    }
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: localizedDescription};
    return [NSError errorWithDomain:kFFEBasicsErrorDomain code:errorCode userInfo:userInfo];
}

#pragma mark NSUSLSessionDelegate methods

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    self.remoteSession = nil;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    NSURLProtectionSpace *protectionSpace = challenge.protectionSpace;
    NSURLSessionAuthChallengeDisposition disposition;
    NSURLCredential *credential = nil;

    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSLog(@"challenge requesting Server Trust for server: %@", protectionSpace.host);
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        
    } else if (challenge.previousFailureCount == 0 && challenge.proposedCredential.hasPassword) {
        NSLog(@"Challenge handling with proposed credential");
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        credential = challenge.proposedCredential;
        
    } else if (challenge.previousFailureCount < 2 &&
        [protectionSpace.realm isEqualToString:self.realm] &&
        [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest]) {
        NSLog(@"Challenge handling with account: %@", self.account);
        disposition = NSURLSessionAuthChallengeUseCredential;
        credential = self.account.credential;
        
    } else {
        NSLog(@"Authentication failed");
        NSLog(@"Register error at: %@", task.currentRequest.URL.absoluteString);
        self.canceledRequests[task.currentRequest.URL.absoluteString] = [self errorWithCode:httpUnAuthorized];
        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
    }
    completionHandler(disposition, credential);
}

#pragma mark - Download management

- (NSMutableSet *)downloadingObjects
{
    if (!_downloadingObjects) {
        self.downloadingObjects = [NSMutableSet setWithCapacity:6];
    }
    return _downloadingObjects;
}

- (void)registerForDownload:(id)object
{
    if ([self.downloadingObjects count] == 0 && [self.delegate respondsToSelector:@selector(downloadsStartedByDataController:)]) {
        [self.delegate downloadsStartedByDataController:self];
    }
    [self.downloadingObjects addObject:object];
}

- (void)unregisterForDownload:(id)object
{
    [self.downloadingObjects removeObject:object];
    if ([self.downloadingObjects count] == 0 && [self.delegate respondsToSelector:@selector(downloadsEndedByDataController:)]) {
        [self.delegate downloadsEndedByDataController:self];
        self.canceledRequests = nil;
    }
}

@end
