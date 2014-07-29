//
//  RKStation.h
//  UbikeGo
//
//  Created by csjan on 7/3/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKStation : NSObject
//id
@property NSNumber *iid;
//total capacity
@property NSNumber *tot;
//current bikes
@property NSNumber *sbi;
//current empty slots
@property NSNumber *bemp;

@property NSNumber *lat;
@property NSNumber *lng;

//chinese name
@property NSString *sna;
//english name
@property NSString *snaen;
//chinese area
@property NSString *sarea;
//english area
@property NSString *sareaen;
//chinese description
@property NSString *ar;
//english description
@property NSString *aren;
@property NSNumber *distance;


@end
