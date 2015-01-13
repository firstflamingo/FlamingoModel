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
//  ATLRoutePosition.m
//  FlamingoModel
//
//  Created by Berend Schotanus on 03-03-12.
//

#import "ATLRoutePosition.h"
#import "ATLRoute.h"
#import "ATLLocation.h"

@implementation ATLRoutePosition

@dynamic km;
@dynamic latitude;
@dynamic longitude;
@dynamic location;
@dynamic route;


- (CLLocationCoordinate2D)coordinate
{
	return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

- (void)setCoordinate:(CLLocationCoordinate2D)coord
{
	self.latitude = coord.latitude;
	self.longitude = coord.longitude;
}

#pragma mark - XML representation

- (NSString *)xmlItemRef
{
    return [NSString stringWithFormat:@"\t<ATLRoutePosition km=\"%.3f\" lat=\"%.7f\" lon=\"%.7f\" location=\"%@\"/>\n",
            self.km, self.coordinate.latitude, self.coordinate.longitude, self.location.id_];
}

- (NSString *)xmlRouteRef
{
    return [NSString stringWithFormat:@"\t<ATLRoutePosition km=\"%.3f\" lat=\"%.7f\" lon=\"%.7f\" route=\"%@\"/>\n",
            self.km, self.coordinate.latitude, self.coordinate.longitude, self.route.id_];
}

@end
