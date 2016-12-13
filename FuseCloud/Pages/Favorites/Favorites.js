var Observable = require("FuseJS/Observable");
var FuseCloud = require("FuseCloud/FuseCloud");
var Login = require("FuseCloud/Login");
var Playlist = require("FuseCloud/Playlist");
var Model = require("FuseCloud/Model");

var asyncTracks;
var favoriteTracks = Login.isLoggedIn
		.map(function(x){
			if (x) {
				return Model.GetFavorites();
			} else {
				return Observable();
			}
		}).inner();

function pushSongDetails(arg){
	Playlist.setCurrentPlaylist(favoriteTracks._values);
	Playlist.setCurrentTrackAndPlayIfDifferent(arg.data);
	router.push("track", { });
}

var isLoading = Observable(false);
function reloadHandler(){
	if (Login.isLoggedIn.value === true){
		isLoading.value = true;
		setTimeout(function(){ isLoading.value = false; }, 10000); //timeout of 10 sec.
		Model.ReloadFavorites()
			.then(function(){
				isLoading.value = false;
			});
	} else {
		isLoading.value = false;
	}
}

function unlikeTrack(arg){
	Model.PostUnlikeTrack(arg.data.id)
		.then(function(t){
			favoriteTracks.removeWhere(function(item){
				return item.id === arg.data.id;
			});
			console.log("Done unliking track");
		}).catch(function(err){
			console.log("Problems unliking track: " + JSON.stringify(err));
		});

}
function loginLogoutClicked(){
	if (!Login.isLoggedIn.value) {
		Login.login();
	} else {
		Login.logout();
	}
}

module.exports = {
	favoriteTracks : favoriteTracks,
	pushSongDetails : pushSongDetails,
	reloadHandler : reloadHandler,
	isLoading : isLoading,
	loginLogoutClicked : loginLogoutClicked,
	unlikeTrack : unlikeTrack,
	isLoggedIn : Login.isLoggedIn
};
