package struct_admin;
use CGI qw(:standard);
use Template;

#Для работы send_mes
use MIME::Lite;
use MIME::Base64;

BEGIN {
		use Exporter ();
		@ISA = "Exporter";
		@EXPORT = (
			'&out_form','&get_params_in_form','&insert_data_in_form', '&read_data', '&update', '&del_file', 
			'&gen_field','&run_event','&add_code_to_event','&send_mes','$form'
		);
	}
	# Процедуры для быстрого создания формы (формы создания и редактирования элемента)

sub read_data{
	my $form=@_[0];
	my $dbh=$form->{dbh};
	unless($form->{id}=~m/^\d+$/){
		print "errmod 8273";
		exit;
	}

	my $sth=$dbh->prepare("SELECT * from $form->{work_table} WHERE $form->{work_table_id}=?");
	$sth->execute($form->{id});
	unless($sth->rows()){
		print "Запись с идентификатором $id отсутсвует на сервере!";
		exit;
	}
	my $items=$sth->fetchrow_hashref();
	foreach my $element (@{$form->{fields}}){
			if($element->{type} eq 'megaselect'){
				my $value='';
				foreach my $name ((split /;/, $element->{name})){
					if($value){$value.=';'}
					$value.=$items->{$name};

				}
				$element->{value}=$value;

			}
			else{
				$element->{value}=$items->{$element->{name}};
			}
	}
}
sub del_file{
=begun
		Эта процедура нужна для удаления файла
=cut
	my $form=shift;
	my $dbh=$form->{dbh};
	my $id=$form->{id};
	my $c=new CGI;
	my $field=$c->param('field');

	foreach my $element (@{$form->{fields}}){
		if($element->{name} eq $field){
			my $sth=$dbh->prepare("SELECT $element->{name} FROM $form->{work_table} WHERE $form->{work_table_id}=?");
			$sth->execute($id);
			if($element->{value}=$sth->fetchrow()){
				
				$sth->finish();
				if($element->{keep_orig_filename}){
					$element->{value}=~s|^(.+);.+$|$1|;
				}
				#print "удалить: $element->{filedir}/$element->{value}";
				if($element->{before_delete_code}){
						eval($element->{before_delete_code});
						if ($@){print "died: $@";}
				}
				if($element->{keep_orig_file}){
					$element->{value}=~s|^(.+?);+$|$1|;
				}
				$element->{file_for_del} = $element->{value};
				unlink("$element->{filedir}/$element->{value}");
				my $sth=$dbh->prepare("UPDATE $form->{work_table} SET $element->{name}='' WHERE $form->{work_table_id}=?");
				$sth->execute($id);
				if($element->{after_delete_code}){
						eval($element->{after_delete_code});
						if ($@){print "died: $@";}
				}
			}
			$sth->finish();
			last;
		}
	}
	return;
}
sub out_form{
=begin
	Эта процедура осуществляет вывод формы
=cut
			my $form = shift;
			my $dbh=$form->{dbh};

			my $fields;
			my $ID_HIDDEN='';
			if($form->{id}=~m/^\d+$/){
				$ID_HIDDEN=qq{<input type='hidden' name='id' value='$id'>}
			}
			#print Dumper($form);
			my $TRS=''; # Строки таблицы
			foreach my $element (@{$form->{fields}}){
				my $field='';
				next if($element->{type}=~/^filter_/);
				#print "$element->{name} : $element->{value}<br/>";
				$form->{use_wysiwyg}=1 if($element->{type} eq 'wysiwyg');
				$form->{use_codelist}=1 if($element->{type} eq 'codelist');
				$form->{use_1_to_m}=1 if($element->{type} eq '1_to_m');
				$fields->{$element->{name}}=&gen_field($element,$dbh,$form);
			}

			$form->{fld}=$fields;

			if($form->{template_form}){
					my $template = Template->new({INCLUDE_PATH => './conf/templates'});
					$template -> process($form->{template_form}, {
						form=>$form
					});
			}
			else{
					my $template = Template->new({INCLUDE_PATH => './templates'});
					$template -> process('edit_form.tmpl', {
						form=>$form
					});
			}
}

sub get_params_in_form{
=begin
		 	Эта процедура позволяет получить все параметры из сгенерированной формы,
		 	затем произвести их проверку.
		 	в случае ошибок возвращаяет строку с описанием ошибок.
		 	В случае успеха возвращает 0
=cut

		my $form = shift;
		my $dbh=$form->{dbh};
		my $id=$form->{id};
		my $c=new CGI;
		my $errors=$form->{errors};

		foreach my $element (@{$form->{fields}}){
			if($element->{type} eq 'multicheckbox'){
					$values='';
					while ($element->{extended}=~m/([^;]+);([^;]+)?/gs){
						my ($permission_name, $permission_description, $permission_checked)=($1,$2,$3);
						$permission_name=erase_spaces($permission_name);
						$permission_description=erase_spaces($permission_description);
						my $chk=$c->param("$element->{name}_$permission_name");
						 if ($chk){
							 $value.=qq{;$permission_name;};
							 $chk='1'
						 }
					}
					unless($value){
						$element->{value}='';
					}
					else{
						$element->{value}=$value;
					}
			}
			elsif($element->{type} eq 'multiconnect'){
				 my $relation_query="SELECT $element->{relation_table_id} FROM $element->{relation_table}";
				 if($element->{relation_where}){
					 $relation_query.=qq{ WHERE $element->{relation_where}};
				 }
				 my $sth=$dbh->prepare($relation_query);
				 $sth->execute();
				 while(my $id=$sth->fetchrow()){
				 			$value=$c->param("$element->{name}_$id");
				 			if($value){
				 				$element->{value}.=qq{$id;}
				 			}
				 }
			}
			elsif($element->{type} eq 'megaselect'){
				my $values='';
				my @regexp=(split /;/, $element->{regexp});
				my @descriptions=(split /;/, $element->{description});
				my $i=0;
				foreach my $cur_name ((split /;/, $element->{name})){
					my $cur_value=$c->param($cur_name);
					$cur_value=0 unless($cur_value);
					if(length($values)){$values.=';'};
					$values.=$cur_value;
					if($regexp[$i] && !($cur_value=~m/$regexp[$i]/)){
						$errors.="Поле '$descriptions[$i]' не заполнено или заполнено не верно<br>";
					}
					$i++;
				}
				$element->{value}=$values;
			}
			elsif($element->{type} eq 'checkbox'){
				$element->{value}=$c->param($element->{name});				
				if($element->{extended} eq 'enum'){
					if($element->{value}){$element->{value}='y'}
					else {$element->{value}='n'}
				}
				else{
					if($element->{value}){$element->{value}=1}
					else {$element->{value}=0}
				}
			}
			else{
				my $v=$c->param($element->{name});
				if (defined($v)){
					$element->{value}=$c->param($element->{name}) unless($element->{not_get_param});
				}
			}

			# в том случае, если для элемента формы задана регулярка для проверки -- осуществляем эту проверку:
			if($element->{regexp} && $element->{type} ne 'megaselect' && !$element->{readonly} && !$element->{read_only}){

				unless($element->{value}=~m/$element->{regexp}/gs){
					# ЗНАЧЕНИЕ ЭЛЕМЕНТА НЕ СООТВЕТВТВУЕТ РЕГУЛЯРКЕ:
						if($element->{type} eq 'file' && $form->{action} eq 'update' && !$element->{value}){
							# если мы всего лишь обновляем форму, но не заливая при этом файл...
							# 1. проверяем наличие файла
								my $sth=$form->{dbh}->prepare("SELECT $element->{name} from $form->{work_table} where $form->{work_table_id}=?");
								$sth->execute($form->{id});
								my $old_value=$sth->fetchrow();
								# Если мы храним уникальные имена файлов -- поправка на этот момент
								$old_value=~s|^(.[^;]+);.+$|$1| if($element->{keep_orig_filename});

								# Идём дальше, если ранее сохранённый файл у нас соответствует регулярке
								next if($old_value=~m/$element->{regexp}/);
						}


						if($element->{error_regexp}){
							$errors.="$element->{error_regexp}<br>";
						}
						else{
							$errors.="Поле '$element->{description}' не заполнено или заполнено не верно<br>";
						}

				}
			}

			if($element->{uniquew} && $dbh){ # Если элемент уникальный
					#print "проверка на уникальность";
					my $sql_query;
					if($id=~m/^\d+$/){ # уникальность для update
						$sql_query="SELECT count(*) from $form->{work_table} where $element->{name}=? AND $form->{work_table_id}<>$id";
					}
					else{ # Уникальность для insert
						$sql_query="SELECT count(*) from $form->{work_table} where $element->{name}=?";
					}
				#print $sql_query;
					my $sth=$dbh->prepare($sql_query);
					$sth->execute($element->{value});
					if($sth->fetchrow()){
						$errors.="В базе данных уже существует запись, поле '$element->{description}' которой принимает значение '$element->{value}'";
					}
			}
		}
		#print "e: $errors";
		if($errors){
			if($form->{action} eq 'insert'){ # Если при добавлении файла произошла ошибка, естесственно файл не залился
				foreach my $element (@{$form->{fields}}){
					if($element->{type} eq 'file'){
						$element->{value}='';
					}
				}
			}
			$form->{errors}=$errors;
			return $errors;
		}

		return 0;
}

sub insert_data_in_form{
	my $form = $_[0];
	my $dbh=$form->{dbh};
	$form->{errors}=get_params_in_form($form);
	my @FIELDS=();
	my @VALUES=();
	my @VOPR=();

	unless($form->{errors}){
		run_event($form->{events}->{before_insert});
		my $id=0;
		foreach my $element (@{$form->{fields}}){
			next if($element->{readonly} || $element->{read_only});
			if(
					($element->{type}!~/^(label|link|code|memo|file|multiconnect|1_to_m|relation_tree)$/) &&
					!($element->{type} =~m/^filter_extend/) 
				){
						if(!$element->{name}){
							print "Поле $element->{description} не имеет имени";
						}
						if($element->{type} eq 'megaselect'){
							my @names=(split /;/, $element->{name});
							my @values=(split /;/, $element->{value});
							my $i=0;
							foreach my $name (@names){
								push @FIELDS, $name;
								push @VALUES, $values[$i];
								push @VOPR,'?';
								$i++;
							}
						}
						elsif((($element->{type} eq 'datetime') || ($element->{type} eq 'date')) && $element->{value} eq 'now()'){
							push @FIELDS, $element->{name};
							push @VOPR,'now()';
						}
						elsif($element->{type} eq 'memo' && $element->{method} eq 'single'){							

							
						}
						else{
							push @FIELDS, $element->{name};
							push @VALUES, $element->{value};
							push @VOPR,'?';
						}
				}
		}
		unless($form->{errors}){
			my $query="INSERT INTO $form->{work_table}(".join(',',@FIELDS).') VALUES('.join(',',@VOPR).')';
			if($form->{explain}){
				print "$query<br>";
				print join(',',@VALUES);
			}

			my $sth=$dbh->prepare($query);
			$sth->execute(@VALUES);
			$form->{id}=$sth->{mysql_insertid};
			$sth->finish();		
			&upload_files($form);
			&upload_memo($form);
			&update_multiconnect($form);
			&update_relation_tree($form);
			&ok($form);
			&run_event($form->{events}->{after_insert});
			return $form->{id};
		}
	}
	
	&out_form($form, $dbh);
	
	return 0;
}

sub update{
	my $form = $_[0];
	my $dbh=$form->{dbh};
	unless($form->{id}=~m/^\d+$/){
		print "errmod 5232";
		exit;
	}

	if($form->{readonly} || $form->{read_only}){
		print "Запрещено исправлять эту форму"; return 0;
	}
	$form->{errors}=get_params_in_form($form);
	my @FIELDS=();
	my @VALUES=();
	my @VOPR=();
	unless($errors){
		run_event($form->{events}->{before_update});
		
		foreach my $element (@{$form->{fields}}){
			next if($element->{readonly} || $element->{read_only});
			#print "$element->{name} $element->{type}<br>";
			if(
					($element->{type}!~/^(label|link|code|memo|file|multiconnect|1_to_m|relation_tree)$/) &&
 					($element->{type} !~m/^filter_extend/) &&
          ($element->{type} ne 'relation_tree') &&
          !(($element->{type}=~m/^date(time)?$/) && ($element->{default_value}))
				)
				{
						#print "ok<br>";
						if($element->{type} eq 'megaselect'){
							my @names=(split /;/, $element->{name});
							my @values=(split /;/, $element->{value});
							my $i=0;
							foreach my $name (@names){
								push @FIELDS, "$name=?";
								push @VALUES, $values[$i];
								$i++;
							}
							
						}
						else{
							
							push @FIELDS, "$element->{name}=?";
							push @VALUES, $element->{value};
						}
			  }
		}
		
		unless($form->{errors}){
			my $query="UPDATE $form->{work_table} SET ".join(',',@FIELDS)." WHERE $form->{work_table_id}=$form->{id}";		
			# print "q: $query<br>";
			if($#FIELDS>-1){
				my $sth=$dbh->prepare($query);
				$sth->execute(@VALUES) || die($dbh->errstr());
			}
			&upload_files($form);
			&upload_memo($form);
			&update_multiconnect($form);
			&update_relation_tree($form);
			#&ok;
			return 1;
		}
	}
	
	print $errors;
	return 0;
	
}

sub get_remove_info{ # информация об авторизованном пользователе для элемента memo
		my $form=shift;
		my $element=shift;
		
		my $sth=$form->{dbh}->prepare("SELECT $element->{auth_id_field} remote_id, $element->{auth_name_field} remote_name FROM $element->{auth_table} WHERE $element->{auth_login_field}=?");
		#$sth->execute('root');
		$sth->execute($ENV{REMOTE_USER});
		return $sth->fetchrow_hashref();
}

sub upload_memo{
	my $form=shift;
	my $c=new CGI;
	foreach my $element (@{$form->{fields}}){
		
		if($element->{type} eq 'memo' && $element->{method} eq 'single'){
			if(my $v=$c->param($element->{name})){
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
				my $message;


				$element->{remote_info}=&get_remove_info($form,$element);

				$year+=1900; $mon++;
				#$message=~s/\[%datetime%\]/<datetime>$year\/$mon\/$mday $hour:$min:$sec<\/datetime>/gs;
				#$message=~s/\[%remote_name%\]/$element->{remote_info}->{remote_name}/gs;
				$v=~s/</&lt;/gs;
				$v=~s/>/&gt;/gs;
				$message=qq{<element_memo><ID>$element->{remote_info}->{remote_id}<\/ID><message>$v<\/message><year>$year</year><mon>}.sprintf('%02d',$mon).qq{</mon><mday>}.sprintf('%02d',$mday).qq{</mday><hour>}.sprintf('%02d',$hour).qq{</hour><min>}.sprintf('%02d',$min).qq{</min><sec>}.sprintf('%02d',$sec).qq{</sec></element_memo>};

				my $sth=$form->{dbh}->prepare(qq{UPDATE $form->{work_table} SET $element->{name}=concat($element->{name},?) WHERE $form->{work_table_id}=?});
				$sth->execute($message,$form->{id});
			}
		}
		elsif($element->{type} eq 'memo' && $element->{method} eq 'multitable'){
			if(my $v=$c->param($element->{name})){
				$element->{remote_info}=&get_remove_info($form,$element);
				my $sth=$form->{dbh}->prepare("INSERT INTO $element->{memo_table}($element->{memo_table_foreign_key},$element->{memo_table_auth_id},$element->{memo_table_comment},$element->{memo_table_registered}) VALUES(?,?,?,now())");
				$sth->execute($form->{id},$element->{remote_info}->{remote_id},$v);
			}
		}
	}
}

sub upload_files($form,$dbh,$id){
	my $form=$_[0];
	my $dbh=$form->{dbh};
	my $id=$form->{id};
	unless($id=~m/^\d+$/){
		print "ERROR 72eh";
	}
	my $j=0;
	foreach my $element (@{$form->{fields}}){
            if( ($element->{type} eq 'file')){
				  $j++;

					if($element->{value}=~m/([^\.]+)$/){
						my $orig_name=$element->{value};
                                                   $orig_name =~ tr/A-Z/a-z/;
						my $ext=$1;
						if($element->{value}=~m/\.(tar\.(gz|bz2))$/){
							$ext=$1
						}
						$ext=$element->{extension} if($element->{extension});
						my $filename_without_ext=(time)."_$j";
						my $filename="$filename_without_ext\.$ext";#$id.qq{_$j.$ext};
						my $full_filename=qq{$element->{filedir}/$filename};
                                                
                                                   #
                                                   $full_filename =~ tr/A-Z/a-z/;
                                                   #
                                                
						my $file=$element->{value};
						my $sth=$dbh->prepare("SELECT $element->{name} from $form->{work_table} WHERE $form->{work_table_id}=$id");
						$sth->execute();
						my $oldfile=$sth->fetchrow();

						if($oldfile=~m/^(.+);?/){
							unlink qq{$element->{filedir}/$1};
						}
						if($element->{keep_name}){
							require Lingua::Translit; #Используем для транслита русских насзваний
							my $ltr=new Lingua::Translit("GOST 7.79 RUS");

							#Возможно понадобиться Encode, по крайней мере на моей локальной машине потребовалось, в связи с utf8
							#Encode::from_to($orig_name,"cp1251","utf8");
							$orig_name = Encode::decode("cp1251",$orig_name);
							
							$filename = $ltr->translit($orig_name);
	
							#Убираем пробелы и остальной лишний хлам
							$filename =~ s/\ /_/g;
							$filename =~ s/('|"|\`)//g;
							
							($filename_without_ext,$ext)=split('\.',$filename);
							$full_filename = qq{$element->{filedir}/$filename};
							$full_filename =~ tr/A-Z/a-z/;
							
						}
						#print "Content-type: text/html\n\n$full_filename";
						if( -e $full_filename ){print "Фаил $full_filename уже существует!"; exit;}
						eval(q{
						open F, ">$full_filename" ;
							binmode F;
							print F while(<$file>);
						close F || die();
						});
						#print "e: $@ ; @$";
						if($@){
							print "Ошибка записи в файл $full_filename";
							exit;
						}
						
						my $sth=$dbh->prepare("UPDATE $form->{work_table} SET $element->{name}=? WHERE $form->{work_table_id}=$id");
						$filename=$filename.qq{;$orig_name} if($element->{keep_orig_filename});
                                                
                                                #
                                                $filename =~ tr/A-Z/a-z/;
						#
                                                $sth->execute($filename);
                                                
                                                #
                                                $filename_without_ext =~ tr/A-Z/a-z/;
                                                $ext =~ tr/A-Z/a-z/;
                                                #
                                                
						if($element->{converter}){
							$element->{converter}=~s/\[%filename%\]/$full_filename/g; #/g antonov, for water mark integratioon. if doesnt work, remove.
							$element->{converter}=~s/\[%input%\]/$element->{filedir}\/$filename_without_ext/g;
							$element->{converter}=~s/\[%input_ext%\]/$ext/g;
							$element->{converter}=~s/\n/ /gs;
							$element->{converter}=~s/^\s+//gs;
							$element->{converter}=~s/\s+$//gs;
							$element->{converter}=~s/\s+/ /gs;
							#print "$element->{converter}<br/>";
							print `$element->{converter}`;
						}


					}
			}
	}
}

sub update_multiconnect{
	my $form=$_[0];
	my $dbh=$form->{dbh};
	my $id=$form->{id};
		unless($id=~m/^\d+$/){
			print "ERROR 7etx";exit;
		}

		foreach my $element (@{$form->{fields}}){
			if( $element->{type} eq 'multiconnect'){

				$element->{relation_save_table_id_relation}=$element->{relation_table_id} unless($element->{relation_save_table_id_relation});
				$element->{relation_save_table_id_worktable}=$form->{work_table_id} unless($element->{relation_save_table_id_worktable});

				my $exists_id='0';
				while($element->{value}=~m/(\d+);/g){$exists_id.=qq{,$1};}
				# удаляем старые связи, не входящие в список тех, что остались
				#print "DELETE FROM $element->{relation_save_table} WHERE $form->{work_table_id}=$id AND $form->{work_table_id} not in ($exists_id)";
				#print "DELETE FROM $element->{relation_save_table} WHERE $element->{relation_save_table_id_worktable}=$id AND $element->{relation_save_table_id_relation} not in ($exists_id)";
				# Удаляем только те записи, галки для которых не выбраны
				my $sth=$dbh->prepare("DELETE FROM $element->{relation_save_table} WHERE $element->{relation_save_table_id_worktable}=$id AND $element->{relation_save_table_id_relation} not in ($exists_id)");
				$sth->execute();
				$sth->finish();
				my $created_id='0';

				# Получаем те записи, которые уже созданы
				my $sth=$dbh->prepare("SELECT $element->{relation_save_table_id_relation} FROM $element->{relation_save_table} WHERE $element->{relation_save_table_id_worktable}=$id");
				$sth->execute();
				while(my $cr_id=$sth->fetchrow()){
					$created_id.=','.$cr_id;
				}
				$sth->finish();

				# добавляем новые связи:
				while($element->{value}=~m/(\d+);/g){
					my $relation_table_id=$1;
					unless($created_id=~m/(^|,)$relation_table_id(,|$)/){
						$dbh->do("INSERT INTO $element->{relation_save_table}($element->{relation_save_table_id_worktable},$element->{relation_save_table_id_relation}) values($id,$relation_table_id)");
					}
				}

			}
		}
}

sub update_relation_tree{
	my $form=$_[0];
	my $dbh=$form->{dbh};
	my $id=$form->{id};

	unless($form->{id}=~m/^\d+$/){print "ERROR 7etx"; exit;}
	foreach my $element (@{$form->{fields}}){
		if($element->{type} eq 'relation_tree'){
			unless($element->{relation_save_table}=~m/^[a-z_0-9]+$/i){
				print "не указана relation_table";
				exit;
				}
				my $cgi=new CGI;
				my @values=$cgi->param($element->{name});
				$dbh->do("DELETE FROM $element->{relation_save_table} where $form->{work_table_id}=$id");
				my $sth=$dbh->prepare("INSERT INTO $element->{relation_save_table}($element->{relation_table_id},$form->{work_table_id}) values(?,?)");
				foreach my $v (@values){
					$sth->execute($v,$form->{id}) if($v=~m/^\d+$/);
				}
			}
		}
}

sub erase_spaces{
	my $s=$_[0];
	$s=~s/(^[\n\s]+|[\n\s]+$)//gs;
	return $s;
}

sub gen_field{
	my ($element,$dbh,$form)=@_;
	my $field='';
	my $sth;
	my $id=$form->{id};
	if($element->{type} eq 'select_values'){ # SELECT_VALUES_FIELD
		if($element->{readonly} || $element->{read_only}){

				while($element->{values}=~m/(.+?)=>(.+?)(;|$)/gs){
					my ($k,$v)=($1,$2);
					if($element->{value}==$1){
						$field=$2; next;
					}
				}
		}
		else{
				if($element->{default_label_empty}){
						$label_empty=$element->{default_label_empty};
				}
				else{
						$label_empty="Выберите значение для поля $element->{description}";
				}
				$field=qq{<SELECT name='$element->{name}'};
				if($element->{onchange}){
					$field.=qq{ onchange="$element->{onchange}"} 
				}
				$field.=qq{ id='$element->{name}'><option value='$element->{default_value_empty}'};
				my @colors=split(';',$element->{colors});

				$field.=qq{ style='background-color: $colors[0]'} if($colors[0]);
				$field.=qq{>$label_empty</option>};
				my $i=1;
				$element->{values}=~s|\n[\t\s]+||gs;
				while($element->{values}=~m/([^;]+)/gs){
					$el=$1;
					if($el=~m/^(.+?)=>(.+?)$/){						
						my($id,$header)=($1,$2);
						my $selected='';
						if($id eq $element->{value}){
							 	 $selected=' selected';
						}

						my $background='';
						if($colors[$i]){
								$background=qq{ style=' background-color: $colors[$i]'}
						}
						$field.=qq{<option value='$id'$selected$background>$header</option>}
					}
					$i++;
				}
				$field.=qq{</select>}
		}
	}
	elsif($element->{type} eq 'text'){ # TEXT FIELD
		$element->{value}=~s/'/&rsquo;/g;
		if($element->{read_only} || $element->{readonly}){
				$field=$element->{value};
		}
		else{
			my $ev=&get_ev_attr($element);
			$field=qq{<input type='text' class="input" style="$element->{style}" $ev name='$element->{name}' id='$element->{name}' class='txt' value='$element->{value}'>};
		}		
			
	}
	elsif($element->{type} eq 'textarea'){ # TEXTAREA FIELD
		if($element->{read_only} || $element->{readonly}){
				$field=$element->{value};
				$field=~s/\n/<br>/g;
		}
		else{
			my $html_id=qq{id='$element->{name}'};
			my $style='';
			$style=qq{style='$element->{style}'} if($element->{style});
			my $ev=get_ev_attr($element);
			$field=qq{<textarea name='$element->{name}' $ev $html_id $style>$element->{value}</textarea>};
		}
	}
	elsif($element->{type} eq 'hidden'){ # HIDDEN_FIELD
		$element->{value}=~s/"/&quot;/g;
		$element->{id}||=$element->{name}.'_id';
		$field=qq{<input type='hidden' name='$element->{name}' id='$element->{id}' value="$element->{value}" class='input'>};
	}
        
        #/***************************/ antonov
       	elsif($element->{type} eq 'html'){ # ДОПОЛНИТЕЛЬНАЯ HTML РАЗМЕТКА
		#$element->{value}=~s/"/&quot;/g;
		#$element->{id}||=$element->{name}.'_id';
		$field=qq{$element->{style}};
	}
        #/***************************/
        
	elsif($element->{type} eq 'select_from_table'){ # SELECT_FROM TABLE
		my $label_empty;
		if($element->{default_label_empty}){
			$label_empty=$element->{default_label_empty};
		}
		else{
			$label_empty="Выберите значение для поля $element->{description}";
		}

		if($element->{readonly} || $element->{read_only}){ # Если селект только для чтения -- выводим только значение
			my $sth_query="SELECT $element->{header_field} as header FROM $element->{table} WHERE $element->{value_field}=?";
			my $sth=$dbh->prepare($sth_query);
			$sth->execute($element->{value}) || die($dbh->errstr());
			my $header=$sth->fetchrow();
			$header='не выбрано' unless($header);
			$sth->finish();
			$field=$header;
		}
		else{
			my $order=qq{order by $element->{order}} if($element->{order});
			$element->{where}=qq{where $element->{where}} if(!($element->{where}=~m/\s*where/i) && $element->{where});
			
			if($element->{tree_use}){
					if($element->{sort}){
						$element->{sortfield}='sort'
					}
					else{
						$element->{sortfield}=$element->{header_field};
					}
					$field=qq{<SELECT class="input" name='$element->{name}' id='$element->{name}'};
					$field.=qq{ onchange="$element->{onchange}"};
					$field.="><option value='$element->{default_value_empty}'>$label_empty</option>".&get_branch('',$element).'</select>';
					sub get_branch{
							my ($path,$element)=@_;
							my $optlist='';
							my $where=$element->{where};
							$where.=' AND ' if($where);
							$where.=qq{path=?};
					
							$where=qq{WHERE $where} unless($where=~m/^\s*where/i);
							my $level=0;
							while($path=~m/\d+/g){$level++};
							my $sth=$form->{dbh}->prepare(qq{
								SELECT $element->{value_field} as id, $element->{header_field} as header 
								FROM $element->{table}
								$where
								ORDER BY $element->{sortfield}
							});
							$sth->execute($path);
							while(my ($id,$header)=$sth->fetchrow()){
								#print "h: $header<br>";
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
			else{					
					my $sth_query="SELECT $element->{value_field} as id, $element->{header_field} as header $element->{optgroup} FROM $element->{table} $element->{where} $order";
#					print "$sth_query";
					my $sth=$dbh->prepare($sth_query);			
					$sth->execute() || die($sth_query.'<br>'.$dbh->errstr());
			
					$field=qq{<SELECT class="input" name='$element->{name}'};
					if($element->{onchange}){								
						$field.=qq{ onchange="$element->{onchange}"};
					}
					$field.=qq{ id='$element->{name}'><option value='$element->{default_value_empty}'>$label_empty</option>};
			
					while(my ($id, $header, $optgroup)=$sth->fetchrow()){ # Получаем поле
						if( $element->{optgroup} && $optgroup ) {
							$field.=qq{<optgroup label="$header">};
						}else{
							my $selected='';
							if($id eq $element->{value}){
								$selected=' selected';
							}
							$field.=qq{<option value='$id'$selected>$header</option>};
						}
					}
					$field.=qq{</select>};
			}
		}
	}
	elsif($element->{type} eq 'checkbox'){ # CHECKBOX FIELD
		my $checked='';
		if($element->{extended} eq 'enum' && $element->{value} eq 'y'){
			$checked='checked';
		}
		elsif($element->{extended} ne 'enum' && $element->{value}) {$checked='checked'}
		
		if($element->{read_only} || $element->{readonly}){
			$field.="<input type='hidden' name='$element->{name}' value='$element->{value}'><input type='checkbox' disabled $checked>"
		}
		else{
			$field=qq{<input type='checkbox' $disabled};
			if($element->{onchange}){								
				$field.=qq{ onchange="$element->{onchange}"};
			}
			$field.=qq{ name='$element->{name}' $checked>};
		}
	}
	elsif($element->{type} eq 'multicheckbox'){ # MULTICHECKBOX FIELD
		my $i=0;
		my @chk_mas=split /;/, $element->{value};
		while ($element->{extended}=~m/([^;]+);([^;]+)?/gs){
			my ($permission_name, $permission_description, $permission_checked)=($1,$2,$3);
			$permission_name=erase_spaces($permission_name);
			$permission_description=erase_spaces($permission_description);
			my $checked='';
			if($element->{value}=~m/;$permission_name;/){
				$checked=' checked';
			}
			$field.=qq{<input type='checkbox' name='$element->{name}_$permission_name'$checked> $permission_description<br>};
				$i++;
			}
			$field=qq{<div style='padding-left: 20px;'><small>$field</small></div>};
	}
	elsif($element->{type} eq 'multiconnect'){ # MULTICONNECT
		# Элемент связи "многие ко многим"
		my $i=0;
		$element->{relation_save_table_id_relation}=$element->{relation_table_id} unless($element->{relation_save_table_id_relation});
		$element->{relation_save_table_id_worktable}=$form->{work_table_id} unless($element->{relation_save_table_id_worktable});
		# получаем все включенные флажки
		my %on=();
		if($form->{id}=~m/^\d+$/){
			my $sth=$dbh->prepare("SELECT $element->{relation_save_table_id_relation}  from $element->{relation_save_table} WHERE $element->{relation_save_table_id_worktable}=$form->{id}");
			$sth->execute();

			while(my $f=$sth->fetchrow()){$on{$f}=1}
				$sth->finish();
			}


			my $relation_query="SELECT $element->{relation_table_id} as id, $element->{relation_table_header} as header from $element->{relation_table}";
			if($element->{relation_where}){
				$relation_query.=qq{ WHERE $element->{relation_where}}
			}
			$relation_query.=qq{ order by $element->{relation_table_header}};
			$sth=$dbh->prepare($relation_query);
			
			$sth->execute();
			while (my ($relation_id, $relation_header)=$sth->fetchrow()){
				my $checked='';
				if($on{$relation_id}){
					$checked=' checked';
				}
				$field.=qq{<input type='checkbox' name='$element->{name}_$relation_id'$checked> $relation_header<br>};
				$i++;
			}
			$field=qq{<div style='padding-left: 20px;'><small>$field</small></div>};
	}
	elsif($element->{type} eq 'megaselect'){ # MEGASELECT
		my @descriptions=(split /;/, $element->{description});
		my @names=(split /;/, $element->{name});
		my @tables=(split /;/, $element->{table});
		my @headers=(split /;/, $element->{table_headers});
		my @indexes=(split /;/, $element->{table_indexes});
		my @despendences=(split /;/, $element->{despendence});
		my @values=(split /;/, $element->{value});

		my $default_value=$values[0];
		my $nameparam=$element->{name};
		$nameparam=~s/;/\//g;
		my $add_change='';
		if ($#names>2){
			my $i=2;
			while($i<=$#names){
				my $prev=$i-1;
				$add_change.=qq{document.getElementById('megaselect_$names[$i]').innerHTML='для выбора поля "$descriptions[$i]" выберите значение в поле "$descriptions[$prev]"'\n};
				$i++;
			}

		}
		$field=qq{
			<script>
				function change_select_$names[0](v){
					loadDoc('./edit_form.pl?config=$form->{config}&action=load_megaselect&position=1&name=$nameparam&despendence_value='+v, 'megaselect_$names[1]');
					$add_change
				}
			</script>
		};

		$field.=qq{<b>$descriptions[0]</b>:<br/><select name='$names[0]' OnChange="change_select_$names[0](this.value)"><option value='0'>Выберите значение для поля $descriptions[0]</option>};
		my $WHERE='';
		if($despendences[0]){
			$WHERE=qq{WHERE $despendences[0]};
		}

		my $sth=$dbh->prepare("SELECT $headers[0],$indexes[0] FROM $tables[0] $WHERE  order by $headers[0]");
		$sth->execute();
		while(my ($h,$i)=$sth->fetchrow()){
			my $selected='';
			if($default_value==$i){
				$selected=' selected';
			}
			$field.=qq{<option value="$i"$selected>$h</option>};
		}
		$field.=q{</select>};
		my $i=1;
		while($descriptions[$i]){
			$field.=qq{<br/><br/><b>$descriptions[$i]</b>:<div id='megaselect_$names[$i]'>для выбора поля "$descriptions[$i]" выберите значение в поле "$descriptions[$i-1]"</div>};
			if($values[$i]){
				my $prev=$values[$i-1];
				$field.=qq{
					<script>
					 document.getElementById('megaselect_$names[$i]').innerHTML=loadDocAsync('./edit_form.pl?config=$form->{config}&action=load_megaselect&position=$i&name=$nameparam&despendence_value=$prev&cur_value=$values[$i]')
					</script>
				}
			}
			$i++;
		}
	}
	elsif($element->{type} eq '1_to_m'){# связь "один ко многим"

		if($form->{action} eq 'insert'){
			$field=q{это поле доступно только при изменении уже существующего объекта<br/>при создании объекта редактировать поле нельзя}
		}
		else{
			$field=qq{
				<div id='1_to_m_$element->{name}'></div>
				<script>
					document.getElementById('1_to_m_$element->{name}').innerHTML=loadDocAsync('./load_1_to_m.pl?config=$form->{config}&field=$element->{name}&id=$id')
				</script>
			};
		}
	}
	elsif($element->{type} eq 'code'){
		foreach my $r (@{$form->{fields}}){
			$element->{code}=~s/\[%$r->{name}%\]/$r->{value}/gs;
		}
		if(ref($element->{code}) eq 'CODE'){
			
			$field=&{$element->{code}};
		}
		else{
			eval($element->{code});
		}
		if ($@){
			print "died: $@";
			my $i=1;
			foreach my $s (split /\n/,$element->{code}){
				print "$i. \t$s<br>";
				$i++;
			}
		}
		
	}
	elsif($element->{type} eq 'relation_tree'){
		$field=qq{
			<div id='relation_tree_$element->{name}'></div>
				<script>document.getElementById('relation_tree_$element->{name}').innerHTML=loadDocAsync('./load_relation_tree.pl?config=$form->{config}&field=$element->{name}&key=$id');</script>
		}
	}
	elsif($element->{type} eq 'wysiwyg'){
		my $html_id='';
		$html_id=qq{id='$element->{html_id}'} if($element->{html_id});
		$field=qq{<textarea name='$element->{name}' class='mce' $html_id>$element->{value}</textarea>};
	}
	elsif($element->{type} eq 'codelist'){
		$field=qq{<textarea id='$element->{name}' name='$element->{name}' class='codepress perl' style='$element->{style}'>$element->{value}</textarea>
		<script>
					editAreaLoader.init({
						id : "$element->{name}"		// textarea id
						,syntax: "perl"			// syntax to be uses for highgliting
						,start_highlight: true		// to display with highlight mode on start-up
						,font_size: "8px"
						,width: '1300px'
					});
					
			</script>
		}
	}
	elsif($element->{type} eq 'date'){
		my $div_name=$element->{name}.'_d';
		unless($element->{value}=~m/[123456789]/){
			$element->{value}='0-0-0';
		}
		if($element->{readonly} || $element->{read_only}){
			$field=$element->{value};
		}
		elsif($element->{default_value} eq 'now()'){
			my $pr_val='-';
			$pr_val=$element->{value} if($element->{value} ne '0-0-0');
			$field=qq{<input type="hidden" name="$element->{name}" value="now()">$pr_val};
		}
		else{
			$field=qq{
				<input type='hidden' name='$element->{name}' id='$element->{name}' value='$element->{value}'>
				<div id='$div_name'></div>
				<div id='$div_name\_for_clear' style='display: none;'><a href="" OnClick="javascript: 
								document.getElementById('$div_name').style.display='none'; 
								document.getElementById('$div_name\_for_clear').style.display='none'; 
								document.getElementById('$element->{name}').value='0-0-0';
								document.getElementById('empty_$div_name').style.display='';
								return false;
					">[x]</a></div>
				<div id='empty_$div_name'><a href="" OnCLick="
					document.getElementById('$element->{name}').value=save_$element->{name};
					document.getElementById('$div_name').style.display='';
					document.getElementById('empty_$div_name').style.display='none';
					document.getElementById('$div_name\_for_clear').style.display=''; 
					return false
				">заполнить</a></div>
				<script>
					init_calendar('$element->{name}','$div_name',0);
					var v='$element->{value}'
					if(v != '0-0-0'){
						document.getElementById('empty_$div_name').style.display='none';
						document.getElementById('$div_name\_for_clear').style.display=''; 
					}
					else{
						var save_$element->{name}=document.getElementById('$element->{name}').value;
						document.getElementById('$element->{name}').value=v
						document.getElementById('$div_name').style.display='none';
					}
				</script>
			};
		}
	}
	elsif($element->{type} eq 'datetime'){
		my $div_name=$element->{name}.'_d';
		unless($element->{value}=~m/[123456789]/){
			$element->{value}='0-0-0 0:0:0';
		}
		if($element->{readonly} || $element->{read_only}){
			$field=$element->{value};
		}
		elsif($element->{default_value} eq 'now()'){
			my $pr_val='-';
			$pr_val=$element->{value} if($element->{value} ne '0-0-0 0:0:0');
			$field=qq{<input type="hidden" name="$element->{name}" value="now()">$pr_val};
		}
		else{
			$field=qq{
				<input type='hidden' name='$element->{name}' id='$element->{name}' value='$element->{value}'>
				<div id='$div_name'></div>
				<div id='$div_name\_for_clear' style='display: none;'><a href="" OnClick="javascript: 
								document.getElementById('$div_name').style.display='none'; 
								document.getElementById('$div_name\_for_clear').style.display='none'; 
								document.getElementById('$element->{name}').value='0-0-0 0:0:0';
								document.getElementById('empty_$div_name').style.display='';
								return false;
					">[x]</a></div>
				<div id='empty_$div_name'><a href="" OnCLick="document.getElementById('$element->{name}').value=save_$element->{name};
					document.getElementById('$div_name').style.display='';
					document.getElementById('empty_$div_name').style.display='none';					
					document.getElementById('$div_name\_for_clear').style.display=''; 
					return false">заполнить</a></div>
				<script>
					init_calendar('$element->{name}','$div_name',1);
					var v='$element->{value}'
					if(v != '0-0-0 0:0:0'){
						document.getElementById('empty_$div_name').style.display='none';
						document.getElementById('$div_name\_for_clear').style.display=''; 
					}
					else{
						var save_$element->{name}=document.getElementById('$element->{name}').value;
						document.getElementById('$element->{name}').value=v
						document.getElementById('$div_name').style.display='none';
						
					}
				</script>
			};
		}
	}
	elsif($element->{type} eq 'file'){ # описание для поля типа file
		$field=qq{<input type='file' name='$element->{name}'>};
		if($element->{value}){
			$element->{filedir}.='/' unless($element->{filedir}=~m/\/$/);
# !@!

			if($element->{keep_orig_filename}){
				$field.=qq{&nbsp;<a href="edit_form.pl?action=file_download&config=$form->{config}&name=$element->{name}&id=$id">открыть</a> <a href="javascript: if(confirm('Вы действительно хотите удалить файл?')) document.location.href='$script?action=del_file&id=$id&config=$form->{config}&field=$element->{name}'">удалить</a>}
			}
			else{
				$field.=qq{&nbsp;<a href="javascript: openWindow('$element->{filedir}$element->{value}', 300, 300)">открыть</a> <a href="javascript: if(confirm('Вы действительно хотите удалить файл?')) document.location.href='$script?action=del_file&id=$id&config=$form->{config}&field=$element->{name}'">удалить</a>}
			}
		}
	}
	elsif($element->{type} eq 'label'){ # описание для поля типа lebel
		$TRS.=qq{<tr class='label'><td colspan='2'>$element->{description}:</td></tr>};
	}
	elsif($element->{type} eq 'megaselect'){ # описание для поля типа megaselect
		$TRS.=qq{<tr><td class='description'>$element->{megaselect_description}:</td><td>$field</td></tr>};
	}
	elsif($element->{type} eq 'link'){
		$element->{url}=~s/\[%id%\]/$id/;
		if($id=~m/\d+/){
			my $target='';
			if($element->{target}){
				$target=qq{ target='$element->{target}'}
			}
			$field=qq{<a href='$element->{url}'$target>$element->{description}</a>};
		}
	}
	elsif($element->{type} eq 'memo'){
		print_error(qq{Не указан атрибут auth_table}) unless($element->{auth_table});
		print_error(qq{Не указан атрибут auth_login_field}) unless($element->{auth_login_field});
		print_error(qq{Не указан атрибут auth_id_field}) unless($element->{auth_id_field});
		print_error(qq{Не указан атрибут auth_name_field}) unless($element->{auth_id_field});
		
		if($element->{method} eq 'single'){
			# 1. информация об идентификаторах

			
			my $sth=$form->{dbh}->prepare(qq{
				SELECT 
					$element->{auth_name_field},
					$element->{auth_login_field},
					$element->{auth_id_field}
				FROM
					$element->{auth_table} 
				WHERE $element->{auth_id_field}=?
			});
			$field='<hr>';
			while($element->{value}=~m/<element_memo>(.+?)<\/element_memo>/gs){				
				my $tags=&parse_memo_tags($1);
				$sth->execute($tags->{ID});
				($remote_name, $remote_login, $remote_id)=$sth->fetchrow();
				$tags->{remote_name}=$remote_name;
				$tags->{remote_login}=$remote_login;
				$tags->{remote_id}=$remote_id;
				my $mes=$element->{format};
				while($element->{format}=~m/\[%(.+?)%\]/gs){
					my $tagname=$1;					
					$mes=~s/\[%$tagname%\]/$tags->{$tagname}/gs;
				}
				$field.=$mes;
			}
			# временно
			$field.="<textarea name='$element->{name}'></textarea>";
		}
		elsif($element->{method} eq 'multitable'){
			$field=qq{				
				<hr>
				
				<div id='memo_$element->{name}'></div>
				<script>document.getElementById('memo_$element->{name}').innerHTML=loadDocAsync('./memo.pl?config=$form->{config}&name=$element->{name}&key=$form->{id}')</script><br>	
			};
			$field.=qq{
				<b>добавить комментарий</b>:<br/>				
				<textarea name='$element->{name}' id='$element->{name}'></textarea><br/>
				<input type="button" Onclick="message=encodeURIComponent(document.getElementById('$element->{name}').value) ; loadDoc('./memo.pl?config=$form->{config}&name=$element->{name}&key=$form->{id}&action=add&message='+message, 'memo_$element->{name}')" value="добавить комментарий">
			} if(!($element->{read_only} || $element->{readonly}));
		}
	
#		$field.="";
	}
	return $field;
}

sub parse_memo_tags{
		my $tags=shift;
		my $hash;
		while($tags=~/<(.+?)>(.+?)<\//gs){			
			$hash->{$1}=$2;
		}
		return $hash;
}

sub ok{
	my $form=$_[0];
    my $edit_link = $form->{edit_form} || "./edit_form.pl?action=edit&id=$form->{id}&config=$form->{config}";
    $edit_link =~ s/<\%id\%>/$form->{id}/;
                
	print qq{
		<html>
			<head>
				<title></title>
			</head>
			<body OnLoad="loaded_document=1">
				<center>
					<p>Данные были успешно сохранены</p>
					<p><a href='$edit_link'>[перейти к редактированию]</a></p>
					<p><a href='javascript: window.close()'>[закрыть]</a></p>
				</center>
			</body>
		</html>
	}
}

sub run_event{
	# Запускает событие
		my $event=shift;		
		return unless($event);		
		if(ref($event) eq 'CODE'){
			&$event;
		}
		elsif(ref($event) eq 'ARRAY'){
			foreach my $e (@{$event}){				
				&run_event($e);
			}
		}
		else{
			eval($event);
			
		}
		print $@ if($@);
}

sub get_ev_attr{
	my $ev;
	my $element=shift;
	if($element->{read_only} || $element->{readonly}){
			$field=$element->{value};
	}
	else{
		my $ev='';
		if($element->{onchange}){
			$ev.=qq{ onchange="$element->{onchange}"};
		}
		return $ev
	}
}

sub add_code_to_event{
	my $event=shift;
	my $add_event=shift;
	if(ref($event) ne 'ARRAY'){		
		$event=[$event];
		
	}
	push @{$event},$add_event;	
	return $event;
	
}

#30.09.2013:Isavnin: Добавление функции отправки писем, чтобы работало при событиях в уникалках.
sub send_mes{
  my $opt=shift;
  if($opt->{to}!~/@/){
    print 'Невозможно отправить сообщение на адрес: '.$opt->{to};
    return;
  }
  $opt->{subject} = MIME::Base64::encode($opt->{subject},"");
  $opt->{subject} = "=?windows-1251?B?".$opt->{subject}."?=";
  my $letter = MIME::Lite->new(
    From => $opt->{from},
    To => $opt->{to},
    Subject => $opt->{subject},
    Type=> 'multipart/mixed',
  );# || &print_error("Can't create $!");
#    # attach body
  $letter->attach (
    Type => 'text/html; charset=windows-1251',
    Data => $opt->{message}
  ) or warn "Error adding the text message part: $!\n";
  #Добавление файлов, скорее всего не нужно
  foreach my $f (@{$opt->{files}}){
    $letter->attach(
      Type => 'AUTO',
      Disposition => 'attachment',
      Filename => $f->{filename},
      Path => $f->{full_path},
    );
  }
  $letter->send();# || &print_error("Can't send $!");
}


	return 1;
END { }
