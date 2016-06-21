#!perl
#ждем параметры --project_id --src
use Image::Magick;
use Data::Dumper;

my $project_id;
my $src_name;
my $wm_name;
do './connect';
#my $project_files_path = '/www/sv-cms/htdocs/files';
my $project_files_path = "$CMSpath/files";


    open(FH, '>./watermark.log');

    foreach ( @ARGV ) {
        
        $_=~s/^'|'$//g;
        
        if ( $_ =~ /^--project_id=(\d+)$/  ) {
            $project_id = $1;
        }
    
        if ( $_ =~ /^--src=((.*).{3})$/  ) {
            $src_name = $1;
        }
    }
    
    if ( $project_id && $src_name ) {
        
        $wm_file = qq{$project_files_path/project_$project_id/watermark.png};
            if ( -e $wm_file ) {
                print FH, "== watermark file found.\n";
            }
            else { die "!! watermark file not found in $wm_file exit.\n"; }
        
        #print $project_id, $src_name;
        my $image;
            $image = Image::Magick->new;
            my $src = $image->Read($src_name);
            my ($src_width, $src_height) = $image->Get('base-columns', 'base-rows');
          
            
        my $watermark;
            $watermark = Image::Magick->new;
            my $wm = $watermark->Read($wm_file);
            my ($wm_width, $wm_height) = $watermark->Get('base-columns', 'base-rows');
            
            if (!$wm_width || !$wm_height) {
                die "!! watermerk file error [$wm_file] exit.\n";
            }
            else {
                print FH, "== watermark size [$wm_width]x[$wm_height]\n";
            }
            
            if ( $src_width>0 && $src_height>0 ) {
            
            print FH, "== processing [$src_name] file\n";
            
                #если src больше чем марк
                if ( $src_width>$wm_width ) {
                    print FH, "== src size [$src_width]x[$src_height]\n";
                    print FH, "== case 1 [$src_width]>[$wm_width]\n";
                    
                    $image->Composite( image => $watermark,
                                           compose => 'Plus',
                                           gravity => 'Center'
                    );

                    $image->Write("$project_files_path/project_$project_id/composition.jpg");
                    
                }
                else {
                    #надо ресайзить $wm
                    print FH, "== src size [$src_width]x[$src_height]\n";
                    print FH, "== case 2 [$src_width]<[$wm_width]\n";

                        my $width=$src_width-10;
                        my $nh;
                        
                           if ( ($wm_width>$width)&&($wm_width/$width>1) ) {
                            my $prop=$wm_width/$width;
                            $nh=int($wm_height/$prop);
                            }

                           else {
                            $nh=$wm_height; $width=$src_width;
                           }
      
                    print FH, "== Resize watermark to [$width]x[$nh]\n";
                    
                    #берем ширину #src и делаем на 10 пикселей меньше
                    $watermark->Resize(width=>$width, height=>$nh );
                    
                                       
                    $image->Composite( image => $watermark,
                                           compose => 'Exclusion',
                                           gravity => 'Center'
                    );

                    $image->Write($src_name);
                    
                }
            }
            else {
                die "!! src file error [$src_name] exit.\n";
            }
            
            close (FH);
        
        
    }
    else {
        print "\n==========================================\n==Awiting params --project_id=xx and --src='xxx.xxx' for image srv file. \n";
    }
        
