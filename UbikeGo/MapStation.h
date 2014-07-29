//
//  MapStation.h
//  UbikeGo
//
//  Created by csjan on 7/3/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapStation : NSObject<MKAnnotation>

- (id)initWithName:(NSString*)name area:(NSString*)area district:(NSString*)district total:(int)total currentbikes:(int)currentbikes emptyslots:(int)emptyslots coordinate:(CLLocationCoordinate2D)coordinate;
- (MKMapItem*)mapItem;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *area;
@property (nonatomic, copy) NSString *district;
@property int total;
@property int currentbikes;
@property int emptyslots;
@property NSNumber *sid;
@property (nonatomic, assign) CLLocationCoordinate2D stationCord;

@end
