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
//  ATLSeries.h
//  FlamingoModel
//
//  Created by Berend Schotanus on 17-10-12.
//

#import "ATLEntry.h"

@class ATLOrganization, ATLRoute, ATLLocation, ATLServicePoint, ATLSeriesRef, ATLService;


@interface ATLSeries : ATLEntry

@property (nonatomic, retain) NSSet *seriesRefs;
@property (nonatomic, retain) NSSet *missionRules;

@property (nonatomic, strong) NSArray *upMissionRules;
@property (nonatomic, strong) NSArray *downMissionRules;

- (void)syncOffsets;

// XML representation
- (NSString*)xmlString;
- (NSString*)xmlReferenceString;

@end

@interface ATLSeries (CoreDataGeneratedAccessors)

- (void)addSeriesRefsObject:(ATLSeriesRef *)value;
- (void)removeSeriesRefsObject:(ATLSeriesRef *)value;
- (void)addSeriesRefs:(NSSet *)values;
- (void)removeSeriesRefs:(NSSet *)values;

- (void)addMissionRulesObject:(ATLSeriesRef *)value;
- (void)removeMissionRulesObject:(ATLSeriesRef *)value;
- (void)addMissionRules:(NSSet *)values;
- (void)removeMissionRules:(NSSet *)values;

@end
