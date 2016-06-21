#!/usr/bin/perl
use DBI;
use CGI::Fast qw(:standard);
#use Carp;
use CGI::Cookie;
use CGI::Carp qw/fatalsToBrowser/;
use strict;
print "Content-type: text/html\n\n";

do './admin/connect';
use vars qw($DBname $DBhost $DBuser $DBpassword);
my $dbh=DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
while (new CGI::Fast) {
	my $domain=$ENV{SERVER_NAME};
	$domain=~s/^www\.//;

	my $sth=$dbh->prepare("SELECT project_id from domain WHERE domain=?");
	$sth->execute($domain);
	my $project_id=$sth->fetchrow();
	unless($project_id){
		print "project_id not found";
		exit;
	}
	my $key=substr($ENV{PATH_INFO},1);

	$sth=$dbh->prepare("SELECT link,attach FROM banner where project_id=? and ban_code=?");
	$sth->execute($project_id,$key);
	my ($link,$file)=$sth->fetchrow();
	
	# здесь потом воткнём подсчёт статистики

	# для картинок
	print qq{
		<div id='id_ban'><a href="$link"><img src="/files/project_$project_id/banners/$file" /></a></div>
	};
}
