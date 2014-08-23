//
//  MapPOI.h
//  UbikeGo
//
//  Created by csjan on 8/22/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapPOI : NSObject<MKAnnotation>

- (id)initWithName:(NSString*)poiname andname_en:(NSString *)poinameen anddescription:(NSString*)poidescription anddescription_en:(NSString*)poidescription_en andimage:(UIImage*)poiimage andcoordinate:(CLLocationCoordinate2D)coordinate andobjectid: (NSString*) objectid;
- (MKMapItem*)mapItem;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, copy) NSString *name_en;
@property (nonatomic, copy) NSString *description_en;
@property (nonatomic, copy) UIImage *image;
@property (nonatomic, assign) CLLocationCoordinate2D poicord;
@property (nonatomic, copy) NSString *objid;

@end
