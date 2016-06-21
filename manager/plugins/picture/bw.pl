#!/usr/bin/perl
#Плагин для создания ЧБ копии

use Image::Magick; #используем модуль
use Data::Dumper;

my $project_id;
my $src_name;
my $output;
do '../../connect';
my $project_file_path = $CMSpath; #'/www/sv-cms/htdocs';

foreach( @ARGV ) {
  $_=~s/^'|'$//g;
  
  if ( $_ =~ /^--project_id=(\d+)$/ ){
    $project_id=$1;
  }
 
  if ( $_ =~ /^--src=((.*).{3})$/ ){
    $src_name=$1;
  }
 
  print "Проверка аргументов";
 
}

if ( $project_id && $src_name ){
  print "Начало трансформации\n";
  #Создаем переменые
  my($img,$bw_img);
  $img=Image::Magick->new;

  #Задаем исходное изображение

  print $src_name."\n";
  my $src=$image->Read($project_files_path.$src_name);
  print $src;
  $img->Quantize(colorspace=>'gray');
  my($f,$e)=split('\.',$src_name);
  $src = $img->Write('../BW_'.$f.$e);
  print "Завершение трансофмации";
}

#my($image, $x); #переменные
#$image = Image::Magick->new; #новый проект
#$x = $image->Read("photo.jpg"); #открываем файл
#$image->Quantize(colorspace=>'gray');
#$x = $image->Write("photo.jpg"); #Сохраняем изображение.
