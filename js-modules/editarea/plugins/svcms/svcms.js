/**
 * Plugin designed for test prupose. It add a button (that manage an alert) and a select (that allow to insert tags) in the toolbar.
 * This plugin also disable the "f" key in the editarea, and load a CSS and a JS file
 */  
var EditArea_svcms= {
	/**
	 * Get called once this file is loaded (editArea still not initialized)
	 *
	 * @return nothing	 
	 */	 	 	
	init: function(){	
		//	alert("test init: "+ this._someInternalFunction(2, 3));
		editArea.load_css(this.baseURL+"css/test.css");
		//editArea.load_script(this.baseURL+"test2.js");
	}
	/**
	 * Returns the HTML code for a specific control string or false if this plugin doesn't have that control.
	 * A control can be a button, select list or any other HTML item to present in the EditArea user interface.
	 * Language variables such as {$lang_somekey} will also be replaced with contents from
	 * the language packs.
	 * 
	 * @param {string} ctrl_name: the name of the control to add	  
	 * @return HTML code for a specific control or false.
	 * @type string	or boolean
	 */	
	,get_control_html: function(ctrl_name){
		switch(ctrl_name){
			case "test_but":
				// Control id, button img, command
				return parent.editAreaLoader.get_button_html('test_but', 'test.gif', 'test_cmd', false, this.baseURL);
			case "unique_select":
				html= "<select id='unique_select' onchange='javascript:editArea.execCommand(\"unique_select_change\")' fileSpecific='no'>"
					+"			<option value='-1'>{$unique_select}</option>"
					+"			<option value='add_checkbox'>Checkbox</option>"
					+"			<option value='add_date'>Date</option>"
					+"			<option value='add_datetime'>DateTime</option>"
					+"			<option value='add_text'>Text</option>"
					+"			<option value='add_textarea'>Textarea</option>"
					+"			<option value='add_wysiwyg'>WYSIWYG</option>"
					+"		</select>";
				return html;
			case "get_data_select":
				html = "<select id='get_data_select' onchange='javascript:editArea.execCommand(\"get_data_select_change\")' fileSpecific='no'><option value=''>&GET_DATA</option><option value='news'>Новости</option><option value='rubricator'>Рубрикатор</option><option value='service_rubricator'>Услуги(рубрикатор)</option><option value='good'>Товары</option><option value='blank'>Пустой</option></select>";
				return html;
		}
		//return false;
	}
	/**
	 * Get called once EditArea is fully loaded and initialised
	 *	 
	 * @return nothing
	 */	 	 	
	,onload: function(){ 
		//alert("test load");
		console.log('svcms load');
	}
	
	/**
	 * Is called each time the user touch a keyboard key.
	 *	 
	 * @param (event) e: the keydown event
	 * @return true - pass to next handler in chain, false - stop chain execution
	 * @type boolean	 
	 */
/*
	,onkeydown: function(e){
		var str= String.fromCharCode(e.keyCode);
		// desactivate the "f" character
		if(str.toLowerCase()=="f"){
			return true;
		}
		return false;
	}
	*/
	/**
	 * Executes a specific command, this function handles plugin commands.
	 *
	 * @param {string} cmd: the name of the command being executed
	 * @param {unknown} param: the parameter of the command	 
	 * @return true - pass to next handler in chain, false - stop chain execution
	 * @type boolean	
	 */
	,execCommand: function(cmd, param){
		// Handle commands
		switch(cmd){
			case "unique_select_change":
				var val= document.getElementById("unique_select").value;
				var field = '';
//				alert(val);
				switch(val){
					case "add_checkbox":
						field = "{name=>'enabled',type=>'checkbox',description=>'Топ'}";
						break;
					case "add_date":
						field = "{name=>'registered',type=>'date',description=>'Дата',value=>time()}";
						break;
					case "add_datetime":
						field = "{name=>'registered',type=>'datetime',description=>'Дата',value=>time()}";
						break;
					case "add_text":
						field = "{name=>'header',type=>'text',description=>''}";
						break;
					case "add_textarea":
						field = "{name=>'anons',type=>'textarea',description=>''}";
						break;
					case "add_wisiwyg":
						field = "{name=>'body',type=>'wysiwyg',decription=>'Текст'}";
						break;
				}
				if(field !== ''){
					parent.editAreaLoader.insertTags(editArea.id,field,',');
				}
/*				if(val!=-1)
					parent.editAreaLoader.insertTags(editArea.id, "<"+val+">", "</"+val+">");
				document.getElementById("test_select").options[0].selected=true; 
				alert('asd');
*/
				return false;
			case "test_cmd":
				alert("user clicked on test_cmd");
				return false;
			case "get_data_select_change":
				var val = document.getElementById("get_data_select").value;
				var field = '';
				switch(val){
					case "news":
						field = "&GET_DATA({struct=>'news',to_tmpl=>'NEWS',where=>'enabled=1',order=>'registered desc',perpage=>$params->{TMPL_VARS}{const}{perpage_news}})";
						break;
					case "rubricator":
						field = "&GET_DATA({struct=>'rubricator',to_tmpl=>'CATALOG',where=>'enabled=1 and path=\"\"',order=>'sort'})";
						break;
					case "service_rubricator":
						field = "&GET_DATA({struct=>'service_rubricator',to_tmpl=>'SERVICE',where=>'enabled=1 and path=\"\"',order=>'sort'})";
						break;
					case "good":
						field = "&GET_DATA({struct=>'good',where=>'enabled=1',perpage=>$params->{TMPL_VARS}{const}{good_perpage},to_tmpl=>'LIST',order=>'id'})";
						break;
					case "blank":
						field = "&GET_DATA({struct=>'',to_tmpl=>'LIST',order=>'id',where=>'enabled=1'})";
						break;
				}
				if(field !== ''){
					parent.editAreaLoader.insertTags(editArea.id,field,';');
				}
				return false;
		}
		// Pass to next handler in chain
		return true;
	}
	
	/**
	 * This is just an internal plugin method, prefix all internal methods with a _ character.
	 * The prefix is needed so they doesn't collide with future EditArea callback functions.
	 *
	 * @param {string} a Some arg1.
	 * @param {string} b Some arg2.
	 * @return Some return.
	 * @type unknown
	 */
	,_someInternalFunction : function(a, b) {
		return a+b;
	}
};

// Adds the plugin class to the list of available EditArea plugins
editArea.add_plugin("svcms", EditArea_svcms);
