#!/usr/bin/perl
use strict;
use warnings;
use CGI qw(:standard);
use CGI::Carp qw(fatasToBrowser);
use Template;
use Spreadsheet::ParseExcel;
use Encode;
use punylib;
use lib '/www/sv-cms/htdocs/lib';
use appdbh;
use Data::Dumper;

our $fld = [
  {name=>'domain_f',description=>'Откуда',regexp=>'[a-z0-9\-\.\_\?\=\/\:]+$'},
  {name=>'domain_t',description=>'Куда',regexp=>'[a-z0-9\-\.\_\?\=\/\:]+$'},
];

our $pid;

init();

sub show {
  eval(q{
    my $template = Template->new({
      INCLUDE_PATH => "./", COMPILE_EXT => '.TT2',
      COMPILE_DIR => '../temp/', CACHE_SIZE => 512,
      PRE_CHOMP => 1, POST_CHOMP => 1,
      DEBUG_ALL => 1,
    });
    $template->process('redirect_parser.tmpl', $tmpl_vars) || croak "tmpl_err: ".$template->error();
  });
 if ( $@ ){ print $@; }
}

sub upload {
  my $orig = param('file');
  if ( $orig =~ m/([^.]+)$/) {
    my $ext = $1;
    my $name;
    map { $name .= join '', (0..9,'A'..'Z','a'..'z')[rand 64]; } (1..32);
    $name .= '.'.$ext;
    open F,qq{>/www/sv-cms/htdocs/temp/$name};
    binmode F;
    print F while ( <$orig> );
    close F;  
  }
  return {full_path => qq{/www/sv-cms/htdocs/temp/$name}, filename => $orig};
}

sub err {
  my ($num,$msg) = @_;
  print header(-type=>'text/html',-status=>($num||500));
  print "<p>$msg</p>";
  exit;
}

sub init {
  $pid = param('project_id');
  $tv->{project_id} = $pid;
  err(500,'PROJECT_ID NOT FOUND!') if ( $pid !~ /^(\d+)$/ );

  if ( !param || param('act') eq 'show' ){
    show();
  }
  elsif ( param('act') eq 'import' ){
    import();
  }
  elsif ( param('act') eq 'upload' ){
    my $f = upload();
    preview($f->{full_path});
  }
}

sub preview {
  my ( $in ) = @_;
  my $parser = Spreadsheet::ParserExcel->new();
  
}

sub import {}
