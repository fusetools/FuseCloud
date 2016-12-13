var Auth = require("FuseCloud/Auth");
var Model = require("FuseCloud/Model");

var me = Auth.isLoggedIn.map(function(x){
	if (x) {
		return Model.GetMe();
	}
	return false;
});

function login(){
	Auth.login();
}

function logout(){
	Auth.logout();
}

module.exports = {
	isLoggedIn : Auth.isLoggedIn,
	me : me,
	login : login,
	logout : logout
};
