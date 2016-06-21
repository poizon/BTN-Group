package struct_admin_find;
use Data::Dumper;
use strict;
use Template;
use CGI qw(:standard);
use CGI::Carp qw (fatalsToBrowser);

BEGIN {
		use Exporter ();
		our @ISA = "Exporter";
		our @EXPORT = ('&get_filter_list', '&out_filters_list', '&get_where_find', '&out_find_results', '&get_result');
}

# Модуль, необходимый для поиска информации по таблице с использованием фильтров
sub get_filter_list{ # Процедура для вывода фильтров
	my $OUT='';
	my $form=shift;
	my $dbh=$form->{dbh};
	foreach my $field (@{$form->{fields}}){
		#print "$field->{type} ($field->{name}<br/>";
		next if ($field->{type} eq 'code' || $field->{type} eq 'memo');
		if(!$field->{name} && ($field->{type} ne 'label') && ($field->{type} ne 'link')){
			print "Внимание! отсутстсвует имя! ($field->{type})<br>\n".(join("<br>\n", map{ sprintf("'%s' = '%s'", $_, $field->{$_}) } sort keys %$field)); exit;
		}
		my $filter_type=get_filter_type($field->{'type'});
		my $filter_name=$field->{'name'};
		my $add_filter_type=$field->{'filter_type'};
		if($filter_type eq 'megaselect'){
			$field->{description}=$field->{megaselect_description};
		}
		if($filter_type && $filter_type!~m/^(label|1_to_m|link)$/ && !$field->{not_filter}){
		if($filter_type eq 'select_values'){
			my $default_label='Не использовать фильтр';
			my $options=qq{<option value="" selected>не использовать фильтр</option>};
			$options.=qq{<option value="$field->{default_value_empty}">$field->{default_label_empty}</option>} if($field->{default_label_empty});
			$options.=qq{<option value="$field->{default_value_empty}">$field->{default_label_empty}</option>} if($field->{default_value_empty});
			while($field->{values}=~m/(.+?)=>(.+?)(;|$)/g){
				my ($id,$header)=($1,$2);
				$options.=qq{<option value='$id'>$header</option>};
			}
			my $multiple='';
			if($field->{multiple_filter_size}){
				$multiple = " size='$field->{multiple_filter_size}' multiple" ;
			}
			$OUT.=qq{<div id='select_value_$field->{name}' style='display: none;'>$field->{description}: <select name='$field->{name}'$multiple>$options</select></div>}
		}
		elsif($filter_type eq 'select_from_table'){

			my $options=qq{<option value="" selected>не использовать фильтр</option>};
			if($field->{default_label_empty}){
				$options.=qq{<option value="$field->{default_value_empty}">$field->{default_label_empty}</option>};
			}
			my $from_table;

			if($field->{type} eq 'filter_extend_select_from_table'){ # Если расширенный фильтр!
				$from_table=$field->{filter_table};
			}
			else{
				$from_table=$field->{table};
			}

			if(!$from_table){
				print "В элементе $field->{name} не указан атрибут table"; exit;
			}
			if($field->{tree_use}){ # используется древовидная структура в select_from_table
				if($field->{sotr}){
					$field->{sortfield}='sort'
				}
				else{
						$field->{sortfield}=$field->{header_field};					
				}
				
				$OUT.=qq{<div id='select_value_$field->{name}' style='display: none;'>$field->{description}<br/><select name='$field->{name}'>}.$options.&get_branch('',$field).q{</select></div>};
				
				sub get_branch{
					my ($path,$element)=@_;
					my $optlist='';
					my $where=$element->{where};
					$where.=' AND ' if($where);
					$where.=qq{path=?};
					
					$where=qq{WHERE $where} unless($where=~m/^\s*where/i);
					my $level=0;
					while($path=~m/\d+/g){$level++};
			
					my $sth=$dbh->prepare(qq{
						SELECT $element->{value_field} as id, $element->{header_field} as header 
						FROM $element->{table}
						$where
						ORDER BY $element->{sortfield}
					});
					$sth->execute($path);
					while(my ($id,$header)=$sth->fetchrow()){
						my $selected='';
						if($id eq $element->{value}){
							$selected=' selected';
						}
						$optlist.=qq{<option value='$id'$selected>}.('&nbsp;&nbsp;'x$level).qq{$header</option>};
						$optlist.=&get_branch(qq{$path/$id},$element);
					}
					return $optlist;
				}
			}
			else
			{
					my $order;
					if($field->{order}){
						$order="order by $field->{order}"
					}
					else{
						$order="order by  $field->{header_field}"
					}
					if($field->{where} && $field->{where}!~/^\s*where/i){
						$field->{where}='where '.$field->{where};
					}
					my $query="SELECT $field->{value_field}, $field->{header_field} from $from_table $field->{where} $order";
					
					my $sth=$dbh->prepare($query);
					$sth->execute() || die("error select_from_table ($field->{name})<br/>");
					while(my ($id,$header)=$sth->fetchrow()){
						$options.=qq{<option value='$id'>$header</option>};
					}
					my $multiple='';
					if($field->{multiple_filter_size}){
						$multiple = " size='$field->{multiple_filter_size}' multiple" ;
					}
					$OUT.=qq{<div id='select_value_$field->{name}' style='display: none;'>$field->{description}<br/><select name='$field->{name}'$multiple>$options</select></div>}
			}
		}
		elsif($filter_type eq 'multiconnect'){
			my $options=qq{<option value="" selected>не использовать фильтр</option>};
			my $sth=$dbh->prepare("SELECT $field->{relation_table_id}, $field->{relation_table_header} from $field->{relation_table} order by $field->{relation_table_header}");
			$sth->execute();
			while(my ($id,$header)=$sth->fetchrow()){
				$options.=qq{<option value='$id'>$header</option>};
			}
			$OUT.=qq{<div id='multiconnect_$field->{name}' style='display: none;'>$field->{description}<br/><select name='$field->{name}' size='8' multiple>$options</select></div>}
		}
		elsif($filter_type eq 'multicheckbox'){
			my $options=qq{<option value="" selected>не использовать фильтр</option>};
			while($field->{extended}=~m/(.+?);(.+?);/gs){
				my ($val,$desc)=($1,$2);
				$options.=qq{<option value="$val">$desc</option>};
								
			}
			$OUT.=qq{<div id='multicheckbox_$field->{name}' style='display: none;'>$field->{description}<br/><select name='$field->{name}' size='8' multiple>$options</select></div>}
		}
		elsif($filter_type eq 'megaselect'){
			my @tables=(split /;/, $field->{table});
			my @despendences=(split /;/, $field->{despendence});
			my @descriptions=(split /;/, $field->{description});
			my @headers=(split /;/, $field->{table_headers});
			my @names=(split /;/, $field->{name});
			my @indexes=(split /;/, $field->{table_indexes});
			my $where='';
			if($despendences[0]){
				$where="where $despendences[0]";
			}

			# для очистки внутренних SELCT'ов при изменении вышестоящего
			$OUT.="<script>function clear_megaselect_$names[0](){\n";
			for(my $i=2;$i<$#tables+1;$i++){
				$OUT.="var id=document.getElementById('ms_$names[$i]')\nif(id) id.innerHTML='';";
			}
			$OUT.='}</script>';


			# Фильтр для самого первого SELECT'а
			$OUT.=qq{
				<div id='megaselect_$field->{name}' style='display: none;'><b>$descriptions[0]</b>:<br/>
					<select name='$names[0]' OnChange="clear_megaselect_$names[0](); add_megaselect_filter('$field->{name}', '$names[1]','1',this.value,'$form->{config}')">
			};
			my $options=q{<option value=''>не использовать фильтр</option>};
			my $sth=$dbh->prepare("SELECT $headers[0], $indexes[0] from $tables[0] $where order by $headers[0]");
			$sth->execute();
			while(my ($header,$id)=$sth->fetchrow()){
				$options.=qq{<option value='$id'>$header</option>};
			}
			$OUT.="$options</select>";
			$OUT.=q{</div>}; # закрываем див с фильтром
		}
		elsif($filter_type eq 'memo'){
			$OUT.=qq{
				<div id='memo_$field->{name}' style='display: none;'>
					$field->{description}<br/>
					<div style='margin-left: 20px;'>
							Текст сообщения:<br>
							&nbsp;&nbsp;<input type="text" name='memo_$field->{name}_comment'><br>
							Период написания комментария:<br>
							<input type='text' name='memo_$field->{name}_reg_low' id='memo_$field->{name}_reg_low'>
							<input type='text' name='memo_$field->{name}_reg_hi' id='memo_$field->{name}_reg_hi'>
							&nbsp;&nbsp;С <div id='memo_$field->{name}_reg_low_div'></div><br>
							&nbsp;&nbsp;По <div id='memo_$field->{name}_reg_hi_div'></div><br>
							<script>
								init_calendar('memo_$field->{name}_reg_low','memo_$field->{name}_reg_low_div',0);
								init_calendar('memo_$field->{name}_reg_hi','memo_$field->{name}_reg_hi_div',0);
							</script>
					</div>
				</div>
			}
			
		}
		elsif($filter_type eq 'code'){}
		my $desc=$field->{description}; $desc=~s/"/\\"/gs;
		$OUT.=qq{<input type='checkbox' id='c_$field->{name}' OnClick='mix_filter("$filter_type","$field->{name}","$desc")'>&nbsp;$field->{description}<br>};
		}
	}
$form->{FILTER_LIST}=$OUT;
undef $OUT;
}

sub get_filter_type{
	my $type=shift;
	if($type=~m/select_values/){
		$type='select_values'
	}
	elsif($type=~m/filter_extend_select_from_table/){
		$type='select_from_table'
	}
	elsif($type=~m/filter_extend_select_values/){
		$type='select_values'
	}
	elsif($type=~m/date/){
		$type='date'
	}
	elsif($type=~m/time/){
		$type='time'
	}
	elsif($type=~m/text|wysiwyg|textarea/){
		$type='text'
	}
	elsif($type ne 'multicheckbox' and $type=~m/checkbox/){
		$type='checkbox'
	}
	return $type;
}
sub out_filters_list{ # вывод шаблона с фильтрами
	my $form=$_[0];
	my $FILTER_LIST=$form->{FILTER_LIST};
	my $TITLE='Поиск';
	my $new_form=qq{./edit_form.pl?action=new&config=$form->{config}};
	$new_form=$form->{new_form} if($form->{new_form});
	my $create_button=qq{<p class="mb-10 f-11"><a class="blue" href="$new_form" target="_blank"><img class="mr-5" src='/icon/new.gif'>Добавить</a></p>};
	my $find_plug_panel='';
	# считываем плагины для поисковой формы:
	foreach my $plug_name (@{$form->{plugins}}){
		if($plug_name =~m/^find::(.+)$/){
			my $plug_file=$1;
			my $plugin;
			my $code='';
			open F, qq{./plugins/find/$plug_file};
			while(<F>){$code.=$_;}close F;
			eval($code);
			print $@ if($@);
			if($plug_file ne 'promo_xls'){
				$find_plug_panel.=qq{<img src="$plugin->{icon}" align="absmiddle">&nbsp;<a href="javascript: find_on_plug('$plug_file')">$plugin->{description}</a> }
			}
			elsif($plug_file eq 'promo_xls' && $form->{project}{options}{use_external_promo_exporter}){
				$find_plug_panel.=qq{<img src="$plugin->{icon}" align="absmiddle">&nbsp;<a href="javascript: find_on_plug('$plug_file')">$plugin->{description}</a> }
			}
		}
	}
	$find_plug_panel=qq{<p>$find_plug_panel</p>} if($find_plug_panel);
	
 	$create_button='' if($form->{not_create});
  print<<EOF;
<html>



 <head>
   <title>$TITLE</title>
    <script language=JavaScript src='./filters.js'></script>
    <script language=JavaScript src='./main.js'></script>
    <script language=JavaScript src='./ajax.js'></script>
    <script language=JavaScript src='./svcalendar.js'></script>
    
<link href='ncss/base.css' rel="stylesheet" />
<link href='ncss_css/ie.css' rel="stylesheet" />
<link href='ncss/window.css' rel="stylesheet" />

    <script>
     function show_filters()
      {
         document.getElementById('filters').style.display='';
         document.getElementById('f_panel').innerHTML='<a href="javascript: hide_filters();">Скрыть фильтры</a>';
      }

      function hide_filters()
      {
         document.getElementById('filters').style.display='none';
         document.getElementById('f_panel').innerHTML='<a href="javascript: show_filters();">Показать фильтры</a>';
      }
      function hide_results()
      {
         document.getElementById('results').style.display='none';
         document.getElementById('r_panel').innerHTML='<a href="javascript: show_results();">Показать результаты</a>';
      }
      function show_results()
      {
         document.getElementById('results').style.display='block';
         document.getElementById('r_panel').innerHTML='<a href="javascript: hide_results();">Скрыть результаты</a>';
      }
      function go_search(){
      	document.f.submit(); document.getElementById("r").style.display="block"; hide_filters();
			}
			function find_on_plug(plug_name){
				document.getElementById('plugin').value=plug_name;
				go_search()
				document.getElementById('plugin').value=''
			}
    </script>
    <style>
      h1 {font-size: 14pt;}
      img {border: none;}


    </style>
 </head>
 <body style='margin: 10px 0 30px 20px'>
  <div class="wrapper">
	<div class="content">
  <div class="h2">$form->{title}</div>
  
  $find_plug_panel
	$create_button
	
  <div id='f_panel' style='margin-bottom: 5px;'><a href='javascript: hide_filters();'>Скрыть фильтры</a></div>
  <div id='filters' style='display: block;'>


  <table class='filters' width='90%'><tr>
   <td valign='top' style='padding: 0; border: 1px solid black;' width='500'>

      <div style='border-bottom: 1px solid black; margin: 0;'>&nbsp;<b>Использовать фильтры:</b></div>
      <div style='margin: 10px'>
      $form->{FILTER_LIST}



   </td>
    <td valign='top'>
    	<form action='./find_objects.pl' method='post' target='results' name='f' OnSubmit=''>
  			<input type='hidden' name='config' value='$form->{config}'>
  			<input type='hidden' name='plugin' id='plugin' value=''>
  			<input type='hidden' name='__page' id='page' value='0'>
     		<div id='main' class='main'></div>
     		<p>
     			<b>Фильтрация: </b><br/>
     			<input type="radio" name='and_or' value="0">&nbsp;Все совпадения<br>
      		<input type="radio" name='and_or' value="1">&nbsp;Любое из совпадений
      	</p>
     	</form>
   </td>
   <td align='right'></td>
   </tr>
		<tr>
			<td style='text-align: center; margin-top: 10px;'><input type='button' OnClick="document.getElementById('page').value=0; go_search()" value='поиск'></td>
			<td></td>
		</tr>
  </table>
      </div>
  </div>

  <div id='r' style='display: none;'>
    <div id='r_panel'><a href='javascript: hide_results();'>Скрыть результаты</a></div>
    <div id='results'>
      <iframe name='results' style='width: 100%; height: 100%; border: none;' border="0"></iframe>
    </div>
  </div>
  </div>
  </div>
 </body>
</html>
EOF
}


sub get_where_find{
	my $form=$_[0];      # данные о таблице-форме
	my $WHERE_STRING=''; # строка условий для SQL-запроса (where)
	#my $ORDER_STRING=''; # строка для упорядочивания (order)
	my @WHERE_VALUES=(); # массив значений для where
	my @ORDER_FILTERS=(); #
	my %LINKS=(); # линки
	my %DESCRIPTION_FIELD;
	my @FIELD_NAME=();
#	my @ORIG_NAMES;
	my $AND_OR=' AND ';
	my %FILTER_TYPE_FIELD=();
	my $min_order=100000;
	my $max_order=0;
	my $cgi=CGI->new;
	my @a=$cgi->param; my %getting_par;
	# // "пробегаем" по параметрам
	my $and_or=$cgi->param('and_or');
  my $LEFT_JOIN_STR='';
  my %table_alias=();
	#$form->{'query_tables'}=qq{$form->{work_table} wt};
	foreach my $k (@a){
		if($k=~m/order_(.+?;.+?)$/){
			$getting_par{$1}=1;
		}
		else{
			$getting_par{$k}=1;
		}
	}
	
	# проверяем, выбирался ли какой-то фильтр
	my $on_filters=0; 	
	foreach my $field (@{$form->{fields}}){
		

		if($getting_par{$field->{name}} || $getting_par{$field->{name}.'_hi'}){
			$on_filters=1; last;
		}
	}
	
	if($on_filters){
		# собираем порядок, в котором включены фильтры и группировку
		my %names=(); my %groups=();
		foreach my $field (@{$form->{fields}}){
			
			my $order=$cgi->param('order_'.$field->{name});
			
			if($order=~m/^\d+$/){
				$names{$order}=$field->{name};
				$groups{$order}=$field->{group_by};
				if($order<$min_order){$min_order=$order}
				if($order>$max_order){$max_order=$order}
			}
			
		}
		
		foreach my $order ($min_order..$max_order){
			push @{$form->{FIELD_NAME}}, $names{$order} if($names{$order});
			if($groups{$order}){
				$form->{GROUP_BY}.=',' if($form->{GROUP_BY});
				$form->{GROUP_BY}.=$groups{$order};
			}
		}
		#print Dumper($form->{FIELD_NAME})."<br/>!!!-------";
	}
	else{ # Если все фильтры выключены, то включаем дефолтные
		while($form->{default_find_filter}=~m/([^\s,]+)/g){
				my $name=$1;
				$getting_par{$1}='-' unless(param($name));
				push @{$form->{FIELD_NAME}}, $name;
		}		
	}
	
	
	my $filter_table_index=1;
	foreach my $field (@{$form->{fields}}){
		my $name=$field->{name};
		$field->{orig_name}=$name;# $field->{orig_name}=~s/^filter_//;
		if($field->{type} eq 'megaselect' || $getting_par{$name} || $getting_par{$name.'_hi'}){
			my $type=$field->{type};
			my $value=$cgi->param($name); #значение поля
			my $order=$cgi->param('order_'.$field->{name});
			my $filter_disabled=$cgi->param('filter_'.$field->{name}.'_disabled');
			
			$DESCRIPTION_FIELD{$field->{orig_name}}=$field->{description};
			# Для сложных запросов
			
			if($type=~m/^filter_extend_/){				
				if($form->{'query_tables'}=~m/(,|\s|^)$field->{filter_table}\s+ext_(\d+)/){
					$field->{'tablename'}='ext_'.$2;
				}
				else{
					$field->{'tablename'}='ext_'.$filter_table_index;
				}
				my $extend_where=$field->{extend_where};
				#$field->{table_mininame}=qq{ext_$filter_table_index};
				
				$extend_where=~s/$form->{work_table}\./wt\./g;
				$extend_where=~s/$field->{filter_table}\./$field->{'tablename'}\./g;
								
				
				if($field->{left_join}){
						#print "-------<br>";
						my @wh=(split / AND /,$extend_where);
						my $jk=0;
						my %tbl_alias=();
						while($field->{extend_tables}=~m/([^\s,]+)/g){
							my $table=$1;
							my $wh=$wh[$jk];							
							
							$tbl_alias{$table}=qq{ext_$filter_table_index\_$jk};
							foreach my $t (keys(%tbl_alias)){
								$wh=~s/(^|\s|=)$t(\.|$|\s)/$1$tbl_alias{$t}$2/g;
							}
							$LEFT_JOIN_STR.=" LEFT JOIN $table as ext_$filter_table_index\_$jk ON ($wh) ";
							$jk++;
						}

						foreach my $t (keys(%tbl_alias)){
							#print "t: $t<br/>";
							$wh[$#wh]=~s/(^|\s|=)$t(\.|$|\s)/$1$tbl_alias{$t}$2/g;
						}
						
						$LEFT_JOIN_STR.=" LEFT JOIN $field->{filter_table} as ext_$filter_table_index ON ($wh[$#wh])";
						$filter_table_index++;
						
				}
				else{					
					$WHERE_STRING=qq{ AND ($WHERE_STRING) } if($WHERE_STRING);
					$WHERE_STRING=qq{$extend_where $WHERE_STRING };
					#print "qt: $field->{name}: $field->{extend_tables} ($type)<br/>";	
					while($field->{extend_tables}=~/([^,\s]+)/gs){
						my $tbl=$1;
						#print " - tbl: $tbl<br>";
						unless($form->{'query_tables'}=~/(^|,|\s)$tbl(,|\s)/){
							$filter_table_index++;							
							$form->{query_tables}.=', ' if($form->{'query_tables'});
							$form->{'query_tables'}.=qq{$tbl ext_$filter_table_index} ;
							#print "&nbsp;&nbsp;qt: $form->{'query_tables'}<br/>";
						}
					}
				#print " -- qt: $form->{query_tables} ($type)<br/>";		
					# Склейка?
					if($form->{'query_tables'}=~/(^|,|\s)$field->{filter_table}(,|\s)/){
						# таблица уже встречалась, склеиваем												
						$field->{tablename}=$table_alias{$field->{filter_table}} if($table_alias{$field->{filter_table}});
					}else{
						$form->{'query_tables'}.=', ' if($form->{'query_tables'});
						$form->{'query_tables'}.=qq{$field->{filter_table} $field->{'tablename'}};
						$table_alias{$field->{filter_table}}=$field->{'tablename'};
						$filter_table_index++;
					}

				
				}
			}
			elsif($type eq 'select_from_table'){
				# Для SELECT_FROM_TABLE составляется сложный запрос 		
				# ДЕЛАЕМ LEFT JOIN для того, чтобы включить записи без пересечений				
				$field->{'tablename'}='ext_'.$filter_table_index;
				$filter_table_index++;
				$LEFT_JOIN_STR.=qq{ LEFT JOIN $field->{table} $field->{'tablename'} ON (wt.$field->{name}=$field->{'tablename'}.$field->{value_field})};
				$form->{GROUP_BY}.=', ' if($form->{GROUP_BY});
				$form->{GROUP_BY}.=qq{wt.$form->{work_table_id}, $field->{'tablename'}.$field->{value_field}};
			}

			
			if($type eq 'megaselect'  || !$filter_disabled && (($value ne '') || ( ($type=~m/date/) && $getting_par{$name.'_hi'} && $getting_par{$name.'_low'}))) {
				
				if($field->{filter_type} eq 'gt'){ # фильтр сравнения (больше или равно)
					if($WHERE_STRING){$WHERE_STRING.=" $AND_OR "}
					$WHERE_STRING.=" wt.$name >= ?";
					push @WHERE_VALUES, $value;
				}
				elsif($field->{filter_type} eq 'lt'){ # фильтр сравнение (меньше или равно)
					if($WHERE_STRING){$WHERE_STRING.=" $AND_OR "}
					$WHERE_STRING.=" wt.$name <= ?";
					push @WHERE_VALUES, $value;
				}
				elsif(!$field->{not_use_for_search} && ($type eq 'text' || $type eq 'textarea' || $type eq 'wysiwyg')){ # текстовые фильтры
					if($value){ # пустые строки лайком не ищем
						if($WHERE_STRING){$WHERE_STRING.=" $AND_OR "}
						$WHERE_STRING.=" wt.$name like ?";
						push @WHERE_VALUES, '%'.$value.'%'
					}
				}
				elsif($type eq 'megaselect'){
					my $order=$cgi->param('order_'.$name);
					$field->{ord_substr}='';
					$field->{select_substr}='';
					my @names=(split /;/,$name);
					my @tables=(split /;/,$field->{table});
					my @table_indexes=(split /;/,$field->{table_indexes});
					my @table_headers=(split /;/,$field->{table_headers});
					my $ms_hidden_order=0;
					foreach my $cur_name (@names){
						if($order){
							$field->{'tablename'}='ext_'.$filter_table_index;
							$filter_table_index++;
							$LEFT_JOIN_STR.=qq{ LEFT JOIN $tables[$ms_hidden_order] $field->{'tablename'} ON (wt.$cur_name=$field->{'tablename'}.$table_indexes[$ms_hidden_order])};
						}
						
						if($field->{ord_substr}){
							$field->{ord_substr}.=', ';
							$field->{select_substr}.=', ';
						}
						$field->{ord_substr}.=qq{$field->{'tablename'}.$table_headers[$ms_hidden_order]};
						$field->{select_substr}.=qq{ifnull(concat($field->{'tablename'}.$table_headers[$ms_hidden_order], ' / '),'')};
						
						#$ORDER_FILTERS[$order].=',' if($ORDER_FILTERS[$order]);
						#$ORDER_FILTERS[$order].=$cur_name;
						my $cur_value=$cgi->param($cur_name);
						if($cur_value){
							push @WHERE_VALUES, $cur_value;
							if($WHERE_STRING){$WHERE_STRING.=" $AND_OR "}
							$WHERE_STRING.=" wt\.$cur_name = ?";
						}
						$ms_hidden_order++;
					}
					$name=~s/;/_/g;
					$field->{db_name}=$name unless($field->{db_name});
					$field->{select_substr}=qq{concat($field->{select_substr}) as `$field->{db_name}`};
					
					#if($order){
					#	if($form->{ORDER_STRING}){$form->{ORDER_STRING}.=', '};
					#	$form->{ORDER_STRING}.=$ord_substr;
					#}
					next;
				}
				elsif($type eq 'multiconnect'){
					
					my @values=$cgi->param($name);
					my $vals=join(', ', @values);
					$form->{query_tables}.=', ' if($form->{query_tables});
					$form->{query_tables}.=qq{$field->{relation_save_table} ext_$filter_table_index};
					if($WHERE_STRING){$WHERE_STRING.=" $AND_OR "};
					$field->{relation_save_table_id_worktable}=$form->{work_table_id} unless($field->{relation_save_table_id_worktable});
					#print "WH:  (wt.$form->{work_table_id} = ext_$filter_table_index.$field->{relation_save_table_id_worktable}) and (ext_$filter_table_index.$field->{relation_save_table_id_relation} in ($vals))<br/>";
					$WHERE_STRING.=" (wt.$form->{work_table_id} = ext_$filter_table_index.$field->{relation_save_table_id_worktable}) and (ext_$filter_table_index.$field->{relation_save_table_id_relation} in ($vals))";
					$filter_table_index++;
					
				}
				elsif($type eq 'multicheckbox'){
					my @values=$cgi->param($name);
					my $add_wh='';
					foreach my $v (@values){
						$add_wh.=' and ' if($add_wh);
						$add_wh.=qq{wt.$name like '%;$v;%' };
					}
					if($add_wh){
						$WHERE_STRING.=' AND ' if($WHERE_STRING);
						$WHERE_STRING.=qq{($add_wh)};
					}
				}
				elsif($type eq 'date' || $type eq 'datetime'){
					my $hi=$cgi->param($name.'_hi');
					my $low=$cgi->param($name.'_low');
					if($WHERE_STRING){$WHERE_STRING.=" $AND_OR "}
					if( ($hi=~m/^\d+-\d+-\d+( \d+:\d+:\d+)?$/) && ($low=~m/^\d+-\d+-\d+( \d+:\d+:\d+)?$/)){
						my ($hi1, $low1);
						if(1 || $type eq 'date'){
							$hi1="$hi 23:59:59";
							$low1="$low 00:00:00";
						}
#						elsif($type eq 'datetime'){
#							$hi1=$hi;
#							$low1=$low;
#						}
						$WHERE_STRING.=" (wt.$name<=? and wt.$name>=?)";
						push @WHERE_VALUES, $hi1;
						push @WHERE_VALUES, $low1;
					}
				}
				elsif($type eq 'code'){}
				elsif($type eq 'filter_extend_text'){ #filter_extend_text
					$WHERE_STRING.=" $AND_OR " if($WHERE_STRING);
					if($field->{db_name}=~m/^func::(.+)$/){
						my $func=$1;
						$func=~s/\[%filter_table%\]/$field->{tablename}/g;
						$WHERE_STRING.="$func like ?";
					}
					else{
						$WHERE_STRING.="$field->{'tablename'}.$field->{db_name} like ?";
					}
					push @WHERE_VALUES, qq{%$value%};
				}
				elsif($type eq 'filter_extend_date' || $type eq 'filter_extend_time'){
					my $hi=$cgi->param($name.'_hi');
					my $low=$cgi->param($name.'_low');
					if( ($hi=~m/^\d+-\d+-\d+( \d+:\d+:\d+)?$/) && ($low=~m/^\d+-\d+-\d+( \d+:\d+:\d+)?$/)){
						my ($hi1, $low1);
						if($type=~m/datetime/){
							$hi1=$hi;
							$low1=$low;
						}
						else{
							$hi1="$hi 23:59:59";
							$low1="$low 00:00:00";
						}
						$WHERE_STRING.=" $AND_OR " if($WHERE_STRING);
						$WHERE_STRING.=" ($field->{'tablename'}.$field->{db_name}<=? and $field->{'tablename'}.$field->{db_name}>=?)";
						push @WHERE_VALUES, $hi1;
						push @WHERE_VALUES, $low1;
					}
				}
				elsif($type=~m/^filter_extend_(checkbox|select_values|select_from_table)$/ && defined($value)){ #filter_extend_checkbox
						my @values=$cgi->param($name);
						my $wh=''; my $hd='';
						foreach my $v (@values){
							$wh.=' OR ' if($wh);
							$wh.=" $field->{'tablename'}.$field->{db_name}=? ";
							push @WHERE_VALUES, $v;
						}
						if($wh){
							if($WHERE_STRING=~/\S/){$WHERE_STRING.=" $AND_OR ($wh)"}
							else{
								$WHERE_STRING=$wh;
							}
						}
				}
				else{
					if($field->{multiple_filter_size}){ # для MULTIPLE SELECT-ов
						my @values=$cgi->param($name);
						my $wh=''; my $hd='';
						foreach my $v (@values){
							$wh.=' OR ' if($wh);
							$wh.=" wt.$name=? ";
							push @WHERE_VALUES, $v;
						}
						if($wh){
							if($WHERE_STRING){$WHERE_STRING.=" $AND_OR ($wh)"}
							else{
								$WHERE_STRING=$wh;
							}
						}
					}
					else{
						if(!$field->{not_use_for_search} && ($value ne '')){
							if($WHERE_STRING){$WHERE_STRING.=" $AND_OR "}
							$WHERE_STRING.=" wt.$name=?";
							push @WHERE_VALUES, $value;
						}
					}
				}
			}
			# Массив типов
			#$FILTER_TYPE_FIELD{$field->{orig_name}}=$type;

			if($field->{'tablename'}){
				$name=qq{$field->{'tablename'}.$field->{db_name}};
			}
			else{
				$name=qq{wt.$name};
			}
#			if($type eq 'link'){
#				$LINKS{$name}=1;
#				next;
#			}

#			$ORIG_NAMES[$order]=$field->{orig_name};


		}
	}

	my $order=1;

	foreach my $name (@{$form->{FIELD_NAME}}){
			my $field=&get_hash_for_element($form,$name);
			next if($field->{not_use_for_search});
			$form->{SELECT_STRING}.=', ' if($form->{SELECT_STRING});
			$form->{ORDER_STRING}.=', ' if($form->{ORDER_STRING} && !($field->{db_name}=~m/^func::/));
			#print "type; $field->{type} tablename: $field->{tablename}<br>";
			if($field->{type} eq 'multiconnect'){ # здесь $order -- порядковый номер фильтра
				
				$ORDER_FILTERS[$order]="wt.$form->{work_table_id}";				
				$form->{SELECT_STRING}.="wt.$form->{work_table_id}";
			}
			elsif($field->{type} eq 'megaselect'){				
				$form->{ORDER_STRING}.=$field->{ord_substr};				
				$form->{SELECT_STRING}.=$field->{select_substr};
			}
			else{
					if($field->{type}=~m/^filter_extend/ && $field->{'tablename'}){
						#$ORDER_FILTERS[$order]=qq{$field->{table_mininame}.$field->{name}};
						if($field->{type} eq 'filter_extend_select_from_table'){
							$field->{header_field}=~s/^.+?\.//;
							$form->{ORDER_STRING}.=qq{$field->{'tablename'}.$field->{header_field}};
							$form->{SELECT_STRING}.=qq{$field->{'tablename'}.$field->{header_field} as `$field->{name}`};
						}
						elsif($field->{type} eq 'filter_extend_select_values'){
																		 
							$form->{ORDER_STRING}.=qq{$field->{'tablename'}.$field->{db_name}};
							$form->{SELECT_STRING}.=qq{CASE $field->{'tablename'}.$field->{db_name} };
							while($field->{values}=~m/([^;]+?)=>([^;]+)/gs){
								$form->{SELECT_STRING}.=qq{WHEN $1 then '$2' }
							}
							$form->{SELECT_STRING}.=qq{ END as `$field->{name}`};
						}
						else{
							
							if($field->{db_name}=~m/^func::(.+)$/){
								my $f=$1;
								$f=~s/\[%filter_table%\]/$field->{'tablename'}/g;
								$form->{SELECT_STRING}.=qq{$f  as `$field->{name}`};
							}
							else{
								#print "type: $field->{type}<br/>";
								$form->{ORDER_STRING}.=qq{$field->{'tablename'}.$field->{db_name}};
								$form->{ORDER_STRING}.=' DESC' if($field->{order_desc});								
								$form->{SELECT_STRING}.=qq{$field->{'tablename'}.$field->{db_name}  as `$field->{name}`};
								
							}
							
							
						}
					}
					elsif($field->{type} eq 'select_from_table'){
						# для того, чтобы у нас была сортировка, составляем хитрющий запрос
						$form->{SELECT_STRING}.=qq{$field->{'tablename'}.$field->{header_field} as `$field->{name}`};
						$form->{ORDER_STRING}.=qq{$field->{'tablename'}.$field->{header_field}};

					}

					elsif($field->{type} eq 'select_values'){
						$form->{ORDER_STRING}.=qq{wt.$field->{name}};
						$form->{SELECT_STRING}.=qq{CASE wt.$field->{name} };
						while($field->{values}=~m/([^;]+?)=>([^;]+)/gs){
							$form->{SELECT_STRING}.=qq{WHEN $1 then '$2' }
						}
						$form->{SELECT_STRING}.=qq{ END as $field->{name}};
					}
					elsif($field->{type} eq 'checkbox'){
						$form->{ORDER_STRING}.=qq{wt.$field->{name} desc};
						$form->{SELECT_STRING}.=qq{CASE wt.$field->{name}  WHEN 1 then 'вкл' WHEN 0 then 'выкл' END as $field->{name} };
					}
					else{						
						if($field->{db_name} && ($field->{db_name} ne $field->{name})){
							$form->{SELECT_STRING}.=qq{wt.$field->{db_name} as $field->{name}};		
						}
						else{
							$form->{SELECT_STRING}.=qq{wt.$field->{name} as $field->{name}};
							$form->{ORDER_STRING}.=qq{wt.$field->{name}};
						}
						
					}
					
				
			}
			#print "SELECT: $form->{SELECT_STRING}<br/>";
			if($field->{type} eq 'date'){
				$form->{ORDER_STRING}.=' desc ';
			}
			$order++;
	}
	if($form->{ORDER_STRING}){$form->{ORDER_STRING}='ORDER BY '.$form->{ORDER_STRING}}
	if($form->{add_where}){
		$WHERE_STRING.=' AND ' if($WHERE_STRING=~/\S/);
		$WHERE_STRING.=qq{ ($form->{add_where})};
	}
	if($WHERE_STRING=~/\S/) {$WHERE_STRING='WHERE '.$WHERE_STRING}
	$form->{WHERE_STRING}=$WHERE_STRING;
	$form->{WHERE_VALUES}=\@WHERE_VALUES;
	$form->{DESCRIPTION_FIELD}=\%DESCRIPTION_FIELD;
#	print "qt: '$form->{'query_tables'}'<br/>";
#	print "lj: '$LEFT_JOIN_STR'<br/>";

	if($LEFT_JOIN_STR){
		if($form->{'query_tables'}){
			$form->{'query_tables'}=qq{$form->{work_table} wt $LEFT_JOIN_STR, $form->{'query_tables'}};	
		}
		else{
			$form->{'query_tables'}=qq{$form->{work_table} wt $LEFT_JOIN_STR};
		}		
	}
	elsif($form->{'query_tables'}){
		$form->{'query_tables'}=qq{$form->{work_table} wt, $form->{'query_tables'}};
	}
	else{
		$form->{'query_tables'}=qq{$form->{work_table} wt};
	}
	
#	print "tables: $form->{'query_tables'}<br/>";
}

sub get_result{
	my $form=shift;
	my $dbh=$form->{dbh};
	unless($form->{default_find_filter}){
		print "Не указан фильтр по умолчанию";
		exit;
	}
	my @WHERE_VALUES=@{$form->{WHERE_VALUES}};
	#my $ORDER_STRING=$form->{ORDER_STRING};
	my %DESCRIPTION_FIELD=%{$form->{DESCRIPTION_FIELD}};
	#my %FILTER_TYPE_FIELD=%{$form->{FILTER_TYPE_FIELD}};
	my $WHERE_STRING=$form->{WHERE_STRING};
	my $RESULT_LIST='<table class="mainout">';
	my $perpage;
	my $page=$form->{page};
	my @FIELD_NAME=@{$form->{FIELD_NAME}};
	my %LINKS=();
	my $default;
	my %QUERIES_FOR_MEGASELECT=();
	$form->{ORDER_STRING}=~s/\sas\s+[a-z_\-0-9]+//i;
	#my %FILTER_CODE=();
	foreach my $field (@{$form->{fields}}){
		#$FILTER_CODE{$field->{orig_name}}=$field->{filter_code};
		if($field->{type} eq 'megaselect' && !$field->{not_filter}){
			# Для фильтрации megaselect'а
			my @names=split /;/, $field->{name};
			my @descriptions=split /;/, $field->{description};
			my @despendences=split /;/, $field->{despendence};
			my @table_headers=split /;/, $field->{table_headers};
			my @table_indexes=split /;/, $field->{table_indexes};
			my @tables=split /;/, $field->{table};
			my $i=0;		
			foreach my $n (@names){
				$DESCRIPTION_FIELD{$n}=$descriptions[$i];
				#$FILTER_TYPE_FIELD{$n}='megaselect';
				my $where="WHERE $table_indexes[$i]=? ";
				$where.=qq{ AND $despendences[$i]} if($despendences[$i]);
				$QUERIES_FOR_MEGASELECT{$n}="SELECT $table_headers[$i] FROM $tables[$i] $where";
				$i++;
			}
		}		
		if($field->{type}=~m/^filter_extend_(checkbox|select_values|select_from_table)$/){
			my $f=$1;
			my $n=$field->{name};
		}

	}	
	$perpage=20 unless($perpage=$form->{perpage});
	# Список полей, которые будем селектить получаем из строки ордера
	my $SELECT_FIELDS;

	# Если фильтры не выбраны, используем фильтр (фильтры) по-умолчанию
	unless($form->{SELECT_STRING}){
		$form->{SELECT_SYRING}=$form->{default_find_filter};
		$DESCRIPTION_FIELD{$form->{default_find_filter}}=$default->{description};
		#$FILTER_TYPE_FIELD{$form->{default_find_filter}}=$default->{type};
		$FIELD_NAME[1]=$default->{name};
	}
	$RESULT_LIST.='<tr class="h">';
	my $i=1;
	# =================================
	# ЗАГОЛОВКИ ДЛЯ ТАБЛИЦЫ РЕЗУЛЬТАТОВ:
	# ==================================

	foreach my $name (@{$form->{FIELD_NAME}}){
		#my $name=$FIELD_NAME[$i];
		#print "name: $name<br/>";
			# DATA DATA DATA
		#$RESULT_LIST.='<td>'.$DESCRIPTION_FIELD{$name}.'</td>';
		push @{$form->{RESULT_HEADERS}},$DESCRIPTION_FIELD{$name};
		# запоминаем имя поля (в соответствии с порядковым  номером)
		$i++;
	}

	foreach my $linkname (keys(%LINKS)){$RESULT_LIST.='<td>&nbsp;</td>'}
	# свободные ячейки под кнопки редактирования и удаления
	if($form->{make_delete}){$RESULT_LIST.='<td>&nbsp;</td>'}
	$RESULT_LIST.='<td>&nbsp;</td>';
	$RESULT_LIST.='</tr>';
	# ОПТИМИЗАТОР ЗАПРОСОВ
	{
		
		my $tables=$form->{query_tables};

		$tables=~s/LEFT JOIN/,/g;
		$tables=~s/ON \(.+?\)//g;

		# 2. Если используются псевдонимы для таблиц, то они должны использоваться везде
			foreach my $tbl ((split/,/,$tables)){
				if($tbl=~m/^\s*([\S]+)\s*([\S]+)/g){
					my ($table,$alias)=($1,$2);				
					# убираем точно такие же таблицы, но не проальясеные (в списке таблиц)
					$form->{query_tables}=~s/(^|,)\s*$table\s*(,|$)/$1/g;
					# корректируем условия
					$WHERE_STRING=~s/([\(\s=])$table\./$1$alias\./sg;

				}
			}
	}
	# добавляем id-шник первым фильтром
	$form->{SELECT_STRING}=', '.$form->{SELECT_STRING} if($form->{SELECT_STRING});
	$form->{SELECT_STRING}="wt.".$form->{work_table_id}.' as work_table_id'.$form->{SELECT_STRING};
	
	
	my $query="SELECT SQL_CALC_FOUND_ROWS $form->{SELECT_STRING} from $form->{query_tables} $WHERE_STRING";
	#my $query_count="SELECT count(distinct(wt.$form->{work_table_id})) FROM $form->{query_tables} $WHERE_STRING";
	#my $query_count="SELECT count(*) FROM $form->{query_tables} $WHERE_STRING";
	if($form->{GROUP_BY}){
		$query.=qq{ GROUP BY $form->{GROUP_BY}} ;
		#$query_count.=qq{ GROUP BY $form->{GROUP_BY}} ;
	}
	
	
	$query.=' '.$form->{ORDER_STRING};
	$query.=qq{ limit $page, $perpage} unless($form->{not_perpage});	
	#rint Dumper($form);
	
	
	

		
	if($form->{explain}){
		# Преобразуем в удобоваримый вид
		my $query_tables=$query;#$form->{query_tables};
		$query_tables=~s/(LEFT JOIN)/<br>$1/gis;
		$query_tables=~s/(from|where|group by|limit)/<br>$1<br>&nbsp;/gis;

		print "explain $query_tables<br><br>";
		my $sth=$form->{dbh}->prepare("explain $query");
		$sth->execute(@WHERE_VALUES) || die($dbh->errstr());
	
		
		while(my $i=$sth->fetchrow_hashref()){
			print qq{
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
			}
		}
		print "<br><br>$query<br>";
		print join(';',@WHERE_VALUES);
		#exit;
	}

	#my $sth=$dbh->prepare($query_count);
	#$sth->execute(@WHERE_VALUES) || die($dbh->errstr());
	#$form->{maxnumber}=$sth->fetchrow();
	#$sth->finish();

	#print "q: $query<br>";
	my $sth=$form->{dbh}->prepare($query);
	$sth->execute(@WHERE_VALUES) || die($dbh->errstr());
	
	$form->{maxnumber} = $dbh->selectrow_array("SELECT FOUND_ROWS()");	
	my $lnum=0;
	while(my $values=$sth->fetchrow_hashref()){		
		#print '<pre>'.Dumper($values).'</pre>';
		my $CUR_ID=$values->{work_table_id};
		my @td=();
		my @parents_megaselect=();
		
		foreach my $name (@{$form->{FIELD_NAME}}){
			my $value=$values->{$name};		
			my $field=&get_hash_for_element($form,$name);
			# при выводе
			#print "name: $name ; value: $value<br/>";
			if($field->{type} eq 'file'){ 
				if($value=~m/\.(jpe?g|gif|bmp|png)$/){
					$value=qq{<a href='$field->{filedir}/$value' target='_blank'><img src='$field->{filedir}/$value' width='50' height='50'/></a>};
				}
				else{
					$value=qq{$field->{filedir}/$value};
				}
			}
			elsif($field->{type} eq 'textarea' || $field->{type} eq 'wysiwyg'){
				$value=~s/\n/<br\/>/gs;
			}
			elsif($field->{type} eq 'megaselect'){
				my $name=$field->{name}; $name=~s/;/_/g;
				$value=$values->{$name};				
#				print "qqqq: $QUERIES_FOR_MEGASELECT{$name} name: $name<br/>";
#				my $sth=$form->{dbh}->prepare($QUERIES_FOR_MEGASELECT{$name});
#				$sth->execute($value, @parents_megaselect);
#				@parents_megaselect=();
#				push @parents_megaselect, $value;
#				$value=$sth->fetchrow();
			}
			elsif($field->{type} eq 'multiconnect'){
				$field->{relation_save_table_id_worktable}=$form->{work_table_id} unless($field->{relation_save_table_id_worktable});
				my $sth=$form->{dbh}->prepare(qq{SELECT $field->{relation_table}.$field->{relation_table_header} FROM $field->{relation_save_table}, $field->{relation_table} WHERE $field->{relation_save_table}.$field->{relation_save_table_id_relation} = $field->{relation_table}.$field->{relation_table_id} AND $field->{relation_save_table}.$field->{relation_save_table_id_worktable}=?});
				$sth->execute($value);
				$value='';
				while(my $v=$sth->fetchrow()){
					$value.="$v<br/>";
				}
			}
			elsif($field->{type} eq  'multicheckbox'){
				while($field->{extended}=~m/(.+?);(.+?);/gs){
					my ($val,$desc)=($1,$2);
					$val=~s/[\s\n]+//gs;
					$value=~s|;$val;|$desc<br/>|;
				}
			}
			if($field->{filter_code}){
				eval($field->{filter_code});
				print "$@<br/>" if($@);
			}
			push @td,$value;
		}
		push @td,$CUR_ID;
		push @{$form->{RESULT}},\@td;
		
	}

	$sth->finish();
	$dbh->disconnect();
}

sub out_find_results{ # вывод результатов поиска
	my $form=$_[0];
	my $RESULT_LIST=$form->{RESULT_LIST};
	my $perpage;
	unless($perpage=$form->{perpage}){$perpage=20;}
	$form->{perpage}=$perpage;
	$form->{edit_form}=qq{./edit_form.pl?action=edit&id=<%id%>&config=$form->{config}} unless($form->{edit_form});
	my $template;
	if($form->{find_result_tmpl}){
		$template = Template->new({INCLUDE_PATH => './conf/templates'});
	}
	else{
		$template = Template->new({INCLUDE_PATH => './templates'});
		$form->{find_result_tmpl}='find_result.tmpl';
	}
	$template -> process($form->{find_result_tmpl},{
		form=>$form
	});
}

sub get_hash_for_element{ # служит для получения элемента из массива описаний полей
	my ($form, $name)=@_;
	my $element;
	
	foreach $element (@{$form->{fields}}){
		if($element->{name} eq $name){
			return $element;
		}
	}
	print "Ошибка! не найден элемент с именем $element->{name} в списке элементов";
	exit;
}

return 1;
END { }
