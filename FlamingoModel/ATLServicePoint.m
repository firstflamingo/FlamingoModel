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
//  ATLServicePoint.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 08-08-14.
//

#import "ATLServicePoint.h"
#import "ATLLocation.h"
#import "ATLService.h"
#import "ATLServiceRule.h"
#import "ATLStation.h"


@implementation ATLServicePoint

@dynamic km;
@dynamic upArrival;
@dynamic upDeparture;
@dynamic upPlatform;
@dynamic downArrival;
@dynamic downDeparture;
@dynamic downPlatform;
@dynamic options;
@dynamic destinationRules;
@dynamic location;
@dynamic noStopRules;
@dynamic originRules;
@dynamic service;


- (NSString *)upDescription
{
    NSString *arrivalString = stringFromMinutes(self.upArrival);
    NSString *departureString = stringFromMinutes(self.upDeparture);
    return [NSString stringWithFormat:@"<%@: %@|%@ A%@ V%@ [%u]>",
            NSStringFromClass([self class]), self.locationCode, self.upPlatform, arrivalString, departureString, self.options];
}

- (NSString *)downDescription
{
    NSString *arrivalString = stringFromMinutes(self.downArrival);
    NSString *departureString = stringFromMinutes(self.downDeparture);
    return [NSString stringWithFormat:@"<%@: %@|%@ A%@ V%@ [%u]>",
            NSStringFromClass([self class]), self.locationCode, self.downPlatform, arrivalString, departureString, self.options];
}

- (NSString *)locationCode
{
    return self.location.code;
}

- (NSString *)name
{
    if ([self.location isKindOfClass:[ATLStation class]]) {
        return [(ATLStation*)self.location name];
    } else {
        return self.location.id_;
    }
}

- (BOOL)referesToStation
{
    if ([self.location isKindOfClass:[ATLStation class]]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)infraDirection
{
    return [self.service infraDirectionAtIndex:[self.service indexOfServicePoint:self]];
}

- (void)setUpArrival:(ATLMinutes)arrival departure:(ATLMinutes)departure
{
    self.upArrival = arrival;
    self.upDeparture = departure;
}

- (void)setDownArrival:(ATLMinutes)arrival departure:(ATLMinutes)departure
{
    self.downArrival = arrival;
    self.downDeparture = departure;
}

- (void)clearSchedule
{
    self.upArrival = 0;
    self.upDeparture = 0;
    self.downArrival = 0;
    self.downDeparture = 0;
}

- (NSString *)xmlString
{
    NSMutableString *theString = [[NSMutableString alloc] initWithCapacity:50];
    [theString appendFormat:@"\t<routePoint km=\"%.3f\">\n\t\t", self.km];
    [self appendDataToXMLString:theString];
    [theString appendString:@"\t</routePoint>\n"];
    return theString;
}

- (NSString *)xmlItemReference
{
    NSString *name = [[NSStringFromClass([self.location class]) substringFromIndex:3] lowercaseString];
    return [NSString stringWithFormat:@"\t\t<%@ km=\"%.3f\" id=\"%@\"/>\n", name, self.km, self.location.id_];
}

- (NSString *)xmlUpSchedule
{
    NSString *arrivalString = stringFromMinutes(self.upArrival);
    NSString *departureString = stringFromMinutes(self.upDeparture);
    return [NSString stringWithFormat:@"\t\t<up A=\"%@\" V=\"%@\" O=\"%u\" P=\"%@\" S=\"%@\"/>\n",
            arrivalString, departureString, self.options, self.upPlatform, self.location.id_];
}

- (NSString *)xmlDownSchedule
{
    NSString *arrivalString = stringFromMinutes(self.downArrival);
    NSString *departureString = stringFromMinutes(self.downDeparture);
    return [NSString stringWithFormat:@"\t\t<down A=\"%@\" V=\"%@\" O=\"%u\" P=\"%@\" S=\"%@\"/>\n",
            arrivalString, departureString, self.options, self.downPlatform, self.location.id_];
}

- (void)appendDataToXMLString:(NSMutableString *)output
{
    [output appendString:self.location.xmlReferenceString];
}


@end
