//
//  ViewController.h
//  UbikeGo
//
//  Created by csjan on 7/2/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>
@class Language;

@interface ViewController : UIViewController<MKMapViewDelegate>
@property (strong, nonatomic) IBOutlet MKMapView *mainmap;
@property NSMutableDictionary *fullstationdict;
@property NSMutableArray *nearbystationarray;
@property (strong, nonatomic) IBOutlet UIToolbar *infobar;
@property (strong, nonatomic) IBOutlet UILabel *area_label;
@property (strong, nonatomic) IBOutlet UILabel *name_label;
@property (strong, nonatomic) IBOutlet UILabel *subtitle_label;
@property (strong, nonatomic) IBOutlet UILabel *main_number_label;
- (IBAction)refresh_action:(UIButton *)sender;
- (IBAction)center_action:(UIButton *)sender;
- (IBAction)navigate_action:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UILabel *navtime_label;
@property (strong, nonatomic) IBOutlet UILabel *navdistance_label;
@property (strong, nonatomic) IBOutlet UIToolbar *menubar;
- (IBAction)longpressonmap:(UILongPressGestureRecognizer *)sender;
- (IBAction)taponmap:(UITapGestureRecognizer *)sender;
- (IBAction)open_menu_action:(UIButton *)sender;
- (IBAction)open_map_action:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIView *nearby_list_view;
@property (strong, nonatomic) IBOutlet UITableView *nearby_list_table;
@property UIRefreshControl *pullrefresh;
@property (strong, nonatomic) IBOutlet UIView *setting_view;
- (IBAction)rate_app_action:(UIButton *)sender;
- (IBAction)email_us_action:(UIButton *)sender;
- (IBAction)tos_action:(UIButton *)sender;
- (IBAction)sharetofb_action:(UIButton *)sender;
- (IBAction)smallmenu_action:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIButton *refresh_outlet;
@property (strong, nonatomic) IBOutlet UIButton *smallmenu_outlet;
@property (strong, nonatomic) IBOutlet UIButton *center_outlet;
@property (strong, nonatomic) IBOutlet UIImageView *up_down_arrow__outlet;
- (IBAction)logo_button_action:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIButton *logo_button_outlet;
@property (strong, nonatomic) IBOutlet UIView *inapplogoview;
@property (strong, nonatomic) IBOutlet UIImageView *weatherimage;
@property (strong, nonatomic) IBOutlet UILabel *weatherlabel;
@property (strong, nonatomic) IBOutlet UIImageView *walker_image;
@property (strong, nonatomic) IBOutlet UIImageView *separator_line;
@property BOOL colorblindmode;
@property BOOL degreeunitisC;
- (IBAction)degree_unit_button_pressed:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIButton *degree_unit_button;
- (IBAction)colorblind_button_pressed:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIButton *colorblind_button;
- (IBAction)switch_lang_button_pressed:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIButton *switch_lang_button;
@property int currentlang;
@property (strong, nonatomic) IBOutlet UILabel *colorblind_state_label;
@property (strong, nonatomic) IBOutlet UILabel *currentlang_state_label;
@property (strong, nonatomic) IBOutlet UIImageView *coloblind_image;
@property (strong, nonatomic) IBOutlet UIImageView *currentlang_image;
@property UIImage *fullgreen;
@property UIImage *green;
@property UIImage *yellow;
@property UIImage *red;
@property UIImage *fullgreen_sel;
@property UIImage *green_sel;
@property UIImage *yellow_sel;
@property UIImage *red_sel;
@property UIImage *parking_green;
@property UIImage *parking_yellow;
@property UIImage *parking_red;
@property (strong, nonatomic) IBOutlet UILabel *parking_spot_label;
@property (strong, nonatomic) IBOutlet UIImageView *parking_image;
@property (strong, nonatomic) IBOutlet UITableView *trip_table;
@property NSArray *trip_list_array;
@property PFObject *selected_trip;
@property NSArray *selected_pois;
@property NSString *trip_name;
@property NSString *trip_name_en;
@property NSString *trip_description;
@property NSString *trip_description_en;
@property NSString *trip_duration;
@property NSString *trip_duration_en;
@property NSNumber *start_station;
@property NSNumber *end_station;
@property UIImage *tripheader;
@property CLLocationManager *locationManager;

@end
