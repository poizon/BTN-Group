#!/usr/bin/perl
# ������ ��� ��������� �������� �����������
use Image::Magick;
#use Data::Dumper;

my $input_file=$ARGV[0];
if($input_file=~m/^(.+)\.(.*?)$/){
	our $input=$1;
	our $input_ext=$2;
}

our @output=();
$output_object={};
our $project_id;
our $project_files='/www/sv-cms/htdocs/files';

foreach my $p (@ARGV){
	if($p=~m/^--(.+?)(=(.+))?$/){
		my ($opt,$val)=($1,$3);
		$val=~s/^'|'$//g;

		if($opt eq 'output_file'){
			$val=~s/\[%input%\]/$input/;
			$val=~s/\[%input_ext%\]/$input_ext/;
			if($val=~m/^[0-9a-zA-Z\._\-\/]+$/){
				$output_object->{file}=$val;
			}
		}

		# 22.12.2014, Isavnin, ��������� �������
		# ��������� �����
		if($opt eq 'crop'){
			$output_object->{crop}=$val;
			$output_object->{precrop}=undef unless($output_object->{precrop});
			$output_object->{gravity} = 'Center' unless($output_object->{gravity});
			$output_object->{xypos} = '+0+0' unless($output_object->{xypos});
		}
		
		# ���� �� �������
		if($opt eq 'precrop'){$output_object->{precrop}=$val;}
	
		# ������ ��������� ����� ��� �������������
		if($opt eq 'xypos'){$output_object->{xypos}=$val;}
		if($opt eq 'gravity'){$output_object->{gravity}=$val;}
		
		# ��������� ���� �� ������ ����
		if($opt eq 'wm'){
			$output_object->{wm}=1;
			#$output_object->{wmresize}='0x0' unless($output_object->{wmresize});
			$output_object->{wmpos}='Center' unless($output_object->{wmpos});
			$output_object->{wmxy}='0x0' unless($output_object->{wmxy});
		}
		
		# ������ ������� �����, ���� ����
		if($opt eq 'wmresize'){
			if($val =~ m/^(\d+)x(\d+)$/){
				$output_object->{wmresize} = ($1 > 0 ? $1 : '').'x'.($2 > 0 ? $2 : '');
			}
		}

		# ������������ ������� �����
		if($opt eq 'wmpos'){
			$output_object->{wmpos} = $val if($val =~ m/^(\w+)$/);
		}
		
		# ����� ������� �����
		if($opt eq 'wmxy'){
			if($val =~ m/^(\d+)x(\d+)$/){
				$output_object->{wmxy}=($1 > 0 ? $1 : '').'x'.($2 > 0 ? $2 : '');
				$output_object->{wmx} = $1 > 0 ? $1 : undef;
				$output_object->{wmy} = $2 > 0 ? $2 : undef;
			}
		}
		
		# ������, ����� ��� ������� �����
		if($opt eq 'project_id'){
			if($val =~ m/^(\d+)$/){
				$project_id = $1;
			}
		}

		# �� � �� �������, �����-������ �������... 8)
		if($opt eq 'filter'){}

		# ����� ������� 
		if($opt eq 'type'){$output_object->{type}=$val;}

		if($opt eq 'size'){
#			print "val: $val<br/>";
			if($val=~m/^(\d+)x(\d+)$/){
#				print "1: $1 ; 2: $2<br/>";
				$output_object->{resize}=($1 > 0 ? $1 : '').'x'.($2 > 0 ? $2 : '');
				$output_object->{width}=$1;
				$output_object->{height}=$2;
			}

			&check_output_object;

		}

		&help if($opt eq 'help');
	}
}
if($input_file!~m/[0-9a-zA-Z\._\-\/]+/){
	print "�� ������� ��� ������� �� ����� ��� �������� ����� ($input_file)\n";
	exit;
}




#print Dumper(@output);
foreach my $o (@output){
	#print "\n\noutput_file: $o->{file}\n";
	#print "\n\width: $o->{width}\n";
	#print "\n\height: $o->{height}\n";
	
	if($o->{type} eq 'new'){
		new_resize($input_file,$o);
	}else{
		leva_resize($input_file, $o->{file}, $o->{width}, $o->{height});
	}
}

sub check_output_object{ # �������� �������, ����������� �� �������� ����
	#print "filel $output_object->{file}\n";
	if($output_object->{file}!~m/[0-9a-zA-Z\._\-\/]+/){
		print "�� ������� ��� �����-�������� ($output_object->{file})\n";
		exit;
	}
	if(!length($output_object->{width}) || !length($output_object->{height})){
		print "�� ������� ��� ������� �� ����� ������� ��������� �����; '$output_object->{width}' ; '$output_object->{height}'";
		exit;
	}
	push @output, {
		# ��������� ��� ������� �������
		file=>$output_object->{file},width=>$output_object->{width}, height=>$output_object->{height},

		# ������ �������� �������� �� ��������� ������ �������...
		type=>$output_object->{type},
	
		# ����� ���������, ������������� ��� �������, � �����...
		precrop=>$output_object->{precrop},
		crop=>$output_object->{crop},resize=>$output_object->{resize},
		xypos=>$output_object->{xypos},gravity=>$output_object->{gravity},
		wmresize=>$output_object->{wmresize},wmxy=>$output_object->{wmxy},
		wmx=>$output_object->{wmx},wmy=>$output_object->{wmy},
		wmpos=>$output_object->{wmpos},
		
		# ������ ����
		wm=>$output_object->{wm}
	};
	$output_object={};

#print Dumper(@output);
}

sub help{
	print q{

������ picture_resize
������������ ��� ��������� ������� ����������� ��������.
�����:
./resize [����-��������] ( --output_file='[����-�������]' --size='[������]x[������]' )
����� ��������� � �������, ����� ����������� ��������� ��� (����� ������� ������ ������ ������� ��������� ����� �����������).

--output_file
  ����-������� -- ���������� ����. �������� ��������, ����� ��� �����-�������� ��������� � ������ �����-���������.
  � ���� ������ ��������� ������������ � ��������. ����� �������� ��������, ����� ����������� ��������� ���������
  (��� ������� �� ��������� ���������� ������ ������ � ������). � ����� ������, �� ������ ��������� ��������� ����� �������� �
  ����������� ���������.
  ��� �������� ��������� ����� �����, �������� ��������� ���������� [%input%] -- ��� ��� �������� ����� ��� ����������.
  [%input_ext%] -- ��������� �������� �����.

  � ���� ������ �������� ����� ������:
  ./resize picture.jpg --output_file='[%input%]_mini.[%input_ext%]' --size='100x100'

--size
  ������ � ������ �����-��������
};
}

sub leva_resize {
    my ($input_file, $output_file, $border_width, $border_height) = @_;
    my $image;
    $image = Image::Magick->new;
    my $x = $image->Read($input_file);
    my ($picture_width, $picture_height) = $image->Get('base-columns', 'base-rows');
    print "($picture_width, $picture_height)\n";
    if (($picture_width < $border_width) && ($picture_height < $border_height)) {
        $image->Resize(width=>$picture_width, height=>$picture_height);
    } elsif ($border_width != 0 && $border_height != 0) {
        my $k;
        my $ko_width = $border_width / $picture_width; # ����������� ����������� ������������������ ����������� ������ ����� � ��������
        my $ko_height = $border_height / $picture_height; # ����������� ����������� ������������������ ����������� ������ ����� � ��������
        my $ko = $ko_width / $ko_height; # ��������� ����������� ����� ��������������
        if ($ko >= 1) { # ���� ���������� ���� ���� ������-�����
            $k = $border_height / $picture_height;
        } elsif ($ko < 1) { # ���� ���������� ���� ���� �� �����-������
            $k = $border_width / $picture_width;
        } elsif (($border_height >= $picture_height) && ($border_width >= $picture_width)) { # ���� �������� ������ ����� - ������ ������ � ��� �� �����
            $k = undef;
        }
        if (defined $k) {
            my $result_height = int($picture_height * $k);
            my $result_width = int($picture_width * $k);
            $image->Resize(width=>$result_width, height=>$result_height);
        } else {
            $image->Resize(width=>$picture_width, height=>$picture_height);
        }
    } elsif ($border_height == 0) {
		if ($picture_width < $border_width) {
			$image->Resize(width=>$picture_width, height=>$picture_height);
		}
		else {
			my $k = $border_width / $picture_width;
			my $result_height = int($picture_height * $k);
			my $result_width = int($picture_width * $k);
			$image->Resize(width=>$result_width, height=>$result_height);
		}
    } elsif ($border_width == 0) {
		if ($picture_height < $border_height) {
			$image->Resize(width=>$picture_width, height=>$picture_height);
		}
		else {
			my $k = $border_height / $picture_height;
			my $result_height = int($picture_height * $k);
			my $result_width = int($picture_width * $k);
			$image->Resize(width=>$result_width, height=>$result_height);
		}
    }
    print "����: $output_file\n";
    $x = $image->Write($output_file);
	1;
}

sub new_resize {
	my($file,$opt) = @_;
	my $img = Image::Magick->new;
	my $pic = $img->Read($file);
	my($w,$h) = $img->Get('base-columns','base-rows');

	# �������
	if($opt->{precrop}){
		if(!$opt->{orig}){
			$img->Crop(geometry=>$opt->{precrop});
			print "����������: $opt->{precrop}\t";
		}
	}

	# ��������
	if($opt->{resize}){
		if($opt->{width} != 0 && $opt->{height} != 0){
			$img->Resize($opt->{resize});
		}
		elsif($opt->{width} == 0 && $h >= $opt->{height}){
			$img->Resize($opt->{resize});
		}
		elsif($opt->{height} == 0 && $w >= $opt->{width}){
			$img->Resize($opt->{resize});
		}
		else{
			#$img->Resize($w.'x'.$h);
			$opt->{orig}=1;
		}

		print "������: $w x $h => $opt->{resize}\t" if(!$opt->{orig});
		print "������: �� �����, �������� ������ ��������\t" if($opt->{orig}==1);
	}

	# ������
	if($opt->{crop}){
		if(!$opt->{orig}){
			$img->Crop(geometry=>$opt->{crop}.$opt->{xypos},gravity=>$opt->{gravity});
			print "������: $opt->{crop}$opt->{xypos} $opt->{gravity}\t";
		}
	}

	if($opt->{wm} eq '1' && $project_id){
		my $wm_file = qq{$project_files/project_$project_id/const_watermark.png};
		if( -f $wm_file ){
			my $watermark = Image::Magick->new;
			my $wm = $watermark->Read($wm_file);
			my($wm_width,$wm_height) = $watermark->Get('base-columns','base-rows');
			
			# �������� ������ ����
			$watermark->Resize(geometry=>$opt->{wmresize}) if($opt->{wmresize});
			
			# ������ ���� ������ ��������
			$opt->{wmpos} = 'Center' unless ($opt->{wmpos});
			$opt->{wmx} = 0 unless($opt->{wmx});
			$opt->{wmy} = 0 unless($opt->{wmy});
			print "G:$opt->{wmpos} X:$opt->{wmx} Y:$opt->{wmy}\n";
			if($w > $wm_width){
				$img->Composite(image => $watermark,compose => 'Over',gravity => $opt->{wmpos},x => $opt->{wmx}, y => $opt->{wmy});
			}
			else{
				$opt->{wmresize} = $opt->{wmresize} ? $opt->{wmresize} : ($wm_width-($wm_width-$w)).'x'.($wm_height-($wm_height-$h));
				$watermark->Resize(geometry=>$opt->{wmresize});
				$img->Composite(image => $watermark, compose => 'Over', gravity => $opt->{wmpos}, x => $opt->{wmx}, y => $opt->{wmy});
				print "�������� ������ ����: $wm_width x $wm_height => $opt->{wmresize}\t";
			}
			print "��������� ������ ����\t";
		}
		else{
			print "<b color='red'>������ ���� �� ������</b>\t";
		}
	}

	# ��������� �������...
	
	# �����
	$pic = $img->Write($opt->{file});
	print "�����: $opt->{file}\n<br/>";
	1;
}


sub resize{ # ��������� ����������
	my ($input_file, $output_file, $width, $height)=@_;
	my $image;
	$image = Image::Magick->new; #����� ������
	my $x = $image->Read($input_file); #��������� ����
	my ($ox,$oy)=$image->Get('base-columns','base-rows');
	#my $nx=int(($ox/$oy)*$height); #��������� ������
	my $ny=int(($oy/$ox)*$width); #��������� ������
	$image->Resize(width=>$width, height=>$ny);
	if($ny>$height){
		$nny=int(($ny-$height)/2); #��������� ������ ��� ������

		$image->Crop(x=>0, y=>$nny);
		$image->Crop($width.'x'.$height); #� ���� ����� �������� 200�150
	}
	$x = $image->Write($output_file);
}

=cut
sub resize{ # ��������� ����������
	my ($input_file, $output_file, $width, $height)=@_;
	my $image;
	$image = Image::Magick->new; #����� ������
	my $x = $image->Read($input_file); #��������� ����
	my ($ox,$oy)=$image->Get('base-columns','base-rows');
	my $nx=int(($ox/$oy)*$height); #��������� ������
	$image->Resize(width=>$nx, height=>$height);
	if($nx>$width){
		$nnx=int(($nx-$width)/2); #��������� ������ ��� ������
		print "nnx: $nnx\n";
		$image->Crop(x=>$nnx, y=>0);
		$image->Crop($width.'x'.$height); #� ���� ����� �������� 200�150
	}
	$x = $image->Write($output_file);
}
=cut
