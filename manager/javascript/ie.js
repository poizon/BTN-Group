document.attachEvent("onreadystatechange", function(){
	if ( document.readyState === "complete" ) {
		fields();
		FirstChild();		
	}
});

function fields() {
	var m = ['INPUT','TEXTAREA','SELECT','BUTTON'];
	for(var i = 0, l = m.length; i < l; i++) {
		var f = document.getElementsByTagName(m[i]);
		for(var j = 0, g = f.length; j < g; j++) {
			var obj = f[j],d=c=r='';	
			obj.disabled==true?d=' disabled':'';
			obj.checked==true?c=' checked':'';
			obj.readOnly==true?r=' readonly':'';
			obj.className += ' '+obj.type+d+c+r;		
		}
	}
}

function FirstChild() {
	var obj = getElementsByClass('fc',null,'UL');
	for(var i = 0, l = obj.length; i < l; i++) {
		obj[i].getElementsByTagName('LI')[0].className += ' first-child';
	}	
}

function getElementsByClass(searchClass,node,tag) {
	var classElements = new Array();
	if ( node == null )	node = document;
	if ( tag == null ) tag = '*';
	var els = node.getElementsByTagName(tag);
	var elsLen = els.length;
	var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
	for (i = 0, j = 0; i < elsLen; i++) {
		if (pattern.test(els[i].className) ) {
			classElements[j] = els[i];
			j++;
		}
	}
	return classElements;
}



try {document.execCommand("BackgroundImageCache",false,true);}catch(e){};

