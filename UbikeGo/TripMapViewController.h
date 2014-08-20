//
//  TripMapViewController.h
//  UbikeGo
//
//  Created by csjan on 8/15/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>


@interface TripMapViewController : UIViewController
@property (strong, nonatomic) IBOutlet MKMapView *trip_map;

@end
