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
//  ATLEntry.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import "ATLEntry.h"

@implementation ATLEntry

#pragma mark - Core Data Environment

- (NSManagedObjectModel *)managedObjectModel
{
    return [[self.managedObjectContext persistentStoreCoordinator] managedObjectModel];
}

- (NSDictionary *)entities
{
	return [self.managedObjectModel entitiesByName];
}

#pragma mark - Core Data properties
@dynamic id_;
@dynamic lastClientModification;
@dynamic lastServerModification;

#pragma mark - FFESyncing methods

+ (NSString *)remotePath
{
    // To be overwritten by subclasses
    return nil;
}

- (NSString *)pathExtension
{
    return self.id_;
}

+ (NSPredicate *)predicateWithModelID:(NSString *)identifier
{
    return [NSPredicate predicateWithFormat:@"id_ == %@", identifier];
}

- (NSString *)modelID
{
    return self.id_;
}

- (void)setModelID:(NSString *)remoteID
{
    self.id_ = remoteID;
}

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

- (NSData *)contentWithDataType:(FFEDataType)type
{
    if (type == DataTypeJSON) {
        return [NSJSONSerialization dataWithJSONObject:self.contentDictionary options:0 error:NULL];
    } else {
        return nil;
    }
}

- (void)fillWithDictionary:(NSDictionary *)dictionary
{
    // To be overwritten by subclasses
}

- (NSDictionary *)contentDictionary
{
    // To be overwritten by subclasses
    return nil;
}

#pragma mark - Support for line groups

+ (NSString *)nameForGroup:(ATLLineGroup)group
{
    switch (group) {
        case groupIntercityNoord:
            return @"Noorderspoorweg";
        case groupIntercityZuid:
            return @"Zuiderspoorweg";
        case groupIntercityOost:
            return @"Oosterspoorweg";
        case groupIntercityHolland:
            return @"Hollandse Spoorweg";
        case groupIntercityBrabant:
            return @"Brabantse Spoorweg";
        case groupIntercityIJssel:
            return @"IJssel Spoorweg";
        case groupFriesland:
            return @"Friesland";
        case groupGroningen:
            return @"Groningen";
        case groupDrenthe:
            return @"Drenthe";
        case groupOverijssel:
            return @"Overijssel";
        case groupGelderland:
            return @"Gelderland";
        case groupFlevoland:
            return @"Flevoland";
        case groupUtrecht:
            return @"Utrecht";
        case groupNoordHolland:
            return @"Noord-Holland";
        case groupZuidHolland:
            return @"Zuid-Holland";
        case groupZeeland:
            return @"Zeeland";
        case groupNoordBrabant:
            return @"Noord-Brabant";
        case groupLimburg:
            return @"Limburg";
        default:
            return @"---";
    }
}

+ (NSString *)codeForGroup:(ATLLineGroup)group
{
    switch (group) {
        case groupIntercityNoord:
            return @"N";
        case groupIntercityZuid:
            return @"Z";
        case groupIntercityOost:
            return @"O";
        case groupIntercityHolland:
            return @"H";
        case groupIntercityBrabant:
            return @"B";
        case groupIntercityIJssel:
            return @"IJ";
        case groupFriesland:
            return @"FR";
        case groupGroningen:
            return @"GR";
        case groupDrenthe:
            return @"DR";
        case groupOverijssel:
            return @"OV";
        case groupGelderland:
            return @"GE";
        case groupFlevoland:
            return @"FL";
        case groupUtrecht:
            return @"UT";
        case groupNoordHolland:
            return @"NH";
        case groupZuidHolland:
            return @"ZH";
        case groupZeeland:
            return @"ZE";
        case groupNoordBrabant:
            return @"NB";
        case groupLimburg:
            return @"LI";
        default:
            return @"";
    }
}

#pragma mark - XML representation

- (NSString*)xmlString
{
    NSString *name = [[NSStringFromClass([self class]) substringFromIndex:3] lowercaseString];
    NSMutableString *theString = [[NSMutableString alloc] initWithCapacity:50];
    [theString appendFormat:@"<%@", name];
    [self appendAttributesToXMLString:theString];
    if (self.hasXMLData) {
        [theString appendString:@">\n"];
        [self appendDataToXMLString:theString];
        [theString appendFormat:@"</%@>\n", name];
    } else {
        [theString appendString:@"/>\n"];
    }
    return theString;
}

- (NSString *)xmlReferenceString
{
    return [NSString stringWithFormat:@"<%@ id=\"%@\"/>\n",
            NSStringFromClass([self class]), self.id_];
}

- (void)appendAttributesToXMLString:(NSMutableString *)output
{
    [output appendFormat:@" id=\"%@\"", self.id_];
}

- (BOOL)hasXMLData
{
    return YES;
}

- (void)appendDataToXMLString:(NSMutableString *)output
{
    // To be overwritten by subclasses
}

@end
