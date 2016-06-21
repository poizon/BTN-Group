#!/usr/bin/perl
# Isavnin
# ћодуль проверки правильности авторизации
package auth;
use CGI;
use Data::Dumper;
use strict;
use warnings;

use lib 'lib';
use appdbh;

sub new {
	my $self = shift;
	my $user = $ENV{REMOTE_USER};# || 'intel';
	my $host = $ENV{HTTP_HOST};# || 'intel.designb2b.ru';
	$host =~ s/^www\.//;
	my $dbh = appdbh->new();
	my $ans = $dbh->selectrow_hashref("
		SELECT IF(count(m.login) > 0,'True','False') as ans 
		FROM manager m INNER JOIN domain d ON d.project_id = m.project_id WHERE m.login = ? AND d.domain like ?",
		undef,($user,'%'.$host)) or die($!);
#	print Dumper($ans);
	return $ans->{ans};
}

1;


