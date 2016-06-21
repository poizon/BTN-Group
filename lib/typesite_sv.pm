package typesite_sv;

BEGIN {
		use Exporter ();
		@ISA = "Exporter";
		@EXPORT = 
		(
			'&go'
		);
}
my $params=$::params;
# параметры из основного модуля
sub go {
	my $url=shift;
	# 0.
		my $data=&::GET_DATA({
			table=>'project_group_site',
			limit=>1,
			onerow=>1,
		});

		$::params->{TMPL_VARS}->{project_id}=$::params->{project}->{project_id};
			
		if($data->{promoblock_id}){

			my $sth=$::params->{dbh}->prepare("SELECT file from template_group_promoblock where id=?");
			$sth->execute($data->{promoblock_id});
			if(my $file=$sth->fetchrow()){ # промоблок выбран
				
				$::params->{TMPL_VARS}->{PROMOBLOCK}='/files/typesites/promoblock/'.$file;
			}
		}

		while ($data->{options}=~m/;(.+?);/g){
			$::params->{project_services}->{$1}=1 if($1);
		}
		$::params->{TMPL_VARS}->{project_services}=$::params->{project_services};

		#&pre($::params->{TMPL_VARS}->{project_services});
		$::params->{project_logo}=$::params->{project_logo}=$data->{logo};	
	
	# 10. (init_basket)
	if($::params->{project_services}->{service_basket}){
		&::init_basket({
			cookie_name=>'basket',
			good_table=>'good',
			good_table_id=>'good_id',
			good_select_fields=>qq{
				good_id id,
				rubricator_id,
				header,
				price,
				anons,
				photo,
				concat('/files/project_$::params->{project}->{project_id}/good/',photo) as photo_and_path ,
				concat('/files/project_$::params->{project}->{project_id}/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
			},
			field_header=>'header',
			field_price=>'price',
		});
		&::basket_info;
	}
	
	# 20. (basket_info)
	if($url=~m/^\/basket_info$/ && $::params->{project_services}->{service_basket}){
		$::params->{TMPL_VARS}->{page_type}='basket_info';
		&::processing_basket;
	}
	elsif($url=~m/^\/basket_info_jq$/ && $::params->{project_services}->{service_basket}){
		
		$::params->{TMPL_VARS}->{page_type}='basket_info_jq';		
		&::processing_basket;
		&::print_header;
		require JSON;
		my $out_data;
		eval(q{	
		my $template = Template->new(
		{
			INCLUDE_PATH => $::params->{project}->{template_folder},
			COMPILE_EXT => '.tt2',
			COMPILE_DIR=>'./tmp',
			CACHE_SIZE => 512,
			PRE_CHOMP  => 1,
			POST_CHOMP => 1,
			DEBUG_ALL=>1,
			#EVAL_PERL=>1,
			FILTERS=>{
				get_url=>\&::filter_get_url
			}

		});
		$template -> process('basket_info.tmpl', $::params->{TMPL_VARS},\$out_data)# || croak "output::add_template: template error: ".$template->error();
		});
	    my $json = JSON->new->allow_nonref;
		my $json_text   = $json->encode( $out_data );
		#$out_data=q{Товаров в <b href="">корзине</b\/>: 20"};
		#$out_data=~s/("|'|\[|\]|>|<|\/|\\|\.)/\\$1/gs;
		#$out_data=~s/&//gs;
		#$out_data=~s/<.+?>//gs;
		#$out_data=~s/</&lt;/gs;
		#$out_data=~s/>/&gt/gs;
		#$out_data=~s/\n/\\n/gs;
		
		print 
		qq{{
			"total_count": "$::params->{TMPL_VARS}->{basket}->{basket}->{total_count}",
			"total_price": "$::params->{TMPL_VARS}->{basket}->{basket}->{total_price}",
			"cur_record_count": "$::params->{TMPL_VARS}->{basket}->{cur_record_count}",
			"cur_record_price": "$::params->{TMPL_VARS}->{basket}->{cur_record_price}",
			"cur_record_total_price": "$::params->{TMPL_VARS}->{basket}->{cur_record_total_price}",
			"html_data": $json_text,
			"add_new_record": "$::params->{TMPL_VARS}->{basket}->{add_new_record}"
		}};
		&::end;
		#$::params->{template_name}='basket_info.tmpl';
		return;
	}
	
	
	# 30. для всех страниц... считываем меню
	# Нижнее меню

	

	&allpages;
	
	# 40

	&mainpage($url);
	&rubricator($url);
	&good($url);
	&news($url);
	&feedback($url);
	&basket($url);
	&zakaz($url);
	&service($url);
	&text_page($url);
	# 50.
	
}
sub allpages{
	
	&::GET_DATA(
	{
	  table=>'bottom_menu',
	  order=>'sort',
	  to_tmpl=>'bottom_menu'
	});

	# Верхнее меню
	&::GET_DATA(
	{
	  table=>'top_menu_tree',
	  order=>'sort',
	  tree_use=>1,
	  to_tmpl=>'top_menu',
	  #debug=>1,
	  select_fields=>"top_menu_tree_id, top_menu_tree_id id, url, header, if(url=?,1,0) as act, ''",
	}, $::params->{PATH_INFO});

	# блок "спецпредложения"
	&::GET_DATA({
		table=>'content',
		url=>'__specpredl',
		select_fields=>'body',
		onevalue=>1,
		to_tmpl=>'specpredl'
	}); #if($::params->{project_services}->{service_goodkat});

	if($::params->{project_services}->{service_goodkat}){

				# считываем рубрики
				&::GET_DATA({
					table=>'rubricator',
					tree_use=>1,
#					max_level=>2,
					#where=>q{path = ''},
					select_fields=>qq{
						rubricator_id,
						rubricator_id id,
						header,
						anons,
						photo,
						concat('/files/project_$::params->{project}->{project_id}/rubricator/',photo) as photo_and_path,
						concat('/files/project_$::params->{project}->{project_id}/rubricator/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
					},
					order=>'sort',
					#debug=>1,
					#where=>q{parent_id is null},
					to_tmpl=>'rub_list'
				});
				#&::pre($::params->{TMPL_VARS}->{rub_list});
				# список спецпредложений
				&::GET_DATA({
					table=>'good',
					select_fields=>qq{
						good_id id,
						header, anons,price,photo,
						concat('/files/project_$::params->{project}->{project_id}/good/',photo) as photo_and_path,
						concat('/files/project_$::params->{project}->{project_id}/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1, 
						concat('/files/project_$::params->{project}->{project_id}/good/',substring_index(photo,'.',1),'_mini2','.',substring_index(photo,'.',-1)) as photo_and_path_mini2 
					},
					to_tmpl=>'specpredl_list',
					where=>'specpredl=1'
				});
	}

	if($::params->{project_services}->{service_rotator}){
	# считываем рубрики
	&::GET_DATA({
		table=>'rotator',
		#tree_use=>1,
		select_fields=>qq{
			id,
			header,
			url,
			body,
			photo,
			concat('/files/project_$::params->{project}->{project_id}/rotator/',photo) as photo_and_path
		},
		order=>'sort',
		to_tmpl=>'rotator_list'
	});
	}

	if($::params->{project_services}->{service_service}){
	# считываем рубрики услуг
	&::GET_DATA({
		table=>'service_rubricator',
		where=>q{path = ''},
		select_fields=>qq{
			id,
			header
		},
		order=>'sort',
		to_tmpl=>'service_rub_list',
		tree_use=>1
	});
	}
}
sub mainpage{
		my $url = shift;

		# 40. Главная
		if($url eq '/')
		{
				$::params->{TMPL_VARS}->{page_type}='main';
				# текст на главной странице
				&::GET_DATA({
					table=>'content',
					url=>'/',
					onerow=>1,
					to_tmpl=>'content'
				});

				#&::pre($::params->{project_services});
				# последние новости
				if($::params->{project_services}->{service_news}){
					&::GET_DATA({
					 select_fields=>q{news_id as id, DATE_FORMAT(registered, '%e %M %Y') as registered, anons, header},  
					 table=>'news',
					 order=>'id desc',
					 limit=>$::params->{TMPL_VARS}->{const}->{count_lastnews},
					 to_tmpl=>'last_news',
					 order=>'registered desc'
					});
				}
				
				
				
				#&pre($params->{TMPL_VARS}->{content});
				
				$::params->{TMPL_VARS}->{promo}->{title}='Главная страница'
					unless($::params->{TMPL_VARS}->{promo}->{title});
				#&::pre($::params->{TMPL_VARS}->{PROMOBLOCK});
		}
}
sub rubricator{
	my $url=shift;
	if($url=~m/^\/rubricator(\/(\d+))?$/){
		return unless($::params->{project_services}->{service_goodkat});
		my $rubricator_id=$2;

		if($rubricator_id=~m/^\d+$/){ # выбран раздел рубрикатора
		  $::params->{TMPL_VARS}->{page_type}='catalog';
			# считываем рубрики
			$::params->{TMPL_VARS}->{maxpage}=&::GET_DATA({
				table=>'rubricator',
				where=>q{parent_id = ?},
				select_fields=>qq{
					rubricator_id,
					rubricator_id id,
					header,
					anons,
					photo,
					concat('/files/project_$::params->{project}->{project_id}/rubricator/',photo) as photo_and_path ,
					concat('/files/project_$::params->{project}->{project_id}/rubricator/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
				},
				order=>'sort',
				perpage=>$::params->{TMPL_VARS}->{const}->{rubricator_perpage},
				to_tmpl=>'LIST',
				perpage=>$::params->{TMPL_VARS}->{const}->{rub_perpage}
			},$rubricator_id);

		  unless(scalar(@{$::params->{TMPL_VARS}->{LIST}})){ 
		  # списка рубрик нет -- пробуем вывести список товаров
			$::params->{TMPL_VARS}->{maxpage}=&::GET_DATA({
				where=>'rubricator_id=?',
				table=>'good',
				select_fields=>qq{
					good_id id,
					header,
					price,
					anons,
					photo,
					concat('/files/project_$::params->{project}->{project_id}/good/',photo) as photo_and_path ,
					concat('/files/project_$::params->{project}->{project_id}/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
				},
				to_tmpl=>'LIST',
				
				perpage=>$::params->{TMPL_VARS}->{const}->{good_perpage}
				
			},$rubricator_id);
			$::params->{TMPL_VARS}->{page_type}='goodlist';

		  }

		  # хлебные крошки
		  &::GET_PATH({
			table=>'rubricator',
			id=>$rubricator_id,
			to_tmpl=>'PATH_INFO',
			create_href=>'/rubricator/[%id%]'
		  });
		  
		  @{$::params->{TMPL_VARS}->{PATH_INFO}}=({href=>'/rubricator',header=>'Каталог продукции'},@{$::params->{TMPL_VARS}->{PATH_INFO}});
		  
		  # наименование текущей рубрики
		  &::GET_DATA({
			table=>'rubricator',
			select_fields=>qq{
			rubricator_id,
			header,
			anons,
			photo,
			body,
			concat('/files/project_$::params->{project}->{project_id}/rubricator/',photo) as photo_and_path ,
			concat('/files/project_$::params->{project}->{project_id}/rubricator/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
			},
			to_tmpl=>'cur_rub',
			onerow=>1,
			id=>$rubricator_id
		  });
		  

		  $::params->{TMPL_VARS}->{promo}->{title}=
		  'Каталог продукции : '.$::params->{TMPL_VARS}->{cur_rub}->{header}
			unless($::params->{TMPL_VARS}->{promo}->{title});
		  
		  
		}
		else{
			$::params->{TMPL_VARS}->{page_type}='catalog';
			
			# считываем рубрики
			$::params->{TMPL_VARS}->{maxpage}=&::GET_DATA({
				table=>'rubricator',
				where=>q{path = ''},
				select_fields=>qq{
					rubricator_id,
					rubricator_id id,
					header,
					anons,
					photo,
					concat('/files/project_$::params->{project}->{project_id}/rubricator/',photo) as photo_and_path ,
					concat('/files/project_$::params->{project}->{project_id}/rubricator/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
				},
				#debug=>1,
				max_level=>2,
				order=>'sort',
				tree_use=>1,
				perpage=>$::params->{TMPL_VARS}->{const}->{rubricator_perpage},
				to_tmpl=>'LIST'
			});
			@{$::params->{TMPL_VARS}->{PATH_INFO}}=({href=>'/rubricator',header=>'Каталог продукции'});
			$::params->{TMPL_VARS}->{cur_rub}->{header}='Каталог продукции';
			$::params->{TMPL_VARS}->{promo}->{title}='Каталог продукции'
			unless($::params->{TMPL_VARS}->{promo}->{title});

		}
	}
}
sub good{
	my $url = shift;
	if($url=~m/^\/good\/(\d+)$/){
		return unless($::params->{project_services}->{service_goodkat});
		my $good_id=$1;
		$::params->{TMPL_VARS}->{page_type}='good';
		&::GET_DATA({
			table=>'good',
			select_fields=>qq{
					good_id id,
					rubricator_id,
					header,
					price,
					body,
					photo,
					concat('/files/project_$::params->{project}->{project_id}/good/',photo) as photo_and_path ,
					concat('/files/project_$::params->{project}->{project_id}/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1,
					concat('/files/project_$::params->{project}->{project_id}/good/',substring_index(photo,'.',1),'_mini2','.',substring_index(photo,'.',-1)) as photo_and_path_mini2
			},
			id=>$good_id,
			get_1_to_m_data=>1,
			onerow=>1,
			to_tmpl=>'content'
		});

		# получаем список фотографий для галереи
		$::params->{TMPL_VARS}->{photo_list}=&::SQL_hash_all(
			qq{SELECT 
				id,
				header,
				photo,
				concat('/files/project_$::params->{project}->{project_id}/good/',photo) as photo_and_path ,
				concat('/files/project_$::params->{project}->{project_id}/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1,
				concat('/files/project_$::params->{project}->{project_id}/good/',substring_index(photo,'.',1),'_mini2','.',substring_index(photo,'.',-1)) as photo_and_path_mini2
			   FROM good_galery
			   WHERE good_id=$good_id
			   ORDER BY sort
			}
		);
		#&::pre($::params->{TMPL_VARS}->{photo_list});

		 # хлебные крошки
		 &::GET_PATH({
			table=>'rubricator',
			id=>$::params->{TMPL_VARS}->{content}->{rubricator_id},
			to_tmpl=>'PATH_INFO',
			create_href=>'/rubricator/[%id%]'
		  });

		$::params->{TMPL_VARS}->{promo}->{title}=$::params->{TMPL_VARS}->{content}->{header}
			unless($::params->{TMPL_VARS}->{promo}->{title});

	}
}
sub news{
	my $url=shift;
	if($url=~m/^\/news(\/(\d+))?$/){
		return unless($::params->{project_services}->{service_news});
		my $id=$2;
		if($id){ # просмотр новости
			&::GET_DATA({
				table=>'news',
				to_tmpl=>'content',
				id=>$id,
				onerow=>1,
				select_fields=>qq{
					news_id id,
					header,
					anons,
					registered,
					body,
					photo,
					concat('/files/project_$::params->{project}->{project_id}/news/',photo) as photo_and_path ,
					concat('/files/project_$::params->{project}->{project_id}/news/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
				},		
			});
			$::params->{TMPL_VARS}->{page_type}='news_in';
			$::params->{TMPL_VARS}->{promo}->{title}='Новости :: '.$::params->{TMPL_VARS}->{content}->{header}
			unless($::params->{TMPL_VARS}->{promo}->{title});

		}
		else{
			$::params->{TMPL_VARS}->{maxpage}=&::GET_DATA({
				table=>'news',
				to_tmpl=>'LIST',
				perpage=>$::params->{TMPL_VARS}->{const}->{news_perpage},
				order=>'registered desc',
				select_fields=>qq{
					news_id id,
					header,
					anons,
					registered,
					photo,
					concat('/files/project_$::params->{project}->{project_id}/news/',photo) as photo_and_path ,
					concat('/files/project_$::params->{project}->{project_id}/news/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
				},
			});
			$::params->{TMPL_VARS}->{page_type}='news';
		}
	}
}
sub feedback{
	my $url=shift;
	if($url=~m/^\/(ajax_feedback|feedback)$/){
		$::params->{TMPL_VARS}->{const}->{message_for_feedback}=q{
			Только что Вам было отправлено сообзение.
			<table>
			<tr>
			 <td><strong>Имя:</strong></td>
			 <td>[%name%]</td>
			</tr>
			<tr>
			 <td><strong>Телефон:</strong></td>
			 <td>[%phone%]</td>
			</tr>
			<tr>
			 <td><strong>Email:</strong></td>
			 <td>[%email%]</td>
			</tr>
			</table>
			<p>[%message%]</p>
		} unless($::params->{TMPL_VARS}->{const}->{message_for_feedback});
		$::params->{TMPL_VARS}->{page_type}=$1;
		next unless($::params->{project_services}->{service_feedback});
		my $encode='';
		if($::params->{TMPL_VARS}->{page_type} eq 'ajax_feedback'){
			$encode='utf8;cp1251',
		}
		my $form={
			use_capture=>1,
			encode=>$encode,
			mail_send=>[
			{
				to=>$::params->{TMPL_VARS}->{const}->{email_for_feedback},
				message=>$::params->{TMPL_VARS}->{const}->{message_for_feedback},
				subject=>'Сообщение с сайта http://'.$::params->{project}->{domain}
			}
			],
			fields=>[
				{
					name=>'name',
					description=>'Имя',
					regexp=>'.+'
				},
				{
					name=>'phone',
					description=>'Телефон',
					regexp=>'^(\d|-|\s|\(|\))+$'
				},
				{
					name=>'email',
					description=>'Email',
					regexp=>'.+@.+\..+',
				},
				{
					name=>'message',
					description=>'Ваш вопрос',
					regexp=>'.+'
				}
			]
			
		};

		($::params->{TMPL_VARS}->{form_errors},$::params->{TMPL_VARS}->{form_vls})=&::GET_FORM($form);
		$::params->{TMPL_VARS}->{promo}->{title}='Обратная связь'
			unless($::params->{TMPL_VARS}->{promo}->{title});
	}
}
sub basket{
	my $url = shift;
	if($url=~m/^\/basket$/){
		return unless($::params->{project_services}->{service_basket});
		$::params->{TMPL_VARS}->{page_type}='basket';
		&::basket_full_info;
	}
}
sub zakaz{
	my $url=shift;
	if($url eq '/zakaz'){
		$::params->{TMPL_VARS}->{page_type}='zakaz';
		my $message_for_zakaz;

		my $zakaz_summ=0;
		if(&::param('action') eq 'form_send'){
			&::basket_full_info('basket');

			
			foreach my $b (@{$::params->{TMPL_VARS}->{basket}->{basket}->{LIST}}){
		#			"$b->{header} $b->{count} $b->{price}<br>";	
				if($b->{price}>0){
				my $summ=$b->{price}*$b->{count};
				$message_for_zakaz.=qq{
				<tr>
					<td>$b->{header}</td>
					<td>$b->{price}</td>
					<td>$b->{count}</td>
					<td>$summ</td>
				</tr>
				};
				}
			}
			
		};
		my $form={
		use_capture=>1,
		action_field=>'zakaz_action',
		#	mail_send=>[

		#	],
			fields=>[
				{
					name=>'name',
					description=>'Имя',
					regexp=>'.+'
				},
				{
					name=>'phone',
					description=>'Телефон',
					regexp=>'.+'
				},
				{
					name=>'email',
					description=>'Email',
					regexp=>'.+@.+',
				},
				{
					name=>'more',
					description=>'дополнительная информация',
					#regexp=>'.+'
				}
			]
			
		};

		($::params->{TMPL_VARS}->{form_zakaz_errors},$::params->{TMPL_VARS}->{form_zakaz_vls})=&::GET_FORM($form);

		my $zakaz_id;
		if(0){ # запись информации о заказе в БД
			# в случае успешного заказа сохраняем информацию о нём в БД
			my $sth=$::params->{dbh}->prepare("INSERT INTO struct_125_zakaz(user_id,registered) values(?,now())");
			$sth->execute($::params->{TMPL_VARS}->{login_info}->{id});
			$zakaz_id=$sth->{mysql_insertid};
			$sth->finish();
			$sth=$::params->{dbh}->prepare("INSERT INTO struct_125_zakaz_info(zakaz_id,good_id,cnt) values($zakaz_id,?,?)");
			foreach my $b (@{$::params->{TMPL_VARS}->{basket}->{basket}->{LIST}}){
				$sth->execute($b->{id},$b->{count});
			#			"$b->{header} $b->{count} $b->{price}<br>";	
			
			}
			
		}

		if($::params->{TMPL_VARS}->{form_errors} eq '1'){

			if($message_for_zakaz){
				$message_for_zakaz=qq{
				<p><b>Информация о заказе:</b></p>
				<table>
				<tr>
					<td>Наименование товара</td>
					<td>Цена</td>
					<td>Количество</td>
					<td>Сумма</td>
				</tr>
					$message_for_zakaz
				</table>
				<p><b>Итого: </b>$::params->{TMPL_VARS}->{basket}->{basket}->{total_price} руб.</p>
				}
			}
			
			my $message=qq{
				<style>
					td {border: 1px solid black;}
				</style>
				<p>Только что на сайте <a href="http://$::params->{project}->{domain}">http://$::params->{project}->{domain}</a> был сделан заказ.</p>
				<p>Информация о заказчике:</p>
				<table>
					<tr><td><b>Имя:</b></td><td>$::params->{TMPL_VARS}->{form_vls}->{name}</td></tr>
					<tr><td><b>Телефон:</b></td><td>$::params->{TMPL_VARS}->{form_vls}->{phone}</td></tr>
					<tr><td><b>Email:</b></td><td>$::params->{TMPL_VARS}->{form_vls}->{email}</td></tr>
					<tr><td><b>Доп. информация:</b></td><td>$::params->{TMPL_VARS}->{form_vls}->{more}</td></tr>
				</table>
				$message_for_zakaz

				};
			if($zakaz_id){
				$message="<p><b>Номер заказа: $zakaz_id</b></p>$message";
			}
			#&::print_header;
			#print "to: $::params->{TMPL_VARS}->{const}->{email_for_zakaz}";			
			#&print_header;
			#print ("message: $message");
			# письмо администратору сайта	
			&::send_mes(
			{
				to=>$::params->{TMPL_VARS}->{const}->{email_for_zakaz},
				message=>$message,
				subject=>'Сообщение с сайта http://'.$::params->{project}->{domain}
			});

			#if($zakaz_id){
			#	$message_for_zakaz="<p><b>Номер заказа: $zakaz_id</b></p>$message";
			#}

			&::clean_basket;
		}
		$::params->{TMPL_VARS}->{promo}->{title}='Оформление заказа'
			unless($::params->{TMPL_VARS}->{promo}->{title});
	}
}
sub service{
	my $url=shift;
	if($url=~m/^\/service(\/(\d+))?$/){
		return unless($::params->{project_services}->{service_service});
		my $service_id=$2;

		if($service_id=~m/^\d+$/){ # выбран раздел рубрикатора
		  $::params->{TMPL_VARS}->{page_type}='service_list';
			# считываем рубрики
			&::GET_DATA({
				table=>'service_rubricator',
				where=>q{parent_id = ?},
				select_fields=>qq{
					id,
					header,
					anons,
					photo,
					concat('/files/project_$::params->{project}->{project_id}/service/',photo) as photo_and_path ,
					concat('/files/project_$::params->{project}->{project_id}/service/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
				},
				order=>'sort',
				to_tmpl=>'LIST',
				perpage=>$::params->{TMPL_VARS}->{const}->{rub_perpage}
			},$service_id);

		  unless(scalar(@{$::params->{TMPL_VARS}->{LIST}})){ 
		  # списка подрубрик нет, следовательно это конечная ветка.
		  # выводим описание услуги
			$::params->{TMPL_VARS}->{page_type}='service_in';

		  }

		  # хлебные крошки
		  &::GET_PATH({
			table=>'service_rubricator',
			id=>$service_id,
			to_tmpl=>'PATH_INFO',
			#debug=>1,
			create_href=>'/service/[%id%]'
		  });
		  
		  # Информация о тек. рубрике
		  &::GET_DATA({
			table=>'service_rubricator',
			select_fields=>qq{
			id,
			header,
			anons,
			photo,
			body,
			concat('/files/project_$::params->{project}->{project_id}/service/',photo) as photo_and_path ,
			concat('/files/project_$::params->{project}->{project_id}/service/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
			},
			to_tmpl=>'cur_rub',
			onerow=>1,
			id=>$service_id
		  });
		  $::params->{TMPL_VARS}->{content}=$::params->{TMPL_VARS}->{cur_rub};

		  $::params->{TMPL_VARS}->{promo}->{title}=
		  'Услуги : '.$::params->{TMPL_VARS}->{cur_rub}->{header}
			unless($::params->{TMPL_VARS}->{promo}->{title});
		  #&::pre($::params->{TMPL_VARS}->{PATH_INFO});
		  
		}
		else{
			$::params->{TMPL_VARS}->{page_type}='service_list';
			
			# считываем рубрики
			&::GET_DATA({
				table=>'service_rubricator',
				where=>q{path = ''},
				select_fields=>qq{
					id,
					header,
					anons,
					photo,
					concat('/files/project_$::params->{project}->{project_id}/service/',photo) as photo_and_path ,
					concat('/files/project_$::params->{project}->{project_id}/service/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 
				},
				order=>'sort',
				tree_use=>1,
				to_tmpl=>'LIST'
			});
			
			$::params->{TMPL_VARS}->{promo}->{title}='Услуги'
			unless($::params->{TMPL_VARS}->{promo}->{title});

		}
	}
}
sub text_page{
	my $url=shift;
	if(!$::params->{TMPL_VARS}->{page_type}){ # Проверяем, есть ли текстовая страница по данному url'у
		if(
			$::params->{TMPL_VARS}->{content}=&::GET_DATA({
				table=>'content',
				url=>$url,
				onerow=>1
			})
		){
			$::params->{TMPL_VARS}->{page_type}='text_page';
			$::params->{TMPL_VARS}->{promo}->{title}=$::params->{TMPL_VARS}->{content}->{header}
				unless($::params->{TMPL_VARS}->{promo}->{title});
		}
	}
}
return 1;
END { }
