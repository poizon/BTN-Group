/*
basket.add(18,1,{size: 1,color: 1});
*/
function template_basket_update(data){
	var o=jQuery.parseJSON(data)
	$('#basket_info').html(o.html_data);
	if(basket.good_count){
		$('#'+basket.good_count+basket.rec_id).html(o.cur_record_count);
	}
	if(basket.good_sum_price){
		$('#'+basket.good_sum_price+basket.rec_id).html(o.cur_record_total_price);
	}
	if(basket.total_price){
		$('#'+basket.total_price).html(o.total_price);
	}	

	if(document.location.pathname=='/basket' && (o.add_new_record) && !basket.not_refresh){ // если добавляем новый товар, которого раньше не было -- обновляем корзину
		document.location.href='/basket'
	}
}

basket={
	name: 'basket'
};

function get_attr_string(attr){
	var attr_string='';
	for  (i in attr){
		var key=i;
		var val=attr[i];
		attr_string=attr_string + '&attr_'+key+'='+val
	}
	return attr_string;
}
basket.add = function(rec_id,cnt,attr,async){
	async=async==false?async:true;
	if(!cnt)
		cnt=1
	if(!rec_id){
	 alert('not rec_id')
	 return false
	}
	var attr_string=get_attr_string(attr);
	
	basket.rec_id=rec_id;
	$.ajax({
			async: async,			
			url: '/basket_info_jq?action=add&rec='+rec_id+'&cnt='+cnt+'&basket='+basket.name+attr_string,		
			success: function(data){
				template_basket_update(data)
			}
	});
}

basket.update = function(){
	var str='';
	$('[id^=good_attr]').each(function(index,element){
		var v
		eval('v={'+element.value+'}');
		if(str) str+='&';
		if(!v.rec_num){
			alert('Не указан rec_num в списке атрибутов');
			exit;
		}
		if(!v.id){
			alert('Не указан id в списке атрибутов');
			exit;
		}
		var cnt=$('#rec_id_'+v.rec_num).val();
		str+='rec_id='+v.id+'&cnt='+cnt
		
		for( i in v){
			if(i != 'rec_num' && i != 'id'){
				str+='&attr_'+i+'='+v[i]
			}
			
		}
		// v -- хеш с атрибутами	
	})
	//alert('str: '+str);
	
	/*
	for( i = 0; i < formlist.length; i ++ ){
		alert(formlist.name);
		
		if(formlist[i].name){
			var arr=reg.exec(formlist[i].name)
			if(arr){
				id=arr[1];
				cnt=formlist[i].value
				//alert(id+' : '+cnt);
				if(str)
					str+='&'
				alert(id);
				alert($('#good_attr'+id).val());
				if(good_attr = $('#good_attr'+id).val()){
					var v
					eval('v={'+good_attr+'}');
					alert(v.id)
				}
				str+='rec_id='+id+'&cnt='+cnt
			}
		}
		
	}*/
	
	$.ajax({
			url: '/basket_info_jq?action=basket_update&basket='+basket.name+'&'+str,
			success: function(data){
				//template_basket_update(data);
				document.location.href='/basket'
			}
	});
}


basket.del=function(rec_id,cnt,attr,async){
	async=async==false?async:true;
	if(!rec_id){
	 alert('not rec_id')
	 return false
	}
	if(!cnt){
		cnt=0;
	}
	
	var attr_string=get_attr_string(attr);

	basket.rec_id = rec_id
	$.ajax({
			async: async,				
			url: '/basket_info_jq?action=del&rec='+rec_id+'&cnt='+cnt+'&basket='+basket.name+attr_string,
			success: function(data){
				template_basket_update(data)
			}
	});
}

basket.clean=function(){
	$.ajax({
			url: '/basket_info_jq?action=clean',
			success: function(data){
				template_basket_update(data)
			}
	});
}

function delrow(num_id){
   var tbody = document.getElementById('bsk'+num_id).parentNode;
   tbody.removeChild(document.getElementById('bsk'+num_id));
}
