#!/usr/bin/perl
use DBI;
# =====================================
# Для конвертирования файлов сущности
# =====================================

my $par;
foreach my $p (@ARGV){
		#print "$p\n";
		if($p=~m/^--(.+?)(=(.+))?$/){
			my ($opt,$val)=($1,$3);
			if($opt eq 'project_id' && $val=~m/^\d+/){
				$par->{project_id}=$val;
			}
			elsif($opt=~m/^struct|config|host|dbname|dbuser$/ && $val){
				$par->{$opt}=$val
			}
			
		}
}
do './connect';

$DBhost=$par->{host} if($par->{host});
$DBname=$par->{dbname} if($par->{dbname});
$DBuser=$par->{dbuser} if($par->{dbuser});
print "DBI:mysql:$DBname:$DBhost,$DBuser,$DBpassword\n";
my $dbh = DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);	
if($par->{project_id} && $par->{struct}){	
	
	#my $dbh = DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);	
	# 1. Проверяем, не типовой ли проект
	my $sth;
	my $table; my $body;
	
	$sth=$dbh->prepare("select t.value from domain d, template_group_site t where d.template_id=t.template_id and d.project_id=? and t.header=?");
	$sth->execute($par->{project_id},'resize_for_'.$par->{struct});

	if(my $value=$sth->fetchrow()){ # Типовой, определяем конфиг и разрешение
		#print "v: $value";
		# value -- параметр ресайза
		$body='';
		open F, 'conf/'.$par->{struct}.'_ct1';
		while(<F>){$body.=$_};
		close F;
		$body=~s/\[%resize_for_$par->{struct}%\]/$value/gs;
		 #exit;
	}
	else
	{
		$sth=$dbh->prepare("select table_name,body from struct where project_id=$par->{project_id} and (table_name='struct_$par->{project_id}_$par->{struct}' or table_name='$par->{struct}')");
		$sth->execute();
		($table,$body)=$sth->fetchrow();
	}
	$body=~s/\[%project_id%\]/$par->{project_id}/gs;
	#print $body;
	eval($body);
	print "wt: ".$form{work_table};
	print $@;
	#exit;
	#use Data::Dumper;
	#print Dumper($form->{work_table});
	#exit;
	foreach my $field (@{$form{fields}}){
		if($field->{type} eq 'file' && $field->{converter}){
			my $add_where='';
			# Конвертим все изображения
			unless($form{work_table}=~m/^struct_/){
				$add_where.=qq{ AND project_id = $par->{project_id}};
			}
			#print "SELECT $field->{name},$form{work_table_id} as id FROM $form{work_table} where $field->{name} <> '' $add_where\n";
			#exit;
			my $sth=$dbh->prepare("SELECT $field->{name},$form{work_table_id} as id FROM $form{work_table} where $field->{name}<>'' $add_where");
			$sth->execute();
			while(my ($filename,$id) = $sth->fetchrow()){
				print "$id\t$filename\n";
				&go_resize({
					converter=>$field->{converter},
					filedir=>$field->{filedir},
					filename=>$filename
				});

			}
		}
		elsif($field->{type} eq '1_to_m'){
			
			foreach my $f (@{$field->{fields}}){
					if($f->{type} eq 'file' && $f->{converter}){
						#print "$field->{name}\n";
						my $sth=$dbh->prepare("SELECT $f->{name},$field->{table_id} FROM $field->{table} where $f->{name}");						
						$sth->execute();
						while(my ($filename,$id) = $sth->fetchrow()){
							#print "$id\t$filename\n";
							&go_resize({
								converter=>$f->{converter},
								filename=>$filename,
								filedir=>$f->{filedir}
							});

						}																		
					}
			}
		}
	}
	
}
elsif($par->{config}){
	print "file: ./conf/$par->{config}\n";
	unless(-e './conf/'.$par->{config}){
		print "\nFile ./conf/$par->{config} not found\n";
		exit;
	}
	my $body='';
	open F, './conf/'.$par->{config};
	while(<F>){
		$body.=$_;
	}
	close F;
	eval($body);
	#print "wt: ".$form{work_table};
	print $@;
	foreach my $field (@{$form{fields}}){
		#print "$field->{name} ($field->{type})\n";
		if($field->{type} eq 'file' && $field->{converter}){
			my $add_where='';
			# Конвертим все изображения
			
			#print "SELECT $field->{name},$form{work_table_id} as id FROM $form{work_table} where $field->{name} <> '' $add_where\n";
			#exit;
			print "SELECT $field->{name},$form{work_table_id} as id FROM $form{work_table} where $field->{name}<>''\n";
			my $sth=$dbh->prepare("SELECT $field->{name},$form{work_table_id} as id FROM $form{work_table} where $field->{name}<>''");
			$sth->execute();
			print "Найдено записей: ".$sth->rows()."\n";
			while(my ($filename,$id) = $sth->fetchrow()){
				print "$id\t$filename\n";
				&go_resize({
					converter=>$field->{converter},
					filedir=>$field->{filedir},
					filename=>$filename
				});

			}
		}
		elsif($field->{type} eq '1_to_m'){
			
			foreach my $f (@{$field->{fields}}){
					if($f->{type} eq 'file' && $f->{converter}){
						#print "$field->{name}\n";
						my $sth=$dbh->prepare("SELECT $f->{name},$field->{table_id} FROM $field->{table} where $f->{name}");						
						$sth->execute();
						while(my ($filename,$id) = $sth->fetchrow()){
							#print "$id\t$filename\n";
							&go_resize({
								converter=>$f->{converter},
								filename=>$filename,
								filedir=>$f->{filedir}
							});

						}																		
					}
			}
		}
	}

}
else{
	print 
qq{Вызов скрипта: ./go_resize --project_id=[проект] --struct=[структура]
	Или
./go_resize --config=[имя_файла-конфига]
}
}
sub go_resize{
	my $opt=shift;
	#my $converter=$opt->{converter};
#	print "$opt->{converter} \r\n";
	my $filename=$opt->{filename};
	my $filedir=$opt->{filedir};
	if($filename=~m/^(.+)\.(.+)$/){
					my $full_filename=qq{$filedir/$filename};
					my $input=$1;
					my $input_ext=$2;
					#print "$input ; $input_ext\n";
					my $converter=$opt->{converter};
					$converter=~s/\[%input%\]/$filedir\/$input/gs;
					$converter=~s/\[%input_ext%\]/$input_ext/gs;
					$converter=~s/\[%filename%\]/$full_filename/gs;
					$converter=~s/\n/ /gs;
					$converter=~s/\s+/ /gs;
					$converter=~s/\s+$//gs;
					$converter=~s/\s+/ /gs;
					print "$converter \r\n";
#					system($converter) || die($!);
					print `$converter`;
	}	
}
