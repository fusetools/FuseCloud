var Observable = require('FuseJS/Observable');

var Timer = require('FuseJS/Timer');
var Moment = require('moment');
var Playlist = require("FuseCloud/Playlist");

var formatDuration = require("FuseCloud/DurationFormatter").formatDuration;

var durationView = Playlist.duration.map(function(x){
	return formatDuration(Moment.duration(Math.floor(x), 'seconds'));
});

var progressView = Playlist.progress.map(function(x){
	return formatDuration(Moment.duration(Math.floor(x), 'seconds'));
});

module.exports = {
	duration : durationView,
	progress : progressView
};
