ORDER_FIELD=0;

function mix_filter(type, name, description){
	var val_chk=document.getElementById(chk_id='c_'+name).checked;
	if(val_chk)
		add_div(type, name, description)
	else
		del_div('filter_'+name, type)
}

function del_div(d,type){
	var del_id;
	if(type=='date'){
		if(del_id=document.getElementById(d+'_low'))
			main.removeChild(del_id);
		if(del_id=document.getElementById(d+'_hi'))
			main.removeChild(del_id);
	}
	else
		if(del_id=document.getElementById(d))
			main.removeChild(del_id);
}

function add_div(type, name, description){
	var field='';
	ORDER_FIELD++;

	field=description+'<br>';
	if(type=='megaselect'){field=document.getElementById('megaselect_'+name).innerHTML;}
	if(type=='text'){field+='<input type="text" name="'+name+'" class="input_text">'}
	if(type=='checkbox'){
		field+='<select name="'+name+'"><option value="">не использовать фильтр</option><option value="1">вкл</option><option value="0">выкл</option></select>'
	}
	if(type=='select_values' || type=='select_from_table'){
		field=document.getElementById('select_value_'+name).innerHTML;
	}
	field+='<input type="hidden" name="order_'+name+'" value="'+ORDER_FIELD+'">';
	var m=document.getElementById('main');

	if(type=='datetime'){ // 2 поля даты, задающие период
		var newObj1 = document.createElement("div");
		var newObj2 = document.createElement("div");
		var field1=field+'С&nbsp;&nbsp;<input type="hidden" name="'+name+'_low" id="'+name+'_low">'
		var field2='По <input type="hidden" name="'+name+'_hi" id="'+name+'_hi">'
		m.appendChild(newObj1);
		m.appendChild(newObj2);
		newObj1.id='filter_'+name+'_low';
		newObj2.id='filter_'+name+'_hi';
		newObj1.innerHTML=field1;
		newObj2.innerHTML=field2;
		init_calendar(name+'_low','filter_'+name+'_low',1	);
		init_calendar(name+'_hi','filter_'+name+'_hi',1);
		newObj2.innerHTML+='&nbsp;<span><select name="filter_'+name+'_disabled"><option value="">вкл</option><option value="1">выкл</option></select></span><div style="height: 150px">&nbsp;</div>';
	}
	else if(type=='date'){
		var newObj1 = document.createElement("div");
		var newObj2 = document.createElement("div");
		var field1=field+'С&nbsp;&nbsp;<input type="hidden" name="'+name+'_low" id="'+name+'_low">'
		var field2='По <input type="hidden" name="'+name+'_hi" id="'+name+'_hi">'
		m.appendChild(newObj1);
		m.appendChild(newObj2);
		newObj1.id='filter_'+name+'_low';
		newObj2.id='filter_'+name+'_hi';
		newObj1.innerHTML=field1;
		newObj2.innerHTML=field2;
		init_calendar(name+'_low','filter_'+name+'_low',0	);
		init_calendar(name+'_hi','filter_'+name+'_hi',0);
		newObj2.innerHTML+='&nbsp;<span><select name="filter_'+name+'_disabled"><option value="">вкл</option><option value="1">выкл</option></select></span>';
	}
	else{
		var newObj = document.createElement("div");
		m.appendChild(newObj);
		newObj.id='filter_'+name;
		newObj.innerHTML=field;
	}
 }

function add_megaselect_filter(name_megaselect, name_select, level, parent_value, config){
	// Создаём div, в который будет помещаться select
	var newObj = document.createElement("div");
	document.getElementById('filter_'+name_megaselect).appendChild(newObj);
	newObj.id='ms_'+name_select;

	var ms=name_megaselect.replace(/;/gi, '\/')
	loadDoc('./edit_form?action=load_megaselect_filter&config='+config+'&level='+level+'&parent_value='+parent_value+'&ms='+ms, 'ms_'+name_select);
}

function clear_megaselect(megaselect_id, del_id){
	document.getElementById(del_id).innerHTML=''
}