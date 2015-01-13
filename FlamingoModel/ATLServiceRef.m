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
//  ATLServiceRef.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 23-06-14.
//

#import "ATLServiceRef.h"
#import "ATLService.h"


@implementation ATLServiceRef

@dynamic previousService;
@dynamic nextService;

- (NSString *)destinationFor:(ATLService *)otherService
{
    if (otherService == self.previousService) {
        return self.nextService.destination;
    } else if (otherService == self.nextService) {
        return self.previousService.origin;
    } else {
        return @"--";
    }
}

- (NSString *)connectedCodeFor:(ATLService *)otherService
{
    NSString *code = nil;
    if (otherService == self.previousService) {
        code = self.nextService.shortName;
    } else if (otherService == self.nextService) {
        code = self.previousService.shortName;
    }
    if (!code) {
        return @"--";
    }
    return code;
}

@end
