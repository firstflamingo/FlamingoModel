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
//  ATLOrganization.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import "ATLOrganization.h"
#import "ATLService.h"

@implementation ATLOrganization

@dynamic concessions;
@dynamic operatedServices;
@dynamic name;
@dynamic iconName;
@dynamic url;

#if TARGET_OS_IPHONE
- (UIImage *)icon
#else
- (NSImage *)icon
#endif
{
    if (self.iconName) {
#if TARGET_OS_IPHONE
        return [UIImage imageNamed:self.iconName];
#else
        id imageSource = (id)[[NSApplication sharedApplication] delegate];
        return [imageSource imageNamed:[NSString stringWithFormat:@"%@.png", self.iconName]];
#endif
    }
    return nil;
}

- (void)addRelation:(ATLEntry *)relation withKey:(NSString *)key
{
    if ([key isEqualToString:@"grantor"]) {
        if ([relation isKindOfClass:[ATLSeries class]]) {
            [self addConcessionsObject:(ATLService*)relation];
        }
    } else if ([key isEqualToString:@"operator"]) {
        if ([relation isKindOfClass:[ATLSeries class]]) {
            [self addOperatedServicesObject:(ATLService*)relation];
        }
    }
}

#pragma mark - XML representation

- (void)appendAttributesToXMLString:(NSMutableString *)output
{
    [super appendAttributesToXMLString:output];
    [output appendFormat:@" name=\"%@\"", self.name];
}

- (void)appendDataToXMLString:(NSMutableString *)output
{
    [super appendDataToXMLString:output];
    [output appendFormat:@"<icon>%@</icon>\n", self.iconName];
}

@end
