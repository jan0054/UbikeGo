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

- (id)initWithName:(NSString*)sname nameen:(NSString *)snameen area:(NSString*)sarea areaen:(NSString*)sareaen district:(NSString*)sdistrict districten:(NSString*) sdistricten total:(int)stotal currentbikes:(int)scurrentbikes emptyslots:(int)semptyslots coordinate:(CLLocationCoordinate2D)coordinate;
- (MKMapItem*)mapItem;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *area;
@property (nonatomic, copy) NSString *district;
@property (nonatomic, copy) NSString *nameen;
@property (nonatomic, copy) NSString *areaen;
@property (nonatomic, copy) NSString *districten;
@property int total;
@property int currentbikes;
@property int emptyslots;
@property NSNumber *sid;
@property (nonatomic, assign) CLLocationCoordinate2D stationCord;

@end
