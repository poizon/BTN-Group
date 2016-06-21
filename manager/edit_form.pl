#!/usr/bin/perl
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use DBI;

use struct_admin;
use lib 'lib';
use read_conf;
use Data::Dumper;
@EXPORT = ($form);
our $form=&read_config;
my $id=$form->{id};

if($form->{action} eq 'file_download' && $form->{id}=~m/^\d+$/){
	my $name=param('name');
	foreach my $field (@{$form->{fields}}){
		if($field->{name} eq $name){
			my $sth=$form->{dbh}->prepare("SELECT $name from $form->{work_table} where $form->{work_table_id}=?");
			$sth->execute($id);
			my $res=$sth->fetchrow();
			if($res=~m/^(.+);([^;]+)$/){
				use Encode;
				my ($filename,$orig_name)=($1,$2);
				
	
			#	$filename =~ tr/A-Z/a-z/;
			#	$orig_name =~ tr/A-Z/a-z/;
				
				$orig_name=~s/ /\_/g;
				Encode::from_to($orig_name, 'cp1251', 'utf8');
				print qq{Content-Disposition: attachment; charset=utf8; filename=$orig_name\n};
				print qq{Content-Type: application/x-force-download; name=$orig_name\n\n};
				open F, qq{$field->{filedir}/$filename} || die($!);
				binmode F;
				print $_ while(<F>);
				close F;
			}
			else{
				print "Content-type: text/html; charset=windows-1251\n\n";
				print "file not found";
			}
			exit;
		}

	}
}

print "Content-type: text/html; charset=windows-1251\n\n";

if($form->{action} eq 'del_file' && $form->{id}=~m/^\d+$/){
	del_file($form);
	$form->{action}='edit';
}

if($form->{action} eq 'new'){ # Вывод формы
	$form->{action}='insert';
	out_form($form);
	exit;
}
elsif($form->{action} eq 'insert'){ # проверка и
	$form->{action}='insert';		
	#&run_event($form->{events}->{before_insert});
	
	$form->{id}=0;
	
	#if($form->{id}=
	insert_data_in_form($form);
	#){	
	#	&run_event($form->{events}->{after_insert});
	#}
	
}
elsif($form->{action} eq 'edit' && $form->{id}=~m/^\d+$/){
	# Читаем состояние формы из БД
	&read_data($form);

	# переключаем форму в состояние update
	$form->{action}='update';

	# Выводим форму
	out_form($form);
}
elsif($form->{action} eq 'update' && $form->{id}=~m/^\d+$/){
	
	# перенёс
	#run_event($form->{events}->{before_update});
	#print $@ if($@);
	if(&update($form)){		
		run_event($form->{events}->{after_update});
	}

	# Читаем состояние формы из БД
	&read_data($form) unless($form->{errors});

	# переключаем форму в состояние update
	$form{action}='update';
	# Выводим форму
	out_form($form);
}
elsif($form->{action} eq 'load_megaselect'){
	my $name=param('name');
	my $position=param('position');
	my $despendence_value=param('despendence_value');
	my $cur_value=param('cur_value');
	$name=~s/\//;/g	;

	load_megaselect($form, $form->{dbh}, $name, $position, $despendence_value, $cur_value);
}
elsif($form->{action} eq 'load_megaselect_filter'){
	&load_megaselect_filter($form);
}


sub load_megaselect{
	# загружает любой фрагмент мегаселекта
	my $form=shift;
	my $dbh=shift;
	my $cur_name=shift;
	my $position=shift;
	my $despendence_value=shift;
	my $cur_value=shift;

	foreach my $element (@{$form->{fields}}){
		if(($element->{name} eq $cur_name) && $element->{type} eq 'megaselect'){

			my @descriptions=(split /;/, $element->{description});
			my @names=(split /;/, $element->{name});
			my @tables=(split /;/, $element->{table});
			my @headers=(split /;/, $element->{table_headers});
			my @indexes=(split /;/, $element->{table_indexes});
			my @despendences=(split /;/, $element->{despendence});;
			$despendences[$position]=~s/\?/$despendence_value/;
			my $nameparam=$element->{name};
			$nameparam=~s/;/\//g;
			my $next_position=$position+1;
			if($next_position<=$#descriptions){

		    my $onchange=qq{loadDoc('\./edit_form.pl?config=$form->{config}&action=load_megaselect&position=$next_position&name=$nameparam&despendence_value='+this.value,'megaselect_$names[$next_position]')};
		    if($next_position>1){
		    		#print "!!!";
						my $i=$next_position+1;
						while($i<=$#names){
							my $prev=$i-1;
							$onchange.=qq{\ndocument.getElementById('megaselect_$names[$i]').innerHTML='для выбора поля &quot;$descriptions[$i]&quot; выберите значение в поле &quot;$descriptions[$prev]&quot;'\n};
							$i++;
						}
		    }

				# При выборе значения подгружаем очередной SELECT
				print "<select name='$names[$position]' OnChange=\"$onchange\"><option value='0'>Выберите значение поля $descriptions[$position]</option>";
			}
			else{
				# Для последнего Select'а ничего подгружать не нужно:
				print "<select name='$names[$position]'><option value='0'>Выберите значение поля $descriptions[$position]</option>";
			}


			my $sth=$dbh->prepare("SELECT $headers[$position],$indexes[$position] FROM $tables[$position] WHERE $despendences[$position] order by $headers[$position]");
			$sth->execute();
			while(my ($h,$i)=$sth->fetchrow()){
								my $selected='';
								if($cur_value==$i){
									$selected=' selected';
								}
								print "<option value='$i' $selected>$h</option>";
			}

			print '</select>';
			last;
		}
	}
}

sub load_megaselect_filter{
	my $form=shift;
	#my $config=param('config');
	my $level=param('level');
	my $parent_value=param('parent_value');
	my $ms=param('ms');
	my $position=$level;
	$ms=~s/\//;/g	;
	foreach my $element (@{$form->{fields}}){
		
		if($element->{name} eq $ms){
			
			my @descriptions=(split /;/, $element->{description});
			my @names=(split /;/, $element->{name});
			my @tables=(split /;/, $element->{table});
			my @headers=(split /;/, $element->{table_headers});
			my @indexes=(split /;/, $element->{table_indexes});
			my @despendences=(split /;/, $element->{despendence});;


			my $nameparam=$element->{name};
			$nameparam=~s/;/\//g;
			my $next_position=$position+1;
			print "<b>$descriptions[$level]:</b> ";
			if($next_position<=$#descriptions){
				
		    my $onchange="add_megaselect_filter('$ms', '$names[$next_position]', $next_position, this.value, '$form->{config}')";
				for(my $i=$next_position+1; $i<=$#names; $i++){
					$onchange.=qq{\nclear_megaselect('filter_$ms', 'ms_$names[$i]')}
				}

				# При выборе значения подгружаем очередной SELECT
				print "<select name='$names[$position]' OnChange=\"$onchange\"><option value='0'>Выберите значение поля $descriptions[$position]</option>";
			}
			else{
				
				# Для последнего Select'а ничего подгружать не нужно:
				print "<select name='$names[$position]'><option value='0'>Выберите значение поля $descriptions[$position]</option>";
			}			
			$despendences[$level]=~s/\?/$parent_value/;
			my $query=qq{SELECT $headers[$level], $indexes[$level] FROM $tables[$level] WHERE $despendences[$level]};
			#print "q: $query";
			my $sth=$form->{dbh}->prepare($query);
			$sth->execute();
			while(my ($h,$i)=$sth->fetchrow()){
								my $selected='';
								if($cur_value==$i){
									$selected=' selected';
								}
								print "<option value='$i' $selected>$h</option>";
			}

			print '</select>';
			last;
		}
	}


}

sub run_code_conf{
	my $dbh=shift;
	my $file=shift;
	if(-f $file){
		my $code='';
		open F, $file;
		while(<F>){
			$code.=$_;
		}
		close F;
		eval($code) if($code);
	}
}

#sub run_code{
#	my ($dbh,$code,$event_name)=@_;
#	if($code){
#		eval($code) if($code);
#		if ($@){print "Ошибка при выполнении $event_name<br/>died: $@<br/>"; exit;}
#	}
#}

