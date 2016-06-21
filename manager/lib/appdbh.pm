package appdbh;
use vars qw($DBname $DBuser $DBpassword $DBhost);
use strict;
use warnings;

use DBI;
use CGI;

my $HOME = $ENV{DOCUMENT_ROOT} ? $ENV{DOCUMENT_ROOT} : '/www/sv-cms/htdocs';
do $HOME.'/manager/connect';

sub new {
	my $self = shift;
	my $user = $DBuser ? $DBuser : 'svcms';
	my $name = $DBname ? $DBname : 'svcms';
	my $host = $DBhost ? $DBhost : '192.168.8.81';
	my $pass = $DBpassword ? $DBpassword : '';
	my $dsn = 'dbi:mysql:'.$name.':'.$host;
	return DBI->connect($dsn,$user,$pass,{RaiseError=>1}) || die($!);
#	return DBI->connect('dbi:mysql:svcms:192.168.8.81','svcms','',{RaiseError=>1}) || die($!);
}

1;
