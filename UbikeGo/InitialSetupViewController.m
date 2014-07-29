//
//  InitialSetupViewController.m
//  UbikeGo
//
//  Created by csjan on 7/4/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import "InitialSetupViewController.h"
#import "ISO8601DateFormatter.h"
#import <CommonCrypto/CommonDigest.h>
#import <RestKit/RestKit.h>
#import "RKStation.h"
#import "Station.h"
#import "MapStation.h"


@interface InitialSetupViewController ()

@end
NSDate *lastupdatedate;
NSTimer *timer;
@implementation InitialSetupViewController
@synthesize fullstationdict;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

-(void) timedout
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"逾時"
                                                    message:@"無法更新站點資訊, 請檢查網路連線"
                                                   delegate:self
                                          cancelButtonTitle:@"重試"
                                          otherButtonTitles:nil];
    [alert show];

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // the user clicked OK
    if (buttonIndex == 0) {
        [self startupdating];
    }
}


-(void) exitupdate
{
    [timer invalidate];
    [self performSegueWithIdentifier:@"updatedonesegue" sender:self];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"lastupdatedate"])
    {
        [self startupdating];
    }
    else
    {
        lastupdatedate = [defaults objectForKey:@"lastupdatedate"];
        NSDate *rightnow = [NSDate date];
        int updatedays = [self daysBetween:rightnow and:lastupdatedate];
        if (updatedays>=7)
        {
            [self startupdating];
        }
        else
        {
            [self exitupdate];
        }
    }
}

-(void) startupdating
{
    timer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                     target:self
                                   selector:@selector(timedout)
                                   userInfo:nil
                                    repeats:NO];
    
    float rotations = -0.5;
    int duration = 10;
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 2.0;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    [self.updatewheel.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    [self setupFullStationList];

}

-(void) setupFullStationList
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKStation class]];
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"iid":@"iid",
                                                  @"lat":@"lat",
                                                  @"lng":@"lng",
                                                  @"sna":@"sna",
                                                  @"snaen":@"snaen",
                                                  @"sarea":@"sarea",
                                                  @"sareaen":@"sareaen",
                                                  @"ar":@"ar",
                                                  @"aren":@"aren"
                                                  }];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodGET pathPattern:nil keyPath:@"stations" statusCodes:nil];
    NSURL *url = [NSURL URLWithString:@"http://app.tapgo.cc/api/youbike/1/station"];
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
        [self.fullstationdict removeAllObjects];
        
        for (RKStation *apistation in result.array)
        {
            NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
            Station *station = [Station MR_createEntity];
            station.lat = apistation.lat;
            station.lon = apistation.lng;
            station.name_ch = apistation.sna;
            station.name_en = apistation.snaen;
            station.district_ch = apistation.sarea;
            station.district_en = apistation.sareaen;
            station.description_ch = apistation.ar;
            station.description_en = apistation.aren;
            station.sid = apistation.iid;
            
            [self.fullstationdict setObject:station forKey:station.sid];
            
            NSDate *rightnow = [NSDate date];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:rightnow forKey:@"lastupdatedate"];
            [defaults synchronize];
            
            [localContext MR_saveToPersistentStoreAndWait];
        }
        [self exitupdate];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Operation failed with error: %@", error);
    }];
    [operation start];
    
}


- (IBAction)retry_action:(UIButton *)sender {

}

- (int)daysBetween:(NSDate *)dt1 and:(NSDate *)dt2 {
    NSUInteger unitFlags = NSDayCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    return [components day]+1;
}


@end
