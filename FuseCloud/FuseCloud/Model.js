var Observable = require("FuseJS/Observable");
var FuseCloud = require("FuseCloud/FuseCloud");
var FuseCloudModel = require("FuseCloud/FuseCloudModel");

function ModelCache(fetcherPromise) {
	var cache = { };
	this.getItem = function(id){
		var ret = Observable();
		if (id in cache) {
			return cache[id];
		} else {
			fetcherPromise(id).then(function(results) {
				if (results instanceof Array) {
					ret.replaceAll(results);
				} else {
					ret.value = results;
				}
			});
			cache[id] = ret;
		}
		return ret;
	};
	this.invalidateItem = function(id) {
		delete cache[id];
	};
}

function Invalidate(cache, item) {
	
}

function DelayedObservable(getter) {
	var ret = Observable();
	getter(ret);
	return ret;
}

var GetTracksForSearchTerm = function(term, emptyResultCallback) {
	return DelayedObservable(function(obs) {
		FuseCloud.fetchTracksForSearchTerm(term)
			.then(function(results) {
				if (results.length == 0) {
					emptyResultCallback();
				}
				obs.replaceAll(results);
			});
	});
};

var trackCache;
var GetTrackInfo = function() {
	trackCache = new ModelCache(FuseCloud.fetchTrackInfoForTrackId);
	return function(id) { return trackCache.getItem(id); };
}();

var GetTracksForUserId = function() {
	var cache = new ModelCache(FuseCloud.fetchTracksForUserId);
	return function(id) { return cache.getItem(id); };
}();


var GetUser = function() {
	var cache = new ModelCache(FuseCloud.fetchInfoForUserId);
	return function(id) { return cache.getItem(id); };
}();

var commentsCache;
var GetTrackComments = function() {
	commentsCache = new ModelCache(FuseCloud.fetchCommentsForTrackId);
	return function(id) { return commentsCache.getItem(id); };
}();

function InvalidateCommentsForTrack(trackId) {
	commentsCache.invalidateItem(trackId);
}

function PostNewComment(trackId,body) {
	return FuseCloud.postNewComment(trackId,body)
		.then(function(x) {
			return FuseCloudModel.CreateComment(x);
		});
}

function GetMe() {
	return DelayedObservable(function(obs) {
		FuseCloud.fetchMe()
			.then(function(me) {
				obs.value = me;
			});
	});
}

function GetIsLikingTrack(trackId) {
	return DelayedObservable(function(obs) {
		FuseCloud.isLikingTrack(trackId)
			.then(function(result) {
				obs.add(result);
			});
	});
}

var favoritesObs;
function GetFavorites() {
	return DelayedObservable(function(obs) {
		favoritesObs = obs;
		FuseCloud.fetchFavorites()
			.then(function(favorites) {
				obs.replaceAll(favorites);
			});
	});
}

function ReloadFavorites() {
	return FuseCloud.fetchFavorites()
		.then(function(favorites) {
			if (favoritesObs) {
				favoritesObs.replaceAll(favorites);
				return true;
			} else {
				return false;
			}
		});
}

function PostLikeTrack(trackId) {
	trackCache.invalidateItem(trackId);
	return FuseCloud.likeTrack(trackId);
}

function PostUnlikeTrack(trackId) {
	trackCache.invalidateItem(trackId);
	return FuseCloud.unlikeTrack(trackId);
}

module.exports = {
	GetTracksForUserId,
	GetTracksForSearchTerm,
	GetTrackInfo,
	GetUser,
	GetTrackComments,
	InvalidateCommentsForTrack,
	PostNewComment,
	GetMe,
	GetIsLikingTrack,
	PostLikeTrack,
	PostUnlikeTrack,
	GetFavorites,
	ReloadFavorites
};
