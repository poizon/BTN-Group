#!/usr/bin/perl
use CGI::Carp qw/fatalsToBrowser/;
use CGI::Fast qw(:standard);
#use strict;
#use DBI;

while ( new CGI::Fast ) {
  print "asd";
}

#if((param('tp') && param('js')) || param('main')){
#  my $d='';
#  @js=split(';',param('js'));
#  foreach my $f(@js){
#    open F,'/www/sv-cms/htdocs/templates/'.param('tp').'/'.$f.'.js';
#    $d.=$_ while <F>;
#    close F;
#    print $f;
#  }
#  if(param('main')){
#    @mainjs=split(';',param('main'));
#    foreach my $f(@mainjs){
#      open F,'/www/sv-cms/htdocs/js/'.$f.'.js';
#      $d.=$_ while <F>;
#      close F;
#    }
#  }
#  print $d;
#}

