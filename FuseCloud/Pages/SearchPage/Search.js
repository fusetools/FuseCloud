var Moment = require("moment");
var Model = require("FuseCloud/Model");
var Observable = require("FuseJS/Observable");
var Playlist = require("FuseCloud/Playlist");

var searchTerm = Observable("");
var searchTermView = Observable("");

function showEmptyResultNotification() {
	console.log("Search returned empty result");
}

var trackList = searchTerm
		.where(function(x) { return x.length > 0; })
		.map(function(x) {
			return Model.GetTracksForSearchTerm(x, showEmptyResultNotification);
		}).inner();

function performSearch() {
	if (searchTermView.value.length > 0) {
		searchTerm.value = searchTermView.value;
	}
}

function abortSearch() {
	trackList.clear();
	searchTermView.value = "";
}

function pushSongDetails(arg) {
	Playlist.setCurrentPlaylist(trackList._values);
	Playlist.setCurrentTrackAndPlayIfDifferent(arg.data);
	router.push("track", {});
}

module.exports = {
	searchTerm: searchTermView,
	trackList: trackList,
	pushSongDetails: pushSongDetails,
	performSearch: performSearch,
	abortSearch: abortSearch
};
