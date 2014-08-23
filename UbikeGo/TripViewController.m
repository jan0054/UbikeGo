//
//  TripViewController.m
//  UbikeGo
//
//  Created by csjan on 8/15/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import "TripViewController.h"
#import "TripInfoTableViewCell.h"
#import "TripPOIAltTableViewCell.h"
#import "TripPOITableViewCell.h"
#import "TripFooterTableViewCell.h"
#import "ISO8601DateFormatter.h"
#import <CommonCrypto/CommonDigest.h>
#import <RestKit/RestKit.h>
#import "RKStation.h"
#import "Station.h"
#import "MapPOI.h"

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface TripViewController ()


@end

Station *starting_station;
Station *ending_station;
MKRoute *routeDetails;
NSMutableDictionary *poi_id_dict;
NSMutableDictionary *poiimg_id_dict;
BOOL poisareready;

@implementation TripViewController
@synthesize tripobjid;
@synthesize poiarray;
@synthesize currentlang;
@synthesize pullrefresh;
@synthesize colorblindmode;
@synthesize poilocalarray;
@synthesize fullstationdict;
@synthesize listup;
@synthesize tripobj;
@synthesize pois;
@synthesize trip_name;
@synthesize trip_name_en;
@synthesize trip_description;
@synthesize trip_description_en;
@synthesize trip_duration;
@synthesize trip_duration_en;
@synthesize start_station;
@synthesize end_station;
@synthesize  tripheader;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"RECEIVED POIS: %@", self.pois);
    
    self.tripmap.showsUserLocation=YES;
    self.listup = YES;
    poisareready = NO;
    
    //get the trip data
    [self setup_trip_list];
    [self setup_bike_status];
    
    //Pull To Refresh Controls
    self.pullrefresh = [[UIRefreshControl alloc] init];
    [pullrefresh addTarget:self action:@selector(refreshctrl:) forControlEvents:UIControlEventValueChanged];
    [self.trippoitable addSubview:pullrefresh];
    
    //language, colorblindmode setup
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.currentlang = [defaults integerForKey:@"currentlang"];
    self.colorblindmode = [defaults boolForKey:@"colorblindmode"];
    
    self.poilocalarray = [[NSMutableArray alloc] init];
    
    poi_id_dict = [[NSMutableDictionary alloc] init];
    poiimg_id_dict = [[NSMutableDictionary alloc] init];
    
}

- (void) viewDidLayoutSubviews
{
    //initial start:
    self.trippoitable.frame = CGRectMake(0, 20, 320, 548);
    
    if( IS_IPHONE_5 )
    {}
    else
    {
        //special layout for 3.5 inch screen
        
    }
}

//called when pulling downward on the tableview
- (void)refreshctrl:(id)sender
{
    //refresh code here
    poisareready = NO;
    [self setup_trip_list];
    [self setup_bike_status];
    //[self.trippoitable reloadData];
    //[self process_trip_route];
    NSLog(@"TABLE ROW COUNT:%d", self.poiarray.count+3);
    NSLog(@"TRIPINFO:%@,%@,%@", trip_name,trip_description,trip_duration);
    
    // End Refreshing
    [(UIRefreshControl *)sender endRefreshing];
}

//center map on provided coordinates
-(void) center_on_locationwithlat: (double) lat andlon: (double) lon
{
    CLLocationCoordinate2D location;
    location.latitude = lat;
    location.longitude = lon;
    
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance (location
                                        , 2250, 2250);
    [self.tripmap setRegion:region animated:NO];
}

//delegate method when user location changed
- (void)mapView:(MKMapView *)mapView
didUpdateUserLocation:
(MKUserLocation *)userLocation
{
    userLocation.title = @"";
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:tripheader];
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.frame = CGRectMake(10,10,300,100);
    
    return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 100;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.poilocalarray.count+3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==0)
    {
        return 100;
    }
    else if (indexPath.row==1)
    {
        return 66;
    }
    else if (indexPath.row==(self.poilocalarray.count+2))
    {
        return 66;
    }
    else if (indexPath.row % 2)
    {
        //odd
        return 132;
    }
    else
    {
        //even
        return 132;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //cell with trip name, desc, duration
    TripInfoTableViewCell *tripinfocell = [tableView dequeueReusableCellWithIdentifier:@"tripinfocell"];
    //cell with trip start and end bike station
    TripFooterTableViewCell *tripfootercellstart = [tableView dequeueReusableCellWithIdentifier:@"tripfootercell"];
    TripFooterTableViewCell *tripfootercellend = [tableView dequeueReusableCellWithIdentifier:@"tripfootercell"];
    //cell with poi stuff
    TripPOITableViewCell *trippoicell = [tableView dequeueReusableCellWithIdentifier:@"trippoicell"];
    //alternate layout of the poi cell
    TripPOITableViewCell *trippoialtcell = [tableView dequeueReusableCellWithIdentifier:@"trippoialtcell"];
    
    
    
    
    /*
    switch (self.currentlang) {
        case 0:
            
            break;
        case 1:

            break;
            
        default:

            break;
    }
    */
    
    
    if (indexPath.row==0)
    {
        tripinfocell.trip_name.text = trip_name;
        tripinfocell.trip_description.text = trip_description;
        tripinfocell.trip_duration.text = trip_duration;

        return tripinfocell;
    }
    else if (indexPath.row==1)
    {
        int bikes = [starting_station.currentbikes intValue];
        tripfootercellstart.current_num.text = [NSString stringWithFormat:@"%d", bikes];
        if (bikes<1)
        {
            tripfootercellstart.bike_icon_image.image = [UIImage imageNamed:@"square_red"];
        }
        else if (bikes<6)
        {
            tripfootercellstart.bike_icon_image.image = [UIImage imageNamed:@"square_yellow"];
        }
        else
        {
            tripfootercellstart.bike_icon_image.image = [UIImage imageNamed:@"square_green"];
        }
        tripfootercellstart.footer_description.text = starting_station.name_ch;
        return tripfootercellstart;
    }
    else if (indexPath.row==(self.poilocalarray.count+2))
    {
        int slots = [ending_station.emptyslots intValue];
        tripfootercellend.current_num.text = [NSString stringWithFormat:@"%d", slots];
        if (slots<1)
        {
            tripfootercellend.bike_icon_image.image = [UIImage imageNamed:@"square_red_parking"];
        }
        else if (slots<6)
        {
            tripfootercellend.bike_icon_image.image = [UIImage imageNamed:@"square_yellow_parking"];
        }
        else
        {
            tripfootercellend.bike_icon_image.image = [UIImage imageNamed:@"square_green_parking"];
        }
        tripfootercellend.footer_description.text = ending_station.name_ch;

        return tripfootercellend;
    }
    else if (indexPath.row % 2)
    {
        //odd
        NSDictionary *poidict = [self.poilocalarray objectAtIndex:indexPath.row-2];
        NSString *objid = [poidict objectForKey:@"objid"];
        trippoicell.poiimage.image = [poiimg_id_dict objectForKey:objid];
        
        switch (self.currentlang) {
            case 0:
                trippoicell.poiname.text = [poidict objectForKey:@"name"];
                trippoicell.poidescription.text = [poidict objectForKey:@"description"];
                break;
                
            case 1:
                trippoicell.poiname.text = [poidict objectForKey:@"name_en"];
                trippoicell.poidescription.text = [poidict objectForKey:@"description_en"];
                break;
                
            default:
                break;
        }
        return trippoicell;
    }
    else
    {
        //even
        NSDictionary *poidict = [self.poilocalarray objectAtIndex:indexPath.row-2];
        NSString *objid = [poidict objectForKey:@"objid"];
        trippoialtcell.poiimage.image = [poiimg_id_dict objectForKey:objid];
        
        switch (self.currentlang) {
            case 0:
                trippoialtcell.poiname.text = [poidict objectForKey:@"name"];
                trippoialtcell.poidescription.text = [poidict objectForKey:@"description"];
                break;
                
            case 1:
                trippoialtcell.poiname.text = [poidict objectForKey:@"name_en"];
                trippoialtcell.poidescription.text = [poidict objectForKey:@"description_en"];
                break;
                
            default:
                break;
        }

        return trippoialtcell;
    }
        
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}



//grab trip and poi info and images from parse
- (void) setup_trip_list
{
    NSLog(@"SETTING UP TRIP LIST");
    
    PFQuery *poitripquery = [PFQuery queryWithClassName:@"poi"];
    
    //build an array from the poi objects ids. used to order the list later
    NSMutableArray *poi_id_array = [[NSMutableArray alloc] init];
    for (PFObject *poi in pois)
    {
        [poi_id_array addObject:poi.objectId];
    }
    NSLog(@"ID ARRAY:%@", poi_id_array);
    
    [poitripquery whereKey:@"objectId" containedIn:poi_id_array];
    [poitripquery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"RETURNED:%@", objects);
        [poilocalarray removeAllObjects];
        for (PFObject *object in objects)
        {
            
            //gets the place of this object in the original ordering
            NSString *objid = object.objectId;
            int poi_order = [poi_id_array indexOfObject:objid];
            
            PFGeoPoint *poicord = object[@"location"];
            double lat = poicord.latitude;
            double lon = poicord.longitude;
            NSNumber *nslat = [NSNumber numberWithDouble:lat];
            NSNumber *nslon = [NSNumber numberWithDouble:lon];
            NSMutableDictionary *local_poi = [[NSMutableDictionary alloc] initWithObjectsAndKeys: object[@"name"],@"name",object[@"name_en"],@"name_en", object[@"description"],@"description", object[@"description_en"], @"description_en", nslat, @"lat", nslon, @"lon", objid, @"objid", nil];
            
            //insert or add the poi, according to the ordering
            if (poi_order > [poilocalarray count])
            {
                [poilocalarray addObject:local_poi];
            }
            else if (poi_order <= [poilocalarray count])
            {
                [poilocalarray insertObject:local_poi atIndex:poi_order];
            }
            
            BOOL islast = NO;
            if (self.poilocalarray.count == objects.count)
            {
                islast = YES;
                poisareready = YES;
            }
            [self setup_poi_images:object withobjectid:objid atindex:poi_order islast:islast];
        }
        [self.trippoitable reloadData];
        [self process_trip_route];
        [self drawPOIToMap];
        NSLog(@"DATA:%@", self.poilocalarray);
        NSLog(@"COUNT:%d", self.poilocalarray.count);
    }];
    
     /*
    PFQuery *tripquery = [PFQuery queryWithClassName:@"trip"];
    [tripquery getObjectInBackgroundWithId:self.tripobjid block:^(PFObject *object, NSError *error) {
        
        self.poiarray = [[NSArray alloc] initWithArray: object[@"pois"]];
        
        //query for poi -> query for poi image -> deal with the data in the image query completion block
        for (PFObject *poiobj in self.poiarray)
        {
            PFQuery *poiquery = [PFQuery queryWithClassName:@"poi"];
            [poiquery getObjectInBackgroundWithId:poiobj.objectId block:^(PFObject *object, NSError *error) {
                PFGeoPoint *poicord = object[@"location"];
                double lat = poicord.latitude;
                double lon = poicord.longitude;
                NSNumber *nslat = [NSNumber numberWithDouble:lat];
                NSNumber *nslon = [NSNumber numberWithDouble:lon];
                PFFile *poiimagefile = object[@"image"];
                [poiimagefile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                    if (!error) {
                        UIImage *poiimage = [UIImage imageWithData:imageData];
                        NSDictionary *local_poi = [[NSDictionary alloc] initWithObjectsAndKeys:poiimage,@"image", object[@"name"],@"name",object[@"name_en"],@"name_en", object[@"description"],@"description", object[@"description_en"], @"description_en", nslat, @"lat", nslon, @"lon", nil];
                        [self.poilocalarray addObject:local_poi];
                    }
                }];

            }];
            
        }
        
        trip_name = object[@"name"];
        trip_name_en = object[@"name_en"];
        trip_description = object[@"description"];
        trip_description_en = object[@"description_en"];
        trip_duration = object[@"duration"];
        trip_duration_en = object[@"duration_en"];
        
        NSString *startstr = object[@"start_station"];
        NSString *endstr = object[@"end_station"];
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        start_station = [f numberFromString:startstr];
        end_station = [f numberFromString:endstr];
        
        PFFile *tripimage = object[@"image"];
        [tripimage getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
            if (!error) {
                tripheader = [UIImage imageWithData:imageData];
            }
        }];
        
    }];
    */
}

- (void) setup_poi_images: (PFObject *) poiobject withobjectid: (NSString *) objid atindex: (int) index islast: (BOOL) islast
{
    NSLog(@"DRAWING IMG %d", index);
    PFFile *poiimagefile = poiobject[@"image"];
    [poiimagefile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            UIImage *poiimage = [UIImage imageWithData:imageData];
            [poiimg_id_dict setObject:poiimage forKey:objid];
            NSMutableDictionary *local_poi = [self.poilocalarray objectAtIndex:index];
            local_poi = [local_poi mutableCopy];
            [local_poi setObject:poiimage forKey:@"image"];
            [self.poilocalarray replaceObjectAtIndex:index withObject:local_poi];
            if (poisareready)
            {
                [self.trippoitable reloadData];
            }
            
            /*
            if (islast)
            {
                [self.trippoitable reloadData];
            }
            */
        }
    }];
}

//grab updated info on bike numbers (actually we only want info on start/end stations
- (void) setup_bike_status
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
            
        }
        starting_station = [self.fullstationdict objectForKey:start_station];
        ending_station = [self.fullstationdict objectForKey:end_station];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Operation failed with error: %@", error);
    }];
    [operation start];
}

- (void) drawPOIToMap
{
    //remove any existing annotations from the trip map first
    for (id<MKAnnotation> annotation in self.tripmap.annotations) {
        [self.tripmap removeAnnotation:annotation];
    }
    
    for (NSMutableDictionary *poiobj in self.poilocalarray)
    {
        double latdbl = [[poiobj objectForKey:@"lat"] doubleValue];
        double londbl = [[poiobj objectForKey:@"lon"] doubleValue];

        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latdbl;
        coordinate.longitude = londbl;
        UIImage *thepoiimage = [poiimg_id_dict objectForKey:[poiobj objectForKey:@"objid"]];
        MapPOI *annotation = [[MapPOI alloc] initWithName:[poiobj objectForKey:@"name"] andname_en:[poiobj objectForKey:@"name_en"] anddescription:[poiobj objectForKey:@"description"] anddescription_en:[poiobj objectForKey:@"description_en"] andimage:thepoiimage andcoordinate:coordinate andobjectid:[poiobj objectForKey:@"objid"]];
        [self.tripmap addAnnotation:annotation];
    }
}

- (void) removeannotations
{
    //remove any existing annotations from the trip map
    for (id<MKAnnotation> annotation in self.tripmap.annotations) {
        [self.tripmap removeAnnotation:annotation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"MapPOI";
    if ([annotation isKindOfClass:[MapPOI class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [self.tripmap dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            //annotationView.canShowCallout = YES;
            
            UILabel *poi_label = [[UILabel alloc] initWithFrame:CGRectMake(9, 10 , 50, 10)];
            poi_label.backgroundColor = [UIColor blackColor];
            poi_label.textColor = [UIColor whiteColor];
            
            poi_label.font = [UIFont fontWithName:@"Helvetica Neue" size:7];
            poi_label.textAlignment = NSTextAlignmentCenter;
            poi_label.tag = 66;
            
            [annotationView addSubview:poi_label];
            
        } else {
            annotationView.annotation = annotation;
        }
        MapPOI *somepoi = annotation;
        //annotationView.image = somepoi.image;
        annotationView.image = [UIImage imageNamed:@"grey_bike"];
        
        UILabel *poilabel = (UILabel *)[annotationView viewWithTag:66];
        poilabel.text = somepoi.name;
        
        return annotationView;
    }
    
    return nil;
}

- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if (![view.annotation isKindOfClass:[MKUserLocation class]])
    {
        //[self.tripmap removeOverlays:self.tripmap.overlays];
        MapPOI *somepoi = view.annotation;

        switch (self.currentlang) {
            case 0:
                break;
            case 1:
                break;
            default:
                break;
        }
        
        UIImage *toImage = view.image;
        [UIView transitionWithView:view
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        animations:^{
                            view.image = toImage;
                        } completion:nil];
        
    }
}

- (void) mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if (![view.annotation isKindOfClass:[MKUserLocation class]])
    {
        //[self.mainmap removeOverlays:self.mainmap.overlays];
        UIImage *toImage = view.image;
        [UIView transitionWithView:view
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        animations:^{
                            view.image = toImage;
                        } completion:nil];

    }
}



//route user from source to destination, and optionally draw the route on map
- (void) routeUserToDestination: (CLLocationCoordinate2D) destinationcord withSource: (CLLocationCoordinate2D) sourcecord withoverlay: (BOOL) drawoverlay
{
    MKDirectionsRequest *directionsRequest = [[MKDirectionsRequest alloc] init];
    //set source
    MKPlacemark *sourceplacemark = [[MKPlacemark alloc] initWithCoordinate:sourcecord addressDictionary:nil];
    MKMapItem *sourcemapitem = [[MKMapItem alloc] initWithPlacemark:sourceplacemark];
    [directionsRequest setSource:sourcemapitem];
    //set destination
    MKPlacemark *destinationplacemark = [[MKPlacemark alloc] initWithCoordinate:destinationcord addressDictionary:nil];
    MKMapItem *destinationmapitem = [[MKMapItem alloc] initWithPlacemark:destinationplacemark];
    [directionsRequest setDestination:destinationmapitem];
    //set transport type to walking (apple maps don't have cycling)
    directionsRequest.transportType = MKDirectionsTransportTypeWalking;
    //start the direction request with completion block
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
                [self.tripmap addOverlay:routeDetails.polyline];
            }
        }
    }];
}

//set styling for the rendered routes
-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer  * routeLineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:routeDetails.polyline];
    routeLineRenderer.strokeColor = [UIColor colorWithRed:61.0f/255.0f green:198.0f/255.0f blue:243.0f/255.0f alpha:1.0];
    routeLineRenderer.lineWidth = 3;
    return routeLineRenderer;
}

//grab list of pois and, starting from user location, request directions between each of them in order
- (void) process_trip_route
{
    //initial set of source and destination: userlocation and first poi
    CLLocationCoordinate2D source;
    CLLocationCoordinate2D destination;
    MKUserLocation *userLocation = self.tripmap.userLocation;
    source = userLocation.location.coordinate;
    NSDictionary *firstpoi = [self.poilocalarray objectAtIndex:0];
    NSNumber *nsdestlat = [firstpoi objectForKey:@"lat"];
    NSNumber *nsdestlon = [firstpoi objectForKey:@"lon"];
    double firstlat = [nsdestlat doubleValue];
    double firstlon = [nsdestlon doubleValue];
    [self center_on_locationwithlat:firstlat andlon:firstlon];
    
    for (NSDictionary *poidict in self.poilocalarray)
    {
        NSNumber *nsdestlat = [poidict objectForKey:@"lat"];
        NSNumber *nsdestlon = [poidict objectForKey:@"lon"];
        double destlat = [nsdestlat doubleValue];
        double destlon = [nsdestlon doubleValue];
        destination.latitude = destlat;
        destination.longitude = destlon;
        
        [self routeUserToDestination:destination withSource:source withoverlay:YES];
        
        source = destination;
    }
    
}

//"back" button that goes back to the main map screen, leaving trip mode
- (IBAction)back_button_tapped:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//switch between map and list of the trip
- (IBAction)switch_view_button_tapped:(UIButton *)sender {
    if (!self.listup)
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.trippoitable.frame = CGRectMake(0, 20, 320, 548);
        }];
        self.listup = YES;
        [self.switch_view_button setImage:[UIImage imageNamed:@"trip_map"] forState:UIControlStateNormal];
        [self.switch_view_button setImage:[UIImage imageNamed:@"trip_map"] forState:UIControlStateHighlighted];
        //[self.switch_view_button setTitle:@"地圖" forState:UIControlStateNormal];
        //[self.switch_view_button setTitle:@"地圖" forState:UIControlStateHighlighted];
    }
    else
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.trippoitable.frame = CGRectMake(0, 566, 320, 548);
        }];
        self.listup = NO;
        [self.switch_view_button setImage:[UIImage imageNamed:@"trip_list"] forState:UIControlStateNormal];
        [self.switch_view_button setImage:[UIImage imageNamed:@"trip_list"] forState:UIControlStateHighlighted];
        //[self.switch_view_button setTitle:@"列表" forState:UIControlStateNormal];
        //[self.switch_view_button setTitle:@"列表" forState:UIControlStateHighlighted];
    }
}



@end
