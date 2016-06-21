#!/usr/bin/perl

use CGI::Carp qw (fatalsToBrowser);
use CGI qw(:standard);
use DBI;
use Data::Dumper;
print "Content-type: text/html; charset=cp1251\n\n";
use lib 'lib';
use read_conf;
use struct_admin;
our $form=&read_config;
our $id=$form->{id};
our $dbh=$form->{dbh};

unless($form->{id}=~m/^\d+$/){
	print "Не указан идентификатор!";
	exit;
}

unless($form->{make_delete}){
	print "Вам запрещено удалять записи из таблицы!";
	exit;
}

#&run_code_conf($dbh,"./conf/$config".'_before_delete');
&run_event($form->{events}->{before_delete});
if($form->{errors}){ # если какие-то ошибки -- не удаляем
	print "$form->{errors}";
	exit;
}
else{
	
	# Удаляем файлы, привязанные к этой записи (если таковые существуют):
	my $query="SELECT * FROM $form->{work_table} wt WHERE $form->{work_table_id}=?";
	$query.=qq{ AND $form->{add_where}} if($form->{add_where});
	my $sth=$dbh->prepare($query);
	$sth->execute($form->{id});
	unless($sth->rows()){
		print "Нет такой записи!";
		exit;
	}
	my $values=$sth->fetchrow_hashref();
	foreach my $element (@{$form->{fields}}){
			if($element->{type} eq 'file'){
				my $filename=$values->{$element->{name}};
				$filename=~s|^(.+);.+$|$1| if($element->{keep_orig_filename});
				#print "unlink $element->{filedir}/$filename<br/>";
				unlink("$element->{filedir}/$filename") if($filename);
			}
			$sth->finish();
	};

	$dbh->do("DELETE FROM $form->{work_table}  WHERE $form->{work_table_id}=$form->{id}");
	&run_event($form->{events}->{after_delete});
}



print qq{
<html>
	<head>
		<title></title>
	</head>
	<body>
		<center>
			<p>Запись успешно удалена</p>			
			<script>				
				opener.delrow($id);
				setTimeout(function(){
            window.close();
        }, 500);
			</script>
			<p><a href='javascript: window.close()'>[закрыть]</a></p>
		</center>
	</body>
</html>
};

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

