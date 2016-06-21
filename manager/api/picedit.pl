#!/usr/bin/perl 
use strict;
use Template;
use CGI qw(:standard);

use lib './lib';
use Picedit;

my $action = param('action');

my $tmpl = Template->new({INCLUDE_PATH=>'./templates/'});

unless($action){
	
}
else{

}

show_html();

sub show_html {
	$tmpl->process('picedit.tmpl');
}
