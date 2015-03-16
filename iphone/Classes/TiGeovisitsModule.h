/**
 * Ti.GeoVisits
 *
 * Native access to iOS 8 CLVisit feature
 *
 * Created by Benjamin Bahrenburg (bencoding)
 * Copyright (c) 2015 Benjamin Bahrenburg (bencoding). All rights reserved.
 *
 */

#import "TiModule.h"
#import <CoreLocation/CoreLocation.h>
@interface TiGeovisitsModule : TiModule<CLLocationManagerDelegate>
{
    @private
    bool _isSupported;
    bool _debug;
    bool _runOnPermissionAdded;
    bool _authorizedStatus;
}

@property (nonatomic, strong) CLLocationManager * locManager;

@end
