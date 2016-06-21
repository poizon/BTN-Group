#!/usr/bin/perl

use CGI::Carp qw (fatalsToBrowser);
use CGI qw(:standard);
use DBI;
use lib 'lib';
use read_conf;
use struct_admin_find;
use struct_admin;
print "Content-type: text/html; charset=cp1251\n\n";

my $config=param('config');
our $form=&read_config($config);

if ( $config =~ /\d+/ ) {
    
#   do '/www/sv-cms/htdocs/manager/connect';
   do './connect';
   use vars qw($DBname $DBhost $DBuser $DBpassword);
   my $dbh=DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);    
   
   my $p = $dbh->selectrow_hashref("SELECT * FROM struct WHERE struct_id=$config and enabled=1"); 
   
   if ( $p->{project_id} == 3306 ) { 
   print "<a href='/manager/options.pl?struct_id=$config&project_id=$p->{project_id}'>OPTIONS</a>\n";
   }
}

=cut
if(-f "connect_$config"){
    do "connect_$config";
}
else{
    do './connect';
}



#do './connect';

our $dbh = DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);

unless(-f "./conf/$config"){
	print "ошибка чтения конфигурационного файла";
	exit;
}
do "./conf/$config";

#my $work_table=$form{work_table};
$form{config}=$config;
=cut



#if($MANAGER_LOGIN eq 'admin1'){$MODERATOR=1};
#$action=param('action');


&get_filter_list($form);
&out_filters_list($form);








