//
//  MapStation.m
//  UbikeGo
//
//  Created by csjan on 7/3/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import "MapStation.h"

@interface MapStation ()

@end

@implementation MapStation
@synthesize currentbikes;
@synthesize emptyslots;
@synthesize total;
@synthesize name;
@synthesize district;
@synthesize area;
@synthesize sid;
@synthesize stationCord;

- (id)initWithName:(NSString*)sname area:(NSString*)sarea district:(NSString*)sdistrict total:(int)stotal currentbikes:(int)scurrentbikes emptyslots:(int)semptyslots coordinate:(CLLocationCoordinate2D)scoordinate {
    if ((self = [super init])) {
        if ([sname isKindOfClass:[NSString class]]) {
            self.name = sname;
        } else {
            self.name = @"無站名";
        }
        self.area = sarea;
        self.district = sdistrict;
        self.total = stotal;
        self.currentbikes = scurrentbikes;
        self.emptyslots = semptyslots;
        self.stationCord = scoordinate;
    }
    return self;
}

- (NSString *)title {
    return [NSString stringWithFormat:@"%@", self.sid];
}

- (NSString *)subtitle {
    return [NSString stringWithFormat:@"%d / %d", self.currentbikes, self.total];
}

- (CLLocationCoordinate2D)coordinate {
    return self.stationCord;
}

- (MKMapItem*)mapItem {
    NSDictionary *addressDict = @{@"name" : self.name};
    
    MKPlacemark *placemark = [[MKPlacemark alloc]
                              initWithCoordinate:self.coordinate
                              addressDictionary:addressDict];
    
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = self.title;
    
    return mapItem;
}

@end