module.exports = {
	STOPPED : 0,
	LOADING : 1,
	PLAYING : 2,
	PAUSED : 3,
	ERROR : -1,
	
	parse : function(str){
		if (str === "Stopped")	return 0;
		else if (str === "Loading")	return 1;
		else if (str === "Playing")	return 2;
		else if (str === "Paused") return 3;
		return -1;
	},
	
	toString : function(val){
		if (val === 0) return "Stopped";
		else if (val === 1) return "Loading";
		else if (val === 2) return "Playing";
		else if (val === 3) return "Paused";
		return "Error";
	}
};
