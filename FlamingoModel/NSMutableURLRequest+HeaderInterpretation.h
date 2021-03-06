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
//  NSMutableURLRequest+HeaderInterpretation.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 07-05-14.
//

#import <Foundation/Foundation.h>
#import "FFESyncing.h"

@interface NSMutableURLRequest (HeaderInterpretation)

- (void)setContentType:(FFEDataType)type;
- (void)setAccept:(NSArray *)types;
- (void)setIfModifiedSince:(NSDate *)dateValue;
- (void)setIfUnmodifiedSince:(NSDate *)dateValue;

@end
