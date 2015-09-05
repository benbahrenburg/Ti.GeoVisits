Ti.UI.setBackgroundColor('#000');

var places = JSON.parse(Ti.App.Properties.getString('PLACE_TESTING',JSON.stringify([])));

var visits = require('ti.geovisits');
console.log("module is => " + visits);

console.log("Turning on debug");
visits.setDebug(true);

var helpers = {
	savePlaces : function(){
		Ti.App.Properties.setString('PLACE_TESTING',JSON.stringify(places));
		addRows();
	},
	getPlacesString : function(){
		return Ti.App.Properties.getString('PLACE_TESTING',JSON.stringify([]));
	},
	getPlaces : function(){
		return JSON.parse(helpers.getPlacesString());
	}
};

visits.addEventListener('started',function(e){
	try{
		console.log("Visits started");
		places.push({
			phase:'start',
			message:'Visit Started'
		});
		helpers.savePlaces();		
	}catch(err){
		alert('Failed in start ' + JSON.stringify(err));
	}
});

visits.addEventListener('stopped',function(e){
	try{
		console.log("Visits stopped");
		places.push({
			phase:'stop',
			message:'Visit Stopped'
		});
		helpers.savePlaces();			
	}catch(err){
		alert('Failed in stopped ' + JSON.stringify(err));
	}
});

visits.addEventListener('errored',function(e){
	try{
		console.log("Visits errored " + JSON.stringify(e));
		places.push({
			phase:'errored',
			message:JSON.stringify(e),
			raw:e
		});
		helpers.savePlaces();		
	}catch(err){
		alert('Failed in errored ' + JSON.stringify(err));
	}
});

visits.addEventListener('visited',function(e){
	try{
		console.log("Visits fired " + JSON.stringify(e));
		places.push({
			phase:'visited',
			message:'Visited: Lat:' + e.coords.latitude + ' lon:' + e.coords.longitude,
			raw:e
		});	
		helpers.savePlaces();	
	}catch(err){
		alert('Failed in visited ' + JSON.stringify(err));
	}
});

visits.addEventListener('authorized',function(e){
	try{
		console.log("Authorized fired " + JSON.stringify(e));
		places.push({
			phase:'authorized',
			message:'permissioned granted: ' + ((e.success) ? 'Yes':'No')
		});	
		helpers.savePlaces();	
	}catch(err){
		alert('Failed in visited ' + JSON.stringify(err));
	}
});

function addRows(){
	var twContents = [];
	if(places.length === 0){
		twContents.push({
			title:'On places recorded yet'
		});
	}else{
		for (var i=0; i < places.length; i++) {
			twContents.push({
				title: places[i].phase + " : " + places[i].message
			});	
		}; 
	}		
	tableView.setData(twContents);		
};

var win = Titanium.UI.createWindow({ 
    backgroundColor:'#fff'
});

var topContainer = Ti.UI.createView({
	top:40, height:60		
});
win.add(topContainer);

var btnCollect = Ti.UI.createButton({
	height:45, width:85, left:5, title:"Start"		
});
topContainer.add(btnCollect);
topContainer.add(Ti.UI.createLabel({
	text:'Ti.Visits Demo App. Press start & go outside to test',
	left:95
}));

var tableView = Ti.UI.createTableView({
	top:100, bottom:70, width:Ti.UI.FILL	
});
win.add(tableView);

var bottomContainer = Ti.UI.createView({
	bottom:0, height:60	
});
win.add(bottomContainer);

var btnShowLog = Ti.UI.createButton({
	height:45, width:85, left:5, title:"Show Log"	
});
bottomContainer.add(btnShowLog);

var btnClearLog = Ti.UI.createButton({
	height:45,width:85, left:150, title:"Clear Log"		
});
bottomContainer.add(btnClearLog);

var btnEmailLog = Ti.UI.createButton({
	height:45, width:85, right:5, title:"Email Log"	
});
bottomContainer.add(btnEmailLog);

var started = false;
btnCollect.addEventListener('click',function(e){	
	if(started){
		visits.stopMonitoring();			
	}else{
		visits.startMonitoring();
	}
	
	started = !(started);
	btnCollect.title  = (started) ? 'Stop' : 'Start';		
});

btnShowLog.addEventListener('click',function(e){
	alert(helpers.getPlacesString());
});

btnClearLog.addEventListener('click',function(e){
	places = [];
	helpers.savePlaces();
	addRows();
});

btnEmailLog.addEventListener('click',function(e){
	var displayText = helpers.getPlacesString();
	var emailDialog = Ti.UI.createEmailDialog();
	if (!emailDialog.isSupported()) {
		Ti.UI.createAlertDialog({
			title:'Error',
			message:'Email not available'
		}).show();
		return;
	}
	emailDialog.setSubject('Ti.Visit Testing');
	emailDialog.setMessageBody(displayText);
	emailDialog.open();
});

win.addEventListener('focus',function(){
	addRows();
});

win.addEventListener('open',function(){
	if(visits.isSupported()){
		setTimeout(function(){
			Ti.Geolocation.requestAuthorization(Ti.Geolocation.AUTHORIZATION_ALWAYS);		
		},1000);
	}else{
		alert('This functionality is not supported. Check your logs');	
	}
});

win.open();