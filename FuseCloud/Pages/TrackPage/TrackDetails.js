var Moment = require("moment");
var FuseCloud = require("FuseCloud/FuseCloud");
var Observable = require("FuseJS/Observable");
var Login = require("FuseCloud/Login");
var Playlist = require("FuseCloud/Playlist");
var Model = require("FuseCloud/Model");

var currentTrackUser = Playlist.currentTrack
		.notNull()
		.map(function(track) {
			if (track && track.user) {
				return Model.GetUser(track.user.id);
			} else {
				return Observable();
			}
		}).inner();

var favoritedCurrentTrack = Playlist.currentTrack.map(function(track) {
	return track.user_favorite;
});

var favoritedCurrentTrackIcon = favoritedCurrentTrack.map(function(x) {
	return x ? 0 : 1;
});

var allComments = Playlist.currentTrackId.map(Model.GetTrackComments).inner();
var nCommentsPerPage = 8;
var nCommentsShowing = 0;

var comments = Observable();

Playlist.currentTrackId.onValueChanged(function(x) {
	comments.clear();
	nCommentsShowing = 0;
});

function showMoreComments() {
	if (nCommentsShowing < allComments.length) {
		nCommentsShowing += nCommentsPerPage;
		while (comments.length < nCommentsShowing && comments.length < allComments.length - 1) {
			comments.add(allComments.getAt(comments.length));
		}
	}
}

allComments.addSubscriber(function() {
	if (nCommentsShowing === 0) {
		showMoreComments();
	}
});

function goBack() {
	router.goBack();
}

function likeUnlike() {
	if (!favoritedCurrentTrack.value) {
		Model.PostLikeTrack(Playlist.currentTrackId.value)
			.then(function(x) {
				console.log("Done liking track " + Playlist.currentTrackId.value);
				Model.ReloadFavorites();
			})
			.catch(function(e) {
				console.log("Error liking : " + e);
				favoritedCurrentTrack.value = false;
			});
	} else {
		Model.PostUnlikeTrack(Playlist.currentTrackId.value)
			.then(function(x) {
				console.log("Done unliking track " + Playlist.currentTrackId.value);
				Model.ReloadFavorites();
			})
			.catch(function(e) {
				console.log("Error unliking : " + e);
				favoritedCurrentTrack.value = true;
			});
	}
	favoritedCurrentTrack.value = !favoritedCurrentTrack.value;
}

var newCommentBody = Observable("");
function addNewComment() {
	if (newCommentBody.value.length === 0) {
		return;
	}
	var comment = { comment : {body : newCommentBody.value } };
	newCommentBody.value = "";
	var trackId = Playlist.currentTrack.value.id;
	Model.PostNewComment(trackId, comment)
		.then(function(x) {
			comments.insertAt(0,x);
			Model.InvalidateCommentsForTrack(trackId);
		}).catch(function(err) {
			console.log("Error commenting: " + JSON.stringify(err));
		});
}

function next() {
	Playlist.playNext();
}

function previous() {
	Playlist.playPrevious();
}

module.exports = {
	currentTrack: Playlist.currentTrack,
	currentTrackUser : currentTrackUser,
	comments: comments,
	goBack: goBack,

	favoritedCurrentTrack : favoritedCurrentTrack,
	favoritedCurrentTrackIcon : favoritedCurrentTrackIcon,

	isLoggedIn : Login.isLoggedIn,
	me : Login.me,

	likeUnlike : likeUnlike,

	newCommentBody : newCommentBody,
	addNewComment : addNewComment,

	next: next,
	previous: previous,

	hasPrevious : Playlist.hasPrevious,
	hasNext : Playlist.hasNext,
	
	showMoreComments : showMoreComments
};
