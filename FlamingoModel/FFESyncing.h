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
//  FFERemoteObject.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 21-04-14.
//

#import <Foundation/Foundation.h>

typedef enum {
    DataTypeUnknown,
    DataTypeXML,
    DataTypeJSON
} FFEDataType;

typedef enum {
    cancelSync = 0,
    syncWithPrevailingServer,
    syncWithPrevailingClient
} FFESyncInstruction;

@protocol FFESyncing <NSObject>

#pragma mark Identity of the object:

/**
 Base path (normally api/class_name) for composing a url.
 */
+ (NSString*)remotePath;

/**
 Path extension indicating the instance, when composing a url.
 */
@property (nonatomic, readonly) NSString *pathExtension;

/**
 Identifier by whitch the instance is known in the model logic.
 */
@property (nonatomic, strong) NSString *modelID;

/**
 Predicate that can be used to find an object with its model id.
 */
+ (NSPredicate*)predicateWithModelID:(NSString*)identifier;

#pragma mark Keeping track of changes:

/**
 Timestamp of the last time when the object was saved into the managedObjectContext.
 If the object was saved due to a server update, lastClientModification will be equal to lastServerModification.
 */
@property (nonatomic) NSDate *lastClientModification;

/**
 Timestamp of the last modification as indicated by the server.
 */
@property (nonatomic) NSDate *lastServerModification;

#pragma mark Reading and writing content:

/**
 Array of data types the object can handle
 */
+ (NSArray*)acceptedDataTypes;

/**
 An NSData object with the contents of the object in the requested format
 */
- (NSData*)contentWithDataType:(FFEDataType)type;

/**
 Fills the object with contents from an NSData object in the indicated format
 */
- (void)fillWithData:(NSData*)data ofType:(FFEDataType)type;

@end
