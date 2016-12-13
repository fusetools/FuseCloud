var Observable = require('FuseJS/Observable');
var Storage = require("FuseJS/Storage");

var self = this;

var file = "gotIt";
var gotIt = Observable(true);


function getId() {
	return self.StorageId.value;
}

function checkIfWeGotIt() {
	var json = Storage.readSync(file);
	var ret = false;
	if (json !== null && json !== "") {
		var c = JSON.parse(json);
		c.forEach(function(x) {
			if (x.id === getId()) {
				ret = true;
			}
		});
	}
	gotIt.value = ret;
}


function saveGotIt() {
	var json = Storage.readSync(file);
	var c = [];
	if (json !== null && json !== "") {
		c = JSON.parse(json);
	}
	var id = getId();
	var f = { id : id };
	c.push(f);
	var toSave = JSON.stringify(c);
	Storage.writeSync(file, toSave);
}

function okGotIt() {
	gotIt.value = true;
	saveGotIt();
}

checkIfWeGotIt();

module.exports = {
	gotIt : gotIt,
	okGotIt : okGotIt
};
