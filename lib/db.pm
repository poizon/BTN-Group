#print "Content-type: text/html\n\n";
#/********************************************************/#
#здесь можно обрабатывать текст прошедшего рендер шаблона
#на предмет замены тегов и прочего
sub custom_processors {
    my $stream=shift;

    if ( index($::params->{project}->{options},'generate_description')>=1 ){
#      $stream =~s!meta! !ig;
      if(!$::params->{TMPL_VARS}{promo}{description}){
        my $s=$::params->{TMPL_VARS}{content}{body}||$::params->{TMPL_VARS}{content}{anons};
        $s=~ s/<[^>]*>//g;
        $s=~ s/^[ \t]*//;
        $s=~ s/[ \t]*$//;
        $s=~ s/"//g;
        $s=~ s/'//g;
        $s=~ s/\n/ /g;
        $s=substr($s,0,255);
        $stream =~s!<meta name="Description" content="(.+)" />!<meta name="Description" content="$s" />!g;
      }
    }

    if ( index($::params->{project}->{options},'post_proccessing')>=1 ) {
    #<div class=h1>=<h1 class=h1>
    #<div class=h2>=<h2 class=h2>
    #<div class=h3>=<h3 class=h3>
    $stream =~s!<(div)(.+?h1.+?)>(.+?)</div>!<h1$2>$3</h1>!ig;
    $stream =~s!<(div)(.+?h2.+?)>(.+?)</div>!<h2$2>$3</h2>!ig;
    $stream =~s!<(div)(.+?h3.+?)>(.+?)</div>!<h3$2>$3</h3>!ig;
    #
    #my $s = $stream;
    #
    #while( $s =~ m!<div class='h1([^']+?)'>(.+?)</div>!i ){
    #   $s =~ s!<div class='h1([^']+?)'>(.+?)</div>!<h1 clas='h1$1'>$2</h1>!i;
    #}
    #
    #while( $s =~ m!<div class='h2([^']+?)'>(.+?)</div>!i ){
    #   $s =~ s!<div class='h2([^']+?)'>(.+?)</div>!<h2 clas='h2$1'>$2</h2>!i;
    #}
    #
    #while( $s =~ m!<div class='h3([^']+?)'>(.+?)</div>!i ){
    #   $s =~ s!<div class='h3([^']+?)'>(.+?)</div>!<h1 clas='h3$1'>$2</h3>!i;
    #}
    # 
    #$stream = $s;
    #
    
    
    
    }

    print $stream;
}
#/********************************************************/#

sub fcgi_loop{
    # минимизируем время от "кривых рук"
    if($ENV{PATH_INFO}=~m/^\/(files|templates|admin|manager)\// || $ENV{PATH_INFO}=~m/\.(swf|jpg|gif|png|css|ico|pdf|doc|xls|js)$/i){
        print "Content-type: text/html\nStatus: 404\n\n<h1 align='center'>Page Not Found...</h1>";
        return;
    }
    Encode::from_to($ENV{PATH_INFO}, 'utf8', 'cp1251');

    #$::params->{TRUE_URL} = $ENV{PATH_INFO};
    
    
    # определяем, используется ли разграничение по проектам в "движке"  
    $system->{use_project}=1;   
    &db_connect;
    $params->{dbh}->do("SET names cp1251");
    $params->{dbh}->do("SET lc_time_names = 'ru_RU'");
    
    
    #&test_redirect();
    &get_project_info;


# перенес в &get_project_info
#    if(index($::params->{project}{options},'site_redirect')>=1){
#      my $url = $ENV{PATH_INFO};
#	print "Content-Type: text/html\n\n";
#	print "PI = $url\n";
#      my @vals = ('1',$params->{project}{project_id},$url);
#      my @whr = ('enabled=?','project_id=?','url_from=?');	
#      my $data = $params->{dbh}->selectrow_hashref('SELECT url_to FROM site_redirect WHERE '.join(' AND ',@whr),undef,@vals);
#	print Dumper($data);
#      my $redir = {status=>'301 Moved Permanently'};
#      if($data->{url_to}){
#        $redir->{url} = 'http://' unless($data->{url_to} =~ m/^(http|https)/);
#	$redir->{url} .= 'www.' if index($::params->{project}{options},'redirect_to_www')>=1;
#	$redir->{url} .= $::params->{project}{domain}.$data->{url_to} if($data->{url_to} =~ m/^\//);
#	$redir->{url} .= $data->{url_to} unless($data->{url_to} =~ m/^\//);
#        redirect(-uri=>$redir->{url},-status=>$redir->{status}) if($redir->{url});
#	print "Status: $redir->{status}\n\nLocation: $redir->{url}\n\n";
#	print redirect(-location=>$redir->{url},-status=>$redir->{status}) if($redir->{url});
#	print "Status: $redir->{status}\n";
#	print "Location: $redir->{url}\n\n";
#	$::params->{stop}=1;
#	$params->{stop}=1;
#	return;
#      }
#    }
    
    
    if($params->{stop}){
        return;
    }
    if(!$params->{TMPL_VARS}->{page_type}){
            print "Status: 404 Not Found\nContent-type: text/html\n\n";
            if(-e qq{$params->{project}->{template_folder}/404.tmpl}){
                $params->{TMPL_VARS}{error_404}=1;
                $params->{TMPL_VARS}{page_type}='text_page';
		$params->{TMPL_VARS}{page_title}='Страница не найдена';
		$params->{TMPL_VARS}{content}{header}='Страница не найдена' unless($params->{TMPL_VARS}{content}{header});
		$params->{TMPL_VARS}{content}{body}='<p>Адрес данной страницы не существует.</p>' unless($params->{TMPL_VARS}{content}{body});
#                $params->{TMPL_VARS}{content}={
#                    header=>'Страница не найдена',
#                    body=>'<p>Адрес данной страницы не существует.</p>'
#                }
            }
            else{
                my $html_404_t=qq{
                  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
                  <html xmlns="http://www.w3.org/1999/xhtml">
                  <head>
                    <meta http-equiv="Content-Type" content="text/html; charset=windows-1251" />
                    <title>404</title>
                    <style type="text/css">
                      html,body{ margin:0; padding:0; }
                      .error-box{ color:#424040; width:361px; font:12px/1.2 Tahoma, Geneva, sans-serif; padding:74px; }
                      .error-box .h{  color:#fff;  line-height:24px; font-size:16px; border-bottom:1px solid #000; overflow:hidden; zoom:1; margin-bottom:43px; }
                      .error-box .h div{ background:#242323; float:left; padding:0 7px; }
                      .error-box .err{ margin-bottom:33px; font-size:1000%; font-weight:bold; width:228px; height:119px; }
                      .error-box .txt{ margin-bottom:15px; border:solid #bdbdbd; border-width:1px 0; padding:12px 0; line-height:1.4; }
                      .error-box .fl-lt{ float:left; }
                      .error-box .fl-rt{ float:right; }
                      .error-box .over{ overflow:hidden; zoom:1; }
                      .error-box a{ color:#2b84d0; }
                    </style>
                  </head>
                  <body>
                    <div class="error-box">
                      <div class="h"><div>Ошибка</div></div>
                      <div class="err">404</div>
                      <div class="txt">Это обозначает, что запрошенному вами URL не соответствует никакая страница сайта. Этому могут быть две причины:  <b>ссылка неверна</b> или ранее существовавшая <b>страница была удалена</b>.</div>
                      <div class="over">
                        <a class="fl-lt" href="/">Назад на главную</a> 
                        <span class="fl-rt"><a href="http://www.designb2b.ru">Разработка сайтов: DesignB2B</a></span>
                      </div>
                    </div>
                  </body>
                  </html>
                };
                #print "Страница не найдена!!!";
                print $html_404_t;
                return;
            }
    }
    else{
        &print_header;
    }
    $params->{TMPL_VARS}->{TEMPLATE_FOLDER}=$params->{project}->{template_folder};
    $params->{TMPL_VARS}->{TEMPLATE_FOLDER}=~s/^.\//\//;
    if(param('explain')){
        print "<br>count_queryes: $params->{project}->{count_queryes}";
        last;
    }
    else{
       #оверайд для сайтов с флагом постпроцессинга
        if ( index($::params->{project}->{options},'post_proccessing')>=1 || index($::params->{project}{options},'generate_description')>=1 ) {
    
        #&mytitles();
        
        eval(q{ 
        my $template = Template->new(
        {
            INCLUDE_PATH => $params->{project}->{template_folder},
            COMPILE_EXT => '.tt2',
            COMPILE_DIR=>'./tmp',
            CACHE_SIZE => 512,
            #PRE_CHOMP  => 1,
            TRIM => 1,
	    #POST_CHOMP => 1,
            DEBUG_ALL=>1,
            #EVAL_PERL=>1,
            FILTERS=>{
                get_url=>\&filter_get_url,
		htmlit=>\&filder_htmlit,
		H1=>\&filter_H1,
		toint=>\&filder_toint,
            }
        
        });
        $template -> process($params->{template_name}, $params->{TMPL_VARS}, \&custom_processors ) || croak "output::add_template: template error: ".$template->error();
        });
        if($@){
	    &::print_error(qq{$@});
            #print $@;
        }
        
        
       }
       else
       {
        #$params->{TMPL_VARS}->{DEN_DEBUG} = $params->{TMPL_VARS}->{const}->{PATH_INFO};
        eval(q{ 
        my $template = Template->new(
        {
            INCLUDE_PATH => $params->{project}->{template_folder},
            COMPILE_EXT => '.tt2',
            COMPILE_DIR=>'./tmp',
            CACHE_SIZE => 512,
            PRE_CHOMP  => 1,
            POST_CHOMP => 1,
            TRIM=>1,
            DEBUG_ALL=>1,
            #EVAL_PERL=>1,
            FILTERS=>{
                get_url=>\&filter_get_url,
                htmlit=>\&filder_htmlit,
		H1=>\&filter_H1,
		toint=>\&filder_toint,
            }

        });
        $template -> process($params->{template_name}, $params->{TMPL_VARS}) || croak "output::add_template: template error: ".$template->error();
        });
        if($@){
	  &::print_error(qq{$@});
            #print $@;
        }
        
        #print $$params{project}{options};
        
       }
    }
    
    
}

sub GET_DATA{
    my $opt=shift;
    my @val=@_;

    # все данные о таблице:
    my $table;
    
    # значения могут передаваться и без where (если переменные требуется закинуть в if например
    my @names=(); my @values=@val;
    # Дескриптор подключения к БД
    my $connect;
    if($opt->{tree_use}){
        if($opt->{tree_level}){
            $opt->{tree_level}++
        }
        else{
            $opt->{tree_level}=1;
        }
        if($opt->{max_level} && ($opt->{tree_level}>$opt->{max_level})){
            return;
        }
    }
    
    unless($opt->{connect}){
        $opt->{connect}=$::params->{dbh};
    }

    if($opt->{select_fields}){
        $table->{select_fields}=$opt->{select_fields};  
    }
    else{
        $table->{select_fields}='*';
    }

    if($opt->{table}){
        $table->{from_table}=$opt->{table};
    }
    elsif($opt->{struct}){
        $table->{from_table}=&get_table_from_struct($opt->{struct});        

        if(!$opt->{onevalue} && !$opt->{select_fields}){
            my $sth=$opt->{connect}->prepare("SELECT body FROM struct WHERE project_id=? and table_name=?");
            $sth->execute($::params->{project}->{project_id}, $table->{from_table});
            my $body=$sth->fetchrow();                      
            $body=~s/^.*(^|\n)\s*our\s*\%form/my \%form/gs;
            $body=~s/\[%project_id%\]/$params->{project}->{project_id}/gs;
            
            $body=~s/\$form->{project}->{project_id}/$::params->{project}->{project_id}/gs;

            # Для структуры определяем некоторые данные
            $body.=q{$table->{work_table_id}=$form{work_table_id};};
            
            $body.=q{$table->{select_fields}.=qq{, $table->{work_table_id} as id};} unless($opt->{onevalue});
            
            $body.=q{               
                foreach my $field (@{$form{fields}}){
                    if($field->{type} eq 'file'){
                        my $fd=$field->{filedir};
                        $fd=~s/^\.\.\//\//;
                        $table->{select_fields}.=qq{, concat('$fd/',$field->{name}) as $field->{name}_and_path };
                        my $i=1;
                        while($field->{converter}=~m/output_file=['"](.+?)['"]/gs){                         
                            my $out=$1;
                            next if ($out eq '[%input%].[%input_ext%]');
                            $out=~s/\.\[%input_ext%\]/\[%input_ext%\]/;
                            $out=~s/(\]|^)([^\[]+)\[/$1,'$2',\[/;
                            
                            $out=~s/\[%input%\]/substring_index($field->{name},'.',1)/;
                            $out=~s/\[%input_ext%\]/'\.',substring_index($field->{name},'.',-1)/;
                            $table->{select_fields}.=qq{, concat('$fd/',$out) as $field->{name}_and_path_mini$i };
                            $i++;
                        }
                        
                    }
                    elsif($field->{type} eq 'select_values'){
                            $table->{select_fields}.=qq{, CASE $field->{name} };
                            while($field->{values}=~m/([^;]+?)=>([^;]+)/gs){
                                $table->{select_fields}.=qq{WHEN '$1' then '$2' }
                            }
                            $table->{select_fields}.=qq{ END as `$field->{name}`, $field->{name} as $field->{name}_val};
                        
                    }
                    #elsif($field->{type} eq 'select_from_table'){
                    #}
                    
                }
            };
            
            #
            # $opt->{add_queryes}
=cut
            # Протестировать
            if($opt->{get_1_to_m_data}){
                &pre('111');
                $body.=q{   
                            my $j=0;
                            foreach my $field (@{$form{fields}}){
                                $j++;
                                if($field->{type} eq '1_to_m'){
                                    foreach my $field2 (@{$field->{fields}}){
                                    if($field2->{type} eq 'file'){
                                        my $fd=$field2->{filedir};
                                        $fd=~s/^\.\.\//\//;
                                        my $select_fields=qq{$field->{table_id}, concat('$fd/',$field2->{name}) as $field2->{name}_and_path };
                                        my $i=1;
                                        while($field2->{converter}=~m/output_file=['"](.+?)['"]/gs){                            
                                            my $out=$1;
                                            next if ($out eq '[%input%].[%input_ext%]');
                                            $out=~s/\.\[%input_ext%\]/\[%input_ext%\]/;
                                            $out=~s/(\]|^)([^\[]+)\[/$1,'$2',\[/;
                                            $out=~s/\[%input%\]/substring_index($field2->{name},'.',1)/;
                                            $out=~s/\[%input_ext%\]/'\.',substring_index($field2->{name},'.',-1)/;
                                            $select_fields.=qq{, concat('$fd/',$out) as $field2->{name}_and_path_mini$i };
                                            $i++;
                                        }
                                        push @{$opt->{add_queryes}},
                                        {
                                            to_tmpl=>qq{$field->{name}_list},
                                            query=>qq{SELECT $select_fields FROM $field->{table} WHERE $field->{foreign_key} = [%id%]}
                                        }
                                        
                                    }
                                    }                                   
                                }
                            
                            }
            };
            }
=cut
            
            eval($body);
            
            #&pre($opt);
            if($@){
                $body=~s/\t/&nbsp;&nbsp;/gs;
                $body=~s/\n/<br\/>/gs;
                &::print_error ("Произошла ошибка при выборке из структуры $opt->{struct}<br/>=====<br/>$body<br/>=====<br/>".$@);
                return ;
            }               
        }   
        else{   
            $table->{work_table_id}=&get_work_table_id_for_table($table->{from_table});                 
        }
    }

    
    if($opt->{url}){
        push @names,'url=?';
        push @values,$opt->{url};
    }
    
    if($opt->{id}=~m/^\d+$/){
        my $id=$opt->{id};
        unless($id=~m/^\d+$/){
            &::print_error ("id должно быть числом!");
            return ;
        }
        $table->{work_table_id}=&get_work_table_id_for_table($opt->{table}) if($opt->{table});
        push @names,"$table->{work_table_id}=?";
        push @values,$id;
    }
    
    if($opt->{where}){
        push @names,$opt->{where};      
    }

    if($opt->{order}){
        $table->{order}=qq{ ORDER BY $opt->{order}};
    }
    
    if(( 
                $table->{from_table}!~/^struct_\d+/ &&
                $::system->{use_project} &&
                !defined($opt->{not_use_project})
         )
    )
    {
        push @names,"project_id=$::params->{project}->{project_id}";
    }

    if($opt->{tree_use} && $opt->{where}!~/path=\S+/){
        # Если выборка из дерева из верхней ветки
        if($opt->{where}=~m/parent_id\s*(=|is)\s*/i){
            # Если указан parent_id, то к дочерним элементам обращаемся через parent_id
            $opt->{tree_use}='parent_id';           
        }
        else{
            push @names, 'path=?';
            push @values,''
        }
    }

    $table->{where}=join(' AND ',@names); $table->{where}=qq{WHERE $table->{where}} if($table->{where});
    if($opt->{perpage}=~m/^\d+$/){ # С УЧЁТОМ РАССТРАНИЧИВАНИЯ
            $opt->{maxpage}=&SQL_row(qq{SELECT CEILING(count(*) / $opt->{perpage}) FROM $table->{from_table} $table->{where}},$opt->{connect},(@values));
            my $limit1=($::params->{TMPL_VARS}->{page}-1)*($opt->{perpage});
            $opt->{limit}=qq{$limit1, $opt->{perpage}}; 
    }

    if($opt->{limit}=~m/(\d+)\s*(,\s*\d+)?/s){
        $table->{limit}=qq{ LIMIT $1$2};
    }
    
    # Запрос, кот. будет выполняться
    my $q=qq{SELECT $table->{select_fields} FROM $table->{from_table} $table->{where} $table->{order} $table->{limit} };
    
    if(defined($opt->{debug})){
        &::print_header;
        print "<hr>DUMPER<hr>SQL: $q<br>VALUES: ".Dumper(@values)."<br><br>";
    }       
    
    if(defined($opt->{onerow})){    
        my $r=&::SQL_hash($q,$opt->{connect},@values);
	
	#Исавнин H1, 19.03.2014
	if($::params->{project}{options} =~ m/;add_h1;/ && defined($r)){
		my $h1=&get_H1($r->{id},$table->{from_table});
		if(defined($h1) && $h1 ne ''){$r->{h1}=$h1;}
		elsif($table->{from_table} =~ m/content$/){
			my $h1 = &get_H1($r->{content_id},'content');
			if(defined($h1) && $h1 ne ''){$r->{h1}=$h1;}
		}
	}          
    
        if($opt->{to_tmpl}){
                $::params->{TMPL_VARS}->{$opt->{to_tmpl}}=$r;
                return;
        }       
        return $r;
    }
    elsif(defined($opt->{onevalue})){
        my $r=&SQL_row($q,$opt->{connect},@values);
        if($opt->{to_tmpl}){
                $::params->{TMPL_VARS}->{$opt->{to_tmpl}}=$r;
                return;
        }       
        return $r;
    }
    else{
        my $r=&SQL_hash_all($q,$opt->{connect},@values);
        if($opt->{perpage}){ # Для расстраничивания помимо прочего возвращаем макс. страницу
            if($opt->{to_tmpl}){
                $::params->{TMPL_VARS}->{$opt->{to_tmpl}}=$r;
                return $opt->{maxpage} unless($opt->{tree_use});
            }
            else{
                return ($r, $opt->{maxpage}) unless($opt->{tree_use});
            }
        }
        if($r && $opt->{tree_use}){ # Рекурсия (собираем всё дерево)
            
            my $work_table_id=&get_work_table_id_for_table($table->{from_table});
            foreach my $rec (@{$r}){

                my @v=();
                if($opt->{tree_use} eq 'parent_id'){
                    $opt->{where}=~s/parent_id\s*=\s*(\d+|\?)/parent_id=$rec->{$work_table_id}/;
                }
                else{
                    #&pre($opt->{where});
                    my $w=$opt->{where};
                    $w=~s/path=\S+//g;
                    #&pre($w);
                    $w=~s/^(\s*AND)+//ig;
                    $opt->{where}=qq{path='$rec->{path}/$rec->{$work_table_id}'};
                    if($w){
                        $opt->{where}.=" AND $w";
                    }
                    
                }

                # прячем "to_tmpl", чтобы при рекурсии &GET_DATA выдавала значение
                my $to_tmpl=$opt->{to_tmpl}; $opt->{to_tmpl}='';
                $opt->{perpage}=undef; $opt->{limit}=undef;
                $rec->{child}=&GET_DATA($opt,(@val,@v));
=cut                
                if(@{$rec->{child}}){
                    $rec->{href}=qq{/rubricator/$rec->{id}};
                }
                else{
                    $rec->{href}=qq{/goods/$rec->{id}};
                }
=cut                
                $opt->{to_tmpl}=$to_tmpl;
                if($opt->{debug}){
                    print "<hr>CHILD: <hr>SQL: $rec->{child}<br><br>";
                }
            }
        }
        
        # вычисляем  кол-во товаров для каждой ветки
        if($opt->{good_calculate}){
            $opt->{hi_href}='/rubricator/[%id%]' unless($opt->{hi_href});
            $opt->{low_href}='/goods/[%id%]' unless($opt->{low_href});
            
            $opt->{good_calculate_struct}='good' unless($opt->{good_calculate_struct});
            foreach my $el (@{$r}){ 
                $el->{count}=&GET_DATA({
                    struct=>$opt->{good_calculate_struct},
                    select_fields=>'count(*)',
                    where=>'rubricator_id=?',
                    onevalue=>1,
                },$el->{id});
                if($el->{count}){
                    my $href=$opt->{low_href};
                    $href=~s/\[%id%\]/$el->{id}/g;
                    $el->{href}=$href
                }
                else{
                    my $href=$opt->{hi_href};
                    $href=~s/\[%id%\]/$el->{id}/g;
                    $el->{href}=$href
                }
            }
        }
        
        if($opt->{to_tmpl}){
            $::params->{TMPL_VARS}->{$opt->{to_tmpl}}=$r;
            return $opt->{maxpage};
        }
        else{
            return $r;
        }
    }
}

#/********************************************************************************************/#
#гетдата которая умеет юзать select_fields при подсчете maxpage
sub GET_DATA2{
    my $opt=shift;
    my @val=@_;

    # все данные о таблице:
    my $table;
    
    # значения могут передаваться и без where (если переменные требуется закинуть в if например
    my @names=(); my @values=@val;
    # Дескриптор подключения к БД
    my $connect;
    if($opt->{tree_use}){
        if($opt->{tree_level}){
            $opt->{tree_level}++
        }
        else{
            $opt->{tree_level}=1;
        }
        if($opt->{max_level} && ($opt->{tree_level}>$opt->{max_level})){
            return;
        }
    }
    
    unless($opt->{connect}){
        $opt->{connect}=$::params->{dbh};
    }

    if($opt->{select_fields}){
        $table->{select_fields}=$opt->{select_fields};  
    }
    else{
        $table->{select_fields}='*';
    }

    if($opt->{table}){
        $table->{from_table}=$opt->{table};
    }
    elsif($opt->{struct}){
        $table->{from_table}=&get_table_from_struct($opt->{struct});        

        if(!$opt->{onevalue} && !$opt->{select_fields}){
            my $sth=$opt->{connect}->prepare("SELECT body FROM struct WHERE project_id=? and table_name=?");
            $sth->execute($::params->{project}->{project_id}, $table->{from_table});
            my $body=$sth->fetchrow();                      
            $body=~s/^.*(^|\n)\s*our\s*\%form/my \%form/gs;
            $body=~s/\[%project_id%\]/$params->{project}->{project_id}/gs;
            
            $body=~s/\$form->{project}->{project_id}/$::params->{project}->{project_id}/gs;

            # Для структуры определяем некоторые данные
            $body.=q{$table->{work_table_id}=$form{work_table_id};};
            
            $body.=q{$table->{select_fields}.=qq{, $table->{work_table_id} as id};} unless($opt->{onevalue});
            
            $body.=q{               
                foreach my $field (@{$form{fields}}){
                    if($field->{type} eq 'file'){
                        my $fd=$field->{filedir};
                        $fd=~s/^\.\.\//\//;
                        $table->{select_fields}.=qq{, concat('$fd/',$field->{name}) as $field->{name}_and_path };
                        my $i=1;
                        while($field->{converter}=~m/output_file=['"](.+?)['"]/gs){                         
                            my $out=$1;
                            next if ($out eq '[%input%].[%input_ext%]');
                            $out=~s/\.\[%input_ext%\]/\[%input_ext%\]/;
                            $out=~s/(\]|^)([^\[]+)\[/$1,'$2',\[/;
                            
                            $out=~s/\[%input%\]/substring_index($field->{name},'.',1)/;
                            $out=~s/\[%input_ext%\]/'\.',substring_index($field->{name},'.',-1)/;
                            $table->{select_fields}.=qq{, concat('$fd/',$out) as $field->{name}_and_path_mini$i };
                            $i++;
                        }
                        
                    }
                    elsif($field->{type} eq 'select_values'){
                            $table->{select_fields}.=qq{, CASE $field->{name} };
                            while($field->{values}=~m/([^;]+?)=>([^;]+)/gs){
                                $table->{select_fields}.=qq{WHEN '$1' then '$2' }
                            }
                            $table->{select_fields}.=qq{ END as `$field->{name}`, $field->{name} as $field->{name}_val};
                        
                    }
                    #elsif($field->{type} eq 'select_from_table'){
                    #}
                    
                }
            };
            
            #
            # $opt->{add_queryes}
=cut
            # Протестировать
            if($opt->{get_1_to_m_data}){
                &pre('111');
                $body.=q{   
                            my $j=0;
                            foreach my $field (@{$form{fields}}){
                                $j++;
                                if($field->{type} eq '1_to_m'){
                                    foreach my $field2 (@{$field->{fields}}){
                                    if($field2->{type} eq 'file'){
                                        my $fd=$field2->{filedir};
                                        $fd=~s/^\.\.\//\//;
                                        my $select_fields=qq{$field->{table_id}, concat('$fd/',$field2->{name}) as $field2->{name}_and_path };
                                        my $i=1;
                                        while($field2->{converter}=~m/output_file=['"](.+?)['"]/gs){                            
                                            my $out=$1;
                                            next if ($out eq '[%input%].[%input_ext%]');
                                            $out=~s/\.\[%input_ext%\]/\[%input_ext%\]/;
                                            $out=~s/(\]|^)([^\[]+)\[/$1,'$2',\[/;
                                            $out=~s/\[%input%\]/substring_index($field2->{name},'.',1)/;
                                            $out=~s/\[%input_ext%\]/'\.',substring_index($field2->{name},'.',-1)/;
                                            $select_fields.=qq{, concat('$fd/',$out) as $field2->{name}_and_path_mini$i };
                                            $i++;
                                        }
                                        push @{$opt->{add_queryes}},
                                        {
                                            to_tmpl=>qq{$field->{name}_list},
                                            query=>qq{SELECT $select_fields FROM $field->{table} WHERE $field->{foreign_key} = [%id%]}
                                        }
                                        
                                    }
                                    }                                   
                                }
                            
                            }
            };
            }
=cut
            
            eval($body);
            
            #&pre($opt);
            if($@){
                $body=~s/\t/&nbsp;&nbsp;/gs;
                $body=~s/\n/<br\/>/gs;
                &::print_error ("Произошла ошибка при выборке из структуры $opt->{struct}<br/>=====<br/>$body<br/>=====<br/>".$@);
                return ;
            }               
        }   
        else{   
            $table->{work_table_id}=&get_work_table_id_for_table($table->{from_table});                 
        }
    }

    
    if($opt->{url}){
        push @names,'url=?';
        push @values,$opt->{url};
    }
    
    if($opt->{id}=~m/^\d+$/){
        my $id=$opt->{id};
        unless($id=~m/^\d+$/){
            &::print_error ("id должно быть числом!");
            return ;
        }
        $table->{work_table_id}=&get_work_table_id_for_table($opt->{table}) if($opt->{table});
        push @names,"$table->{work_table_id}=?";
        push @values,$id;
    }
    
    if($opt->{where}){
        push @names,$opt->{where};      
    }

    if($opt->{order}){
        $table->{order}=qq{ ORDER BY $opt->{order}};
    }
    
    if(( 
                $table->{from_table}!~/^struct_\d+/ &&
                $::system->{use_project} &&
                !defined($opt->{not_use_project})
         )
    )
    {
        push @names,"project_id=$::params->{project}->{project_id}";
    }

    if($opt->{tree_use} && $opt->{where}!~/path=\S+/){
        # Если выборка из дерева из верхней ветки
        if($opt->{where}=~m/parent_id\s*(=|is)\s*/i){
            # Если указан parent_id, то к дочерним элементам обращаемся через parent_id
            $opt->{tree_use}='parent_id';           
        }
        else{
            push @names, 'path=?';
            push @values,''
        }
    }

    $table->{where}=join(' AND ',@names); $table->{where}=qq{WHERE $table->{where}} if($table->{where});
    if($opt->{perpage}=~m/^\d+$/){ # С УЧЁТОМ РАССТРАНИЧИВАНИЯ
	#SQL_CALC_FOUND_ROWS
	
	$___connect=$::params->{dbh};
	
	my $___results = $___connect->selectall_arrayref(qq{SELECT SQL_CALC_FOUND_ROWS count(*) / $opt->{perpage} as countresult, $table->{select_fields} FROM $table->{from_table} $table->{where}}, {Slice=>{}} );
	
	$mp = ($___connect->selectrow_array("SELECT FOUND_ROWS()")/$opt->{perpage});
	
	#print "inner maxpage: ".$mp;
	
	
	if ( int($mp)<$mp ) { $mp=int($mp)+1; }
	$opt->{maxpage} = $mp;
	
	       #$opt->{maxpage} = $___results->{countresult};
		   # $opt->{maxpage} = $sth->{countresults};
		
		
	    
	    
	    
	    
            my $limit1=($::params->{TMPL_VARS}->{page}-1)*($opt->{perpage});
            $opt->{limit}=qq{$limit1, $opt->{perpage}}; 
    }

    if($opt->{limit}=~m/(\d+)\s*(,\s*\d+)?/s){
        $table->{limit}=qq{ LIMIT $1$2};
    }
    
    # Запрос, кот. будет выполняться
    my $q=qq{SELECT $table->{select_fields} FROM $table->{from_table} $table->{where} $table->{order} $table->{limit} };
    
    if(defined($opt->{debug})){
        &::print_header;
        print "<hr>DUMPER<hr>SQL: $q<br>VALUES: ".Dumper(@values)."<br><br>";
    }       
    
    if(defined($opt->{onerow})){    
        my $r=&::SQL_hash($q,$opt->{connect},@values);              
        if($opt->{to_tmpl}){
                $::params->{TMPL_VARS}->{$opt->{to_tmpl}}=$r;
                return;
        }       
        return $r;
    }
    elsif(defined($opt->{onevalue})){
        my $r=&SQL_row($q,$opt->{connect},@values);
        if($opt->{to_tmpl}){
                $::params->{TMPL_VARS}->{$opt->{to_tmpl}}=$r;
                return;
        }       
        return $r;
    }
    else{
        my $r=&SQL_hash_all($q,$opt->{connect},@values);
        if($opt->{perpage}){ # Для расстраничивания помимо прочего возвращаем макс. страницу
            if($opt->{to_tmpl}){
                $::params->{TMPL_VARS}->{$opt->{to_tmpl}}=$r;
                return $opt->{maxpage} unless($opt->{tree_use});
            }
            else{
                return ($r, $opt->{maxpage}) unless($opt->{tree_use});
            }
        }
        if($r && $opt->{tree_use}){ # Рекурсия (собираем всё дерево)
            
            my $work_table_id=&get_work_table_id_for_table($table->{from_table});
            foreach my $rec (@{$r}){

                my @v=();
                if($opt->{tree_use} eq 'parent_id'){
                    $opt->{where}=~s/parent_id\s*=\s*(\d+|\?)/parent_id=$rec->{$work_table_id}/;
                }
                else{
                    #&pre($opt->{where});
                    my $w=$opt->{where};
                    $w=~s/path=\S+//g;
                    #&pre($w);
                    $w=~s/^(\s*AND)+//ig;
                    $opt->{where}=qq{path='$rec->{path}/$rec->{$work_table_id}'};
                    if($w){
                        $opt->{where}.=" AND $w";
                    }
                    
                }

                # прячем "to_tmpl", чтобы при рекурсии &GET_DATA выдавала значение
                my $to_tmpl=$opt->{to_tmpl}; $opt->{to_tmpl}='';
                $opt->{perpage}=undef; $opt->{limit}=undef;
                $rec->{child}=&GET_DATA($opt,(@val,@v));
=cut                
                if(@{$rec->{child}}){
                    $rec->{href}=qq{/rubricator/$rec->{id}};
                }
                else{
                    $rec->{href}=qq{/goods/$rec->{id}};
                }
=cut                
                $opt->{to_tmpl}=$to_tmpl;
                if($opt->{debug}){
                    print "<hr>CHILD: <hr>SQL: $rec->{child}<br><br>";
                }
            }
        }
        
        # вычисляем  кол-во товаров для каждой ветки
        if($opt->{good_calculate}){
            $opt->{hi_href}='/rubricator/[%id%]' unless($opt->{hi_href});
            $opt->{low_href}='/goods/[%id%]' unless($opt->{low_href});
            
            $opt->{good_calculate_struct}='good' unless($opt->{good_calculate_struct});
            foreach my $el (@{$r}){ 
                $el->{count}=&GET_DATA({
                    struct=>$opt->{good_calculate_struct},
                    select_fields=>'count(*)',
                    where=>'rubricator_id=?',
                    onevalue=>1,
                },$el->{id});
                if($el->{count}){
                    my $href=$opt->{low_href};
                    $href=~s/\[%id%\]/$el->{id}/g;
                    $el->{href}=$href
                }
                else{
                    my $href=$opt->{hi_href};
                    $href=~s/\[%id%\]/$el->{id}/g;
                    $el->{href}=$href
                }
            }
        }
        
        if($opt->{to_tmpl}){
            $::params->{TMPL_VARS}->{$opt->{to_tmpl}}=$r;
            return $opt->{maxpage};
        }
        else{
            return $r;
        }
    }
}
#/********************************************************************************************/#



sub SQL_hash_all{
  my $sql = shift;
  my $connect=shift;
  $connect=$::params->{dbh} unless($connect);
  my @vars = @_;
  my $sth = $connect->prepare($sql);
  eval q{$sth->execute(@vars) or die "Не могу выполнить: [$sql] $DBI::errstr\n";};  
  if($@){
        &::print_error (qq{
            SQL Error:<br>
            $sql<br/>
            $@
        });
        return;
    }
    elsif(param('explain')){
        to_explain($sql,$connect,@vars);
    }
    my @a=();
    return \@a unless ($sth->rows());
  return $sth->fetchall_arrayref({}); 
  
}
sub SQL_hash{
  my $sql = shift;
  my $connect=shift;
  if(!$connect){
        $connect=$::params->{dbh};
    }
  my @vars=@_;
  my $sth = $connect->prepare($sql);
  eval(q{$sth->execute(@vars) or print "Не могу выполнить: [$sql] $DBI::errstr\n";});
   if($@){
        &::print_error (qq{
            SQL Error:<br>
            $sql<br/>
            $@
        });
        return;
    }
    elsif(param('explain')){
        to_explain($sql,$connect,@vars);
    }
    return $sth->fetchrow_hashref();
}
sub to_explain{
    &print_header;
    my $sql = shift;
    my $connect=shift;
    print "<br><br>$sql<br>";
#    print join(';',@vars);
    my @vars=@_;
    my $sth=$connect->prepare("explain $sql");
    $params->{project}->{count_queryes}++;
    $sth->execute(@vars) || die($!); #die($dbh->errstr());
    while(my $i=$sth->fetchrow_hashref()){
            my $color='#000000';
            if($i->{rows}>20 || ($i->{rows} && !$i->{key})){
                $color='red';
            }
            print qq{
            <div style="color: $color;">
            =======================<br>
            id: $i->{id}<br>
            select_type: $i->{select_type}<br>
            table: $i->{table}<br>
            type: $i->{type}<br>
            possible_keys: $i->{possible_keys}<br>
            key: $i->{key}<br>
            key_len: $i->{key_len}<br>
            ref: $i->{ref}<br>
            rows: $i->{rows}<br>
            Extra: $i->{extra}<br><br>
            </div>
            }
    }

}
sub get_work_table_id_for_struct{

    # возвращает Primary key для структуры
    my $struct=shift;   
    my $table=&get_table_from_struct($struct);
    my $work_table_id=&get_work_table_id_for_table($table);
    return $work_table_id;
}
sub get_work_table_id_for_table{
    # возвращает Primary KEY для таблицы
    my $table=shift;
    
    my $sth=$::params->{dbh}->prepare("show tables like ?");
    $sth->execute($table);
    if($sth->rows()){
        $sth=$::params->{dbh}->prepare("desc $table");
        $sth->execute();
    }
    else{
        return 0;
    }
    
    while(my $h=$sth->fetchrow_hashref()){
            return $h->{Field} if($h->{Key} eq 'PRI');
    }
    return 0;
}
sub SQL_row{
  my $sql = shift;
  my $connect=shift;
  $connect=$::params->{dbh} unless($connect);  
  my @vars=@_;
  my $sth = $connect->prepare($sql);
  eval q{$sth->execute(@vars) or warn "Не могу выполнить: [$sql] $DBI::errstr\n";};
    if($@){
        &print_error (qq{
            SQL Error:<br>
            $sql<br/>
            $@
        });
        return;
    }
    elsif(param('explain')){
        to_explain($sql,$connect,@vars);
    }
  return $sth->fetchrow();
}

sub SQL_row2{
  my $sql = shift;
  my $connect=shift;
  
  #&pre($sql);
  
  $connect=$::params->{dbh} unless($connect);  
  my @vars=@_;
  my $sth = $connect->prepare($sql);
  eval q{$sth->execute(@vars) or warn "Не могу выполнить: [$sql] $DBI::errstr\n";};
    if($@){
        &print_error (qq{
            SQL Error:<br>
            $sql<br/>
            $@
        });
        return;
    }
    elsif(param('explain')){
        to_explain($sql,$connect,@vars);
    }
  return $sth->fetchrow();
}

sub SQL_row_hashref{
  my $sql = shift;
  my $connect=shift;
  $connect=$::params->{dbh} unless($connect);  
  my @vars=@_;
  my $sth = $connect->prepare($sql);
  eval q{$sth->execute(@vars) or warn "Не могу выполнить: [$sql] $DBI::errstr\n";};
    if($@){
        &print_error (qq{
            SQL Error:<br>
            $sql<br/>
            $@
        });
        return;
    }
    elsif(param('explain')){
        to_explain($sql,$connect,@vars);
    }
  return $sth->fetchrow_hashref();
}


# ===============================
# Получение данных о структуре
# ===============================
sub get_table_from_struct{
    my $struct=shift;
    # 1. Имя структуры может совпадать с именем общих таблиц
    my $sth=$::params->{dbh}->prepare("SELECT count(*) FROM struct WHERE project_id=? AND table_name=?");
    $sth->execute($::params->{project}->{project_id},$struct);
    if(my $r=$sth->fetchrow()){ # да
        return $struct;
    }
    else{ # структура уникальна для проекта:
        return 'struct_'.$::params->{project}->{project_id}.'_'.$struct;
    }
}
sub db_connect{
    use vars qw($::params);
    if(!$::system->{dbh}){
        $::system->{dbh}=DBI->connect("DBI:mysql:$::system->{DBname}:$::system->{DBhost}",$::system->{DBuser},$::system->{DBpassword},{ RaiseError => 1 }) || die($::system->{dbh}->{errstr});# || die($!);
#       $::system->{dbh}->do("SET lc_time_names = 'ru_RU'");
#       $::system->{dbh}->do("SET names CP1251");
        $::system->{dbh}->{mysql_auto_reconnect} = 1;
    }
    $::params->{dbh}=$::system->{dbh};
}

sub get_project_info{
    use vars qw($::params);
    my $domain=$::ENV{SERVER_NAME};
    $domain=~s/^www\.//;
    $::params->{project}=SQL_hash
    (
        q{
            SELECT 
                d.template_id,d.project_id,
                t.folder as template_folder,
                d.domain,d.domain_id,p.options,t.options template_options
            FROM domain d, project p, template t
            WHERE d.project_id=p.project_id AND d.domain=? AND d.template_id =t.template_id
        },
        undef,
        $domain
    );

    #/*****************************************/#
    #/* РЕДИРЕКТЫ
    #/*****************************************/#

    #post_proccessing;замена тегов для оптимизации (h1,h2,h3);
    #redirect_to_www;редирект x.com на www.x.com;
    #redirect_from_www;редирект www.x.com на x.com;
    #redirect_to_slash;редирект /news на /news/;
    #redirect_from_slash;редирект /news/ на /news<hr/>;
    #site_redirect;внутриние редиректы

    my $curl = $::ENV{PATH_INFO};
    my $src_domain = $::ENV{SERVER_NAME};
    
    
if  ( $curl !~ m/txt|xml/) {
    ##не работает
    if ( $::params->{project}->{options} =~ /redirect_to_slash/  ) {
        if ( $curl && $curl !~ /\/$/ ) {
            $curl =~m/(.*)(\/)?$/;
            #print "Content-type: text/html\n\n";
            #print "http://$params->{project}->{domain}$1/\n\n";
                print "Status: 301 Moved Permanently\n";
                print "Location: http://$params->{project}->{domain}$1/\n\n";
                exit;
        }
    }
    
    if ( $::params->{project}->{options} =~ /redirect_from_slash/ ) {
        if ( $curl !~ /^\/$/ ) {
            if( $curl =~/^(.*)(\/)$/){
                print "Status: 301 Moved Permanently\n";
		#$curl =~ s/\/$//;
                print "Location: http://$params->{project}->{domain}$1\n\n";
		#print "Location: http://$curl\n\n";
                exit;
            }
            #if( $curl =~/\/page=(\d)$/ ){
            #    print "Status: 301 Moved Permanently\n";
	    #   $curl =~ s/\/page=(\d+)$/?page=$1/;
	    #   #$www = $::params->{project}{options} =~ /redirect_to_www/ ? 'www.' : undef;
	    #	print "Location: http://$curl\n\n";
	    #	exit; 
            #}
	    #elsif($curl =~ /^(.*)(\/)$/){
            #    print "Status: 301 Moved Permanently\n";
	    #   print "Location: http://$project->{project}{domain}$1\n\n";
	    #   exit;
	    #}
        }
	if($curl =~ m/\/page=(\d+)$/){
		print "Status: 301 Moved Permanently\n";
		$curl =~ s/\/page=(\d+)$/?page=$1/;
		$www = 'www.' if($::params->{project}{options} =~ /redirect_to_ww/);
		print "Location: http://$www$params->{project}{domain}$curl\n\n";
		exit;
	}
    }
    
    if ( $::params->{project}->{options} =~ /redirect_to_www/ ) {
        if ( $src_domain !~ /^www/ ) {
            $curl =~/^(.*)$/;
                print "Status: 301 Moved Permanently\n";
		#$qs=$ENV{QUERY_STRING} ? "?$ENV{QUERY_STRING}" : undef;
                print "Location: http://www.$domain$1\n\n";
                exit;
            
        }
    }
    
    if ( $::params->{project}->{options} =~ /redirect_from_www/ ) {
        if ( $src_domain =~ m/^www/ ) {
                print "Status: 301 Moved Permanently\n";
                print "Location: http://$params->{project}->{domain}$curl\n\n";
                exit;
        }
    }

    if($::params->{project}{options} =~ /site_redirect/){
      my $url = $ENV{PATH_INFO};
      my @vals = ('1',$params->{project}{project_id},$url);
      my @whr = ('enabled=?','project_id=?','url_from=?');
      my $data = $params->{dbh}->selectrow_hashref('SELECT url_to FROM site_redirect WHERE '.join(' AND ',@whr),undef,@vals);
      my $redir = {status=>'301 Moved Permanently'};
      if($data->{url_to}){
        $redir->{url} = 'http://' unless($data->{url_to} =~ m/^(http|https)/);
        $redir->{url} .= 'www.' if($::params->{project}{options} =~ m/redirect_to_www/);
        $redir->{url} .= $::params->{project}{domain}.$data->{url_to} if($data->{url_to} =~ m/^\//);
        $redir->{url} .= $data->{url_to} unless($data->{url_to} =~ m/^\//);
        exit print redirect(-uri=>$redir->{url},-status=>$redir->{status}) if($redir->{url});
      }
    }
}
    #/*****************************************/#



   if ( $::params->{project}->{options} =~ /use_external_sitemap_file/
        &&
        $curl =~ /\/sitemap.xml$/
      )
   {
        if ( -e "/www/sv-cms/htdocs/templates/$::params->{project}->{template_folder}/sitemap.xml" ) {
            
            print "Content-type: text/xml\n\n";
            
            open (my $FH, "</www/sv-cms/htdocs/templates/$::params->{project}->{template_folder}/sitemap.xml") || die "Can\'t open sitemap.xml\n";
            while (<$FH>) {
                print $_;
            }
            close $FH;            
            
            #print "Content-type: text/html\n\n";
            #print "/www/sv-cms/htdocs/templates/$::params->{project}->{template_folder}/sitemap.xml";
            #print "END";
            exit;
        }     
   }
   



    unless(index($::params->{project}->{options},';cache_in_nginx;')>=1){
        print "Cache-Control: no-cache\n";
    }
    
    # Костыль, пока в шаблоне прописывается путь с './templates'
    # ===
    if($::params->{project}->{template_folder}!~/^$::system->{TEMPLATE_DIR}/){
        $::params->{project}->{template_folder}=qq{$::system->{TEMPLATE_DIR}/$::params->{project}->{template_folder}};
    }
    # ===

    
    unless($::params->{project}->{project_id}){
        $::params->{stop}=1;
        &print_header;
        print 'Данный домен не найден';
        return ;
    }
    
### !!!! ОТСЮДА
    
    # Защита от XSS
    $ENV{PATH_INFO}=~s/>/&gt;/gs;
    $ENV{PATH_INFO}=~s/</&lt;/gs;
    
    # Дешифрация URL'а
    $::params->{PATH_INFO}=$ENV{PATH_INFO};
    
    #$::params->{TRUE_URL} = $::params->{PATH_INFO};
    $::params->{PATH_INFO}='/' unless($::params->{PATH_INFO});

    # Оригинальные URL'ы
    if(index($::params->{project}->{options},';ex_links;')>=0){

                    # Если мы пытаемся зайти на страницу, для которой позднее был создан оригинальный url
                    #if($params->{project}->{project_id}==77){
                    #   &print_header;
                    #   print "SELECT ext_url FROM in_ext_url WHERE project_id=77 and in_url='$::params->{PATH_INFO}'";
                        #&end; return;
                    #}
                    my $sth=$::params->{dbh}->prepare("SELECT ext_url FROM in_ext_url WHERE project_id=? and in_url=?");
                    $sth->execute($::params->{project}->{project_id},$::params->{PATH_INFO});
                    if($sth->rows()){
                        my $newurl=$sth->fetchrow();
                        print "Status: 301\n";
			$query_string = $ENV{QUERY_STRING} ? "?$ENV{QUERY_STRING}" : undef;
                        print "Location: http://$ENV{HTTP_HOST}$newurl$query_string\n\n";
                        $::params->{stop}=1;
                        return ;
                    }

                    
                    $sth=$::params->{dbh}->prepare("SELECT in_url FROM in_ext_url WHERE project_id=? and ext_url=?");
                    $sth->execute($::params->{project}->{project_id},$::params->{PATH_INFO});
                    $::params->{PATH_INFO}=$sth->fetchrow() if($sth->rows());
                    $sth->finish();
    }

    sub get_const{
        my $q=qq{SELECT name,value from const};
        $q.=qq{ WHERE project_id=$::params->{project}->{project_id}} if($system->{use_project});
        my $sth=$::params->{dbh}->prepare($q); $sth->execute();
        while(my ($name,$value)=$sth->fetchrow()){$::params->{TMPL_VARS}->{const}->{$name}=$value;}
    }
    
# !!!! Сюда
    if(0 && index($::params->{project}->{options},';cache_const;')>=0){
        if(defined($CACHE->{$::params->{project}->{project_id}}->{cache_const})){
            $::params->{TMPL_VARS}->{const}=$CACHE->{$::params->{project}->{project_id}}->{cache_const};
        }
        else{
            &get_const;
            $CACHE->{$::params->{project}->{project_id}}->{cache_const}=$::params->{TMPL_VARS}->{const};
        }
    }
    else{
        # Собираем константы
        &get_const;
    }
    
    # расстраничивание....
    ## фикс для оптимизаторов
    ## антонов
    ##  if($::params->{PATH_INFO}=~m/^(.+?)(\/page=(\d+))?$/){
    ##              >>>>>>>>>>>>>>>>(\/)?
    if($::params->{PATH_INFO}=~m/^(.+?)(\/page=(\d+)(\/)?)?$/){     
        $::params->{TMPL_VARS}->{const}->{PATH_INFO}=$1;
        my $page=$3;
        unless($page){
            $page=param('page');
            $page=1 unless($page);
        }
        $::params->{TMPL_VARS}->{page}=$page;
    }
    
    # Код счётчика b2b (по просьбе Ивана)
    $::params->{TMPL_VARS}->{const}->{b2bcounter}=q{<script type="text/javascript">document.write('<scr'+'ipt type="text/javascript" src="http://b2bcontext.ru/analytics/catch?&'+Math.random()+'"></scr'+'ipt>');</script>};
    
    # вычисляем PROMO
    if(0 && index($::params->{project}->{options},';cache_promo;')>=0 && defined($CACHE->{$::params->{project}->{project_id}}->{cache_promo}->{$ENV{PATH_INFO}})){
        $::params->{TMPL_VARS}->{promo}=$CACHE->{$::params->{project}->{project_id}}->{cache_promo}->{$ENV{PATH_INFO}};
        #`echo "get_promo_from cache ($ENV{PATH_INFO})" >> log`;
    }
    else{
	# Исавнин, чтобы не пришлось переписывать урлы в карточке про при ЧПУ
	my $url_in = $ENV{REQUEST_URI};
	my @promo_vals = ($url_in,$::params->{project}{project_id});
	my $sql ="SELECT promo_title as title, promo_description as description, promo_keywords as keywords, promo_body as body, add_tags FROM promo WHERE url=? AND project_id=?";
	if($::params->{project}{options} =~ m/ex_links/){
		#$url_in = $ENV{PATH_INFO};
		$urls = &SQL_hash("SELECT in_url FROM in_ext_url WHERE project_id = ? AND ext_url = ?",undef,($::params->{project}{project_id},$url_in));
#		$url_in = $urls->{in_url} if($urls->{in_url});
		push @promo_vals,$::params->{project}{project_id} if($urls->{in_url});
		push @promo_vals,$urls->{in_url} if($urls->{in_url});
		$sql.=" OR ( project_id = ? AND url=?)" if($urls->{in_url});
	}
        $::params->{TMPL_VARS}->{promo}=&SQL_hash
#            ("SELECT 
#                promo_title as title, promo_description as description, promo_keywords as keywords,
#                promo_body as body, add_tags
#            FROM promo WHERE url=? AND project_id=?",undef,
#		($ENV{REQUEST_URI},$::params->{project}->{project_id})
	    (
		$sql,undef,@promo_vals
		#($url_in,$::params->{project}{project_id})
	    );
            
        $::params->{TMPL_VARS}->{page_title} = $::params->{TMPL_VARS}->{promo}->{title};
            
        #`echo "get_promo_from db $::params->{project}->{project_id} ($ENV{PATH_INFO})" >> log`;
        if(0 && index($::params->{project}->{options},';cache_promo;')>=1){
            #`echo "save to cache" >> log`;
            unless(defined($::params->{TMPL_VARS}->{promo})){
                #$CACHE->{$::params->{project}->{project_id}}->{cache_promo}->{$ENV{PATH_INFO}}='';
            }
            else{
                $CACHE->{$::params->{project}->{project_id}}->{cache_promo}->{$ENV{PATH_INFO}}=$::params->{TMPL_VARS}->{promo};
            }
        }
    }
    
    ##НАДО ПЕРЕНЕСТИ иначе игнорируются редиректы и к файлам домешивается лишний код (самих редиректов). Антонов.
    { # Файлы поисковиков
        #&pre("SELECT body from files where project_id=$::params->{project}->{project_id} and url='$::params->{TMPL_VARS}->{const}->{PATH_INFO}'");
        my $sth=$params->{dbh}->prepare("SELECT body from files where project_id=? and url=?");
        $sth->execute($::params->{project}->{project_id}, $::params->{TMPL_VARS}->{const}->{PATH_INFO});
        if($sth->rows()){
            my $default_type='text/plain';
            if($::params->{TMPL_VARS}->{const}->{PATH_INFO}=~m/\.html$/){
                $default_type='text/html';
            }
            my $body=$sth->fetchrow();
            #эта хня нужна обязательно для правильного вывода роботсов Атн
            print "Content-type: $default_type\n\n";
            #print $::params->{PATH_INFO};
            print $body;
#	    if($default_type == 'text/html'){print "<!-- test -->";}
            &end;
        }
    }
    # --
    # В зависимости от текущего URL'а выполняем тот или иной код
    my $rules_list=undef;
    if(0 && index($::params->{project}->{options},';cache_rules;')>=1){
        if(defined($CACHE->{$::params->{project}->{project_id}}->{cache_rules})) # $CACHE->{$::params->{project}->{project_id}}->{cache_rules}
        {
            $rules_list=$CACHE->{$::params->{project}->{project_id}}->{cache_rules};
        }
        else{
            $rules_list=&SQL_hash_all("SELECT * from url_run_code WHERE template_id=? order by sort",undef,$::params->{project}->{template_id});
            $CACHE->{$::params->{project}->{project_id}}->{cache_rules}=$rules_list;
        }
        
    }
    else{


        if(0 && index($::params->{project}->{tempate_options},';run_code_on_fs;')>=-1){
            # чтение правил для кодов из файловой системы 
            my $dir='./admin/develop_rules/'.$::params->{project}->{template_id};
            opendir D,$dir || &print_error(qq{Не могу считать каталог '$dir'});
            foreach my $file (grep { /^\d+$/} readdir D){
                open F, qq{$dir/$file};
                my $element=undef; my $str=0;
                while(<F>){
                    my $line=$_;
                    $str++;
                    if(($str==1 || $str==2) && $line=~m/^#header:(.+)$/){
                        $element->{header}=$1;
                    }
                    if(($str==1 || $str==2) && $line=~m/^#url_regexp:(.+)$/){
                        $element->{url_regexp}=$1;
                    }
                    else{
                        $element->{run_code}.=$line;
                    }
                    
                }
                close F;
                
                push @{$rules_list},$element;
                $element=undef;$str=undef;
            }
            
            closedir D;
        }
        else{
            # чтение правил для кодов из БД (традиционно)
            $rules_list=&::SQL_hash_all("SELECT * from url_run_code WHERE template_id=? order by sort",undef,$::params->{project}->{template_id});
        }
    }
    
    
    #print "Content-type: text/html\n\n";
    
    foreach my $rul (@{$rules_list}){
        
        #print "<!-- $rul->{url_regexp} -->\n";
        
=cut
        eval(q{$params->{TMPL_VARS}->{const}->{PATH_INFO}=~m/$rul->{url_regexp}/});
        if($@){
            &print_error("ошибка в регулярном выражении $@".$rul->{url_regexp});
            $params->{stop}=1;
            return;
        }
=cut
        if($::params->{TMPL_VARS}->{const}->{PATH_INFO}=~m/$rul->{url_regexp}/){ # URL подходит
  ###Isavnin 8.08.2013
  #          $::params->{TMPL_VARS}{CONTROLLER_ID}=$rul;
            eval($rul->{run_code});
            
            return if($::params->{stop});
            if($@){ # При ошибке отладочная инфа
                $rul->{run_code}=~s/ /&nbsp;/gs;
                my $i=0;
                $rul->{run_code}=join('<br>',map {$i++; s/^(.+)$/$i&nbsp;$1/gs; $_} split /\n/,$rul->{run_code});
                $i=1;#my $i=1;
                
                &::print_error(qq{
                      Произошла ошибка $@         
                });
                
                #&::print_error(qq{
                #    <p><b>$ENV{REQUEST_METHOD} http://$ENV{SERVER_NAME}/$ENV->{PATH_INFO}</b></p>
                #    При выполнении кода $rul->{header}:<br/>
                #    <hr>
                #    <div style='font-size: 10pt;'>
                #    $rul->{run_code}<br/>
                #    </div>
                #    </hr>
                #    произошла ошибка:
                #    $@;
                #});
                
                $::params->{stop}=1;
                return ;
            }
            
        }
###        if (defined($::params->{TMPL_VARS}{page_type})) {
###            $::params->{project}{url_run_code_id} = $rul->{url_run_code_id};
###        }
        last if(defined($::params->{TMPL_VARS}->{page_type}));
###        if (defined($::params->{TMPL_VARS}->{page_type})) {
###            $::params->{project}{url_run_code_id} = $rul->{url_run_code_id};
###            last;
###        }
    }
    $rules_list=undef;
    #   print Dumper($::params->{TMPL_VARS}); exit;
    if(!$::params->{TMPL_VARS}->{page_type}){
        # последний шанс... поиск в  files
        if($::params->{TMPL_VARS}->{const}->{PATH_INFO} eq '/robots.txt'){ # если запрашивался robots.txt -- выдаём дефалтовый
            print "Content-type: text/plain\n\n";
            if($::params->{project}->{domain} =~ /^(\w+)\.designb2b\.ru$/){
              print "User-agent: *\nDisallow: /\n";
            }
            else{
              print "User-agent: *\nDisallow: \n";
            }
            &end;
        }
#        elsif($::params->{TMPL_VARS}->{content} = &::GET_DATA({table=>'files',onerow=>1,where=>'url=? AND project_id=?'},($::params->{TMPL_VARS}->{const}->{PATH_INFO},$::params->{project}->{project_id}))){
#          print "Content-Type: text/plain\n\n $::params->{TMPL_VARS}->{content}->{body}\n\n";
#	}
#	elsif($::params->{TMPL_VARS}{content} = &::GET_DATA({table=>'files',where=>'url=? AND project_id=?',onerow=1,},($::params->{TMPL_VARS}{const}{PATH_INFO},$::params->{project}{project_id}))){
#		print "Content-Type: text/plain\n\n";
#		print "$::params->{TMPL_VARS}{content}{body}\n";
#	}
=cut
        else{
            print "Status: 404 Not Found\n";
            #my $html404 = qq{
            #    <h1>Ошибка 404 - такой страницы не существует ($ENV{REQUEST_URI})</h1>
            #    <p>Пожалуйста <a href="/">перейдите на главную</a> для поиска нужного Вам раздела.</p>
            #};
            my $html404 = qq{
              <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
              <html xmlns="http://www.w3.org/1999/xhtml">
              <head>
                <meta http-equiv="Content-Type" content="text/html; charset=windows-1251" />
                <title>404</title>
                <style type="text/css">
                  html,body{ margin:0; padding:0; }
                  .error-box{ color:#424040; width:361px; font:12px/1.2 Tahoma, Geneva, sans-serif; padding:74px; }
                  .error-box .h{  color:#fff;  line-height:24px; font-size:16px; border-bottom:1px solid #000; overflow:hidden; zoom:1; margin-bottom:43px; }
                  .error-box .h div{ background:#242323; float:left; padding:0 7px; }
                  .error-box .err{ margin-bottom:33px; font-size:1000%; font-weight:bold; width:228px; height:119px; }
                  .error-box .txt{ margin-bottom:15px; border:solid #bdbdbd; border-width:1px 0; padding:12px 0; line-height:1.4; }
                  .error-box .fl-lt{ float:left; }
                  .error-box .fl-rt{ float:right; }
                  .error-box .over{ overflow:hidden; zoom:1; }
                  .error-box a{ color:#2b84d0; }
                </style>
              </head>
              <body>
                <div class="error-box">
	          <div class="h"><div>Ошибка</div></div>
                  <div class="err">404</div>
	          <div class="txt">Это обозначает, что запрошенному вами URL не соответствует никакая страница сайта. Этому могут быть две причины:
                  <b>ссылка неверна</b> или ранее существовавшая <b>страница была удалена</b>.</div>
                  <div class="over">
                    <a class="fl-lt" href="/">Назад на главную</a> 
                    <span class="fl-rt">Разработка сайтов: <a href="http://www.designb2b.ru">DesignB2B</a></span>
                  </div>
                </div>
              </body>
              </html>
            };
            &::print_header;
            print $html404;
            &::end;
        }
=cut
    }
    return if($::params->{stop});
    # Впределяем, в зависимости от URL'а, какой шаблон использовать
    # !!! Здесь тоже можно оптимизировать
    my $template_rules_list;
    unless($::params->{template_name}){
        $template_rules_list=&::SQL_hash_all("SELECT * from url_rules WHERE template_id=? order by sort",undef,($::params->{project}->{template_id}));
        
        
        foreach my $rul (@{$template_rules_list}){
            my $reg_true;
            eval(q{$reg_true=($::params->{TMPL_VARS}->{const}->{PATH_INFO}=~m/$rul->{url_regexp}/)});
            if($@){
                &::print_error("Ошибка в регулярном выражении $rul->{url_regexp}<br>".$@);
                return;
            }
            if($reg_true){ # URL подходит для шаблона?
               $::params->{template_name}=$rul->{template_name};
                return;
            }
        }
        $template_rules_list=undef;
    }
    
    
    #if ( $::params->{TMPL_VARS}->{const}->{PATH_INFO} eq '/sitemap.xml' ) {
    #   print "Content-type: text/plain\n\n";
    #   
    #}
    

    
    # если не известен шаблон, с которым работаем -- отбой
    if(!$::params->{template_name}){
        $::params->{template_name}='index.tmpl';
#	unless(-e qq{$params->{project}->{template_folder}.'/index.tmpl'}){&print_error(qq{$::params->{template_name} not found});}
        #print "Status: 404 Not Found\n";
        #&::print_error("Error 404\nНе задан обработчик шаблона для $ENV{PATH_INFO} ");
        #return ;
    }
    

}

sub get_system{
    # всякие системные параметры (как подключаться к БД и пр.)  
    use vars qw($DBname $DBhost $DBuser $DBpassword);
    my $system; my $s='';
    open F,'./manager/connect';
    while(<F>){$s.=$_;}
    close F;
    $s.=q{$system->{DBname}=$DBname;$system->{DBhost}=$DBhost;$system->{DBuser}=$DBuser;$system->{DBpassword}=$DBpassword;};
    eval($s);
    print $@ if($@);
    $system->{TEMPLATE_DIR}='./templates';
    $system->{DEBUG}=1;
    return $system;
}

sub GET_CONTENT{
    my $p=shift;
    $p=$::ENV{PATH_INFO} unless($p);
    return &::SQL_hash(q{SELECT body from content WHERE project_id=? and url=?},$::params->{project}->{project_id},$p);
}

sub GET_PATH{
    # Возвращает путь для иерархической таблицы (полезно для нав. строки типа "хлебные крошки"
    
    my $opt=shift;
    $opt->{connect}=$::params->{dbh} unless($opt->{connect});
    my $table;
    my $table_id='rubricator_id';
    if($opt->{table}){
        $table=$opt->{table};
        $table_id=&get_work_table_id_for_table($opt->{table});
    }
    elsif($opt->{struct}){
        $table=&get_table_from_struct($opt->{struct});
        $table_id=&get_work_table_id_for_struct($opt->{struct});
    }
    
    my $path=&SQL_row("SELECT path FROM $table WHERE $table_id = ?", $opt->{connect},$opt->{id});
    $path.=qq{/$opt->{id}} unless($opt->{not_last});

    my $path_string;
    
    if($opt->{good_calculate} && !$opt->{good_calculate_struct}){
        $opt->{good_calculate_struct}='good';
    }
    $opt->{header_field}='header' unless($opt->{header_field});
    while($path=~m/(\d+)/g){
        my $rub_id=$1;
        my $header=&SQL_row("SELECT $opt->{header_field} FROM $table WHERE $table_id = ?", $opt->{connect},$rub_id);
        my $element={header=>$header, id=>$rub_id};
        if($opt->{good_calculate}){
                $element->{count}=&GET_DATA({
                    struct=>$opt->{good_calculate_struct},
                    select_fields=>'count(*)',
                    where=>'rubricator_id=?',
                    onevalue=>1,
                },$rub_id);
                if($element->{count}){
                    $element->{href}=qq{/goods/$element->{id}};
                    $element->{url}=qq{/goods/$element->{id}}; #add
                }
                else{
                    $element->{href}=qq{/rubricator/$element->{id}};
                    $element->{url}=qq{/rubricator/$element->{id}}; #add
                }
        }
        elsif($opt->{create_href}){
            $element->{href}=$opt->{create_href};
            $element->{href}=~s/\[%id%\]/$element->{id}/gs;
            $element->{url}=~s/\[%id%\]/$element->{id}/gs; #add
        }
        push @{$path_string}, $element;
    }
    if($opt->{to_tmpl}){
        $::params->{TMPL_VARS}->{$opt->{to_tmpl}}=$path_string;
    }
    else{
        return $path_string;
    }
}

sub CONTEXT_SEARCH{
    # процедура, отвечающая за поиск по нескольким таблицам лайком
    my $opt=shift;

    my $query='';
    my $i=0;
    my @like=();
    foreach my $part (@{$opt->{info}}){ # перебираем таблицы для выборки
                
        unless($part->{header}){
            print_error("Не указан header! (CONTEXT_SEARCH)");
            return ;
        }

        unless($part->{table}){
            print_error("Не указан table! (CONTEXT_SEARCH)".&pre($part));
            return ;
        }

        unless($part->{s_part}){
            print_error("Не указан s_part! (CONTEXT_SEARCH)");
            return ;
        }
        
        unless($part->{s_part}){
            print_error("Не указан url! (CONTEXT_SEARCH)");
            return ;
        }
        my $subquery='';
        $subquery=$part->{where} if($part->{where});
        while($opt->{pattern}=~m/(\S+)/g){
            my $w=$1;
            $w=~s/[аеёийоуьыэюя]{1,2}$// if(length($w)>3);
            push @like, '%'.$w.'%';
            $subquery.=" AND " if($subquery);
            $subquery.=" $part->{s_part} like ? ";
        }
	
	#&pre(\@like);
	
        $query.=" UNION \n" if($i);
        $query.=qq{ ( SELECT $part->{header} as header, $part->{s_part} as s_part, $part->{url} as url FROM $part->{table}  WHERE $subquery\n};
        $query.=qq{ AND ($part->{where})} if($part->{where});
        $query.=' )';
        $i++;
    }

    $opt->{connect}=$params->{dbh} unless($opt->{connect});
 
  
  # присекаем xss
  $opt->{pattern}=~s/</&lt;/gs;
  $opt->{pattern}=~s/>/&gt;/gs;
  
  #push @like, '%'.$opt->{pattern}.'%' foreach(1..$i);  
  
    if($opt->{perpage}=~m/^\d+$/){ # учитываем расстраничивание
        my $sth=$opt->{connect}->prepare("SELECT count(*) from ($query) as xcnt");
        $sth->execute(@like);
        #pre("SELECT count(*) from ($query) as xcnt");
        $::params->{TMPL_VARS}->{total_count}=$sth->fetchrow();
        #pre($::params->{TMPL_VARS}->{total_count});
        my $query_count=$params->{TMPL_VARS}->{search_count}="SELECT CEILING(count(*) / $opt->{perpage}) from ($query) as xcnt";
        if($opt->{debug}){
            &print_header;
            print "SEARCH DUMPER: <pre>$query_count</pre><br>";
            print join(';',@like)
        }
        $sth=$opt->{connect}->prepare($query_count);    
        $sth->execute(@like) || die ($::params->{dbh}->{errorstr});
        $opt->{maxpage}=$sth->fetchrow();
        
        my $limit1=($::params->{TMPL_VARS}->{page}-1)*($opt->{perpage});

        $query=qq{select SQL_CALC_FOUND_ROWS * from ($query) as res limit $limit1, $opt->{perpage}};
    }
    
  
  
    if($opt->{debug}){
      &print_header;
      print "SEARCH DUMPER: <pre>$query</pre><br>";
      print join(';',@like)
    }
  my $sth;
  eval(q{
    $sth=$opt->{connect}->prepare($query);
    $sth->execute(@like) || die ("query: $query<br>".$!);
  });
  if($@){
      &print_error($@);
      exit;
  }
  
  my $result=$sth->fetchall_arrayref({});
  my $s_regexp=$opt->{pattern};
  $s_regexp=~s/\s+/\\s\+/gs;
  use POSIX qw/setlocale LC_ALL LC_CTYPE/;
  use locale;  
  setlocale(LC_CTYPE, "ru_RU.cp1251");
  #$s_regexp=~s/абвгдеёжзийклмнопрстуфхцчшщьыъэюя/[аА][бБ][вВ][гГ][дД][еЕ][ёЁ][жЖ][зЗ][иИ][йЙ][кК][лЛ][мМ][нН][оО][пП][рР][сС][тТ][уУ][фФ][хХ][цЦ][чЧ][шШ][щЩ][ьЬ][ыЫ][ъЪ][эЭ][юЮ][яЯ]/gs;
  #&pre($s_regexp);
  foreach my $r (@{$result}){# before_symbols  after_symbols mark_tag_begin mark_tag_end
        $r->{s_part}=~s/<.+?>//gs;
        $r->{s_part}=~s/\s\s+/ /gs;
        #$r->{s_part}=~s/^.*?\s*(.{0,100})?($s_regexp)(.{0,100}\S)?\s*.*$/$1<strong>$2<\/strong>$3/gs;
        #&pre($r->{s_part});
        $r->{s_part}=~s/($s_regexp)/<strong>$1<\/strong>/igs;
    }
  
  $::params->{TMPL_VARS}->{GET_CONTENT_COUNT}=$opt->{connect}->selectrow_array("SELECT FOUND_ROWS()");
  
  if($opt->{to_tmpl}){
        $::params->{TMPL_VARS}->{$opt->{to_tmpl}}=$result;
        return $opt->{maxpage} if($opt->{perpage}=~m/^\d+$/);
    }
    else{
        return $result;
    }
    
}

sub GET_MULTIMENU{
    foreach my $element (@{&SQL_hash_all("SELECT * from multimenu WHERE project_id=?",undef,$::params->{project}->{project_id})})
    {
        if($::ENV{PATH_INFO}=~/$element->{url}/){
            # УРЛ совпал
            $::params->{TMPL_VARS}->{MULTIMENU}=
                &SQL_hash_all("SELECT * from multimenu_list WHERE multimenu_id=? order by sort",undef, $element->{multimenu_id});
                last;
        }
    }
}

sub GET_FORM{
    my $form=shift;
    $form->{connect}=$::params->{dbh} unless($form->{connect});
    $form->{action_field}='action' unless($form->{action_field});
    my $work_table;
    if($form->{struct}){
        $work_table=&get_table_from_struct($form->{struct})
    }
    elsif($form->{table}){
        $work_table=$form->{table};
    }
    
    my $action=param($form->{action_field});
    
    $form->{work_table_id}=&get_work_table_id_for_struct($form->{struct});  
    if($action ne 'form_send'){
        if($form->{record_method} eq 'update'){
            #print "Читаем данные";
            my $form_values=&SQL_hash("SELECT * from $work_table where $form->{work_table_id}=?",$form->{connect},($form->{struct_id}));
            return ('0',$form_values);
        }
        return 0;
    }
    else{ # форма передавалась, проверяем
      $form->{record_method}='insert'
            unless($form->{record_method});
            
        my @names=();   my @values=(); my @vopr=();
        my $errors; my $form_values;
    if($form->{use_capture}){ # включено использование капчи, проверяем

      #Исавнин, добавляем проверку на ввод данных
      my $str_key=param('capture_key');
      my $str=param('capture_str')?param('capture_str'):'CAPTURE_STR_INPUT_ERROR';


      my $str_res=&SQL_row("SELECT str from capture WHERE project_id=? and str_key=?",undef,
                (
                    $::params->{project}->{project_id},
                    $str_key,
                    
                )
    );
      
      
      
    $str_res=~s/=$//;
    #&print_header;
    #print "str_key: $str_key<br>";
    #print "str_res: $str_res<br>";
    #print "str: $str<br>eq: ".(eval($str_res) eq $str);
            unless((eval($str_res) eq $str)){ # капча не подошла ; eval нужен для всяких выражений типа 5+8
                    push @{$errors},
                    "Проверочный числовой код введён неверно";
            }
            #Исавнин, удаление из БД после проверки, не смотря на результат проверки
            #&SQL_row(
            $::params->{dbh}->do("DELETE FROM capture WHERE project_id=? AND str_key=?",undef,($::params->{project}{project_id},$str_key));
            
        }
        foreach my $field (@{$form->{fields}}){
            next if($field->{read_only} || $field->{readonly});
            my $value=&html_strip(param($field->{name}));
            $value=~s/^\s+//;
            $value=~s/\s+$//;
            $value=~s/\s\s+/ /gs;
            #--- sanman -- encode=>'utf8;cp1251' ---
            if($form->{encode}){
                my ($trom,$to) = split ';',$form->{encode};
                if($trom && $to){
                    Encode::from_to($value, $trom, $to);
                }
            }
            #----------------
            $value=~s/</&lt;/gs; $value=~s/>/&gt;/gs; # html-фильтр         
            if($field->{value}=~m/^func::(.+?)$/){ # В значениях функция Mysql
                my $fname=$1;
                if($form->{record_method} eq 'insert'){ # Если Insert
                    push @names, $field->{name};
                    push @vopr, $fname;
                }
                elsif($form->{record_method} eq 'update'){ #
                    push @names,qq{$field->{name}=$fname}
                }
            }
            else{
                $field->{value}=$value unless($field->{value});
                if($field->{s}){
                    $field->{value}=~s/${$field->{s}}[0]/${$field->{s}}[1]/gs;
                }
                $form_values->{$field->{name}}=$value;
                if($form->{record_method} eq 'insert'){
                    push @names, $field->{name};
                    push @vopr, '?'
                }
                elsif($form->{record_method} eq 'update'){
                    push @names, qq{$field->{name}=?};
                }
                push @values, $field->{value};
                
            }
            if($field->{uniquew}){ # если поле должно быть уникальным:
                my $query="SELECT count(*) FROM $work_table WHERE $field->{name}=?";
                $query.=qq{ and $form->{work_table_id}<>$form->{struct_id}} if($form->{record_method} eq 'update');
                my $sth=$form->{connect}->prepare($query);
                $sth->execute($field->{value});
                my $c=$sth->fetchrow();
        
                if($c){
                    push @{$errors},
                    "Уже существует запись с полем '$field->{description}',  '$field->{value}' ";
                }
                
            }
            if($field->{regexp} && !($field->{value}=~m/$field->{regexp}/)){
                my $err;
                
                if($field->{error_regexp}){
                    $err=$field->{error_regexp};
                }
                else{
                    $err="Поле $field->{description} не заполнено или заполнено неверно";
                }
                push @{$errors},$err;
            }
        }
        
        
        if($#{$errors}>=0){ # Произошли ошибки
            return ($errors,$form_values);
        }
        else{ # ошибок нет
            if($form->{use_capture}){ # включено использование капчи, проверяем
                my $str_key=param('capture_key');
                my $str=param('capture_str');
                my $sth=$::params->{dbh}->prepare("DELETE from capture WHERE project_id=? and str_key=? and str=?");
                $sth->execute(
                        $::params->{project}->{project_id},
                        $str_key,
                        $str
                );
            }
            if($work_table){ # если указана структура -- пишем в неё
                    unless($work_table){
                        print_error ("Ошибка! не известно, в какую таблицу записывать данные формы");
                        return;
                        
                    }
# sanman
                    @values = map{ $_ ? $_ : ''} @values;
                    my @names1 = map{ "`$_`"} @names;
#############
                    if($form->{record_method} eq 'insert'){ #INSERT
                        my $vopr=join ',',(split //,('?' x ($#names1+1)));
                        if($form->{debug}){
                            &print_header;
                            print "<br>INSERT INTO $work_table(".join(',',@names1).') VALUES('.join(',',@values).')';
                            print "<br>".join(',',@values)."<br/>";
                        }
                        my $sth=$form->{connect}->prepare("INSERT INTO $work_table(".join(',',@names1).') VALUES('.join(',',@vopr).')');
                        $sth->execute(@values) || die($sth->errstr);
                        if($form->{insert_id_ref}){
                            ${$form->{insert_id_ref}}=$form->{insert_id}=$sth->{mysql_insertid};
                        }
                    }
                    elsif($form->{record_method} eq 'update'){ #UPDATE
                        unless($form->{struct_id}=~m/^\d+$/){
                            &print_error('<br/>struct_id должно быть числом<br/>');
                            return
                        }
                        my $q="UPDATE $work_table SET ".join(', ',@names)." WHERE $form->{work_table_id}=$form->{struct_id}";
                        if($form->{debug}){
                            &print_header;
                            print "<br>$q<br/>";
                            print "<br>".join(',',@values)."<br/>";
                        }
                        my $sth=$form->{connect}->prepare($q);
                        $sth->execute(@values);
                    }
            }
            foreach my $mail_send (@{$form->{mail_send}}){
                #print "Отправляем сообщение на адрес $form->{mail_send}->{to}";
                $mail_send->{from}='no-reply@'.$::params->{project}->{domain} unless($mail_send->{from});
                my $filelist;
                foreach my $field (@{$form->{fields}}){
                    my $value;
                    
                    if($field->{type} eq 'file'){
                        # сохраняем файл, запоминаем его имя и полный путь к файлу
                        my $orig_filename=param($field->{name});
                        if($orig_filename=~m/([^.]+)$/){
                            my $ext=$1;
                            # генерим случайное имя файла:
                            my $a='123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
                            my $filename='';
                            foreach my $k (1..50){
                                $filename.=substr($a,int(rand(length($a))),1)
                            }
                            $filename.='.'.$ext;
                            open F,qq{>./temp/$filename};
                            binmode F;
                            print F while(<$orig_filename>);
                            close F;
                            push @{$filelist},{
                                full_path=>qq{./temp/$filename},
                                filename=>$orig_filename
                            };
                            
                            # foreach my $f (@{$mail_send->{files}}){
                            foreach my $f (@$filelist){
                                $f->{full_path}=~s/\[%$field->{name}.full_path%\]/\.\/temp\/$filename/;
                                $f->{filename}=~s/\[%$field->{name}.filename%\]/$orig_filename/
                            }

                            $$mail_send{files}=$filelist;
                        }
                    }
                    
                    if($field->{values}){
                        while($field->{values}=~m/(\d+)=>([^;]+)/g){
                            my ($k,$v)=($1,$2);
                            if($k eq $field->{value}){
                                $value=$v;
                                last;
                            }
                        }
                    }
                    else{
                        $value=$field->{value};
			push @{$mail_send->{fields}},$field;
                    }
                    
                    $value=~s/\n/<br\/>/gs;
                    $mail_send->{message}=~s/\[%$field->{name}%\]/$value/gs;
                    $mail_send->{from}=~s/\[%$field->{name}%\]/$value/gs;
                    $mail_send->{to}=~s/\[%$field->{name}%\]/$value/gs;
                }
                
                $mail_send->{message}=~s/\[%insert_id%\]/$form->{insert_id}/gs;             
		if($form->{html} eq '1'){
			&send_html_msg($mail_send);
		}
		else{
       	        	&send_mes($mail_send);
		}

                foreach my $f (@{$filelist}){
                    unlink($f->{full_filename});
                }
                $filelist=undef;
            }

            #Исавнин, доработка сбора данных для рассылки
	if(!$form->{dbgfs}){
                        $save_data = {
                                email => 'undefined',
                                name => 'undefined',
                                phone => 'undefined',
                                message => '',
				remote_addr => $ENV{HTTP_X_FORWARDED_FOR} ? $ENV{HTTP_X_FORWARDED_FOR} : $ENV{REMOTE_ADDR},
                        };
                        foreach my $f (@{$form->{fields}}){
                                if($f->{name} =~ m/(email|name|phone)/){
#                                       &pre($f->{name});
                                        $save_data->{"$f->{name}"}=$f->{value};
                                }
                                elsif($f->{name} eq 'message'){
                                        $save_data->{message}.=$f->{value}.'\r\n';
                                }
                                else{
                                        $save_data->{message}.="\"$f->{name}\":\"$f->{value}\"\r\n";
                                }
                        }
#                        $sql=qq{INSERT INTO form_data(project_id,registered,email,name,phone,message,city,otrasl,remote_addr) VALUES($params->{project}{project_id},CURRENT_TIMESTAMP(),"$save_data->{email}","$save_data->{name}","$save_data->{phone}","$save_data->{message}",1,1,"$save_data->{remote_addr}")};
                        $params->{dbh}->do("
				INSERT INTO form_data(project_id,registered,email,name,phone,message,city,otrasl,remote_addr)
				VALUES(?,CURRENT_TIMESTAMP(),?,?,?,?,?,?,?)",undef,
				(
					$params->{project}{project_id},				
					$save_data->{email},
					$save_data->{name} || '',
					$save_data->{phone},
					$save_data->{message},
					1,1,
					$save_data->{remote_addr}
				)
			);
                }

           


            return (1,$form_values);
        }
        
            return ($errors,$form_values);
        }
    }

sub START_SESSION{
    use vars qw($::params);
# проверяет, заведена ли сессия
  my $sess=shift;
  my $user_id=cookie('auth_user_id');
  my $key=cookie('auth_key');
    $sess->{session_table}='session'
            unless($sess->{session_table}); 

    my $c=&SQL_row("SELECT count(*) FROM $sess->{session_table} WHERE project_id=? and auth_id=? and session_key=?",
        undef,
        ($::params->{project}->{project_id}, $user_id, $key)
    );

    if($c){ # если сессия верна
        $sess->{auth_table}=&get_table_from_struct($sess->{auth_struct})
            if($sess->{auth_struct});
        $::params->{TMPL_VARS}->{login_info}=&SQL_hash("SELECT * from $sess->{auth_table} WHERE $sess->{auth_id_field}=?",$sess->{connect},($user_id));
    }
    else{
        $::params->{TMPL_VARS}->{login_info}=undef;
    }
}

sub DROP_SESSION{
    use vars qw($::params);
    my $sess=shift;
    
    $sess->{session_table}='session'
            unless($sess->{session_table});
            
  my $user_id=cookie('auth_user_id');
  my $key=cookie('auth_key');

  if($user_id=~m/^\d+$/ && $key){       
        my $sth=$::params->{dbh}->prepare("DELETE FROM $sess->{session_table} WHERE project_id=? and auth_id=? and session_key=?");
        $sth->execute($::params->{project}->{project_id}, $user_id, $key);
        
    }
    $::params->{TMPL_VARS}->{login_info}=0; 
}

sub CREATE_SESSION{
    my $sess=shift;

    if(!$sess->{auth_struct} && !$sess->{auth_table}){
        print_error('При создании сесси: не указано ни auth_struct, ни auth_table');
        return;
    }
    
    if(!$sess->{login}){
        $sess->{login}=param('login');
        unless(defined($sess->{login})){
            print_error('При создании сессии (не указан login)');
            return;
        }
    }
    
    if(!$sess->{password}){
        $sess->{password}=param('password');
        unless(defined($sess->{password})){
            print_error('При создании сессии (не указан password)');
            return ;
        }   
    }
    
    if(!$sess->{auth_id_field}){
        print_error('При создании сессии (не указан auth_id_field)');
        return;
    }

    # Таблица, по кот. будем проверять логин и пароль
    $sess->{auth_table}=&get_table_from_struct($sess->{auth_struct})
        if($sess->{auth_struct});
    
    $sess->{auth_log_field}='login' unless($sess->{auth_log_field});
    $sess->{auth_pas_field}='password' unless($sess->{auth_pas_field}); 
    $sess->{session_table}='session' unless($sess->{session_table});    
    
    # 1. Узнаём идентификатор записи того, кто логинится:
    my $add_where='';
    if($sess->{where}){
        $add_where=qq{ AND $sess->{where}};
    }

    if($sess->{debug}){
        &print_header;
        print "SELECT $sess->{auth_id_field} FROM $sess->{auth_table} WHERE $sess->{auth_log_field}='$sess->{login}' AND $sess->{auth_pas_field}='$sess->{password}' $add_where<br>";
    }
    my $user_id=&SQL_row("SELECT $sess->{auth_id_field} FROM $sess->{auth_table} WHERE $sess->{auth_log_field}=? AND $sess->{auth_pas_field}=? $add_where",$sess->{connect},($sess->{login}, $sess->{password}));
    
    if($user_id=~m/^\d+$/){ # залогинились
        
        # 3. Генерируем ключ сессии
        my $a='123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        my $key='';
        foreach my $k (1..200){
            $key.=substr($a,int(rand(length($a))),1)
        }
    
        # 4. Делаем запись в таблицу сессий
        my $sth=$::params->{dbh}->prepare(qq{
                INSERT INTO $sess->{session_table}(project_id, auth_id, registered, session_key)
                VALUES(?,?,now(),?)}
        );
    
        $sth->execute($::params->{project}->{project_id},$user_id, $key);
        
        # 5. Вешаем куку
        my $auth_user_id=new CGI::Cookie(
            -name=>'auth_user_id',
            -value=>$user_id
        );
        my $auth_key=new CGI::Cookie(
            -name=>'auth_key',
            -value=>$key
        );
        
        $::params->{TMPL_VARS}->{login_info}=&SQL_hash("SELECT * from $sess->{auth_table} WHERE $sess->{auth_id_field}=?",$sess->{connect},($user_id));
        
        print "Set-Cookie: $auth_user_id\nSet-Cookie: $auth_key\n";
        return;
    }
    else{
        $::params->{TMPL_VARS}->{login_info}='0';
        return;
    }   
}

#=cut
sub send_html_msg {
	my($opt) = @_;
	if($opt->{to} !~ /@/){
		&print_error(qq{Невозможно отправить сообщение на адрес '$opt->{to}'});
		return;
	}
	

	my $mail_tmpl = '/templates/mail_tmpl/';
	my $fld = $ENV{DOCUMENT_ROOT}.$mail_tmpl;

	my $tmpl_vars = {
		fields => $opt->{fields},
		site => $::params->{project}{domain},
		TEMPLATE_FOLDER => 'http://'.$::params->{project}{domain}.$mail_tmpl,
		const => $::params->{TMPL_VARS}{const},
		tv => $::params->{TMPL_VARS},
	};
	
	if($opt->{tmpl}){
		$fld = $::params->{project}{template_folder};
		$fld =~ s/^\.//;
		$tmpl_vars->{TEMPLATE_FOLDER}='http://'.$::params->{project}{domain}.$fld.'/mail';
		$mail_tmpl=$ENV{DOCUMENT_ROOT}.$fld.'/mail/';
		$fld = $mail_tmpl;
		
	}

	#print "FLD: $fld\r\n MAIL_TMPL: $mail_tmpl\r\n";

	my $letter = MIME::Lite::TT::HTML->new({
		From => ($opt->{from} ? $opt->{from} : 'no-reply@'.$::params->{project}{domain}),
		To => $opt->{to},
		Subject => ($opt->{subject} ? $opt->{subject} : 'Сообщение с сайта'.$::params->{project}{domain}),
		TimeZone => 'Europe/Moscow',
		Encoding => 'base64',#'quoted-printable',
		Template => {html=>($opt->{tmpl} ? $opt->{tmpl} : 'default.tmpl')},
		Charset => ($opt->{charset} ? $opt->{charset} : 'Windows-1251'),
		TmplOptions => {INCLUDE_PATH=>$fld},
		TmplParams => $tmpl_vars,
	});
	if(scalar(@{$opt->{files}})){
		$letter->attr("content-type"=>"multipart/mixed");
		shift @{$letter->{Parts}};
		
	}
	foreach my $f (@{$opt->{files}}){
		$letter->attach(
			Type => 'AUTO',
			Disposition => 'attachment',
			Filename => $f->{filename},
			Path => $f->{full_path},
		);
	}

	$letter->send() || &print_error("Cant send letter $!");
	
}
#=cut

sub send_mes{
    my $opt=shift;
    #pre $opt;
    if($opt->{to}!~/@/){
        &print_error(qq{Невозможно отравить сообщение на адрес '$opt->{to}'});
        return;
    }
    $opt->{subject} = MIME::Base64::encode(($opt->{charset} ? encode($opt->{charset},$opt->{subject}) : $opt->{subject}),"");
    $opt->{subject} = "=?".($opt->{charset} ? $opt->{charset} : "windows-1251")."?B?".$opt->{subject}."?=";
#    $opt->{subject} = "=?windows-1251?B?".$opt->{subject}."?=";
    my $letter = MIME::Lite->new(
        From => $opt->{from},
        To => $opt->{to},
        Subject => $opt->{subject},
        Type=> 'multipart/mixed',
    ) || &print_error("Can't create $!");
    # attach body
    $letter->attach (
        Type => 'text/html; charset='.($opt->{charset} ? $opt->{charset} : 'windows-1251'),
        Data => ($opt->{charset} ? encode($opt->{charset},$opt->{message}) : $opt->{message}),
    ) or warn "Error adding the text message part: $!\n";

#   &print_header;
#   print Dumper($opt);
    foreach my $f (@{$opt->{files}}){

            $letter->attach(
                Type => 'AUTO',
                Disposition => 'attachment',
                Filename => $f->{filename},
                Path => $f->{full_path},
            );
        
    }
    $letter->send() || &print_error("Can't send $!");
}
sub print_header{
    #&print_last_modified if($::params->{project}->{project_id}<80);
    print "Content-type: text/html; charset=windows-1251\n\n" unless($::params->{print_header});
    $::params->{print_header}=1;
}

sub print_error{
    my $err=shift;
    #20.02.2014 Isavnin - Выносим ошибки в шаблоны и наводим красоту
    $::params->{error}{status}='500' unless($::params->{error}{status});
    $::params->{error}{info}='Internal Server Error' unless($::params->{error}{info});
    print "Status: $::params->{error}{status} $::params->{error}{info}\n";
#    print "Content-Type: text/html; charset=windows-1251\n\n";
    &print_header;

    $::params->{TMPL_VARS}{system_debug}=1; #Но по хорошему надо прятать, все равно в лог пишет.
    $::params->{template_name}=$::params->{error}{status};
    $::params->{TMPL_VARS}{err}=$err;
    my $template=Template->new({
      INCLUDE_PATH=>$ENV{DOCUMENT_ROOT}.'/templates/error',
      COMPILE_EXT=>'.tt2',
      COMPILE_DIR=>'./tmp',
      CACHE_SIZE=>512,
      DEBUG_ALL=>1,
    });
    $::params->{template_name}=$::params->{error}{status}.'.tmpl';
    $::params->{TMPL_VASR}{err}=$err;
    $template->process($::params->{template_name},$::params->{TMPL_VARS},undef) || die "Internal Script Error: ".$template->error(); #croak "Internal Script Error: ".$template->error();
    
    #print $err;
   
    ##my ($sec,$min,$hour,$day,$mon,$year)=(localtime(time-3600))[0..5];
    ##$mon++;
    ##$year+=1900;
    
    ##if($system->{DEBUG}){
    ##   open F, '>>log';
    ##   print F qq{$year-$mon-$day $hour:$min:$sec project: $::params->{project}->{project_id}<br>$::params->{project}->{domain} $ENV{REQUEST_METHOD} $ENV{REQUEST_URI})}.$err.qq{<hr>};
    ##   close F;
    ##}
    &to_error_log(qq{$::params->{project}->{project_id}<br>$::params->{project}->{domain} $ENV{REQUEST_METHOD} $ENV{REQUEST_URI})}.$err);
    $::params->{stop}=1;
    &end;
    ##exit;
}

sub urldecode{
    my $val=shift;
    $val=~s/\+/ /g;
    $val=~s/%([0-9a-hA-H]{2})/pack('C',hex($1))/ge;
    return $val;
}

sub pre{
    my $data=shift;
    eval(q{
    &print_header;
    print '<br>=====<br>pre:<br><pre>'.Dumper($data).'</pre>=====<br>';
    });
}

sub print_last_modified{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime(time-(3600*12));
    my @MON=qw(Jan  Feb  Mar  Apr  Mai  Jun  Jul  Aug  Sep  Oct  Nov  Dec);
    my @W=qw(Mon Tue Wed Thu Fri Sat Sun);
    $hour=sprintf("%02d",$hour);
    $mday=sprintf("%02d",$mday);
    $year+=1900;
    #print "Content-type: text/html\n\n";
    print "Last-Modified: $W[$wday], $mday $MON[$mon] $year $hour:00:00 GMT\n";
}

#isavnin 02.09.2013 
#Создание url
#antonov update to array|hash 23.08.2014
sub mk_url{
 ($LIST,$href)=@_;
 if ( ref($LIST) eq 'ARRAY' ) {   
  foreach(@{$LIST}){
    $_->{url}=&filter_get_url('/'.$href.'/'.$_->{id});
    if($_->{child}){
      mk_url($_->{child},$href);
    }
    if($_->{photo}){
      $_->{title} = &filder_htmlit($_->{header}) unless($_->{title});
      $_->{alt} = $_->{title} unless($_->{alt});
    }
  }
 }
 elsif ( ref ($LIST) eq 'HASH' ) {
    $LIST->{url}=&filter_get_url('/'.$href.'/'.$LIST->{id});
    if($LIST->{photo}){
      $LIST->{title} = &filder_htmlit($LIST->{header}) unless($LIST->{title});
      $LIST->{alt} = $LIST->{title} unless($LIST->{alt});
    }
 }
}
#Удаления постфикса, и клонирование полей.
#5.12.13, Неизвестный друг человечества.
sub mk_depst {
  ($in, $postfix) = @_;
  
 if ( ref($in) eq 'ARRAY' ) { 
  foreach my $record ( @{ $in } ) {
	foreach my $field ( keys %$record ) {
		if ( $field =~ m/((.+?)_($postfix))/i ) {
			$record->{$2} = $record->{$field};
		}
	}
  }
 }
 elsif ( ref($in) eq 'HASH' ) {
    foreach my $field ( keys %$in ) {
        if ( $field =~ m/((.+?)_($postfix))/i ) {
            $in->{$2} = $in->{$field};
        }
    }
 }
}
#isavnin 03.09.2013
#Генерация пароля заданой длины
sub gen_password{
  ($len)=@_;
  $len = 10 if(!$len);
  $password = '';
  for (1..$len){
    $password .= join '', (0..9, 'A'..'Z', 'a'..'z')[rand 64];
  }
  return $password;
}

#isavnin 24.09.2013
sub fb_msg{
  ($fields)=@_;
  my $msg='<ul>';
  foreach(@{$fields}){
    $msg.='<li>'.$_->{description}.': [%'.$_->{name}.'%]</li>';
  }
  $msg.='</ul>';
  return $msg;
}

sub fb_msg2{
  ($fields)=@_;
  my $msg='<ul>';
  #foreach(@{$fields}){
  map {
    if ( param($_->{name}) && !$_->{hidden} )  {
	$msg.='<li>'.$_->{description}.': '.param($_->{name}).'</li>';
    }
  } @{$fields};
  #}
  $msg.='</ul>';
  return $msg;
}

sub filter_get_url{ 
    # фильтр для шаблона, подменяющиц внутренний url CMS на уникальный
    # Шифрация URL'а из формата CMS в  формат пользователя
    my $u=shift;
    if($::params->{project}->{options} =~m/;ex_links;/){
        my $sth=$::params->{dbh}->prepare("SELECT ext_url FROM in_ext_url WHERE project_id=? and in_url=?");
        $sth->execute($::params->{project}->{project_id},$u);
        $u=$sth->fetchrow() if($sth->rows());
        $sth->finish();
    }
    return $u;
}

sub filder_htmlit {
    my $in = shift;
    $in =~ s!"!&quot;!sg;
    $in =~ s!'!&prime;!sg;
    $in =~ s!`!&lsquo;!sg;
    $in =~ s!<!&lt;!sg;
    $in =~ s!>!&gt;!sg;    
    
    return $in;
}

sub filder_toint {
    my $in = shift;
    return int $in;
}

#18.02.2014 Isavnin
sub filter_H1{}

sub get_H1{
	my($id,$table_name)=@_;
#	my $in = shift;
#	&::pre($table_name.' - '.$id);
	my $h1;
        if($::params->{project}->{options} =~ m/;add_h1;/){
#        my $h1=$::params->{dbh}->selectrow_arrayref("SELECT h1 FROM h1_tags_test WHERE hash_key = md5(concat(?,':',?,':',md5(?))) limit 1",undef,($id,$::params->{project}->{project_id},$h));
#	my $sql=qq{SELECT h1 FROM h1_tags_test WHERE hash_key = md5(concat($id,":",$::params->{project}{project_id},":",md5(\"$h\")))};
		#my $h1=$::params->{dbh}->selectrow_array("SELECT h1 FROM h1_tags_url WHERE project_id = ? AND in_url = ?",undef,($::params->{project}{project_id},$in));
		$h1=$::params->{dbh}->selectrow_array("SELECT h1 FROM h1_tags WHERE project_id = ? AND id = ? AND table_name = ?",undef,($::params->{project}{project_id},$id,$table_name));
#		&::pre($h1);
       }
       if(defined($h1)){
	 return $h1;
       }
}



sub end{
    $::params->{stop}=1;
}

sub html_strip{
    my $s=shift;
    $s=~s/</&lt;/gs;
    $s=~s/>/&gt;/gs;
    return $s;
}

sub to_error_log{
    
    if($::system->{debug}){
    open F, '>>./admin/logs/'.$ENV{HTTP_HOST}.'.html';
    print F '<b>'.`date`."</b>\t$_[0]\n";
    
    close F;
    }
}

return 1;
#END { }


#sub mytitles {
#   if ( $$params{project}{project_id} == 1825 ) {
#       
#       my $list = $params->{dbh}->selectall_arrayref("SELECT * from autotitlesant where project_id=1825", {Slice=>{}});
#       
#       #потом будет цикл
#       my $record = @{$list}[0];
#
#       #если маска подошла под текущий урл
#       if ( $$params{PATH_INFO} =~ $$record{url} ) {
#           
#           #ужасающий костыль (потому что это неьебенное допущение)
#           $$params{PATH_INFO} =~ /\/(\d+)/;
#           #надо еще выделять table.id как-то. будем считать что здесь предвидение у скрипта сработало... 
#           $hash_ref = $params->{dbh}->selectrow_hashref(qq{SELECT $$record{target_field} FROM $$record{target_table} where $$record{table_id}=$1});
#           
#           my $title = $$hash_ref{$$record{target_field}};
#           
#           #[%promo.title%]
#           my $final_title = $$record{title_template}.$title;
#           $$params{TMPL_VARS}{promo}{title} = $final_title;
#       
#       }
#       
#       
#   #$$params{TMPL_VARS}{DEN_DEBUG} = $list;
#   }
#}
