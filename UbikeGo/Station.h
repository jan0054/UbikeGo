//
//  Station.h
//  UbikeGo
//
//  Created by csjan on 7/7/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Station : NSManagedObject

@property (nonatomic, retain) NSNumber * sid;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSString * name_ch;
@property (nonatomic, retain) NSString * name_en;
@property (nonatomic, retain) NSString * district_ch;
@property (nonatomic, retain) NSString * district_en;
@property (nonatomic, retain) NSString * description_ch;
@property (nonatomic, retain) NSString * description_en;
@property (nonatomic, retain) NSNumber * total;
@property (nonatomic, retain) NSNumber * currentbikes;
@property (nonatomic, retain) NSNumber * emptyslots;
@property (nonatomic, retain) NSNumber * distance;

@end
