//
//  MapPOI.m
//  UbikeGo
//
//  Created by csjan on 8/22/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import "MapPOI.h"
@interface MapPOI ()

@end

@implementation MapPOI
@synthesize name;
@synthesize name_en;
@synthesize description;
@synthesize description_en;
@synthesize image;
@synthesize objid;
@synthesize poicord;

- (id)initWithName:(NSString*)poiname andname_en:(NSString *)poinameen anddescription:(NSString*)poidescription anddescription_en:(NSString*)poidescription_en andimage:(UIImage*)poiimage andcoordinate:(CLLocationCoordinate2D)coordinate andobjectid: (NSString*) objectid {
    if ((self = [super init])) {
        self.name = poiname;
        self.name_en = poinameen;
        self.description = poidescription;
        self.description_en = poidescription_en;
        self.image = poiimage;
        self.objid = objectid;
        self.poicord = coordinate;
    }
    return self;
}

- (NSString *)title
{
    return [NSString stringWithFormat:@"%@", self.name];
}


- (CLLocationCoordinate2D)coordinate
{
    return self.poicord;
}

- (MKMapItem*)mapItem
{
    NSDictionary *addressDict = @{@"name" : self.name};
    MKPlacemark *placemark = [[MKPlacemark alloc]
                              initWithCoordinate:self.coordinate
                              addressDictionary:addressDict];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = self.title;
    return mapItem;
}



@end
