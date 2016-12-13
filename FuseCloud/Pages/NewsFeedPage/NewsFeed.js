var FuseCloud = require("FuseCloud/FuseCloud");
var Observable = require('FuseJS/Observable');
var Login = require("FuseCloud/Login");
var Playlist = require("FuseCloud/Playlist");

var activities = Observable();

var next_href;
function fetchActivities(){
	return FuseCloud.fetchActivities()
		.then(function(ac){
			activities.replaceAll(ac.collection);
			next_href = ac.next_href;
		});
}


Login.isLoggedIn.addSubscriber(function(x){
	if (x.value) {
		fetchActivities();
	} else {
		activities.clear();
	}
});

function fetchMore(){
	if (next_href && next_href !== ""){
		FuseCloud.fetchNextActivities(next_href)
			.then(function(ac){
				activities.addAll(ac.collection);
				next_href = ac.next_href;
			});
	}
}

function pushSongDetails(arg){
	var newsFeedTracks = [];
	activities.forEach(function(x){
		if (x.type === "track" || x.type === "track-repost")
			newsFeedTracks.push(x.origin);
	});
	Playlist.setCurrentPlaylist(newsFeedTracks);
	Playlist.setCurrentTrackAndPlayIfDifferent(arg.data.origin);
	router.push("track", { });
}

var isLoading = Observable(false);
function reloadHandler(){
	console.log("ReloadHandler: Is logged in : " + Login.isLoggedIn.value);
	if (Login.isLoggedIn.value === true){
		isLoading.value = true;
		setTimeout(function(){ isLoading.value = false; }, 10000); //timeout of 10 sec.
		fetchActivities()
			.then(function(x){
				isLoading.value = false;
			});

	} else {
		console.log("Since it is false");
		isLoading.value = false;
	}
}
function loginLogoutClicked(){
	if (!Login.isLoggedIn.value)
		Login.login();
	else
		Login.logout();
}

module.exports = {
	activities : activities,
	fetchMore : fetchMore,
	isLoggedIn : Login.isLoggedIn,
	pushSongDetails : pushSongDetails,
	loginLogoutClicked : loginLogoutClicked,
	reloadHandler : reloadHandler,
	isLoading : isLoading
};
