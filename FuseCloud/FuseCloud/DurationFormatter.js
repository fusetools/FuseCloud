function formatDuration(dur){
	var min = dur.minutes() + ":";
	if (dur.minutes() < 10)
		min = "0" + min;
	var sec = dur.seconds() + "";
	if (dur.seconds() < 10)
		sec = "0" + sec;
	var ret = min + sec;
	return ret;
}

module.exports = {
	formatDuration
};
