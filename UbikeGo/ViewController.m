//
//  ViewController.m
//  UbikeGo
//
//  Created by csjan on 7/2/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import "ViewController.h"
#import "ISO8601DateFormatter.h"
#import <CommonCrypto/CommonDigest.h>
#import <RestKit/RestKit.h>
#import "RKStation.h"
#import "Station.h"
#import "MapStation.h"
#import "NearbyStationCellTableViewCell.h"
#import "RKWeather.h"

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface ViewController ()

@end

@implementation ViewController
MKRoute *routeDetails;
CLLocationCoordinate2D selected_station_cord;
bool nearybylistishidden;

@synthesize fullstationdict;
@synthesize nearbystationarray;
@synthesize pullrefresh;
@synthesize colorblindmode;
@synthesize degreeunitisC;
@synthesize currentlang;
@synthesize fullgreen;
@synthesize green;
@synthesize yellow;
@synthesize red;
@synthesize green_sel;
@synthesize fullgreen_sel;
@synthesize yellow_sel;
@synthesize red_sel;

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.mainmap.showsUserLocation=YES;
    
    self.walker_image.layer.cornerRadius=2;
    
    //get saved colorblind, degree unit, and language settings, then setup ui
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.colorblindmode = [defaults boolForKey:@"colorblindmode"];
    self.degreeunitisC = [defaults boolForKey:@"degreeunitisC"];
    self.currentlang = [defaults integerForKey:@"currentlang"];
    switch (self.currentlang) {
        case 1:
            [self.switch_lang_button setTitle:@"中文" forState:UIControlStateNormal];
            [self.switch_lang_button setTitle:@"中文" forState:UIControlStateHighlighted];
            self.currentlang_state_label.text = @"English";
            self.currentlang_image.image = [UIImage imageNamed:@"lang_en.png"];
            break;
        case 0:
            [self.switch_lang_button setTitle:@"English" forState:UIControlStateNormal];
            [self.switch_lang_button setTitle:@"English" forState:UIControlStateHighlighted];
            self.currentlang_state_label.text = @"中文";
            self.currentlang_image.image = [UIImage imageNamed:@"lang_ch.png"];
            break;
        default:
            break;
    }
    if (self.colorblindmode)
    {
        [self.colorblind_button setTitle:@"關" forState:UIControlStateNormal];
        [self.colorblind_button setTitle:@"關" forState:UIControlStateHighlighted];
        self.colorblind_state_label.text = @"色盲好讀模式";
        self.coloblind_image.image = [UIImage imageNamed:@"colorblind_on.png"];
    }
    else
    {
        [self.colorblind_button setTitle:@"開" forState:UIControlStateNormal];
        [self.colorblind_button setTitle:@"開" forState:UIControlStateHighlighted];
        self.colorblind_state_label.text = @"正常模式";
        self.coloblind_image.image = [UIImage imageNamed:@"colorblind_off.png"];
    }
    if (self.degreeunitisC)
    {
        [self.degree_unit_button setTitle:@"°F" forState:UIControlStateNormal];
        [self.degree_unit_button setTitle:@"°F" forState:UIControlStateHighlighted];
    }
    else
    {
        [self.degree_unit_button setTitle:@"°C" forState:UIControlStateNormal];
        [self.degree_unit_button setTitle:@"°C" forState:UIControlStateHighlighted];
    }

    
    //init data structure
    self.fullstationdict = [[NSMutableDictionary alloc] init];
    self.nearbystationarray = [[NSMutableArray alloc] init];
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSArray *stationsearch =[Station MR_findAllInContext:localContext];
    for (Station *station in stationsearch)
    {
        [self.fullstationdict setObject:station forKey:station.sid];
    }
    
    //styling
    self.infobar.barStyle = UIBarStyleDefault;
    self.infobar.opaque=NO;
    self.infobar.translucent=YES;
    
    self.menubar.barStyle = UIBarStyleDefault;
    self.menubar.opaque=NO;
    self.menubar.translucent=YES;
    self.menubar.layer.cornerRadius=3;
    
    [self setup_annotaion_image_mode];
    [self setupNearbyListAtLocation:self.mainmap.userLocation.coordinate];

    //nearby station list is initially hidden
    nearybylistishidden=YES;
    
    //Pull To Refresh Controls
    self.pullrefresh = [[UIRefreshControl alloc] init];
    [pullrefresh addTarget:self action:@selector(refreshctrl:) forControlEvents:UIControlEventValueChanged];
    [self.nearby_list_table addSubview:pullrefresh];
    
    [self getweatheronline];
    
    //Shadows
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.menubar.bounds];
    self.menubar.layer.masksToBounds = NO;
    self.menubar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menubar.layer.shadowOffset = CGSizeMake(0.0f, 3.0f);
    self.menubar.layer.shadowOpacity = 0.3f;
    self.menubar.layer.shadowPath = shadowPath.CGPath;
    
    UIBezierPath *shadowPathtwo = [UIBezierPath bezierPathWithRect:self.infobar.bounds];
    self.infobar.layer.masksToBounds = NO;
    self.infobar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.infobar.layer.shadowOffset = CGSizeMake(0.0f, 3.0f);
    self.infobar.layer.shadowOpacity = 0.3f;
    self.infobar.layer.shadowPath = shadowPathtwo.CGPath;
    
    UIBezierPath *shadowPaththree = [UIBezierPath bezierPathWithRect:self.nearby_list_view.bounds];
    self.nearby_list_view.layer.masksToBounds = NO;
    self.nearby_list_view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.nearby_list_view.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
    self.nearby_list_view.layer.shadowOpacity = 0.2f;
    self.nearby_list_view.layer.shadowPath = shadowPaththree.CGPath;
    
    UIBezierPath *shadowPathfour = [UIBezierPath bezierPathWithRect:self.setting_view.bounds];
    self.setting_view.layer.masksToBounds = NO;
    self.setting_view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.setting_view.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
    self.setting_view.layer.shadowOpacity = 0.2f;
    self.setting_view.layer.shadowPath = shadowPathfour.CGPath;

    UIBezierPath *shadowPathfive = [UIBezierPath bezierPathWithRect:self.inapplogoview.bounds];
    self.inapplogoview.layer.masksToBounds = NO;
    self.inapplogoview.layer.shadowColor = [UIColor blackColor].CGColor;
    self.inapplogoview.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
    self.inapplogoview.layer.shadowOpacity = 0.2f;
    self.inapplogoview.layer.shadowPath = shadowPathfive.CGPath;

    UIBezierPath *shadowPathsix = [UIBezierPath bezierPathWithRect:self.separator_line.bounds];
    self.separator_line.layer.masksToBounds = NO;
    self.separator_line.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.separator_line.layer.shadowOffset = CGSizeMake(1.0f, 0.0f);
    self.separator_line.layer.shadowOpacity = 1.0f;
    self.separator_line.layer.shadowPath = shadowPathsix.CGPath;
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    [self setup_annotaion_image_mode];
    [self center_on_taipei_and_refresh];
}

//ui layout
- (void) viewDidLayoutSubviews
{
    //initial start: hide the top menu and the bottom nearby station list
    self.nearby_list_view.frame = CGRectMake(0, 566, 320, 200);
    self.setting_view.frame = CGRectMake(0, 566, 320, 200);
    self.inapplogoview.frame = CGRectMake(0, 566, 320, 200);
    self.infobar.frame= CGRectMake(0, -90, 320, 90);
    self.menubar.frame= CGRectMake(0, -90, 320, 90);
    if( IS_IPHONE_5 )
    {}
    else
    {
        //special layout for 3.5 inch screen
        self.refresh_outlet.frame = CGRectMake(20, 404, 44, 44);
        self.smallmenu_outlet.frame = CGRectMake(138, 404, 44, 44);
        self.center_outlet.frame = CGRectMake(256, 404, 44, 44);
    }
}

//calculate color of the number label according to bike number
- (UIColor*) determine_color: (int) current
{
    if (!self.colorblindmode)
    {
        if (current>=5)
        {
            return [UIColor colorWithRed:81.0f/255.0f green:165.0f/255.0f blue:15.0f/255.0f alpha:1.0];
        }
        else if (current>=1)
        {
            return [UIColor colorWithRed:234.0f/255.0f green:139.0f/255.0f blue:0.0f/255.0f alpha:1.0];
        }
        else
        {
            return [UIColor colorWithRed:238.0f/255.0f green:72.0f/255.0f blue:35.0f/255.0f alpha:1.0];
        }

    }
    else
    {
        if (current>=5)
        {
            return [UIColor colorWithRed:862.0f/255.0f green:96.0f/255.0f blue:36.0f/255.0f alpha:1.0];
        }
        else if (current>=1)
        {
            return [UIColor colorWithRed:96.0f/255.0f green:75.0f/255.0f blue:7.0f/255.0f alpha:1.0];
        }
        else
        {
            return [UIColor colorWithRed:168.0f/255.0f green:40.0f/255.0f blue:19.0f/255.0f alpha:1.0];
        }
    }
    
    }

//center map on user and a 750 meter radius
-(void) center_on_user
{
    MKUserLocation *userLocation = self.mainmap.userLocation;
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance (
                                        userLocation.location.coordinate, 750, 750);
    [self.mainmap setRegion:region animated:YES];
}

//center map on user and a 1250 meter radius, also call refresh on the bike list
-(void) center_on_user_and_refresh
{
    MKUserLocation *userLocation = self.mainmap.userLocation;
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance (
                                        userLocation.location.coordinate, 1250, 1250);
    [self.mainmap setRegion:region animated:NO];
    [self setupDynamicList];
}

//used at app start, center on taipei central station and a 2250 meter radius, also refreshes the bike list
-(void) center_on_taipei_and_refresh
{
    double tpelat = 25.04778;
    double tpelon = 121.51722;
    CLLocationCoordinate2D taipei_center;
    taipei_center.latitude = tpelat;
    taipei_center.longitude = tpelon;
    
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance (taipei_center
                                        , 2250, 2250);
    [self.mainmap setRegion:region animated:NO];
    [self setupDynamicList];
}

//delegate method when user location changed
- (void)mapView:(MKMapView *)mapView
didUpdateUserLocation:
(MKUserLocation *)userLocation
{
    userLocation.title = @"";
}

//get bike numbers for all stations
- (void) setupDynamicList
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKStation class]];
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"iid":@"iid",
                                                  @"tot":@"tot",
                                                  @"sbi":@"sbi",
                                                  @"bemp":@"bemp"
                                                  }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodGET pathPattern:nil keyPath:@"stations" statusCodes:nil];
    NSURL *url = [NSURL URLWithString:@"http://app.tapgo.cc/api/youbike/1/station?type=s"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *nonce = [[NSUUID UUID] UUIDString];
    NSData *nonceData = [nonce dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Nonce = [nonceData base64EncodedStringWithOptions:0];
    
    ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
    formatter.includeTime = true;
    NSString *createdat = [formatter stringFromDate:[NSDate date]];
    
    [request setValue:@"OWIwNTgyYjU4MDQ5ZDJkMjg3NmI2Nzc0OThkNDM0" forHTTPHeaderField:@"x-appgo-appid"];
    [request setValue:base64Nonce forHTTPHeaderField:@"x-appgo-nonce"];
    [request setValue:createdat forHTTPHeaderField:@"x-appgo-createdat"];
    NSString *source = [nonce stringByAppendingString:[createdat stringByAppendingString:@"YjMzYzUyMmNmMDBkMWU1MmZmYzNlNGNlYTNjZjk2" ]];
    NSData *data = [source dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);
    NSData *digestData = [NSData dataWithBytes:(const void *)digest length:CC_SHA1_DIGEST_LENGTH];
    NSString *digestString = [digestData base64EncodedStringWithOptions:0];
    NSLog(@"digestString: %@", digestString);
    
    [request setValue:digestString forHTTPHeaderField:@"x-appgo-digest"];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        
        for (RKStation *apistation in result.array)
        {
            Station *station = [self.fullstationdict objectForKey:apistation.iid];
            station.total = apistation.tot;
            station.currentbikes = apistation.sbi;
            station.emptyslots = apistation.bemp;
            
            [self.fullstationdict setObject:station forKey:station.sid];
            
            NSDate *rightnow = [NSDate date];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:rightnow forKey:@"lastrefreshdate"];
            [defaults synchronize];
        }
        [self drawStationToMap];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Operation failed with error: %@", error);
    }];
    [operation start];
}

//get nearby stations and their bike numbers, centered at a coordinate
- (void) setupNearbyListAtLocation: (CLLocationCoordinate2D) coordinate
{
    double userlat = coordinate.latitude;
    double userlon = coordinate.longitude;
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKStation class]];
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"iid":@"iid",
                                                  @"tot":@"tot",
                                                  @"sbi":@"sbi",
                                                  @"bemp":@"bemp",
                                                  @"distance":@"distance"
                                                  }];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodGET pathPattern:nil keyPath:@"stations" statusCodes:nil];
    NSString *urlstr = [NSString stringWithFormat:@"http://app.tapgo.cc/api/youbike/1/station/%f/%f/3000?type=s", userlat, userlon];
    NSURL *url = [NSURL URLWithString:urlstr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *nonce = [[NSUUID UUID] UUIDString];
    NSData *nonceData = [nonce dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Nonce = [nonceData base64EncodedStringWithOptions:0];
    
    ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
    formatter.includeTime = true;
    NSString *createdat = [formatter stringFromDate:[NSDate date]];
    
    [request setValue:@"OWIwNTgyYjU4MDQ5ZDJkMjg3NmI2Nzc0OThkNDM0" forHTTPHeaderField:@"x-appgo-appid"];
    [request setValue:base64Nonce forHTTPHeaderField:@"x-appgo-nonce"];
    [request setValue:createdat forHTTPHeaderField:@"x-appgo-createdat"];
    NSString *source = [nonce stringByAppendingString:[createdat stringByAppendingString:@"YjMzYzUyMmNmMDBkMWU1MmZmYzNlNGNlYTNjZjk2" ]];
    NSData *data = [source dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);
    NSData *digestData = [NSData dataWithBytes:(const void *)digest length:CC_SHA1_DIGEST_LENGTH];
    NSString *digestString = [digestData base64EncodedStringWithOptions:0];
    NSLog(@"digestString: %@", digestString);
    
    [request setValue:digestString forHTTPHeaderField:@"x-appgo-digest"];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {

        [self.nearbystationarray removeAllObjects];
        
        for (RKStation *apistation in result.array)
        {
            Station *station = [self.fullstationdict objectForKey:apistation.iid];
            station.total = apistation.tot;
            station.currentbikes = apistation.sbi;
            station.emptyslots = apistation.bemp;
            station.distance = apistation.distance;
            [self.nearbystationarray addObject:station];
            
        }
        [self.nearby_list_table reloadData];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Operation failed with error: %@", error);
    }];
    [operation start];
}

- (void) drawStationToMap
{
    //remove any existing annotations from main map first
    for (id<MKAnnotation> annotation in self.mainmap.annotations) {
        [self.mainmap removeAnnotation:annotation];
    }
    for (id key in self.fullstationdict)
    {
        Station *station = [self.fullstationdict objectForKey:key];
        double latdbl = [station.lat doubleValue];
        double londbl = [station.lon doubleValue];
        int total = [station.total intValue];
        int current = [station.currentbikes intValue];
        int empty = [station.emptyslots intValue];
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latdbl;
        coordinate.longitude = londbl;
        MapStation *annotation = [[MapStation alloc] initWithName:station.name_ch area:station.description_ch district:station.district_ch total:total currentbikes:current emptyslots:empty coordinate:coordinate] ;
        [self.mainmap addAnnotation:annotation];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"longpressalert"])
    {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"在地圖任何一處長按可開啟選單"
                                                       delegate:self
                                              cancelButtonTitle:@"確定"
                                              otherButtonTitles:nil];
        [alert show];
        [defaults setObject:@"1" forKey:@"longpressalert"];
    }

}

- (void) removeannotations
{
    //remove any existing annotations from main map first
    for (id<MKAnnotation> annotation in self.mainmap.annotations) {
        [self.mainmap removeAnnotation:annotation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"MapStation";
    if ([annotation isKindOfClass:[MapStation class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [self.mainmap dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            //annotationView.canShowCallout = YES;
            
            UILabel *bikenum_label = [[UILabel alloc] initWithFrame:CGRectMake(9, 10 , 10, 10)];
            bikenum_label.backgroundColor = [UIColor clearColor];
            bikenum_label.textColor = [UIColor whiteColor];
            
            bikenum_label.font = [UIFont fontWithName:@"Helvetica Neue" size:7];
            bikenum_label.textAlignment = NSTextAlignmentCenter;
            bikenum_label.tag = 66;
            
            [annotationView addSubview:bikenum_label];
            
        } else {
            annotationView.annotation = annotation;
        }
        
        MapStation *somemapstation = annotation;
        if (somemapstation.currentbikes >= 5)
        {
            int total = somemapstation.currentbikes + somemapstation.emptyslots;
            float percentagefull = (float)somemapstation.currentbikes / (float) total;
            if (percentagefull > 0.5)
            {
                annotationView.image = self.fullgreen;
            }
            else
            {
                annotationView.image = self.green;
            }
        }
        else if (somemapstation.currentbikes >=1)
        {
            annotationView.image = self.yellow;
        }
        else if (somemapstation.currentbikes==0)
        {
            annotationView.image = self.red;
        }
        UILabel *bikenum = (UILabel *)[annotationView viewWithTag:66];
        if (somemapstation.currentbikes != 0)
        {
            bikenum.text = [NSString stringWithFormat:@"%d",somemapstation.currentbikes];
        }
        else
        {
            bikenum.text = @"";
        }

        
        return annotationView;
    }
    
    return nil;
}

- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if (![view.annotation isKindOfClass:[MKUserLocation class]])
    {
        [self.mainmap removeOverlays:self.mainmap.overlays];
        MapStation *somemapstation = view.annotation;
    
        self.name_label.text = somemapstation.name;
        self.area_label.text = somemapstation.district;
        selected_station_cord = somemapstation.stationCord;
        self.main_number_label.text = [NSString stringWithFormat:@"%d", somemapstation.currentbikes];
        self.subtitle_label.text = somemapstation.area;
        self.main_number_label.textColor = [self determine_color:somemapstation.currentbikes];
        self.parking_spot_label.text = [NSString stringWithFormat:@"%d",somemapstation.emptyslots];
        if (somemapstation.emptyslots>5)
        {
            self.parking_image.image = self.parking_green;
        }
        else if (somemapstation.emptyslots>0)
        {
            self.parking_image.image = self.parking_yellow;
        }
        else
        {
            self.parking_image.image = self.parking_red;
        }

        if (view.image == self.fullgreen)
        {
            UIImage * toImage = self.fullgreen_sel;
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }

        if (view.image == self.green)
        {
            UIImage * toImage = self.green_sel;
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        if (view.image == self.yellow)
        {
            UIImage * toImage = self.yellow_sel;
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        if (view.image == self.red)
        {
            UIImage * toImage = self.red_sel;
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            self.infobar.frame= CGRectMake(0, 0, 320, 90);
        }];
        [self routeUserToDestination:selected_station_cord withoverlay:NO];
    }
}

- (void) mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if (![view.annotation isKindOfClass:[MKUserLocation class]])
    {
        //[self.mainmap removeOverlays:self.mainmap.overlays];
        self.navdistance_label.text=@"";
        self.navtime_label.text = @"";
        
        if (view.image == self.fullgreen_sel)
        {
            UIImage * toImage = self.fullgreen;
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        if (view.image == self.green_sel)
        {
            UIImage * toImage = self.green;
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        if (view.image == self.yellow_sel)
        {
            UIImage * toImage = self.yellow;
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        if (view.image == self.red_sel)
        {
            UIImage * toImage = self.red;
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        

        [UIView animateWithDuration:0.3 animations:^{
            self.infobar.frame= CGRectMake(0, -90, 320, 90);
        }];
    }
}

- (void) routeUserToDestination: (CLLocationCoordinate2D) destinationcord withoverlay: (BOOL) drawoverlay
{
    MKDirectionsRequest *directionsRequest = [[MKDirectionsRequest alloc] init];
    [directionsRequest setSource:[MKMapItem mapItemForCurrentLocation]];
    MKPlacemark *destinationplacemark = [[MKPlacemark alloc] initWithCoordinate:destinationcord addressDictionary:nil];
    MKMapItem *destinationmapitem = [[MKMapItem alloc] initWithPlacemark:destinationplacemark];
    [directionsRequest setDestination:destinationmapitem];
    directionsRequest.transportType = MKDirectionsTransportTypeWalking;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (error)
        {
            NSLog(@"Error %@", error.description);
        }
        else
        {
            routeDetails = response.routes.lastObject;
            if (drawoverlay)
            {
                [self.mainmap addOverlay:routeDetails.polyline];
            }
            int minutes = floor(routeDetails.expectedTravelTime/60);
            //int seconds = trunc(routeDetails.expectedTravelTime - minutes * 60);
            self.navdistance_label.text = [NSString stringWithFormat:@"%d分鐘", minutes];
            int distance = (int)routeDetails.distance;
            self.navtime_label.text = [NSString stringWithFormat:@"%d公尺", distance];
        }
    }];
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer  * routeLineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:routeDetails.polyline];
    routeLineRenderer.strokeColor = [UIColor colorWithRed:61.0f/255.0f green:198.0f/255.0f blue:243.0f/255.0f alpha:1.0];
    routeLineRenderer.lineWidth = 3;
    return routeLineRenderer;
}

//refresh button on map
- (IBAction)refresh_action:(UIButton *)sender {
    [self setupDynamicList];
    [self getweatheronline];
}

//center button on map
- (IBAction)center_action:(UIButton *)sender {
    [self center_on_user];
}

//upper right corner navigate button
- (IBAction)navigate_action:(UIButton *)sender {
    [self routeUserToDestination:selected_station_cord withoverlay: YES];
}

//long press on map
- (IBAction)longpressonmap:(UILongPressGestureRecognizer *)sender {
    
    [self setupNearbyListAtLocation:self.mainmap.userLocation.coordinate];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.menubar.frame= CGRectMake(0, 0, 320, 90);
    }];
    [UIView animateWithDuration:0.3 animations:^{
        self.infobar.frame= CGRectMake(0, -90, 320, 90);
    }];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.nearby_list_view.frame = CGRectMake(0, 367, 320, 200);
    }];
    [self center_on_user];
    nearybylistishidden=NO;
    [self update_arrow_state];
}

//short press on map
- (IBAction)taponmap:(UITapGestureRecognizer *)sender {
    if (nearybylistishidden)
    {
        [self.mainmap removeOverlays:self.mainmap.overlays];
    }
    else
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.menubar.frame= CGRectMake(0, -90, 320, 90);
            self.setting_view.frame = CGRectMake(0, 566, 320, 477);
            self.nearby_list_view.frame = CGRectMake(0, 566, 320, 200);
            self.inapplogoview.frame = CGRectMake(0, 566, 320, 200);
        }];
        
        nearybylistishidden=YES;
    }
}

//upper left button (私房行程)
- (IBAction)open_menu_action:(UIButton *)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.setting_view.frame = CGRectMake(0, 566, 320, 477);
        self.inapplogoview.frame = CGRectMake(0, 367, 320, 200);
    }];
    [self update_arrow_state];
}

//pressed "附近站點" on upper right
- (IBAction)open_map_action:(UIButton *)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.setting_view.frame = CGRectMake(0, 566, 320, 477);
        self.inapplogoview.frame = CGRectMake(0, 566, 320, 200);
    }];
    [self update_arrow_state];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.nearbystationarray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Station *station = [self.nearbystationarray objectAtIndex:indexPath.row];
    NearbyStationCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"nearbystationcell"];
    cell.name_label.text = station.name_ch;
    cell.current_bikes_label.text = [NSString stringWithFormat:@"%d",[station.currentbikes intValue]];
    cell.current_bikes_label.textColor = [self determine_color:[station.currentbikes intValue]];
    cell.navdistance_label.text = [NSString stringWithFormat:@"%d公尺",[station.distance intValue]];
    cell.navtime_label.text = [NSString stringWithFormat:@"%d分鐘",[station.distance intValue]/80];
    cell.area_label.text = station.district_ch;
    cell.subtitle_label.text = station.description_ch;
    int empty = [station.emptyslots intValue];
    cell.parking_spot_label.text = [NSString stringWithFormat:@"%d",empty];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (empty >5)
    {
        cell.parking_image.image = self.parking_green;
    }
    else if (empty >0)
    {
        cell.parking_image.image = self.parking_yellow;
    }
    else
    {
        cell.parking_image.image = self.parking_red;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.mainmap removeOverlays:self.mainmap.overlays];
    Station *station = [self.nearbystationarray objectAtIndex:indexPath.row];
    CLLocationCoordinate2D stationcord;
    stationcord.latitude = [station.lat doubleValue];
    stationcord.longitude = [station.lon doubleValue];
    MKUserLocation *stationlocation = [[MKUserLocation alloc] init];
    stationlocation.coordinate = stationcord;
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance (
                                        stationlocation.coordinate, 750, 750);
    [self.mainmap setRegion:region animated:YES];
    [self routeUserToDestination:stationcord withoverlay:YES];
}


//called when pulling downward on the tableview
- (void)refreshctrl:(id)sender
{
    [self setupNearbyListAtLocation:self.mainmap.userLocation.coordinate];
    
    // End Refreshing
    [(UIRefreshControl *)sender endRefreshing];
}

//setting view, "rate us" button
- (IBAction)rate_app_action:(UIButton *)sender {
}

//setting view, "email us" button
- (IBAction)email_us_action:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto://csjan@tapgo.cc"]];
}

//setting view, "tos" button
- (IBAction)tos_action:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://tapgo.cc/tw/?page_id=1060"]];
}

//setting view, "share" button
- (IBAction)sharetofb_action:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:@"fb://profile/304427062990226"];
    [[UIApplication sharedApplication] openURL:url];
}

//mid hamburger button on map
- (IBAction)smallmenu_action:(UIButton *)sender {
    [self setupNearbyListAtLocation:self.mainmap.userLocation.coordinate];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.menubar.frame= CGRectMake(0, 0, 320, 90);
    }];
    [UIView animateWithDuration:0.3 animations:^{
        self.infobar.frame= CGRectMake(0, -90, 320, 90);
    }];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.nearby_list_view.frame = CGRectMake(0, 367, 320, 200);
    }];
    [self center_on_user];
    nearybylistishidden=NO;
    [self update_arrow_state];
}

//tap ubike logo on top mid
- (IBAction)logo_button_action:(UIButton *)sender {
    
    
    if (self.setting_view.frame.origin.y==566)
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.setting_view.frame = CGRectMake(0, 90, 320, 477);
            self.inapplogoview.frame = CGRectMake(0, 566, 320, 200);
        }];
    }
    else if (self.setting_view.frame.origin.y==90)
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.setting_view.frame = CGRectMake(0, 566, 320, 477);
            self.inapplogoview.frame = CGRectMake(0, 566, 320, 200);
        }];
        
    }
    
    [self update_arrow_state];

}

//determines the state of the green arrow next to the logo
- (void) update_arrow_state
{
    if (self.setting_view.frame.origin.y==566)
    {
        self.up_down_arrow__outlet.image = [UIImage imageNamed:@"arrow_down.png"];
    }
    else if (self.setting_view.frame.origin.y==90)
    {
        self.up_down_arrow__outlet.image = [UIImage imageNamed:@"arrow_up.png"];
    }
}

//grab weather data from openweathermap
- (void) getweatheronline
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKWeather class]];
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"weather":@"weather",
                                                  @"main":@"main"
                                                  }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodGET pathPattern:nil keyPath:@"" statusCodes:nil];
    
    NSString *unit = @"metric";
    NSString *lang = @"zh_tw";
    if (!self.degreeunitisC)
    {
        unit = @"imperial";
    }
    switch (self.currentlang) {
        case 0:
            break;
        case 1:
            lang = @"en";
            break;
        default:
            break;
    }
    
    NSString *urlstr = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?q=Taipei&lang=%@&units=%@", lang, unit];
    NSURL *url = [NSURL URLWithString:urlstr];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        
        for (RKWeather *weatherresult in result.array)
        {
            NSArray *mainarray = weatherresult.weather;
            NSDictionary *weatherdict = weatherresult.main;
            NSDictionary *mainarraydict = [mainarray objectAtIndex:0];
            NSString *iconname = [mainarraydict objectForKey:@"icon"];
            NSString *weather_desc = [mainarraydict objectForKey:@"description"];
            //NSString *temp = [weatherdict objectForKey:@"temp"];
            NSNumber *nstempnum = [weatherdict objectForKey:@"temp"];
            float tempfloat = [nstempnum floatValue];
            NSString *temp = [NSString stringWithFormat:@"%.01f", tempfloat];
            self.weatherimage.image = [UIImage imageNamed:iconname];
            if (self.degreeunitisC)
            {
                self.weatherlabel.text = [NSString stringWithFormat:@"%@°C %@",temp, weather_desc];
            }
            else
            {
                self.weatherlabel.text = [NSString stringWithFormat:@"%@°F %@",temp, weather_desc];
            }
            NSLog(@"WEATHER:%@,%@,%@",iconname,temp,weather_desc);
        }
        
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Operation failed with error: %@", error);
    }];
    [operation start];
}

//setting page, change weather degree unit
- (IBAction)degree_unit_button_pressed:(UIButton *)sender {
    self.degreeunitisC = !(self.degreeunitisC);
    [self getweatheronline];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.degreeunitisC forKey:@"degreeunitisC"];
    [defaults synchronize];
    if (self.degreeunitisC)
    {
        [self.degree_unit_button setTitle:@"°F" forState:UIControlStateNormal];
        [self.degree_unit_button setTitle:@"°F" forState:UIControlStateHighlighted];
    }
    else
    {
        [self.degree_unit_button setTitle:@"°C" forState:UIControlStateNormal];
        [self.degree_unit_button setTitle:@"°C" forState:UIControlStateHighlighted];
    }
}

//setting page, toggle colorblind mode
- (IBAction)colorblind_button_pressed:(UIButton *)sender {
    self.colorblindmode = !(self.colorblindmode);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.colorblindmode forKey:@"colorblindmode"];
    [defaults synchronize];
    
    if (self.colorblindmode)
    {
        [self.colorblind_button setTitle:@"關" forState:UIControlStateNormal];
        [self.colorblind_button setTitle:@"關" forState:UIControlStateHighlighted];
        self.colorblind_state_label.text = @"色盲好讀模式";
        self.coloblind_image.image = [UIImage imageNamed:@"colorblind_on.png"];
    }
    else
    {
        [self.colorblind_button setTitle:@"開" forState:UIControlStateNormal];
        [self.colorblind_button setTitle:@"開" forState:UIControlStateHighlighted];
        self.colorblind_state_label.text = @"正常模式";
        self.coloblind_image.image = [UIImage imageNamed:@"colorblind_off.png"];
    }
    
    [self setup_annotaion_image_mode];
    [self setupDynamicList];
}

//setting page, switch language
- (IBAction)switch_lang_button_pressed:(UIButton *)sender {
    switch (self.currentlang) {
        case 0:
            self.currentlang = 1;
            [self.switch_lang_button setTitle:@"中文" forState:UIControlStateNormal];
            [self.switch_lang_button setTitle:@"中文" forState:UIControlStateHighlighted];
            self.currentlang_state_label.text = @"English";
            self.currentlang_image.image = [UIImage imageNamed:@"lang_en.png"];
            break;
        case 1:
            self.currentlang = 0;
            [self.switch_lang_button setTitle:@"English" forState:UIControlStateNormal];
            [self.switch_lang_button setTitle:@"English" forState:UIControlStateHighlighted];
            self.currentlang_state_label.text = @"中文";
            self.currentlang_image.image = [UIImage imageNamed:@"lang_ch.png"];
            break;
        default:
            break;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.currentlang forKey:@"currentlang"];
    [defaults synchronize];
    [self getweatheronline];
    
}

//set up annotation images according to colorblind mode on/off
- (void) setup_annotaion_image_mode
{
    if (self.colorblindmode)
    {
        self.fullgreen = [UIImage imageNamed:@"cb_greenfull.png"];
        self.green = [UIImage imageNamed:@"cb_green.png"];
        self.yellow = [UIImage imageNamed:@"cb_yellow.png"];
        self.red = [UIImage imageNamed:@"cb_red.png"];
        self.fullgreen_sel = [UIImage imageNamed:@"cb_greenfull_sel.png"];
        self.green_sel = [UIImage imageNamed:@"cb_green_sel.png"];
        self.yellow_sel = [UIImage imageNamed:@"cb_yellow_sel.png"];
        self.red_sel = [UIImage imageNamed:@"cb_red_sel.png"];
        self.parking_green = [UIImage imageNamed:@"cb_parking_green.png"];
        self.parking_yellow = [UIImage imageNamed:@"cb_parking_yellow.png"];
        self.parking_red = [UIImage imageNamed:@"cb_parking_red.png"];
    }
    else
    {
        self.fullgreen = [UIImage imageNamed:@"greenfull.png"];
        self.green = [UIImage imageNamed:@"green.png"];
        self.yellow = [UIImage imageNamed:@"yellow.png"];
        self.red = [UIImage imageNamed:@"red.png"];
        self.fullgreen_sel = [UIImage imageNamed:@"greenfull_sel.png"];
        self.green_sel = [UIImage imageNamed:@"green_sel.png"];
        self.yellow_sel = [UIImage imageNamed:@"yellow_sel.png"];
        self.red_sel = [UIImage imageNamed:@"red_sel.png"];
        self.parking_green = [UIImage imageNamed:@"parking_green.png"];
        self.parking_yellow = [UIImage imageNamed:@"parking_yellow.png"];
        self.parking_red = [UIImage imageNamed:@"parking_red.png"];
    }

}






@end
