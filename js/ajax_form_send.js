/*Khabusev Phanis [pmk@trade.su] 22.05.2012+ 
Ajax-отправка форм и т.д.
Необходимо подключение jquery
*/
function form_send(form_id, response_id){
	if($('#'+form_id).length){
		var $form = $('#'+form_id);
			var $params = $form.serializeArray();
			if($params.length){
				$.ajax({
					type: "POST",
					url: "/ajax",
					data: $params,
					success: 
						function(data){
							try{
								var json=eval('('+data+')');
							}catch(e){
								//alert(e.name);
								var json=({data: "Синтаксическая ошибка на сервере: Ошибка в шаблоне TT." + e, status: 0});
							}
							if($("#"+response_id).length){						
								$("#"+response_id).empty(); 
								$("#"+response_id).html(json.data);
							}else{
								$("#response_form_send").remove(); 
								$("#"+form_id).before('<span id="response_form_send">'+json.data+'</span>');
							}
							if(json.status=='1'){
								$('input:text, textarea', $form).val('');
							}
							get_captcha(form_id);
						}
				});
			}else{
				alert('Ошибка при выполнении функции form_send: по указанному id='+form_id+' форма не содержит полей');
			}
	}else{
		alert('Ошибка при выполнении функции form_send: по указанному id='+form_id+' форма не найдена');
	}
}

function get_captcha(form_id){
	$.ajax({
		async: false,
		type: "POST",
		url: "/get_captcha.pl",
		data: ({action: 'out_key'}),
		success: 
			function(data){
				$('.response_get_captcha', $('#'+form_id)).empty(); 
				$('.response_get_captcha',  $('#'+form_id)).html(data);
			}
	});
}

function reset_form(form_id, response_id){
	if($("#"+response_id).length){
		$("#"+response_id).empty();
	}else{
		$("#response_form_send").remove();
	}
	$('input:text, textarea', $('#'+form_id)).val('');
}
