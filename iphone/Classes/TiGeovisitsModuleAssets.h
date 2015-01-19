/**
 * Ti.GeoVisits
 *
 * Native access to iOS 8 CLVisit feature
 *
 * Created by Benjamin Bahrenburg (bencoding)
 * Copyright (c) 2015 Benjamin Bahrenburg (bencoding). All rights reserved.
 *
 */

@interface TiGeovisitsModuleAssets : NSObject
{
}
- (NSData*) moduleAsset;
- (NSData*) resolveModuleAsset:(NSString*)path;

@end
