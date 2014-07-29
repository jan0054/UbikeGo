//
//  InitialSetupViewController.h
//  UbikeGo
//
//  Created by csjan on 7/4/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InitialSetupViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *updatewheel;
- (IBAction)retry_action:(UIButton *)sender;
@property NSMutableDictionary *fullstationdict;
@end
