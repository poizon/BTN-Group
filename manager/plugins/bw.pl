#!/usr/bin/perl
#Плагин для создания ЧБ копии

use Image::Magick; #используем модуль
use Data::Dumper;

my $project_id;
my $src_name;
my $output;
do '../connect';
my $project_file_path = $CMSpath; #'/www/sv-cms/htdocs';

foreach( @ARGV ) {
  $_=~s/^'|'$//g;
  
  if ( $_ =~ /^--project_id=(\d+)$/ ){
    $project_id=$1;
  }
 
  if ( $_ =~ /^--src=((.*).{3})$/ ){
    $src_name=$1;
  }

  if ( $_ =~ /^--output=((.*).{3})$/ ){
    $output=$1;
  }
 
}

if ( $project_id && $src_name && $output){
  my $img;
  $img=Image::Magick->new;
  my $src=$img->Read($src_name);
  $img->Quantize(colorspace=>'gray');
  $src = $img->Write($output);
}
