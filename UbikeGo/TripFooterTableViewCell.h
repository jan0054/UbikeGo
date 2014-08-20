//
//  TripFooterTableViewCell.h
//  UbikeGo
//
//  Created by csjan on 8/15/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TripFooterTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *bike_icon_image;
@property (strong, nonatomic) IBOutlet UILabel *footer_description;
@property (strong, nonatomic) IBOutlet UILabel *current_num;

@end
