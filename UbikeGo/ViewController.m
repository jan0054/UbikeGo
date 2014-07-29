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

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.mainmap.showsUserLocation=YES;
    [self getweatheronline];

    //disable click logo, can enable in future if we need to
    self.logo_button_outlet.userInteractionEnabled=NO;
    //also hide the arrow
    self.up_down_arrow__outlet.hidden=YES;
    
    self.walker_image.layer.cornerRadius=2;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"colorblindmode"]==1)
    {
        [self.colorblind_outlet setOn:YES animated:YES];
        NSLog(@"ON LOAD: colorblindmode found to be on");
    }
    else
    {
        [self.colorblind_outlet setOn:NO animated:YES];
        NSLog(@"ON LOAD: colorblindmode found to be off");
    }
    
    self.fullstationdict = [[NSMutableDictionary alloc] init];
    self.nearbystationarray = [[NSMutableArray alloc] init];
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSArray *stationsearch =[Station MR_findAllInContext:localContext];
    for (Station *station in stationsearch)
    {
        [self.fullstationdict setObject:station forKey:station.sid];
    }
    
    self.infobar.barStyle = UIBarStyleDefault;
    self.infobar.opaque=NO;
    self.infobar.translucent=YES;
    
    self.menubar.barStyle = UIBarStyleDefault;
    self.menubar.opaque=NO;
    self.menubar.translucent=YES;
    self.menubar.layer.cornerRadius=3;
    
    [self setupNearbyListAtLocation:self.mainmap.userLocation.coordinate];

    nearybylistishidden=YES;
    
    //Pull To Refresh Controls
    self.pullrefresh = [[UIRefreshControl alloc] init];
    [pullrefresh addTarget:self action:@selector(refreshctrl:) forControlEvents:UIControlEventValueChanged];
    [self.nearby_list_table addSubview:pullrefresh];
    
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
    [self center_on_taipei_and_refresh];
}

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
        self.refresh_outlet.frame = CGRectMake(20, 404, 44, 44);
        self.smallmenu_outlet.frame = CGRectMake(138, 404, 44, 44);
        self.center_outlet.frame = CGRectMake(256, 404, 44, 44);
    }
}

//calculate color of the number label according to bike number
- (UIColor*) determine_color: (int) current
{
    if (current>=5)
    {
        return [UIColor colorWithRed:119.0f/255.0f green:190.0f/255.0f blue:67.0f/255.0f alpha:1.0];
    }
    else if (current>=1)
    {
        return [UIColor colorWithRed:246.0f/255.0f green:177.0f/255.0f blue:67.0f/255.0f alpha:1.0];
    }
    else
    {
        return [UIColor colorWithRed:238.0f/255.0f green:72.0f/255.0f blue:35.0f/255.0f alpha:1.0];
    }
}

-(void) center_on_user
{
    MKUserLocation *userLocation = self.mainmap.userLocation;
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance (
                                        userLocation.location.coordinate, 750, 750);
    [self.mainmap setRegion:region animated:YES];
}

-(void) center_on_user_and_refresh
{
    MKUserLocation *userLocation = self.mainmap.userLocation;
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance (
                                        userLocation.location.coordinate, 1250, 1250);
    [self.mainmap setRegion:region animated:NO];
    [self setupDynamicList];
}

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
            
        } else {
            annotationView.annotation = annotation;
        }
        
        MapStation *somemapstation = annotation;
        NSLog(@"DRAW ANNO VIEW:GREEN %@, %d", somemapstation.name, somemapstation.currentbikes);
        if (somemapstation.currentbikes >= 5)
        {
            annotationView.image = [UIImage imageNamed:@"green.png"];
            NSLog(@"DRAW ANNO VIEW:GREEN %@, %d", somemapstation.name, somemapstation.currentbikes);
        }
        else if (somemapstation.currentbikes >=1)
        {
            annotationView.image = [UIImage imageNamed:@"yellow.png"];
            NSLog(@"DRAW ANNO VIEW:YELLOW %@, %d", somemapstation.name, somemapstation.currentbikes);
        }
        else if (somemapstation.currentbikes==0)
        {
            annotationView.image = [UIImage imageNamed:@"red.png"];
            NSLog(@"DRAW ANNO VIEW:RED %@, %d", somemapstation.name, somemapstation.currentbikes);
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
        self.area_label.text = somemapstation.area;
        selected_station_cord = somemapstation.stationCord;
        self.main_number_label.text = [NSString stringWithFormat:@"%d", somemapstation.currentbikes];
        self.subtitle_label.text = [NSString stringWithFormat:@"單車: %d | 車位: %d", somemapstation.currentbikes, somemapstation.emptyslots];
        self.main_number_label.textColor = [self determine_color:somemapstation.currentbikes];
        NSLog(@"ANNOTATION BIKE NUM: %d", somemapstation.currentbikes);
        if (view.image == [UIImage imageNamed:@"green.png"])
        {
            UIImage * toImage = [UIImage imageNamed:@"greensel.png"];
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        if (view.image == [UIImage imageNamed:@"yellow.png"])
        {
            UIImage * toImage = [UIImage imageNamed:@"yellowsel.png"];
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        if (view.image == [UIImage imageNamed:@"red.png"])
        {
            UIImage * toImage = [UIImage imageNamed:@"redsel.png"];
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
        
        if (view.image == [UIImage imageNamed:@"greensel.png"])
        {
            UIImage * toImage = [UIImage imageNamed:@"green.png"];
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        if (view.image == [UIImage imageNamed:@"yellowsel.png"])
        {
            UIImage * toImage = [UIImage imageNamed:@"yellow.png"];
            [UIView transitionWithView:view
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            animations:^{
                                view.image = toImage;
                            } completion:nil];
        }
        if (view.image == [UIImage imageNamed:@"redsel.png"])
        {
            UIImage * toImage = [UIImage imageNamed:@"red.png"];
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

- (IBAction)refresh_action:(UIButton *)sender {
    [self setupDynamicList];
    [self getweatheronline];
}

- (IBAction)center_action:(UIButton *)sender {
    [self center_on_user];
}

- (IBAction)navigate_action:(UIButton *)sender {
    [self routeUserToDestination:selected_station_cord withoverlay: YES];
}

- (IBAction)longpressonmap:(UILongPressGestureRecognizer *)sender {
    NSLog(@"LONG PRESS");
    
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

- (IBAction)taponmap:(UITapGestureRecognizer *)sender {
    NSLog(@"short tap");
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

- (IBAction)open_menu_action:(UIButton *)sender {

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
    cell.area_label.text = station.description_ch;
    cell.subtitle_label.text = [NSString stringWithFormat:@"單車:%d | 車位:%d", [station.currentbikes intValue], [station.total intValue]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
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

- (IBAction)rate_app_action:(UIButton *)sender {
}

- (IBAction)email_us_action:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto://csjan@tapgo.cc"]];
}

- (IBAction)tos_action:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://tapgo.cc/tw/?page_id=1060"]];
}

- (IBAction)sharetofb_action:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:@"fb://profile/304427062990226"];
    [[UIApplication sharedApplication] openURL:url];

}

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
- (IBAction)logo_button_action:(UIButton *)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.setting_view.frame = CGRectMake(0, 566, 320, 477);
        self.inapplogoview.frame = CGRectMake(0, 367, 320, 200);
    }];
    [self update_arrow_state];
}

- (IBAction)colorblind_toggle:(UISwitch *)sender {
    if ([self.colorblind_outlet isOn])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:1 forKey:@"colorblindmode"];
        [defaults synchronize];
        NSLog(@"colorblind mode turned on");
    }
    else
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:0 forKey:@"colorblindmode"];
        [defaults synchronize];
        NSLog(@"colorblind mode turned off");
    }
}

//determines the state of the green arrow next to the logo
- (void) update_arrow_state
{
    if (self.inapplogoview.frame.origin.y==566)
    {
        self.up_down_arrow__outlet.image = [UIImage imageNamed:@"arrow_down.png"];
    }
    else if (self.inapplogoview.frame.origin.y==367)
    {
        self.up_down_arrow__outlet.image = [UIImage imageNamed:@"arrow_up.png"];
    }
}

- (void) getweatheronline
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKWeather class]];
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"weather":@"weather",
                                                  @"main":@"main"
                                                  }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodGET pathPattern:nil keyPath:@"" statusCodes:nil];
    NSURL *url = [NSURL URLWithString:@"http://api.openweathermap.org/data/2.5/weather?q=Taipei&lang=zh_tw&units=metric"];
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
            NSString *temp = [weatherdict objectForKey:@"temp"];
            self.weatherimage.image = [UIImage imageNamed:iconname];
            self.weatherlabel.text = [NSString stringWithFormat:@"%@度 %@",temp, weather_desc];
            NSLog(@"WEATHER:%@,%@,%@",iconname,temp,weather_desc);
        }
        
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Operation failed with error: %@", error);
    }];
    [operation start];
}

@end
