#!/usr/bin/perl
#ждем параметры --project_id --src
use Image::Magick;
use Data::Dumper;

my $project_id;
my $src_name;
my $offset;
my $position='Center';
my $wm_width_new;
my $wm_height_new;
my $wm_name;
do './connect';
if(!$CMSpath){do '/www/sv-cms/htdocs/manager/connect';}
#`pwd > /home/isavnin/watermark.tmp`;
#	do 'echo `pwd` > /home/isavnin/watermark.tmp';
#use vars q{$CMSpath};
my $project_files_path = "$CMSpath/files"; #'/www/sv-cms/htdocs/files';
#my $project_files_path = '/www/sv-cms/htdocs/files';

#print "Content-type: text/html\n\n";


    foreach ( @ARGV ) {
        
        $_=~s/^'|'$//g;
        
        if ( $_ =~ /^--project_id=(\d+)$/  ) {
            $project_id = $1;
        }

	if( $_ =~ /^--wmresize=(\d+)x(\d+)$/){
		$wm_width_new = $1;
		$wm_height_new = $2;
	}
    
        if ( $_ =~ /^--src=((.*).{3})$/  ) {
            $src_name = $1;
        }
	if ( $_ =~ /^--offset=(\d+)$/  ) {
            $offset = $1;
        }
	if ( $_ =~ /^--position=(\w+)$/ ){
	    $position = $1;
	}
	if( $_ =~ /^--x=(\d+)$/ ){$x = $1;}
	if( $_ =~ /^--y=(\d+)$/ ){$y = $1;}
    }
    
    if ( $project_id && $src_name ) {
        
        $wm_file = qq{$project_files_path/project_$project_id/const_watermark.png};
           # if ( -e $wm_file ) {
           #     print "== watermark file found.\n";
           # }
           # else { die "!! watermark file not found in $wm_file exit.\n"; }
        
        #print $project_id, $src_name;
        my $image;
            $image = Image::Magick->new;
            my $src = $image->Read($src_name);

	print $src."\n";
	print $src_name;

            my ($src_width, $src_height) = $image->Get('base-columns', 'base-rows');
          
            
        my $watermark;
            $watermark = Image::Magick->new;
            my $wm = $watermark->Read($wm_file);
            my ($wm_width, $wm_height) = $watermark->Get('base-columns', 'base-rows');
            
            if (!$wm_width || !$wm_height) {
                die "!! watermerk file error [$wm_file] exit.\n";
            }
            else {
                print "== watermark size [$wm_width]x[$wm_height]\n";
            }

	    if($wm_width_new || $wm_height_new){
                    print "== Resize watermark to [$wm_width_new]x[$wm_height_new]\n";
		    my $wmwn = 0;
		    my $wmhn = 0;
		    if($wm_width_new > 0){
			$wmwn = $wm_width_new;
		    }else{
			$wmwn = $wm_width;
		    }
		
		    if($wm_height_new > 0){$wmhn=$wm_height_new;}else{$wmhn=$wm_height;}

                    #берем ширину #src и делаем на 10 пикселей меньше
                    $watermark->Resize(width=>$wmwn, height=>$wmhn );

	    }
            
            if ( $src_width>0 && $src_height>0 ) {
            
            print "== processing [$src_name] file\n";
            
                #если src больше чем марк
                if ( $src_width>$wm_width ) {
                    print "== src size [$src_width]x[$src_height]\n";
                    print "== case 1 [$src_width]>[$wm_width]\n";

		    #Метод композинга не трогайте нахуй!                     
                    $image->Composite( image => $watermark,
                                           compose => 'Over',
                                           gravity => $position ? $position : 'Center',
					   x => $x ? $x : undef,
					   y => $y ? $y : undef,
                    );

                   my $x = $image->Write($src_name);
		   print $x;
                    
                }
                else {
                    #надо ресайзить $wm
                    print "== src size [$src_width]x[$src_height]\n";
                    print "== case 2 [$src_width]<[$wm_width]\n";

		    my $width;
		    if ( $offset>0 ) { $width=$src_width-$offset; }
		    else { $width=$src_width-10; }
                        my $nh;
                        
                           if ( ($wm_width>$width)&&($wm_width/$width>1) ) {
                            my $prop=$wm_width/$width;
                            $nh=int($wm_height/$prop);
                            }

                           else {
                            $nh=$wm_height; $width=$src_width;
                           }
      
                    print "== Resize watermark to [$width]x[$nh]\n";
                    
                    #берем ширину #src и делаем на 10 пикселей меньше
                    $watermark->Resize(width=>$width, height=>$nh );
                    
                    #Метод композинга не трогайте нахуй! 
                    $image->Composite( image => $watermark,
                                           compose => 'Over',
                                           gravity => $position,
                    );

                    my $x = $image->Write($src_name);
		    print $x;
                    
		    
		    
                }
            }
            else {
                die "!! src file error [$src_name] exit.\n";
            }
            
            
        
        
    }
    else {
        print "\n==========================================\n==Awiting params --project_id=xx and --src='xxx.xxx' for image srv file. \n";
    }
        
