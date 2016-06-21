basket={
	name: 'basket'
};

basket.add = function(rec_id,cnt){
	if(!cnt)
		cnt=1
	if(!rec_id){
	 alert('not rec_id')
	 return false
	}	
	document.getElementById('basket_info').innerHTML=loadDocAsync('/basket_info?action=add&rec='+rec_id+'&cnt='+cnt+'&basket='+basket.name)
}

basket.update = function(){
	var formlist=document.basket_update.getElementsByTagName('input');
	var reg=/^rec_id_(\d+)$/;
	var str=''
	for( i = 0; i < formlist.length; i ++ ){
		if(formlist[i].name){
			var arr=reg.exec(formlist[i].name)
			if(arr){
				id=arr[1];
				cnt=formlist[i].value
				//alert(id+' : '+cnt);
				if(str)
					str+='&'
				
				str+='rec_id='+id+'&cnt='+cnt
			}
		}
		
	}
	document.getElementById('basket_info').innerHTML=loadDocAsync('/basket_info?action=basket_update&basket='+basket.name+'&'+str);	
}

basket.del=function(rec_id,cnt,basket_name){
	if(!rec_id){
	 alert('not rec_id')
	 return false
	}
	if(!cnt){
		cnt=0;
	}
	if(!basket_name){
		basket_name=basket.name;
	}
	
	document.getElementById('basket_info').innerHTML=loadDocAsync('/basket_info?action=del&rec='+rec_id+'&cnt='+cnt+'&basket='+basket_name)
}

basket.clean=function(){
	document.getElementById('basket_info').innerHTML=loadDocAsync('/basket_info?action=clean')
}

function delrow(num_id){
   var tbody = document.getElementById('bsk'+num_id).parentNode;
   tbody.removeChild(document.getElementById('bsk'+num_id));
}
