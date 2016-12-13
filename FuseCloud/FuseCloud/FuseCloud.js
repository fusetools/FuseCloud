var baseUrl = "http://api.soundcloud.com/";
var Auth = require("FuseCloud/Auth");
var FuseCloudModel = require("FuseCloud/FuseCloudModel");
var Config = require("FuseCloudConfig");

function FuseCloud(api, args, m, body, access_token, baseUrl_) {
	var b = baseUrl;
	var isFullBase = false;
	if (baseUrl_){
		isFullBase = true;
		b = baseUrl_;
	}

	var url = b + api
			+ (isFullBase ? "&" : "?")
			+ "client_id=" + Config.clientId;
	if (access_token){
		url = url + "&" + "oauth_token=" + access_token;
	}
	for (var k in args){
		url = url + "&" + k + "=" + encodeURI(args[k]);
	}

	var requestData = {
		method : m
	};
	if (body !== null){
		requestData.headers = {
			'Content-Type': 'application/json'
		};
		requestData.body = JSON.stringify(body);
	}

	//console.log(m +  ": " + url);

	return fetch(url,requestData).then(function(res) {
		//console.log("URL in res: " + url);
		if (res.status === 200 || res.status === 201 || res.status === 303) {
			//console.log("200|201|303: Reqeust OK");
			return res.json();
		} else if (res.status === 400) { //400 Bad request
			//console.log("400: Bad request");
		} else if (res.status === 401) { //401 Unauthorized
			//console.log("401: Unauthorized request");
		} else if (res.status == 403) { //403 Forbidden
			//console.log("403: We do not have access to the requested resource");
		} else if (res.status === 404) { //404 Not Found
			//console.log("404: Not found (but this is hopefully expected");
		} else if (res.status === 422) { //422 something wrong with the contents of the request
			//console.log("The request have some missing or wrong data");
		} else if (res.status == 429) { //429 Too Many Requests
			//console.log("We are making too many requests");
		} else {
			//console.log("Other status code: " + res.status);
		}
		return null;
	}).catch(function(msg) {
		console.log("Failed to fetch: " + url + ", msg: " + msg);
	}); 
}

function FuseCloudGet(api,args,token) {
	return FuseCloud(api,args,"get",null,token);
}

function FuseCloudPut(api,args,token) {
	return FuseCloud(api,args,"put",null,token)
		.catch(function(msg){
			console.log("Failed to soundcloudput : " + msg);
		});
}

function FuseCloudPost(api,args,body,token) {
	return FuseCloud(api,args,"post",body,token)
		.catch(function(msg){
			console.log("Failed to soundcloudpost : " + msg);
		});
}

function FuseCloudDelete(api,args,token) {
	return FuseCloud(api,args,"delete",null,token)
		.catch(function(msg){
			console.log("Failed to soundclouddelete : " + msg);
		});
}

function fetchTracksForUserId(userId) {
	return FuseCloudGet("users/" + userId + "/tracks", {})
		.then(function(tracks) {
			var ret = [];
			tracks.forEach(function(t) {
				var track = FuseCloudModel.CreateTrack(t);
				if (track) {
					ret.push(track);
				}
			});
			return ret;
		});
}

function fetchTracksForSearchTerm(term) {
	if (Auth.isLoggedIn.value) {
		return Auth.getAccessToken().then(function(token) {
			return FuseCloudGet("tracks", { q: term }, token).then(function(result) {
				return FuseCloudModel.CreateTracks(result);
			});
		});
	} else {
		return FuseCloudGet("tracks", { q: term }).then(function(result) {
			return FuseCloudModel.CreateTracks(result);
		});
	}
}

function fetchTrackInfoForTrackId(trackId) {
	if (Auth.isLoggedIn.value) {
		return Auth.getAccessToken().then(function(token) {
			return FuseCloudGet("tracks/" + trackId,{},token).
				then(function(trackInfo) {
					return FuseCloudModel.CreateTrack(trackInfo);
				});
		});
	} else {
		return FuseCloudGet("tracks/" + trackId,{}).
			then(function(trackInfo) {
				return FuseCloudModel.CreateTrack(trackInfo);
			});
	}
}

function fetchInfoForUserId(userId) {
	return FuseCloudGet("users/" + userId, {})
		.then(function(userInfo) {
			return FuseCloudModel.CreateUser(userInfo);
		});
}

function fetchCommentsForTrackId(trackId) {
	return FuseCloudGet("tracks/" + trackId + "/comments",{})
		.then(function(comments) {
			var ret = [];
			comments.forEach(function(c) {
				ret.push(FuseCloudModel.CreateComment(c));
			});
			return ret;
		});
}

function postNewComment(trackId,body) {
	return FuseCloudPost("tracks/" + trackId + "/comments", {}, body);
}

function fetchMe() {
	console.log("Fetching me");
	return Auth.getAccessToken("me")
		.then(function(token) {
			return FuseCloudGet("me", {}, token)
				.then(function(me) {
					return FuseCloudModel.CreateUser(me);
				});
		});
}

function fetchActivities() {
	return Auth.getAccessToken()
		.then(function(token) {
			return FuseCloudGet("me/activities", {}, token)
				.then(function(activities) {
					return FuseCloudModel.CreateActivityCollection(activities);
				}).catch(function(err) {
					console.log("error fetching activities: " + err);
				});
		});
}

function fetchNextActivities(next_href) {
	return Auth.getAccessToken().then(function(token) {
		return FuseCloud("",{},"get",null,token,next_href)
			.then(function(activities) {
				return FuseCloudModel.CreateActivityCollection(activities);
			});
	});
}

function isLikingTrack(trackId) {
	return Auth.getAccessToken()
		.then(function(token) {
			return FuseCloudGet("me/favorites/" + trackId, {}, token);
		});
}

function likeTrack(trackId) {
	return Auth.getAccessToken()
		.then(function(token) {
			return FuseCloudPut("me/favorites/" + trackId, {}, token);
		});
}

function unlikeTrack(trackId) {
	return Auth.getAccessToken()
		.then(function(token) {
			return FuseCloudDelete("me/favorites/" + trackId, {}, token);
		});
}

function fetchFavorites() {
	return Auth.getAccessToken("fetchFavorites")
		.then(function(token) { 
			return FuseCloudGet("me/favorites", {}, token)
				.then(function(favorites) {
					return FuseCloudModel.CreateTracks(favorites);
				});
		});
}

module.exports = {

	fetchTracksForSearchTerm : fetchTracksForSearchTerm,
	fetchTracksForUserId : fetchTracksForUserId,
	fetchTrackInfoForTrackId: fetchTrackInfoForTrackId,
	fetchInfoForUserId : fetchInfoForUserId,
	fetchCommentsForTrackId : fetchCommentsForTrackId,

	isLikingTrack : isLikingTrack,
	likeTrack : likeTrack,
	unlikeTrack : unlikeTrack,

	fetchMe : fetchMe,

	postNewComment : postNewComment,

	fetchActivities : fetchActivities,
	fetchNextActivities : fetchNextActivities,

	fetchFavorites : fetchFavorites
};
