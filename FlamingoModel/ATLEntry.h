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
//  ATLEntry.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FFESyncing.h"

typedef enum {
    groupIntercityNoord,
    groupIntercityZuid,
    groupIntercityOost,
    groupIntercityHolland,
    groupIntercityBrabant,
    groupIntercityIJssel,
    groupFriesland,
    groupGroningen,
    groupDrenthe,
    groupOverijssel,
    groupGelderland,
    groupFlevoland,
    groupUtrecht,
    groupNoordHolland,
    groupZuidHolland,
    groupZeeland,
    groupNoordBrabant,
    groupLimburg,
    groupNeutral,
    groupStart,
    groupOneStep,
    groupMoreSteps,
    nrOfGroups
} ATLLineGroup;

@interface ATLEntry : NSManagedObject <FFESyncing>

// Core Data environment
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSDictionary *entities;

// Core Data properties
@property (nonatomic, retain) NSString *id_;
@property (nonatomic, retain) NSDate * lastClientModification;
@property (nonatomic, retain) NSDate * lastServerModification;

- (void)fillWithDictionary:(NSDictionary*)dictionary;
@property (nonatomic, readonly) NSDictionary *contentDictionary;

// Support for line groups
+ (NSString *)nameForGroup:(ATLLineGroup)group;
+ (NSString *)codeForGroup:(ATLLineGroup)group;

// XML representation
- (NSString*)xmlString;
- (NSString*)xmlReferenceString;
- (void)appendAttributesToXMLString:(NSMutableString*)output;
@property (nonatomic, readonly) BOOL hasXMLData;
- (void)appendDataToXMLString:(NSMutableString*)output;

@end

