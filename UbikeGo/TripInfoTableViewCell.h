//
//  TripInfoTableViewCell.h
//  UbikeGo
//
//  Created by csjan on 8/15/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TripInfoTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *trip_name;
@property (strong, nonatomic) IBOutlet UILabel *trip_duration;
@property (strong, nonatomic) IBOutlet UILabel *trip_description;

@end
