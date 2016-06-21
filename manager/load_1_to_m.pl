#!/usr/bin/perl
#use Strict;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
use DBI;
use struct_admin;
use Template;
use lib 'lib';
use read_conf;
my $c=new CGI;
our $sys;
our $sys->{config}=$c->param('config');
our $sys->{field_name}=$c->param('field');
our $sys->{key}=$c->param('id'); # значение для внешнего ключа
my $action=$c->param('action');
our $template = Template->new({
           INCLUDE_PATH => './templates'
});
print "Content-type: text/html; charset=windows-1251\n\n";
#unless(-f "./conf/$sys->{config}"){
#    print "конфиг отсутствует";
#    exit;
#}

unless($sys->{key}=~m/^\d+$/){
    print "Ключ не задан";
    exit;
}

our $form=&read_config;
our $cur_id=param('cur_id');

$form->{cur_id}=$cur_id;


my $this_element=&return_element;
if($form->{read_only} || $form->{read_only}){
	$this_element->{read_only}=1;
}

if($action eq 'add_form'){ # добавление записи
    if($this_element->{tree_use}){
			$this_element->{parent_id} = param('parent_id');
			$this_element->{parent_id}=undef if(!$this_element->{parent_id});
		}
    
    out_form('add', $this_element);
    exit;
}
elsif($action eq 'del_file'){
		my $cur_element=param('cur_element');
		foreach my $element (@{$this_element->{fields}}){
			if($element->{name} eq $cur_element){
				#print "$element->{name}<br/>";
				#print "SELECT $element->{name} from $this_element->{table} where $this_element->{table_id}=?";
				my $sth=$form->{dbh}->prepare("SELECT $element->{name} from $this_element->{table} where $this_element->{table_id}=?");
				$sth->execute($cur_id);
				my $name=$sth->fetchrow();
				$element->{file_for_del}=$name;
				
				# делаем что-то перед удалением				
				eval($element->{before_delete_code});
				if ($@){print "died: $@";}
				#print "удаляю: qq{$element->{filedir}/$name}";
				unlink(qq{$element->{filedir}/$name});	
				$form->{dbh}->do("
					UPDATE $this_element->{table} SET $element->{name}='' where $this_element->{table_id}=$cur_id
				");
				# после удаления
				eval($element->{after_delete_code});
				if ($@){print "died: $@";}

			}
		}
		$action='edit'
}
elsif($action eq 'down_up'){
	my $du=param('du');
	my $cur_id=param('cur_id'); # текущий id-шник того элемента кот. двигаем
	my $sth=$form->{dbh}->prepare("SELECT sort FROM $this_element->{table} WHERE $this_element->{table_id}=?");
	$sth->execute($cur_id);
	my $cur_sort=$sth->fetchrow();
	$cur_sort=0 unless($cur_sort);
	my $q1;
	if($du){ # поднимаем элемент вверх
		$q1="SELECT $this_element->{table_id}, sort from $this_element->{table} WHERE $this_element->{foreign_key}=$sys->{key} AND sort<$cur_sort order by sort desc  limit 1";
	}
	else{ # опускаем вниз
		$q1="SELECT $this_element->{table_id}, sort from $this_element->{table} WHERE $this_element->{foreign_key}=$sys->{key} AND sort>$cur_sort order by sort  limit 1";
	}
	
	$sth=$form->{dbh}->prepare($q1);
	$sth->execute();
	
	# запись, с которой будем меняться местами:
	my ($n_id,$n_sort)=$sth->fetchrow();

	# меняем местами:
	if($cur_sort && $n_sort){
		$form->{dbh}->do("UPDATE $this_element->{table} SET sort=$n_sort WHERE $this_element->{table_id}=$cur_id");
		$form->{dbh}->do("UPDATE $this_element->{table} SET sort=$cur_sort WHERE $this_element->{table_id}=$n_id");
	}
	#print "$q1<br>($n_id,$n_sort)";
}
if($action eq 'edit'){
	my $element=$this_element;
	my $cur_id=$c->param('cur_id');
	
	if($cur_id=~m/^\d+$/){
		my $sth=$form->{dbh}->prepare("SELECT * from $element->{table} WHERE $element->{table_id}=?");
		$sth->execute($cur_id);
		my $item=$sth->fetchrow_hashref();
		foreach my $e (@{$element->{fields}}){
			$e->{value}=$item->{$e->{name}};
		}
		
		edit_form($element,$cur_id);
	}
}
elsif($action eq 'add'){ # Добавляем...
	# собираем параметры для нового элемента (ну и проверяем заодно)
	my @names=(); my @values=(); my @vpr=();
	foreach my $element (@{$this_element->{fields}}){
		next if($element->{type} eq 'code');
		$element->{value}=$c->param($element->{name});
		if($element->{type} eq 'checkbox'){
			if($element->{value}){
				$element->{value}=1;
			}
			else{
				$element->{value}=0;
			}
		}
		if($element->{regexp} && ($element->{value}!~m/$element->{regexp}/)){
			# несовпедение по regexp'у
			print "<script>alert('значение для поля $element->{name} не верно')</script>";
			#&add_form($this_element);
			out_form('add', $this_element);
			last;
		}
		if($element->{type} eq 'file'){
			$element->{value}=&upload_1_to_m($element);
		}

		if($element->{name}){
			push @names, $element->{name};
			push @values, $element->{value};
			push @vpr,'?';
		}
	}
	
	my $parent_id;
	if($this_element->{tree_use}){ # учитываем возможность добавления дочернего элемента в дерево
		$parent_id=param('parent_id');
		if($parent_id=~m/^\d+$/){
			if($this_element->{tree_use}){
				$this_element->{parent_id} = param('parent_id');
				$this_element->{parent_id}=undef if(!$this_element->{parent_id});
			}
			# получаем path
			my $sth=$form->{dbh}->prepare(qq{SELECT path FROM $this_element->{table} WHERE $this_element->{table_id}=?});
			$sth->execute($parent_id);
			my $path=$sth->fetchrow();
			$path.=qq{/$parent_id};
			
			# Добавляем parent_id для дерева
			push @names,'parent_id';
			push @values, $parent_id;
			push @vpr,'?';
			
			# Добавляем path для дерева
			push @names,'path';
			push @values, $path;			
			push @vpr,'?';
			
		}
		else{
			$parent_id='';
		}
		
	}
	
	$this_element->{foreign_key}=$form->{work_table_id} unless($this_element->{foreign_key});
	push @names, $this_element->{foreign_key};
	#push @names, $form{work_table_id};
	push @values, $sys->{key};
	push @vpr,'?';
	
	if($this_element->{sort}){
		# инсертим с учётом сортировки
		#print "SELECT max(sort)+1 FROM $this_element->{table} WHERE $this_element->{foreign_key}=$sys->{key}";
		my $query="SELECT max(sort)+1 FROM $this_element->{table} WHERE $this_element->{foreign_key}=$sys->{key}";
		if($parent_id){ # сортировка с учётом дерева
			$query.=qq{ AND parent_id=$parent_id}
		}
		my $sth=$form->{dbh}->prepare($query);
		$sth->execute();

		my $cur_sort=$sth->fetchrow();
		$cur_sort=1 unless($cur_sort);
		push @names,'sort'; push @vpr,'?'; push @values, $cur_sort;
	}
	my $sth=$form->{dbh}->prepare("insert into $this_element->{table}(".join(',',@names).") values(".join(',',@vpr).")");
	$sth->execute(@values);
	$sth->finish();
	#print "<script src='./ajax.js'></script>";
	if($parent_id){ # При добавлении дочернего элемента перегружаем только дочернюю ветку
		print qq{<script>var base=parent.opener; base.document.getElementById('$sys->{field_name}_sub$parent_id').innerHTML=base.loadDocAsync('./load_1_to_m.pl?config=$sys->{config}&field=$sys->{field_name}&id=$sys->{key}&parent_id=$parent_id'); parent.window.close()</script>};	
	}
	else{ # перегружаем весь 1_to_m
		print qq{<script>var base=parent.opener; base.document.getElementById('1_to_m_$sys->{field_name}').innerHTML=base.loadDocAsync('./load_1_to_m.pl?config=$sys->{config}&field=$sys->{field_name}&id=$sys->{key}'); parent.window.close()</script>};
	}
	exit;
  
}
elsif($action eq 'update'){

	# Обновление данных подэлемента
	my $cur_id=$c->param('cur_id');	
	if($cur_id=~m/^\d+$/){
		my @names=(); my @values=();
		foreach my $element (@{$this_element->{fields}}){
				next if($element->{type} eq 'code');
				$element->{value}=$c->param($element->{name});
				if($element->{regexp} && ($element->{value}!~m/$element->{regexp}/)){
					# несовпедение по regexp'у
					print "<script>alert('значение для поля $element->{name} не верно')</script>";
					&edit_form($this_element,$cur_id);
					last;
				}
				if($element->{type} eq 'file'){
					$element->{value}=&upload_1_to_m($element,$this_element,$cur_id);
				}
				
				if($element->{name} && !($element->{type} eq 'file' && $element->{value} eq '0')){
					if($element->{type} eq 'checkbox'){
						if($element->{value}){
							$element->{value}=1;
						}
						else{
							$element->{value}=0;
						}
					}
					#print "name: $element->{name} ; type: $element->{type} ; 	 '$element->{value}'<br/>";						
					push @names, "$element->{name}=?";
					push @values, $element->{value};
				}
				
		}
		#print join(',',@names)."<br>";
		my $sth=$form->{dbh}->prepare("UPDATE $this_element->{table} SET ".join(',',@names)." WHERE $this_element->{table_id}=$cur_id");
		$sth->execute(@values);
		print q{<script>			
			alert('ok')
			parent.opener.location.href=parent.opener.location;
		</script>
		};
		exit;
		# выводим форму
		#$sth=$form->{dbh}->prepare("SELECT * from $this_element->{table} WHERE $this_element->{table_id}=?");
		#$sth->execute($cur_id);
		#my $item=$sth->fetchrow_hashref();
		#foreach my $e (@{$this_element->{fields}}){
		#	$e->{value}=$item->{$e->{name}};
		#}
		#print Dumper(
		#&edit_form($this_element,$cur_id);
	}
}
elsif($action eq 'del'){
    my $cur_id=$c->param('cur_id');
		if($this_element->{before_delete_code}){
			eval($this_element->{before_delete_code});
			if ($@){print "died: $@";}
		}
    if($cur_id=~m/^\d+$/){
				foreach my $element (@{$this_element->{fields}}){
					if($element->{type} eq 'file'){ # удаление файлов

						my $sth=$form->{dbh}->prepare("SELECT $element->{name} from $this_element->{table} WHERE $this_element->{table_id}=?");
						$sth->execute($cur_id);
						my $filename=$sth->fetchrow();
						$sth->finish();
						unlink("$element->{filedir}/$filename") if($filename);
					}
				}
				my $sth=$form->{dbh}->prepare("DELETE FROM $this_element->{table} WHERE $this_element->{table_id}=?");
				$sth->execute($cur_id);
				$sth->finish();
				if($this_element->{arter_delete_code}){
					eval($this_element->{after_delete_code});
					if ($@){print "died: $@";}
				}
    }
    #print "удаляю...";
    &out_slide($this_element);
}
elsif($action eq 'load_child'){
	#my $parent_id=param('parent_id');
	#print $this_element->{description};
	#my $sth=$form->{dbh}->prepare("SELECT FROM $form-")
	&out_slide($this_element);
	#exit;
}
else{
	# Проверяем, менялись ли значения прямо в слайде:
	my $change_field=param('change_field');
	my $newvalue=param('newvalue');
	my $change_id=param('change_id');
	#print "$change_field ; $newvalue ; $change_id<br/>";
	if($change_field && $change_id=~m/^\d+$/){
		foreach my $element (@{$this_element->{fields}}){
			if($element->{name} eq $change_field){
			
				print "изменён $element->{description}";
#				print "UPDATE $this_element->{table} SET $element->{name}=$newvalue WHERE $this_element->{table_id}=?";	
				my $sth=$form->{dbh}->prepare("UPDATE $this_element->{table} SET $element->{name}=? WHERE $this_element->{table_id}=?");
				$sth->execute($newvalue, $change_id);
			}
		}
	}
	
	&out_slide($this_element);
}

sub edit_form{
		my ($element,$cur_id)=@_;
		
		gen_all_fields($element);
		
		$template -> process('1_to_m_form.tmpl', {
			action=>'update',
			sys=>$sys,
			element=>$element,
			cur_id=>$cur_id
		}) || die($!);
}

sub gen_all_fields{
	my $cur_element=$_[0];	
	foreach my $element (@{$cur_element->{fields}}){
		
		if($element->{type} eq 'file'){
			# в 1_to_m, по сравнению с обычной формой, свои особенности
			# поэтому делаем свою генерацию поля file
			$element->{field}=qq{<input type='file' name='$element->{name}'>};
			$element->{field}.=qq{&nbsp;<a href="$element->{filedir}/$element->{value}" target="_blank">открыть</a>
				<a href="javascript:
					if(confirm('Вы действительно хотите удалить файл?'))
						document.location.href='load_1_to_m.pl?action=del_file&cur_id=$cur_id&config=$sys->{config}&id=$sys->{key}&field=$sys->{field_name}&cur_element=$element->{name}'">
					удалить
				</a>
			} if($element->{value});
			#$element->{field}=~s/<a href.+?>удалить<\/a>/<a href="?action=del_file&id=$id&config=$sys->{config}&key=$sys->{key}">удалить<\/a>/gis
			#$element->{field}=~s/action=del_file&id=&/action=del_file&id=$id&key=$sys->{key}&/gs;
			#$element->{field}=~s/&config=&/&config=$sys->{config}&/;
		}
		else{
			$element->{field}=&gen_field($element,$form->{dbh},$form);
			if($element->{type} eq 'codelist'){
				$this_element->{use_codelist}=1;
			}
			elsif($element->{type} eq 'wysiwyg'){
				$this_element->{use_wysiwyg}=1;
			}
		}
	}
};

sub upload_1_to_m{
	my ($element,$this_element,$cur_id)=@_;
	
	my $file=$element->{value};
	
	if($element->{value}=~m/([^\.]+)$/){
		my $ext=$1;
		
		# 1. прибиваем залитый ранее файл, если такой имеется
		if($cur_id=~m/^\d+$/){
			#print "SELECT $element->{name} from $this_element->{table} WHERE $this_element->{table_id}=$cur_id\n\n";
			my $sth=$form->{dbh}->prepare("SELECT $element->{name} from $this_element->{table} WHERE $this_element->{table_id}=$cur_id");
			$sth->execute();
			my $value=$element->{value};
			my $old_filename=$element->{file_for_del}=$element->{value}=$sth->fetchrow();
			eval($element->{before_delete_code});
			
			if ($@){print "died: $@";}
			#print "Удаляем: $element->{filedir}/$old_filename<br>";
			unlink(qq{$element->{filedir}/$old_filename});

			eval($element->{after_delete_code});
			if ($@){print "died: $@";}
			$element->{value}=$value;
		}

		
		
		# 2. генерируем имя файла
		my $j=int(rand(1)*10);
		my $filename_without_ext=(time)."_$j";
		my $filename="$filename_without_ext\.$ext";
		my $full_filename=qq{$element->{filedir}/$filename};		


		# 3. Аплоадим
		eval(q{
		open F, ">$full_filename";
		binmode F;
		print F while(<$file>);
		close F || die();
		});
		if($@){
			print "Ошибка записи в файл $full_filename";
		}
		
		# 4. Конвертируем
		if($element->{converter}){
			$element->{converter}=~s/\[%filename%\]/$full_filename/;
			$element->{converter}=~s/\[%input%\]/$element->{filedir}\/$filename_without_ext/g;
			$element->{converter}=~s/\[%input_ext%\]/$ext/g;
			$element->{converter}=~s/\n/ /gs;
			$element->{converter}=~s/^\s+//gs;
			$element->{converter}=~s/\s+$//gs;
			$element->{converter}=~s/\s+/ /gs;
			`$element->{converter}`;
		}		
		
		return $filename;

	}

	return 0;

}

sub out_slide{ # вывод слайда для связи 1 ко многим
	my $this_element=$_[0];
	my @names=(); my @desc=(); my @types=();
	my $i=0;
	my $struct;
	foreach my $element (@{$this_element->{fields}}){
		next if($element->{not_out_in_slide});
		push @desc, $element->{description};
		next if($element->{type} eq 'code');
		push @names, $element->{name};
		$i++;
	}	
	push @names,$this_element->{table_id};
	$this_element->{foreign_key}=$form->{work_table_id} unless($this_element->{foreign_key});
	

	my $q="SELECT ".join(',',@names)." from $this_element->{table} WHERE $this_element->{foreign_key}=$sys->{key}";
	
	# Для древовидных структур
	my $parent_id=param('parent_id');	
	if($this_element->{tree_use}){
		if($parent_id=~m/^\d+$/){
			# $parent_id
			if($parent_id==0){
				$q.=" AND (parent_id is null)";
			}
			else{
				$q.=" AND (parent_id = $parent_id)";
			}
			$this_element->{parent_id}=$parent_id;
			
			
			
			
			# вычисляем cur_level
			my $sth=$form->{dbh}->prepare("SELECT path from $this_element->{table} WHERE $this_element->{table_id}=?");
			$this_element->{cur_level}=($sth->execute($parent_id)+1);
			
		}
		else{
			$this_element->{cur_level}=1;
			$q.=" AND (parent_id is null)"
		}
	}
	# / для древовидных структур

	if($this_element->{sort}){ # включена возможность сортировки в 1_to_m
		$q.=' order by sort';
	}
	else{
		$q.=" order by $this_element->{order}" if($this_element->{order}); # Если предусмотрена сортировка
	}
	#print "q: ($q)<br>\n";
	my $sth=$form->{dbh}->prepare($q);
	$sth->execute();
	$values=$sth->fetchall_arrayref({});

	# изначально make_delete для 1_to_m не существовало, поэтому, если не указано, то удалять можно
	$this_element->{make_delete}=1 unless(defined($this_element->{make_delete}));

	# выполняем коды...
	foreach my $element (@{$this_element->{fields}}){

		foreach my $val (@{$values}){
			
			my $id=$val->{$this_element->{table_id}};
			if($element->{type} eq 'code'){
				eval($element->{code});
				$val->{$element->{name}}=$field;
			}
			else{
				my $out_element=$element;
				if($element->{change_in_slide}){
					# Возможность выбора значений прямо в слайде
					if(
						$element->{type} eq 'select_from_table' ||
						$element->{type} eq 'select_values'
						
					){
						$element->{onchange}=qq{document.getElementById('1_to_m_$this_element->{name}').innerHTML='<img src=/icon/ajax-loader.gif>'; document.getElementById('1_to_m_$this_element->{name}').innerHTML=loadDocAsync('./load_1_to_m.pl?config=$form->{config}&field=$this_element->{name}&id=$sys->{key}&change_field=$element->{name}&change_id=$id&newvalue='+this.value)};
					}
					elsif($element->{type} eq 'checkbox'){
						$element->{onchange}=qq{if(this.checked) newvalue=1; else newvalue = 0; document.getElementById('1_to_m_$this_element->{name}').innerHTML='<img src=/icon/ajax-loader.gif>'; document.getElementById('1_to_m_$this_element->{name}').innerHTML=loadDocAsync('./load_1_to_m.pl?config=$form->{config}&field=$this_element->{name}&id=$sys->{key}&change_field=$element->{name}&change_id=$id&newvalue='+newvalue)};
					}
				}
				else{
					$out_element->{readonly}=1
				}

				$out_element->{value}=$val->{$element->{name}};
				$val->{$out_element->{name}}=gen_field($out_element,$form->{dbh});
			}
		}

	}

	if($form->{read_only} || $form->{readonly}){
		$this_element->{read_only}=1;
	}
	#print Dumper($this_element->{sort});
	$this_element->{srt}=$this_element->{sort};
	
	# Если parent_id=0
	$this_element->{parent_id}='0' if($this_element->{tree_use} && !$this_element->{parent_id});
	
	$template -> process('1_to_m_slide.tmpl', {
		desc=>\@desc,
		element=>$this_element,
		sys=>$sys,
		values=>$values,
		form=>$form
	}) || die($!);
}

sub out_form{ # Вывод формы для создания или редактирования 1_to_m связи
	my($action,$element)=@_;	
	&gen_all_fields($element);
	
	$template -> process('1_to_m_form.tmpl', {
		action=>$action,
		sys=>$sys,
		element=>$element,
	}) || die($!);
}

sub return_element{		
    foreach my $element (@{$form->{fields}}){
        if($element->{type} eq '1_to_m' and $element->{name} eq $sys->{field_name}){
            return $element;
        }
    }
    return 0;
}
