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
//  FFEAccount.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 29-04-14.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import "FFESyncing.h"

@protocol FFEAccountDelegate;

@interface FFEAccount : NSObject <FFESyncing>

// Object lifecycle:
- (instancetype)initWithDelegate:(id <FFEAccountDelegate>)delegate;
- (void)resetAccount;
@property (nonatomic, weak) id <FFEAccountDelegate> delegate;

// Managing te credential:
- (BOOL)hasUsername;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, readonly) NSURLCredential *credential;

// Account properties
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *email;

// Using Keychain:
void createKeychainItem(NSString *service, NSString *username, NSString *password);
NSString *getKeychainPassword(NSString *service, NSString *username);
void changeKeychainUsername(NSString *service, NSString *oldName, NSString *newName);
void changeKeychainPassword(NSString *service, NSString *username, NSString *newPassword);
void deleteKeychainItem(NSString *service, NSString *username);
NSString *randomPassword(int length);

@end

@protocol FFEAccountDelegate <NSObject>

@property (nonatomic, readonly) NSString *realm;
@property (nonatomic, readonly) NSString *serviceName;

@end