var Observable = require('FuseJS/Observable');
var Playlist = require("FuseCloud/Playlist");

var isInteracting = false;
var sliderValue = Observable(0.0);

Playlist.progress.addSubscriber(function(x) {
	if (isInteracting)
		return;
	var ret = x.value / Playlist.duration.value;
	sliderValue.value = ret;
});

function interacting() {
	if (endInteractionTimeout !== null) {
		clearTimeout(endInteractionTimeout);
	}
	isInteracting = true;
	Playlist.setIsInteracting(true);
}

endInteractionTimeout = null;
function endInteractionIn(ms) {
	endInteractionTimeout = setTimeout(function() {
		isInteracting = false;
	}, ms);
}

function seekToSliderValue() {
	if (sliderValue.value) {
		Playlist.seek(sliderValue.value);
	}
	Playlist.setIsInteracting(false);
	endInteractionIn(500);
}

sliderValue.onValueChanged(function(val) {
	if (isInteracting) {
		Playlist.setProgressNorm(val);
	}
});

module.exports = {
	seekToSliderValue : seekToSliderValue,
	interacting : interacting,
	isInteracting : isInteracting,
	sliderValue : sliderValue
};
