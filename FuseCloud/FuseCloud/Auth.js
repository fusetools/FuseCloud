var Observable = require("FuseJS/Observable"); 
var InterApp = require("FuseJS/InterApp");
var Storage = require("FuseJS/Storage");
var Config = require("FuseCloudConfig");
var Environment = require("FuseJS/Environment");

var clientId = Config.clientId;
var clientSecret = Config.clientSecret;

var isLoggedIn = Observable(false);
var accessToken = null;

var isRefreshing = false;
var isGettingToken = false;

isLoggedIn.onValueChanged(function(val){
	
});

function AccessToken(token, expires_in, scope, refresh_token){
	this.token = token;
	this.expires_in = expires_in; //n seconds until expiration
	this.scope = scope;
	this.refresh_token = refresh_token;
	this.created = Date.now(); //in millis since the unix epoch
}

var Safari = require("SafariViewController");
function requestCode(){
	var uri = "https://soundcloud.com/connect?client_id=" + clientId
			+ "&display=popup"
			+ "&response_type=code"
			+ "&redirect_uri=fuse-soundcloud://fuse";
	
	if (Environment.ios) {
		console.log("requestCode: " + uri);
		Safari.openUrl(uri);
	} else {
		InterApp.launchUri(uri);
	}
}


var filename = "accessToken";
function getAccessTokenFromStorage() {
	var c = Storage.readSync(filename);
	if (c !== null && c !== "") {
		return JSON.parse(c);
	}
	return null;
}

function deleteAccessTokenFromStorage(){
	Storage.deleteSync(filename);
}

function saveAccessTokenToStorage(token){
	deleteAccessTokenFromStorage();
	if (Storage.writeSync(filename, JSON.stringify(token))) {
		isLoggedIn.value = true;
		return true;
	} else {
		return false;
	}
}

var accessTokenPromises = [];
function resolvePendingPromises(at){
	accessTokenPromises.forEach(function(p){
		p.resolve(at);
	});
	accessTokenPromises = [];
}

function requestAccessToken(code){
	var uri = "https://api.soundcloud.com/oauth2/token";
	//console.log(uri);
	
	fetch(uri, {		
		method: "POST",
		headers: { 
			"Accept": "application/json",
			"Content-type": "application/x-www-form-urlencoded; charset=UTF-8"
		},
		body: "client_id=" + clientId
			+ "&client_secret=80673cb888c9215256d17c99a7310859"
			+ "&redirect_uri=fuse-soundcloud://fuse"
			+ "&grant_type=authorization_code"
			+ "&scope=non-expiring"
			+ "&code=" + code.split("#")[0]
		
	}).then(function(response){
		return response.json();
	}).then(function(r){
		accessToken = new AccessToken(r.access_token, r.expires_in, r.scope, r.refresh_token);
		saveAccessTokenToStorage(accessToken);
		resolvePendingPromises(accessToken.token);
		isLoggedIn.value = true;
		isGettingToken = false;
	}).catch(function(err){
		isGettingToken = false;
		console.log("Error in Auth.js: " + JSON.stringify(err));
	});
}

var pendingRefreshRequests = [];
function resolvePendingRefreshRequests(t) {
	pendingRefreshRequests.forEach(function(p){
		p.resolve(t);
	});
	pendingRefreshRequests = [];
}

function refreshToken(refresh_token) {
	if (isRefreshing) {
		var pendingRefreshRequest = new Promise(function(resolve, reject){
			pendingRefreshRequests.push({ resolve: resolve, reject: reject });
		});
		return pendingRefreshRequest;
	}
	
	isRefreshing = true;
	var uri = "https://api.soundcloud.com/oauth2/token";

	//console.log("Refreshing access token: " + uri);

	var body =  "client_id=" + clientId
			+ "&client_secret=" + clientSecret
			+ "&grant_type=refresh_token"
			+ "&scope=non-expiring"
			+ "&refresh_token=" + refresh_token
			+ "&redirect_uri=fuse-soundcloud://fuse";

	return fetch(uri, {
		method: "POST",
		headers: {
			"Accept": "application/json",
			"Content-type": "application/x-www-form-urlencoded; charset=UTF-8"
		},
		body: body
	}).then(function(response){
		return response.json();
	}).then(function(responseObject){
		isRefreshing = false;
		if ("error" in responseObject) {
			console.log("Response object had error: " + JSON.stringify(responseObject));
			deleteAccessTokenFromStorage();
			throw new Error("We had an error fetching refresh token");
		} else {
			return new AccessToken(
				responseObject.access_token,
				responseObject.expires_in,
				responseObject.scope,
				responseObject.refresh_token
			);
		}
	}).catch(function(err){
		isRefreshing = false;
		console.log("Error in Login.js: requestAccessToken");
		console.log(JSON.stringify(err.message));
	});
}

InterApp.onReceivedUri = function(uri){
	if (Environment.ios) {
		Safari.close();
	}
	if (uri.indexOf("fuse?") > -1){
		var splitCode = uri.split("?");
		var code = splitCode[splitCode.length - 1].split("=")[1];
		requestAccessToken(code);
	}
};


function isExpired(t){
	var errorMargin = 500000;// 500000 just to have a slight margin of error between token creation and when it was saved
	var now = Date.now();
	var ret = now > ((t.expires_in * 1000) + t.created) - errorMargin;
	return ret;
}

function refreshIfExpired(token){
	if (isExpired(token)) {
		return refreshToken(token);
	} else {
		return token;
	}
}

function getAccessToken() {
	var promise = new Promise(function(resolve, reject){
		try {
			if (accessToken === null) { 
				var t = getAccessTokenFromStorage();
				if (t) {
					if (!isExpired(t)) {
						resolve(t.token);
					} else {
						refreshToken(t.refresh_token);
					}
				} else {
					//we are not logged in and are not trying to, so this path resolves to null
					//should this be reject("Because we're not logged in") ?
					resolve(null);
				}	
			} else {
				if (!isExpired(accessToken)) {
					resolve(accessToken.token);
				} else {
					refreshToken(accessToken.refreshToken);
				}
			}
		} catch (err) {
			console.log("Error in Auth.js: " + err);
		}
	});
	return promise;
}

function login(){
	requestCode();
}

function logout(){
	isLoggedIn.value = false;
	accessToken = null;
	deleteAccessTokenFromStorage();
}

function loginIfTokenInStorage() {
	getAccessToken(false).then(function(t){
		if (t){
			isLoggedIn.value = true;
		}
	});
}

loginIfTokenInStorage();

module.exports = {
	getAccessToken: getAccessToken,
	isLoggedIn : isLoggedIn,
	
	login : login,
	logout : logout
};
