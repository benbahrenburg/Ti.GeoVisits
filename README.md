<h1>Ti.GeoVisits</h1>

Ti.GeoVisits allows you to use iOS 8 Visit functionality in your iOS Titanium app.
Access to iOS 8 [CLVisit](https://developer.apple.com/library/prerelease/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/index.html#//apple_ref/doc/uid/TP40007125-CH3-SW81) functionality.

Ti.GeoVisits raises the "visited" event when the user arrives or departs a new location as determined by iOS.

<h2>Before you start</h2>
* You need Titanium 3.5.0.GA or greater.
* This module has only been tested on iOS7+ and Android 4+

<h2>tiapp.xml update</h2>

When using this module you need the following added to your tiapp.xml

1. You need to create a location UIBackgroundModes key
2. You need to have the NSLocationAlwaysUsageDescription key with text expanding what you will be doing in the background

Below is a snippet showing the tiapp.xml updates you will need to make.

~~~
    <ios>
        <plist>
            <dict>
                <key>UIBackgroundModes</key>
                <array>
                    <string>location</string>
                </array>            
                <key>NSLocationAlwaysUsageDescription</key>
                <string>Will do something awesome in the background</string>
            </dict>
        </plist>
    </ios>
~~~

<h2>Setup</h2>

* You must be running iOS 8 or greater
* You must be using Ti SDK 3.5.0.GA or greater
* Compiled modulle available at [dist folder](https://github.com/benbahrenburg/Ti.GeoVisits/tree/master/dist) 
* Install the Ti.GeoVisits module. If you need help here is a "How To" [guide](https://wiki.appcelerator.org/display/guides/Configuring+Apps+to+Use+Modules). 
* You can now use the module via the commonJS require method, example shown below.

<pre><code>
//Add the core module into your project
var visits = require('ti.geovisits');

</code></pre>

Now we have the module installed and avoid in our project we can start to use the components, see the feature guide below for details.

<h2>Methods</h2>

The module contains only four methods. The goal is to keep the function of this module narrow.

<h4>isSupported</h4>

Indicates of the module is supported

Method returns true or false

<b>Example</b>
~~~
var visits = require('ti.geovisits');
var supported = visits.isSupported();
console.log("device is supported? " + (supported)? "Yes" : "No");
~~~

<h4>setDebug</h4>

Turns on/off debug functionality

<b>Example</b>
~~~
var visits = require('ti.geovisits');
console.log("Turn on Debug");
visits.setDebug(true);
console.log("Turn off Debug");
visits.setDebug(false);
~~~

<h4>startMonitoring</h4>

The <b>startMonitoring</b> method creates the background process that will monitor when the user visits or leaves a place.  Once monitoring has been started, the <b>started</b> event is fired.  During the monitoring process the <b>visited</b> event is fired when the device user arrives or departs a "place".
 
<b>Example</b>
~~~
var visits = require('ti.geovisits');
visits.startMonitoring();
~~~

<h4>stopMonitoring</h4>

The <b>stopMonitoring</b> method stops the monitoring process.  Once monitoring is stopped, the <b>stopped</b> event is fired.
 
<b>Example</b>
~~~
var visits = require('ti.geovisits');
visits.stopMonitoring();
~~~

<h2>Events</h2>
Since Ti.GeoVisits is a primarily a background service, events are used to communicate changes.  The following events are available off the root of the module.

<h4>started</h4>

The <b>started</b> event is fired when visit monitoring is first enabled.

<b>Example</b>
~~~
var visits = require('ti.geovisits');

visits.addEventListener('started',function(e){
	console.log(JSON.stringify(e));
});
~~~

<h4>stopped</h4>

The <b>stopped</b> event is fired when visit monitoring is stopped.

<b>Example</b>
~~~
var visits = require('ti.geovisits');

visits.addEventListener('stopped',function(e){
	console.log(JSON.stringify(e));
});
~~~

<h4>errored</h4>

The <b>errored</b> event is fired when visit monitoring encounters an error.  The event is provides a category and message.  These can be used to determine the root cause of the error generated.

<b>Example</b>
~~~
var visits = require('ti.geovisits');

visits.addEventListener('errored',function(e){
	console.log(JSON.stringify(e));
	if(e.category === "compatibility"){
		console.log("the device or configuration is not compatible with the module");
	}
	if(e.category === "permissions"){
		console.log("necessary permissions are missing or disabled");
	}	
	if(e.category === "exception"){
		console.log("a general exception happened");
	}		
});
~~~

<h4>authorized</h4>

The <b>authorized</b> event is fired geo location permissions have been granted or changed.

<b>Example</b>
~~~
var visits = require('ti.geovisits');

visits.addEventListener('authorized',function(e){
	console.log(JSON.stringify(e));
	if(e.success){
		console.log("We now have the permissions needed to run the module");
	}else{
		console.log("We are missing the permissions needed to do anything meaningful");
	}	
});
~~~

<h4>visited</h4>

The <b>visited</b> event is fired the device user arrives or departs from a place.

<b>Example</b>
~~~
var visits = require('ti.geovisits');

visits.addEventListener('visited',function(e){
	console.log(JSON.stringify(e));
	console.log("latitude:" + e.coords.latitude);
	console.log("longitude:" + e.coords.longitude);
	console.log("horizontalAccuracy:" + e.coords.horizontalAccuracy);
	if(e.hasOwnProperty("arrivalDate")){
		console.log("arrivalDate:" + String.formatDate(new Date(e.arrivalDate),"long"));
	}
	if(e.hasOwnProperty("departureDate")){
		console.log("departureDate:" + String.formatDate(new Date(e.departureDate),"long"));	
	}	
});
~~~

<h2>Testing</h2>

You might ask how do you test this module? The best approach is to use the example [app.js](https://github.com/benbahrenburg/Ti.GeoVisits/tree/master/example) and head outside and do some errands.  You can use the simulator's location settings, but my testing this did not result in a meaningful test environment.

<h2>Important Information</h2>

1. <b>When does the visited event fire?</b> Unfortunately Apple determines when a user arrives and departs a "place". In my testing I've found that is when you spent about 10-15 minutes without moving in a location.  Your mileage might verify so I encourage you to test and to read the Apple documentation on this feature.
2. <b>It does X in my app</b> As this wraps the native iOS components you will need to read the Apple documentation and test yourself.
3. <b>I need the module to do...</b>  I welcome [pull requests](https://help.github.com/articles/using-pull-requests/).
4. <b>I don't know how to code but need...</b> Most likely this module is not for you.

<h2>Licensing</h2>

This project is licensed under the OSI approved Apache Public License (version 2). For details please see the license associated with each project.

Developed by [Ben Bahrenburg](http://bahrenburgs.com) available on twitter [@bencoding](http://twitter.com/bencoding)

<h2>Learn More</h2>

<h3>Twitter</h3>

Please consider following the [@bencoding Twitter](http://www.twitter.com/bencoding) for updates and more about Titanium.

<h3>Blog</h3>

For module updates, Titanium tutorials and more please check out my blog at [bencoding.com](http://bencoding.com). 
