$(function(){
				$(".select_rub").change(function(){change($(this))});
				$("#all_goods").click(function(){all_goods();return false;});
			});
			
			function all_goods(){		
				$("#count_good_from").val("0");
				$("#select_rub_1").nextAll('select,label,br,hr,a,div,i').remove();
				$("#select_rub_1 option:first").attr('selected', 'selected');
				$("ul").remove();
				
				var count_good_from=parseInt($("#count_good_from").val());
				$.post(
					"/manager/fast_load_photo_good.pl",
					{action:'all_goods',count_good_from:count_good_from},
					function(data){
						if(data){
							json=eval(data);
							$("#count_good_from").val(parseInt($("#count_good_from").val())+parseInt(json.count));
							count_all_goods(0,json.count);
							$("#select_rub_div").append(json.body);
							$(".button").each(function(i){
								ajax_upload_photo($(this));
                                			});
							$("#more_goods_link").unbind("click");
							$("#more_goods_link").click(function(){more_all_goods();return false;});
							if($('a[rel=lightbox]').length){
								$('a[rel=lightbox]').lightBox(
									{
										imageLoading: './javascript/lightbox/i/lightbox-ico-loading.gif',
										imageBtnClose: './javascript/lightbox/i/lightbox-btn-close.gif',
										imageBtnPrev: './javascript/lightbox/i/lightbox-btn-prev.gif',
										imageBtnNext: './javascript/lightbox/i/lightbox-btn-next.gif'
			
									}
								);
		
							}
						}	
					}
				);
							
			}

			function more_all_goods(){
				var count_good_from=parseInt($("#count_good_from").val());
				$.post(
					"/manager/fast_load_photo_good.pl",
					{action:'all_goods',count_good_from:count_good_from},
					function(data){
						if(data!=0){
							var json=eval(data);
							$("#count_good_from").val(parseInt($("#count_good_from").val())+parseInt(json.count));
							$("#select_rub_div").append(json.body);
							$(".button").each(function(i){
								ajax_upload_photo($(this));
                                			});
							if($('a[rel=lightbox]').length){
								$('a[rel=lightbox]').lightBox(
									{
										imageLoading: './javascript/lightbox/i/lightbox-ico-loading.gif',
										imageBtnClose: './javascript/lightbox/i/lightbox-btn-close.gif',
										imageBtnPrev: './javascript/lightbox/i/lightbox-btn-prev.gif',
										imageBtnNext: './javascript/lightbox/i/lightbox-btn-next.gif'
			
									}
								);
		
							}
							var count_all_goods=$("#count_all_goods").val();
							var count_good_from=$("#count_good_from").val();
							
							$("#more_goods_link_counter").text("Показано " +count_good_from+ " из "+ count_all_goods +" товаров. ");
						}else{
							$("#more_goods_link").css("visibility","hidden");
						}	
					}
				);				
			}

			function change(tmp){
				$("#count_good_from").val("0");
				$("#more_goods_link").css("visibility","hidden");
       				tmp.nextAll('select,label,br,hr,div,i').remove();
				$("ul").remove();
				var rubricator_id=tmp.val();
				$("#rubricator_id").val(rubricator_id);
				if(rubricator_id!=0){	
					var level=tmp.attr("id").match(/\d+/);
					var count_good_from=parseInt($("#count_good_from").val());
					$.post(
						"/manager/fast_load_photo_good.pl",
						{action:'get_rub_level',rubricator_id:rubricator_id,level:level,count_good_from:count_good_from},
						function(data){
							if(data){
								var json=eval(data);
								if(json.count){
									$("#count_good_from").val(parseInt($("#count_good_from").val())+parseInt(json.count));
									count_all_goods(rubricator_id,json.count);
								}
								$("#select_rub_div").append(json.body);
								$(".select_rub").unbind("change");
								$(".select_rub").change(function(){change($(this))});
								$(".button").each(function(i){
									ajax_upload_photo($(this));
		                        			});
								
								$("#more_goods_link").unbind("click");
								$("#more_goods_link").click(function(){more_goods();return false;});
								if($('a[rel=lightbox]').length){
									$('a[rel=lightbox]').lightBox(
										{
											imageLoading: './javascript/lightbox/i/lightbox-ico-loading.gif',
											imageBtnClose: './javascript/lightbox/i/lightbox-btn-close.gif',
											imageBtnPrev: './javascript/lightbox/i/lightbox-btn-prev.gif',
											imageBtnNext: './javascript/lightbox/i/lightbox-btn-next.gif'
			
										}
									);
								}
							}	
						}
					);					
				}else{
					$("#more_goods_link").css("visibility","hidden");
				}			
			}
		
			function more_goods(){
				var rubricator_id=$("#rubricator_id").val();
				if(rubricator_id!=0){					
					var count_good_from=parseInt($("#count_good_from").val());
					$.post(
						"/manager/fast_load_photo_good.pl",
						{action:'more_goods',rubricator_id:rubricator_id,count_good_from:count_good_from},
						function(data){
							if(data!=0){
								var json=eval(data);
								$("#count_good_from").val(parseInt($("#count_good_from").val())+parseInt(json.count));
								$("#select_rub_div").append(json.body);
								$(".button").each(function(i){
									ajax_upload_photo($(this));
		                        			});
								if($('a[rel=lightbox]').length){
									$('a[rel=lightbox]').lightBox(
										{
											imageLoading: './javascript/lightbox/i/lightbox-ico-loading.gif',
											imageBtnClose: './javascript/lightbox/i/lightbox-btn-close.gif',
											imageBtnPrev: './javascript/lightbox/i/lightbox-btn-prev.gif',
											imageBtnNext: './javascript/lightbox/i/lightbox-btn-next.gif'
			
										}
									);
		
								}
								var count_good_from=$("#count_good_from").val();
								var count_all_goods=$("#count_all_goods").val();
								$("#more_goods_link_counter").text("Показано " +count_good_from+ " из "+ count_all_goods +" товаров. ");
								$("#more_goods_link").css("visibility","visible");
														
							}else{
								$("#more_goods_link").css("visibility","hidden");
							}	
						}
					);			
				}else{
					$("#more_goods_link").css("visibility","hidden");
				}				
			}
		
			function ajax_upload_photo(tmp){
				var button = tmp;
				var good_id = $(" + input:hidden",button).val();
				//alert(good_id);	
      	 			$.ajax_upload(button, {
             				action : '/manager/fast_load_photo_good.pl',
             				name : 'myfile',
					data : {action:'upload_photo',good_id:good_id},
             				onSubmit : function(file, ext) {
              				 	// показываем картинку загрузки файла
               					$(">img",button).attr("src", "./javascript/ajaxupload/load.gif");
               					$(">font",button).text('Загрузка');

              					 /*
               						 * Выключаем кнопку на время загрузки файла
               					 */
               					button.attr("disabled","disabled");
             				},
             				onComplete : function(file, response) {
               					// убираем картинку загрузки файла
               					$(">img",button).attr("src", "./javascript/ajaxupload/loadstop.gif");
               					$(">font",button).text('Загрузить');

               					// снова включаем кнопку
               					button.removeAttr("disabled");

               					// показываем что файл загружен
						
						if(response){
							//alert(response);
							var found=response.match(/([\/\w]+)\.(\w+)/);
							//alert(found[1]+"_mini1."+found[2]);
							$("#good_img_"+good_id).attr("src",found[1]+"_mini1."+found[2]);				
							$("#good_a_"+good_id).attr("href",response);
						}else{
							//alert("Ошибка: Выбранный файл не является картинкой!");
						}

             				}
           			});
			}
	
			
			function del_photo(good_id){		
				$.post(
					"/manager/fast_load_photo_good.pl",
					{action:'del_photo',good_id:good_id},
					function(data){
						if(data==1){
							$("#good_img_"+good_id).attr("src","");
							$("#good_a_"+good_id).attr("href","");
						}else{
							alert(data);
						}	
					}
				);			
								
			}
			
			function count_all_goods(rubricator_id,count){		
					$.post(
						"/manager/fast_load_photo_good.pl",
						{action:'count_all_goods',rubricator_id:rubricator_id},
						function(data){
							if(data!=0){
								//alert(data);
								$("#count_all_goods").val(data);
								$("#more_goods_link_counter").text("Показано " +count+ " из "+ data +" товаров. ");
								$("#more_goods_link").css("visibility","visible");
							}else{
								$("#more_goods_link").css("visibility","hidden");
							}	
						}
					);			
			}	
