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

@synthesize locManager;

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
    
    _debug = NO;
    _runOnPermissionAdded = NO;
    _isSupported = [TiUtils isIOS8OrGreater];
    _authorizedStatus = [self authorized];
    
    if(_isSupported)
    {
        if([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"])
        {
            if ([[[TiApp app] launchOptions] objectForKey:UIApplicationLaunchOptionsLocationKey])
            {
                [self startMonitoring:nil];
            }
        }
        else
        {
            NSLog(@"[ERROR] NSLocationAlwaysUsageDescription in our tiapp.xml is required");
            _isSupported = NO;
        }
    }
    else
    {
         NSLog(@"[ERROR] iOS 8 or greater required");
    }
    
}

-(void)shutdown:(id)sender
{
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

#pragma mark Our public methods

-(void)setDebug:(id)value
{
    ENSURE_UI_THREAD(setDebug, value);
    ENSURE_TYPE(value, NSNumber);
    _debug = [TiUtils boolValue:value];
}

-(NSNumber*)isSupported:(id)args
{
    return NUMBOOL(_isSupported);
}

-(NSNumber*)hasPermission:(id)args
{
    ENSURE_UI_THREAD(hasPermission,args);
    return NUMBOOL([self authorized]);
}

-(bool)authorized
{
    CLAuthorizationStatus currentPermissionLevel = [CLLocationManager authorizationStatus];
    return ((currentPermissionLevel == kCLAuthorizationStatusAuthorizedAlways) ||
            (currentPermissionLevel == kCLAuthorizationStatusAuthorized));
}

- (void)requestPermission
{
    if (locManager!=nil)
    {
        if([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"])
        {
            [locManager requestAlwaysAuthorization];
        }
        else
        {
            NSLog(@"[ERROR] The keys NSLocationAlwaysUsageDescription are not defined in your tiapp.xml.  Starting with iOS8 this is required.");
        }
    }
}

-(void) postError:(NSString*)category withMessage:(NSString*) message
{
    if ([self _hasListeners:@"errored"])
    {
        NSDictionary *errEvent = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(NO),@"success",
                                    category,@"category",
                                    message,@"message",
                                  nil];
        [self fireEvent:@"errored" withObject:errEvent];
    }
}

- (void)startMonitoring:(id)args
{
    //We need to be on the UI thread, or the Change event wont fire
    ENSURE_UI_THREAD(startMonitoring,args);
    
    if(_debug)
    {
        NSLog(@"[DEBUG] startMonitoring");
    }
    
    if(_isSupported == NO)
    {
        NSLog(@"[ERROR] is not supported");
        [self postError:@"compatibility" withMessage:@"Visits not supported on this device"];
        return;
    }

    if ([CLLocationManager locationServicesEnabled]== NO)
    {
        NSLog(@"[ERROR] Location Services not enabled");
        [self postError:@"permissions" withMessage:@"Location Services not enabled"];
        return;
    }
    
    _authorizedStatus = [self authorized];
    
    if(_authorizedStatus == NO)
    {
        if(_debug)
        {
            NSLog(@"[DEBUG] requesting permission");
        }
        
        _runOnPermissionAdded = YES;
        
        [self requestPermission];
        return;
    }
    
    [[self locationManager] startMonitoringVisits];
  
    if ([self _hasListeners:@"started"])
    {
        NSDictionary *startEvent = [NSDictionary dictionaryWithObjectsAndKeys:NUMBOOL(YES),@"success",nil];
        [self fireEvent:@"started" withObject:startEvent];
    }
    
}

- (void) stopMonitoring:(id)args
{
    ENSURE_UI_THREAD(stopMonitoring,args);
  
    if(_debug)
    {
        NSLog(@"[DEBUG] stopMonitoring");
    }
    
    [[self locationManager] stopMonitoringVisits];
    
    if ([self _hasListeners:@"stopped"])
    {
        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                               NUMBOOL(YES),@"success",nil];
        
        [self fireEvent:@"stopped" withObject:event];
    }    
}


-(CLLocationManager*)locationManager
{
    if (locManager!=nil)
    {
        return locManager;
    }
    
    if (locManager == nil)
    {
        locManager = [[CLLocationManager alloc] init];
        locManager.delegate = self;
        locManager.pausesLocationUpdatesAutomatically = NO;
        
        if([self authorized] == NO)
        {
            [self requestPermission];
        }
        
        NSString * purpose = [TiUtils stringValue:[self valueForUndefinedKey:@"purpose"]];
        if(purpose!=nil)
        {
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            if ([locManager respondsToSelector:@selector(setPurpose)])
            {
                [locManager setPurpose:purpose];
            }
        }
    }
    return locManager;
}


- (void)locationManager:(CLLocationManager *)manager
               didVisit:(CLVisit *)visit{
 
    if(_debug)
    {
        NSLog(@"[DEBUG] latitude as number: %@", [NSNumber numberWithDouble:visit.coordinate.latitude]);
        NSLog(@"[DEBUG] longitude as number: %@", [NSNumber numberWithDouble:visit.coordinate.longitude]);
        NSLog(@"[DEBUG] horizontalAccuracy as number: %@", [NSNumber numberWithDouble:visit.horizontalAccuracy]);
    }
    
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithDouble:visit.coordinate.latitude],@"latitude",
                                 [NSNumber numberWithDouble:visit.coordinate.longitude],@"longitude",
                                 [NSNumber numberWithDouble:visit.horizontalAccuracy],@"horizontalAccuracy",
                                 NUMBOOL(YES),@"success",
                                 nil];
    
    if(visit.arrivalDate != nil)
    {
        if(_debug)
        {
            NSLog(@"[DEBUG] arrivalDate is %@",visit.arrivalDate);
        }

        NSNumber * arrival = [NSNumber numberWithLongLong:(long long)([visit.arrivalDate timeIntervalSince1970] * 1000)];
        if([arrival doubleValue] > 1.0)
        {
            [data setObject:arrival forKey:@"arrivalDate"];
        }
        
    }

    if(visit.departureDate != nil)
    {
        if(_debug)
        {
            NSLog(@"[DEBUG] departureDate is %@",visit.departureDate);
        }
        
        NSNumber * departure = [NSNumber numberWithLongLong:(long long)([visit.departureDate timeIntervalSince1970] * 1000)];
        if([departure doubleValue] > 1.0)
        {
            [data setObject:departure forKey:@"departureDate"];
        }
    }
    
    if ([self _hasListeners:@"visited"])
    {
        [self fireEvent:@"visited" withObject:data];
    }
    
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self postError:@"exception" withMessage:[error localizedDescription]];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if(_authorizedStatus == YES)
    {
        if(_debug)
        {
            NSLog(@"[DEBUG] already authorized");
        }
        return;
    }
    
    if ([self _hasListeners:@"authorized"])
    {
        NSDictionary *eventOk = [NSDictionary dictionaryWithObjectsAndKeys:
                                         NUMBOOL((status == kCLAuthorizationStatusAuthorizedAlways ||
                                                  status == kCLAuthorizationStatusAuthorized)),@"success",nil];
        [self fireEvent:@"authorized" withObject:eventOk];
    }
    
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorized)
    {
        if(_runOnPermissionAdded)
        {
            if(_debug)
            {
                NSLog(@"[DEBUG] running startMonitoringVisits now we have correct permissions");
            }
            
            [self startMonitoring:nil];
        }
    }
    else
    {
        NSLog(@"[ERROR] does not have correct permissions");
        [self postError:@"permissions" withMessage:@"Does not have correct permissions"];
    }
}

//Force the calibration header to turn off
- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    return NO;
}

@end
