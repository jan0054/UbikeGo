//
//  NearbyStationCellTableViewCell.h
//  UbikeGo
//
//  Created by csjan on 7/7/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NearbyStationCellTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *navtime_label;
@property (strong, nonatomic) IBOutlet UILabel *navdistance_label;
@property (strong, nonatomic) IBOutlet UILabel *area_label;
@property (strong, nonatomic) IBOutlet UILabel *name_label;
@property (strong, nonatomic) IBOutlet UILabel *current_bikes_label;
@property (strong, nonatomic) IBOutlet UILabel *subtitle_label;

@end
