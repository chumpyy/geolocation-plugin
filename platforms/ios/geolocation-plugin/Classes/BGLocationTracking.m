//
//  BGLocationTracking.m
//  BGLocationTracking
//
//  Created by Alex Shmaliy on 8/20/13.
//  MIT Licensed
//

#import "BGLocationTracking.h"

#define LOCATION_MANAGER_LIFETIME_MAX (14 * 60) // in seconds
#define DISTANCE_FILTER_IN_METERS 10.0
#define MINIMUM_DISTANCE_BETWEEN_DIFFERENT_LOCATIONS 1.0 // in meters

@interface BGLocationTracking ()
    
- (void)initAndStartLocationManager;
    
    @property (strong, nonatomic) CDVInvokedUrlCommand *successCB;
    @property (strong, nonatomic) CDVInvokedUrlCommand *errorCB;
    @property (strong, nonatomic) NSDate *locationManagerCreationDate;
    
    @end


@implementation BGLocationTracking
    @synthesize locationManager, successCB, errorCB;
    @synthesize locationManagerCreationDate;
    
    
    
    
- (void)startUpdatingLocation:(CDVInvokedUrlCommand *)command {
    
    [self initAndStartLocationManager];
    NSUInteger argumentsCount = command.arguments.count;
    self.successCB = argumentsCount ? command.arguments[0] : nil;
    self.errorCB = (argumentsCount > 1) ? command.arguments[1] : nil;
}
    
    
    
- (void)initAndStartLocationManager {
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManagerCreationDate = [NSDate date];
    [self.locationManager setDelegate:self];
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    locationManager.distanceFilter = DISTANCE_FILTER_IN_METERS;
    locationManager.activityType = CLActivityTypeFitness;
    [locationManager startUpdatingLocation];
}
    
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"New Location: %@", [newLocation description]);
    [self callSuccessJSCalback:newLocation];
    if ([newLocation distanceFromLocation:oldLocation] >= MINIMUM_DISTANCE_BETWEEN_DIFFERENT_LOCATIONS) {
        [self callSuccessJSCalback:newLocation];
    }
    else {
        NSLog(@"New location is almost equal to old location. Ignore update");
    }
    
    // if location manager is very old, need to re-init
    NSDate *currentDate = [NSDate date];
    if ([currentDate timeIntervalSinceDate:self.locationManagerCreationDate] >= LOCATION_MANAGER_LIFETIME_MAX) {
        [self initAndStartLocationManager];
    }
}
    
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    [self callErrorJSCalback:error];
    
    [self initAndStartLocationManager];
}
    
- (void)callSuccessJSCalback:(CLLocation *)location {
    [self.webView stringByEvaluatingJavaScriptFromString:
     [NSString stringWithFormat:@"%@({ coords: { latitude: %f, longitude: %f}});", self.successCB, location.coordinate.latitude, location.coordinate.longitude ]];
}
    
- (void)callErrorJSCalback:(NSError *)error {
    [self.webView stringByEvaluatingJavaScriptFromString:
     [NSString stringWithFormat:@"%@({ message: '%@' });", self.errorCB, error.localizedDescription ]];
}
    
    @end
