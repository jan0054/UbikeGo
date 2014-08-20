//
//  TripViewController.h
//  UbikeGo
//
//  Created by csjan on 8/15/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>


@interface TripViewController : UIViewController<MKMapViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *trippoitable;
@property NSString *tripobjid;
@property NSArray *poiarray;
@property NSString *tripname;
@property NSString *tripdescription;
@property NSString *tripduration;
@property NSString *tripstart;
@property NSString *tripend;
@property int currentlang;
@property UIRefreshControl *pullrefresh;
@property BOOL colorblindmode;
@property NSMutableArray *poilocalarray;
@property NSMutableDictionary *fullstationdict;
@property (strong, nonatomic) IBOutlet MKMapView *tripmap;
@property (strong, nonatomic) IBOutlet UIButton *back_button;
- (IBAction)back_button_tapped:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIButton *switch_view_button;
- (IBAction)switch_view_button_tapped:(UIButton *)sender;
@property BOOL listup;
@property PFObject *tripobj;
@property NSArray *pois;
@property NSString *trip_name;
@property NSString *trip_name_en;
@property NSString *trip_description;
@property NSString *trip_description_en;
@property NSString *trip_duration;
@property NSString *trip_duration_en;
@property NSNumber *start_station;
@property NSNumber *end_station;
@property UIImage *tripheader;
@end
