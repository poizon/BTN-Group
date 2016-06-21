#!/usr/bin/perl
#Khabusev Phanis [pmk@trade.su]
# Быстрое сохраниние фотографий в товарах
use DBI;
use Template;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
#use strict;
our $params;
do './connect';

my $dbh = DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
print "Content-type: text/html; charset=windows-1251\n\n";


our $template = Template->new({
           INCLUDE_PATH => './templates'
});
&go;


undef($params);


sub go{
	# узнаём, из какой структуры тянем рубрикатор
	my $sth=$dbh->prepare("SELECT project_id from manager where login = ?");
	$sth->execute($ENV{REMOTE_USER});
	our $project_id=$sth->fetchrow();

	$sth=$dbh->prepare("SELECT options from project_group_site where project_id=?");
	$sth->execute($project_id);
	my $rubricator_table; my $rubricator_table_id;
	my $good_table; my $good_table_id;
	if(my $options=$sth->fetchrow()){ # типовой!
		$rubricator_table='rubricator';
		$rubricator_table_id='rubricator_id';
		$good_table='good';
		$good_table_id='good_id';
	}
	elsif(0){ # таблица рубрикатора для нетиповых
		exit;
		# 2. ветки рубрикатора
		$sth=$dbh->prepare("SELECT work_table from struct where project_id=? AND table_name='rubricator' OR table_name ");
		$sth->execute($project_id);
	}
	
	# получаем дерево рубрик
	$params->{rublist}=&get_rub_list({
		table=>$rubricator_table,
		table_id=>$rubricator_table_id
	});
	print Dumper(params->{rublist});
	$template -> process('fast_load_photo.tmpl', $params) || die($!);
}



sub get_rub_list{
	my $opt=shift;
	$opt->{path}='' unless($opt->{path});
	print "SELECT $opt->{table_id},header FROM $opt->{table} where project_id=$project_id and path='$opt->{path}' order by sort<br>";
	my $sth=$dbh->prepare("SELECT $opt->{table_id},header FROM $opt->{table} where project_id=? and path=? order by sort");
	$sth->execute($project_id,$opt->{path});
	my $list = $sth->fetchall_arrayref({});
	my $path=$opt->{path};
	foreach my $r (@{$list}){
		$opt->{path}=qq{$path/$r->{$opt->{table_id}}};
		$r->{child}=get_rub_list($opt);
	}
	return $list;
}
