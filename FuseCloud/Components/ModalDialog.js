var dialogDelegate = null;


function openDialog(text){
	if (dialogDelegate) {
		dialogDelegate.openDialog(text);
	}
}

module.exports = {
	dialogDelegate,
	openDialog
};
