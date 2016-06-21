#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use Template;

my $q = new CGI;

print $q->header(-type=>'text/html',-encoding=>'cp1251');
my $fh = $q->upload('image');
my $act = $q->param('action');
my $tt = Template->new({INCLUDE_PATH=>'./tmpl'});

my $vars = {
	version=>'1.0.0',
	preview => [{width=>'100px',height=>'100px'},{width=>'300px',height=>'300px'}],
};

unless($act){
	$tt->process('test.tmpl',$vars);	
}
else{
	$tt->process('test_'.$act.'.tmpl',$vars);
}
