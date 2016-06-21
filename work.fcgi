#!/usr/bin/perl
use Template;
use DBI;
use CGI::Fast qw(:standard);

#use FCGI::ProcManager;
#use FCGI::ProcManager qw(pm_manage pm_pre_dispatch pm_post_dispatch);
#use FCGI::ProcManager qw(pm_manage pm_die pm_exit pm_pre_dispatch pm_post_dispatch);

#my $proc_manager = FCGI::ProcManager->new({ n_processes => 50, pm_title=> 'processmanager: work.fcgi ' });
#pm_manage( n_processes => 5 );
use CGI::Cookie;
use CGI::Carp qw/fatalsToBrowser/;
use Data::Dumper;
use MIME::Lite;
use MIME::Base64;
use lib 'lib';
use basket_par; # работа с корзиной
use FCGI::ProcManager;
#use FCGI::ProcManager qw(pm_manage pm_die pm_exit);
use FCGI::ProcManager qw(pm_manage pm_die pm_exit pm_pre_dispatch pm_post_dispatch);

#use db;
#use capture; # капча
# - sanman --
use Encode;
#------------
#use strict;
  require 'lib/db.pm';
  our $system=&get_system;
  #$system->{debug}=1;
  #$system->{fast_cgi_maxcount}=5;
#$system->{logname}='log_fcgi';
my $count=0;
our $CACHE; # ссылка на кеш
my $proc_manager = FCGI::ProcManager->new({ n_processes => 1, pm_title=> 'processmanager: svcms' });
while (new CGI::Fast) {
	#&to_error_log("OPEN $ENV{SERVER_NAME}$ENV{REQUEST_URI} ($count)");
	#print "Content-type: text/html\n\n";
	#pre($params);
	#print "fcgi ($count)";
	&fcgi_loop;
	#print "<br> status: $status";
	#&to_error_log("CLOSE $ENV{SERVER_NAME}$ENV{REQUEST_URI} ($count)\n");
	$count++;
	#if($count>$system->{fast_cgi_maxcount}){
		#&to_error_log("RELOAD\n");
	#	$proc_manager->pm_exit("code reload.");
	#	exit;
	#}
	undef $params;	
}
