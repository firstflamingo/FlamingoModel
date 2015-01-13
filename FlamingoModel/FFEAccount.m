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
//  FFEAccount.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 29-04-14.
//

#import "FFEAccount.h"

@interface FFEAccount ()

@property (nonatomic, readonly) NSString *clientModifiedKey;
@property (nonatomic, readonly) NSString *serverModifiedKey;
@property (nonatomic, readonly) NSString *usernameKey;
@property (nonatomic, readonly) NSString *nameKey;
@property (nonatomic, readonly) NSString *emailKey;

@end

@implementation FFEAccount

#pragma mark - Object lifecycle

- (instancetype)initWithDelegate:(id<FFEAccountDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)resetAccount
{
    deleteKeychainItem(self.delegate.serviceName, self.username);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.usernameKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.clientModifiedKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.serverModifiedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass([self class]), self.username];
}

#pragma mark - Managing the credential

- (BOOL)hasUsername
{
    return (BOOL)[[NSUserDefaults standardUserDefaults] objectForKey:self.usernameKey];
}

- (NSString *)usernameKey
{
    return [NSString stringWithFormat:@"%@-id", self.delegate.serviceName];
}

- (NSString *)username
{
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:self.usernameKey];
    if (!username) {
        username = @"new_user";
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:self.usernameKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        createKeychainItem(self.delegate.serviceName, username, randomPassword(20));
        self.lastClientModification = [NSDate date];
    }
    return username;
}

- (void)setUsername:(NSString *)newUsername
{
    NSString *oldUsername = [[NSUserDefaults standardUserDefaults] objectForKey:self.usernameKey];
    if (![newUsername isEqualToString:oldUsername]) {
        [[NSUserDefaults standardUserDefaults] setObject:newUsername forKey:self.usernameKey];
        changeKeychainUsername(self.delegate.serviceName, oldUsername, newUsername);
    }
}

- (NSString *)password
{
    return getKeychainPassword(self.delegate.serviceName, self.username);
}

- (void)setPassword:(NSString *)password
{
    changeKeychainPassword(self.delegate.serviceName, self.username, password);
}

- (NSURLCredential *)credential
{
    if (self.username) {
        return [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceForSession];
    } else {
        return nil;
    }
}

#pragma mark - Account properties

- (NSString *)nameKey
{
    return [NSString stringWithFormat:@"%@-name", self.delegate.serviceName];
}

- (NSString *)name
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:self.nameKey];
}

- (void)setName:(NSString *)name
{
    self.lastClientModification = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:self.nameKey];
}

- (NSString *)emailKey
{
    return [NSString stringWithFormat:@"%@-email", self.delegate.serviceName];
}

- (NSString *)email
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:self.emailKey];
}

- (void)setEmail:(NSString *)email
{
    self.lastClientModification = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:email forKey:self.emailKey];
}

#pragma mark - Connecting to a remote server with <FFESyncing>
#pragma mark model identity

+ (NSString *)remotePath
{
    return @"";
}

- (NSString *)pathExtension
{
    return self.modelID;
}

+ (NSPredicate *)predicateWithModelID:(NSString *)identifier
{
    return [NSPredicate predicateWithFormat:@"username == %@", identifier];
}

- (NSString *)modelID
{
    NSString *username = self.username;
    if ([username isEqualToString:@"new_user"]) {
        return nil;
    } else {
        return username;
    }
}

- (void)setModelID:(NSString *)remoteID
{
    self.username = remoteID;
}

#pragma mark keeping track of changes

- (NSString *)clientModifiedKey
{
    return [NSString stringWithFormat:@"%@-client-modified", self.delegate.serviceName];
}

- (NSDate *)lastClientModification
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:self.clientModifiedKey];
}

- (void)setLastClientModification:(NSDate *)lastClientModification
{
    [[NSUserDefaults standardUserDefaults] setObject:lastClientModification forKey:self.clientModifiedKey];
}

- (NSString *)serverModifiedKey
{
    return [NSString stringWithFormat:@"%@-server-modified", self.delegate.serviceName];
}

- (NSDate *)lastServerModification
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:self.serverModifiedKey];
}

- (void)setLastServerModification:(NSDate *)lastServerModification
{
    [[NSUserDefaults standardUserDefaults] setObject:lastServerModification forKey:self.serverModifiedKey];
}


#pragma mark Reading and writing content:

+ (NSArray *)acceptedDataTypes
{
    return @[@(DataTypeJSON)];
}

- (void)fillWithData:(NSData *)data ofType:(FFEDataType)type
{
    if (type == DataTypeJSON) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        NSAssert([dict isKindOfClass:[NSDictionary class]], @"Must be dictionary");
        [self fillWithDictionary:dict];
    }
}

- (void)fillWithDictionary:(NSDictionary *)dictionary
{
    NSString *username = dictionary[@"username"];
    if (username) {
        self.username = username;
    }
    NSString *name = dictionary[@"name"];
    if (name) {
        self.name = name;
    }
    NSString *email = dictionary[@"email"];
    if (email) {
        self.email = email;
    }
}

- (NSDictionary *)contentDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    if ([self.username isEqualToString:@"new_user"]) {
        dict[@"realm"] = self.delegate.realm;
        dict[@"token"] = self.password;
    } else {
        dict[@"username"] = self.username;
    }
    NSString *name = self.name;
    if (name) {
        dict[@"name"] = name;
    }
    NSString *email = self.email;
    if (email) {
        dict[@"email"] = email;
    }
    return dict;
}

- (NSData *)contentWithDataType:(FFEDataType)type
{
    if (type == DataTypeJSON) {
        return [NSJSONSerialization dataWithJSONObject:self.contentDictionary options:0 error:NULL];
    } else {
        return nil;
    }
}

@end

#pragma mark - Wrappers for Keychain item

void createKeychainItem(NSString *service, NSString *username, NSString *password)
{
    NSData* secret = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: service,
                            (__bridge id)kSecAttrAccount: username,
                            (__bridge id)kSecValueData: secret
                            };
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    if (status != errSecSuccess) {
        NSLog(@"Error %d while trying to add secure password", (int)status);
    }
}

NSString *getKeychainPassword(NSString *service, NSString *username)
{
    NSDictionary* query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: service,
                            (__bridge id)kSecAttrAccount: username,
                            (__bridge id)kSecReturnData: @YES
                            };
    CFDataRef data = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef*)&data);
    if (status == errSecSuccess) {
        return [[NSString alloc] initWithData:(__bridge_transfer NSData *)data encoding:NSUTF8StringEncoding];
    } else {
        NSLog(@"Error %d while trying to get secure password", (int)status);
        return nil;
    }
}

void changeKeychainUsername(NSString *service, NSString *oldName, NSString *newName)
{
    NSDictionary* query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: service,
                            (__bridge id)kSecAttrAccount: oldName,
                            };
    NSDictionary* changes = @{(__bridge id)kSecAttrAccount: newName};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
    if (status != errSecSuccess) {
        NSLog(@"Error %d while trying to change secure user", (int)status);
    }
}

void changeKeychainPassword(NSString *service, NSString *username, NSString *newPassword)
{
    NSData* secret = [newPassword dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: service,
                            (__bridge id)kSecAttrAccount: username,
                            };
    NSDictionary* changes = @{(__bridge id)kSecValueData: secret};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
    if (status != errSecSuccess) {
        NSLog(@"Error %d while trying to change secure password", (int)status);
    }
}

void deleteKeychainItem(NSString *service, NSString *username)
{
    NSDictionary* query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: service,
                            (__bridge id)kSecAttrAccount: username,
                            };
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status != errSecSuccess) {
        NSLog(@"Error %d while trying to delete secure password", (int)status);
    }
}

NSString *randomPassword(int length)
{
    NSMutableString *string = [NSMutableString stringWithCapacity:length];
    for (int index = 0; index < length; index++) {
        int character = arc4random_uniform(62) + 48;
        if (character > 57) {
            character += 7;
            if (character > 90) {
                character += 6;
            }
        }
        [string appendFormat:@"%c", character];
    }
    return string;
}
