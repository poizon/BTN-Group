var FileBrowserDialogue = {
	init : function () {},
	mySubmit : function (iist) {
		var URL = iist;
		var win = tinyMCEPopup.getWindowArg("window");

		win.document.getElementById(tinyMCEPopup.getWindowArg("input")).value = URL;
		tinyMCEPopup.close();
	}
}

function CheckAll(obj, obj_copy){
	var i;
	for(i = 0; i < obj_copy.length; i++){
		if(obj_copy[i].value){
			obj_copy[i].checked = obj.checked;
		}
	}
}

function getDirName(obj){
	if(name = prompt('Имя каталога')){ 
		obj.href += 'name='+name; 
		return true;
	}
	
	return false;
}

function DelFormSend(){
	var lists = document.forms['flist'].elements['file_name'];
	var check = 0;
	var i;	
	for(i = 0; i < lists.length; i++){
		if(lists[i].value &&  lists[i].checked) check++;
	}
	
	if(check){
		if(confirm('Удалить файлы?')){
			document.forms['flist'].elements['action'].value = 'delete';
			document.forms['flist'].submit();
		}
	}
	else{
		alert('Выберите файлы');
	}
}

var Table_row_cnt = 1;
function TableAddRow(id){
	if(Table_row_cnt < 12){
		Table_row_cnt++;
		var table = document.getElementById(id);
		var tbody = table.getElementsByTagName('TBODY')[0];
		var row = document.createElement("TR");
		tbody.appendChild(row);
		
		var td = document.createElement("TD");
		row.appendChild(td);
		td.innerHTML = 'Файл&nbsp;'+Table_row_cnt;
		
		var td = document.createElement("TD");
		row.appendChild(td);
		td.innerHTML = '<input class="oneelement" name="fileload" type="file">';
		
		var td = document.createElement("TD");
		row.appendChild(td);
		td.innerHTML = '<input type="button" value=" - " onclick="TableRemoveRow(this, \''+id+'\')">';		
	}
	else{
		alert('Вы не можете заливать больше 12 файлов одновременно');	
	}
}

function TableRemoveRow(o, id){
	var tbody = document.getElementById(id).getElementsByTagName('TBODY')[0];
	var tr = o.parentNode.parentNode;
	tbody.removeChild(tr);
	Table_row_cnt--;
}
