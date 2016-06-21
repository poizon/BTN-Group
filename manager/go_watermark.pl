#!/usr/bin/perl
#ждем параметры --project_id --src
use Image::Magick;
use Data::Dumper;

my $dir;
#my $src_name;
my $wm_name;
#my $project_files_path = '/www/sv-cms/htdocs/files';
#my $project_files_path = './files';

print "Content-type: text/html\n\n";


    foreach ( @ARGV ) {
        
        $_=~s/^'|'$//g;
        
        if ( $_ =~ /^--dir=(.*)$/  ) {
            $dir = $1;
        }
    
        if ( $_ =~ /^--watermark=((.*).{3})$/  ) {
            $wm_file = $1;
        }
	
	
        if ( $_ =~ /^--all$/  ) {
            $all = 1;
        }
	
    }
    
    if ( $dir && $wm_file ) {
        
	
	 opendir(DR, "$dir") or die "can't opendir $dir";
#            if($all){
#              my @filelist = grep {$_ =~ /^(.*).(jpg|png)$/i } readdir(DR);
#            }
#            else{
  	      my @filelist = grep {$_ =~ /^(.*).(jpg|png)$/i && $_ !~ /^\./ && $_ !~ /mini\d/i } readdir(DR);
#            }
         closedir DR;
	
	if ( scalar(@filelist)>0 ) {
	    
	      if ( -f $wm_file ) { print "== watermark file found.\n"; }
            else { die "!! watermark file not found in $wm_file exit.\n"; }
	    
	    foreach ( @filelist ) {
		$_ =~ s/\n//;
		#wmIt({ src_name=>"$dir/$_", wm_files=>$wm_file, });
		print $_."\n\n";
		
		#/*************************************************
		
		my $src_name = qq{$dir/$_};
	
    
    print Dumper($wm_file);
#    print Dumper(@filelist);
    
    my $image;
        $image = Image::Magick->new;
        my $src = $image->Read("$src_name");# || die "Cant access file $src_name, exit.\n";

	warn $src if $src;

        #print $src;

        my ($src_width, $src_height) = $image->Get('base-columns', 'base-rows');
	
	print "111";
	
        my $watermark;
            $watermark = Image::Magick->new;
            my $wm = $watermark->Read($wm_file);# || die;
            my ($wm_width, $wm_height) = $watermark->Get('base-columns', 'base-rows');
            
            if (!$wm_width || !$wm_height) {
                die "!! watermerk file error [$wm_file] exit.\n";
            }
            else {
                print "== watermark size [$wm_width]x[$wm_height]\n";
            }
            
            if ( $src_width>0 && $src_height>0 ) {
            
            print "== processing [$src_name] file\n";
            
                #если src больше чем марк
                if ( $src_width>$wm_width ) {
                    print "== src size [$src_width]x[$src_height]\n";
                    print "== case 1 [$src_width]>[$wm_width]\n";
                    
                    $image->Composite( image => $watermark,
                                           compose => 'Plus',
                                           gravity => 'Center'
                    );

                   my $x = $image->Write($src_name);
		   print $x;
                    
                }
                else {
                    #надо ресайзить $wm
                    print "== src size [$src_width]x[$src_height]\n";
                    print "== case 2 [$src_width]<[$wm_width]\n";

                        my $width=$src_width-10;
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
                    
                                       
                    $image->Composite( image => $watermark,
                                           compose => 'Plus',
                                           gravity => 'Center'
                    );

                    my $x = $image->Write($src_name);
		    print $x;
                    
		    
		    
                }
            }
            else {
                die "!! src file error [$src_name] exit.\n";
            }
	    
	    #/****************************************************
		
		
		
	    }
	}
	else {
	    die "No files found in $dir\n";
	    exit;
	}

    

    
    }
    else {
        print qq{==========================================
==Watermark fiels of directory == 
    --dir=/../..
    --watermark='xxxxxxx.xxx'
    --all -if defined all jpg|png files in path will be processed with script, or just jpg|png without 'mini' in a file name.

    };
    }
     
exit;   

    
    
