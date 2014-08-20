//
//  TripTableViewCell.h
//  UbikeGo
//
//  Created by csjan on 8/14/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TripTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *trip_image;
@property (strong, nonatomic) IBOutlet UILabel *trip_name;
@property (strong, nonatomic) IBOutlet UILabel *trip_duration;
@property (strong, nonatomic) IBOutlet UILabel *num_of_pois;

@end
