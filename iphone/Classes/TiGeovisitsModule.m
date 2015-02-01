/**
 * Ti.GeoVisits
 *
 * Native access to iOS 8 CLVisit feature
 *
 * Created by Benjamin Bahrenburg (bencoding)
 * Copyright (c) 2015 Benjamin Bahrenburg (bencoding). All rights reserved.
 *
 */

#import "TiGeovisitsModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiApp.h"

@implementation TiGeovisitsModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"6a759615-bdfa-4134-ac91-dc7a039dd92a";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.geovisits";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
    
    _isSupported = [TiUtils isIOS8OrGreater];
    
    if ([[[TiApp app] launchOptions] objectForKey:UIApplicationLaunchOptionsLocationKey])
    {
        [self startMonitoringVisits:nil];
    }
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably

	// you *must* call the superclass
	[super shutdown:sender];
}


#pragma mark Internal Memory Management



-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

-(NSNumber*)isSupported:(id)args
{
    ENSURE_UI_THREAD(isSupported,args);
    return NUMBOOL(_isSupported);
}

-(NSNumber*)hasPermission:(id)args
{
    ENSURE_UI_THREAD(hasPermission,args);
    return NUMBOOL([self authorized]);
}

-(bool) authorized
{
    CLAuthorizationStatus currentPermissionLevel = [CLLocationManager authorizationStatus];
    return ((currentPermissionLevel == kCLAuthorizationStatusAuthorizedAlways) ||
            (currentPermissionLevel == kCLAuthorizationStatusAuthorized));
}
- (void) requestPermission
{
    if (_locationManager!=nil){
        if([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"]){
            [_locationManager requestAlwaysAuthorization];
        }else{
            NSLog(@"[ERROR] The keys NSLocationAlwaysUsageDescription are not defined in your tiapp.xml.  Starting with iOS8 this is required.");
        }
    }
}

- (void)startMonitoringVisits:(id)args
{
    //We need to be on the UI thread, or the Change event wont fire
    ENSURE_UI_THREAD(startMonitoringVisits,args);
    
    if(_isSupported == NO){
        NSLog(@"[ERROR] is not supported");
        return;
    }
    
    if([self authorized] == NO){
        NSLog(@"[ERROR] does not have correct permissions");
        return;
    }
    
    if ([CLLocationManager locationServicesEnabled]== NO)
    {
        NSLog(@"[ERROR] Location Services not enabled");
        return;
    }
    
    [self requestPermission];
    
    [[self locationManager] startMonitoringVisits];
  
    NSDictionary *startEvent = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES),@"success",nil];
    
    if ([self _hasListeners:@"start"])
    {
        [self fireEvent:@"start" withObject:startEvent];
    }
    
    //[self rememberSelf];
}

- (void) stopMonitoringVisits:(id)args
{
    ENSURE_UI_THREAD(stopMonitoringVisits,args);
    
     [[self locationManager] stopMonitoringVisits];
    
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                           NUMBOOL(YES),@"success",nil];
    
    if ([self _hasListeners:@"stop"])
    {
        [self fireEvent:@"stop" withObject:event];
    }    
}


-(CLLocationManager*)locationManager
{
    if (_locationManager!=nil)
    {
        return _locationManager;
    }
    
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        
        [self requestPermission];
        
        NSString * purpose = [TiUtils stringValue:[self valueForUndefinedKey:@"purpose"]];
        if(purpose!=nil){
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            if ([_locationManager respondsToSelector:@selector(setPurpose)]) {
                [_locationManager setPurpose:purpose];
            }
        }
    }
    return _locationManager;
}


- (void)locationManager:(CLLocationManager *)manager
               didVisit:(CLVisit *)visit{
 
    NSLog(@"[DEBUG] latitude as number: %@", [NSNumber numberWithDouble:visit.coordinate.latitude]);
    NSLog(@"[DEBUG] longitude as number: %@", [NSNumber numberWithDouble:visit.coordinate.longitude]);
    NSLog(@"[DEBUG] horizontalAccuracy as number: %@", [NSNumber numberWithDouble:visit.horizontalAccuracy]);
    
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithDouble:visit.coordinate.latitude],@"latitude",
                                 [NSNumber numberWithDouble:visit.coordinate.longitude],@"longitude",
                                 [NSNumber numberWithDouble:visit.horizontalAccuracy],@"horizontalAccuracy",
                                 NUMBOOL(YES),@"success",
                                 nil];
    if(visit.arrivalDate !=nil){
        NSLog(@"[DEBUG] arrivalDate is %@",visit.arrivalDate);
        [data setObject:[NSNumber numberWithLongLong:(long long)([visit.arrivalDate timeIntervalSince1970] * 1000)] forKey:@"arrivalDate"];
    }

    if(visit.departureDate !=nil){
        NSLog(@"[DEBUG] departureDate is %@",visit.departureDate);
        [data setObject:[NSNumber numberWithLongLong:(long long)([visit.departureDate timeIntervalSince1970] * 1000)] forKey:@"departureDate"];
    }
    
    if ([self _hasListeners:@"visited"])
    {
        [self fireEvent:@"visited" withObject:data];
    }
    
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    
    NSDictionary *errEvent = [NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription],@"error",
                              NUMINT((int)[error code]), @"code",
                              NUMBOOL(NO),@"success",nil];
    
    if ([self _hasListeners:@"error"])
    {
        [self fireEvent:@"error" withObject:errEvent];
    }
}

//Force the calibration header to turn off
- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    return NO;
}


@end
