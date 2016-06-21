#!/usr/bin/perl
use Image::Magick;

my($image, $x);

$image = Image::Magick->new;
$image->Set(size => ('50x50'));
$image->ReadImage('xc: black');
$image->Set(
  type        => 'TrueColor',
  antialias   =>  'True',
  fill        =>  'white',
# строку STRING шрифтом $font размером $pointsize
  pointsize   =>  8,
);

$image->Draw(
  primitive   =>  'text',
  points      =>  '20,75', # ориентация строки текста внутри картинки
  text        =>  'test_str', # что печатаем
);

print "Content-type: image/png\n\n";
binmode STDOUT; 

$image->Write('png:-'); 
