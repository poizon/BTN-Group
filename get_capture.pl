#!/usr/bin/perl
use Image::Magick;
use CGI::Carp qw/fatalsToBrowser/;
use CGI::Fast qw(:standard);
use strict;
#use DBI;
use lib 'lib';
use appdbh;

while (new CGI::Fast) {
	
#	do './manager/connect';
#	use vars qw($DBname $DBhost $DBuser $DBpassword);
#	my $dbh=DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
	my $dbh = appdbh->new;
	
	
	# убираем записи, старше 1-го часа:
	my ($sec,$min,$hour,$day,$mon,$year)=(localtime(time-3600))[0..5];
	$year+=1900; $mon++;
	$dbh->do("DELETE from capture WHERE registered<'$year-$mon-$day $hour:$min:$sec'");
	#if(0){
	#	print "Content-type: text/html\n\nopt_string: $opt->{params};"; exit;
	#}
	my $action=param('action');	
	my $domain=$ENV{SERVER_NAME};
	$domain=~s/^www\.//;
	
	my $sth=$dbh->prepare("SELECT project_id from domain WHERE domain=?");
	$sth->execute($domain);
	my $project_id=$sth->fetchrow();
	unless($project_id){
		print "Content-type: text/html\n\n";
		print "project_id not found";
		exit;
	}
	my $opt=&get_options({
		dbh=>$dbh,
		project_id=>$project_id
	});
	my $qs=$ENV{QUERY_STRING};
	$qs=~s/action=.+?&?//;
	if($action eq 'refrash'){
		# если делается refrash, нужно проверить, генерировался ли код ранее:
		my $str_key=param('str_key');
		my $sth=$dbh->prepare("SELECT count(*) from capture where str_key=?");
		$sth->execute($str_key);
		if($sth->fetchrow()){
			#$dbh->do("DELETE from capture where str_key='$str_key'");			
		}
		else{
			print "Content-type: text/html; charset=windows-1251\n\n";
			print "попытка подмены?";
			exit;
		}
	}
	if($action eq 'out_key' || $action eq 'refrash'){
		print "Content-type: text/html\n\n";
		# получаем случайную строку и ключ для неё
		
		my $str;
		my $str_res;
		if($opt->{method}==1){ # вывод примера
			
			$opt->{chars_count}=2 unless($opt->{chars_count});
			$str=$str_res=&gen_example($opt->{chars_count});
			eval('$str_res=('.$str.')');
			$str.='=';
		}
		else{ # вывод цифр
			$opt->{chars_count}=5 unless($opt->{chars_count});
			$str=$str_res=&gen_str($opt->{chars_count});
			
		}
		
		my $sth=$dbh->prepare('select md5(?)');
		$sth->execute($str_res);
		my $str_key=$sth->fetchrow();
		#open F, '>./temp/tst_cap';
		#print F "str: $str\nstr_res: $str_res\nstr_key: $str_key";
		#close F;
		# сохраняем информацию о строки и ключе в БД
		$sth=$dbh->prepare("INSERT INTO capture(str,str_key,registered,project_id) values(?,?,now(),?)");
		$sth->execute($str,$str_key,$project_id);
		
		# генерируем ключ для cpan'а с капчей (ведь на странице капч может быть несколько)
		
		

		#print "Content-type: text/html\n\n"; print "qs: $qs";  exit;		
		if($action eq 'refrash'){
			my $cpt_id=param('cpt_id');
			print qq{<input type='hidden' name='capture_key' value='$str_key'><a href="#" onclick="javascript: document.getElementById('$cpt_id').innerHTML=loadDocAsync('/get_capture.pl?action=refrash&cpt_id=$cpt_id&str_key=$str_key&$qs&$opt->{params}');return false"><img class="capture" align='absmiddle' src='/get_capture.pl?action=out_capture&key=$str_key&$qs&$opt->{params}'></a>};
		}
		else{
			my $cpt_p=param('cpt_id');
			$cpt_p='cpt' unless($cpt_p);
			my $cpt_id=$cpt_p.&gen_str(5);
			my $img_and_hidden=qq{<input type='hidden' name='capture_key' value='$str_key'><a href="#" onclick="javascript: document.getElementById('$cpt_id').innerHTML=loadDocAsync('/get_capture.pl?action=refrash&cpt_id=$cpt_id&str_key=$str_key&$qs&$opt->{params}');return false"><img class="capture" align='absmiddle' src='/get_capture.pl?action=out_capture&key=$str_key&cpt_id=$cpt_id&$qs&$opt->{params}'></a>};
			print qq{<span id='$cpt_id'>$img_and_hidden</span>};
		}
		#$sth=$dbh->prepare("INSERT INTO capture(str,str_key) VALUES()");		
	}	
	elsif($action eq 'out_capture'){		
		my $key=param('key');
		my $sth=$dbh->prepare("SELECT str from capture where project_id=? and str_key=?");
		$sth->execute($project_id,$key);
		my $str=$sth->fetchrow();
		&out_capture($str,$opt);
	}
	
	

}

sub gen_str{
	my $count=shift;
	my $a=q{123456789abcdefghijklmnopqrstuvwxyz};		
	my $str='';
	foreach my $k (1..$count){
		$str.=substr($a,int(rand(length($a))),1)
	}
	return $str;
}

sub gen_example{
	my $count=shift;
#	my $a=q{1234567890};		
	my $a=q{123456789};
	my $x1='';
	foreach my $k (1..$count){
		$x1.=substr($a,int(rand(length($a))),1)
	}
	
	my $x2='';
	foreach my $k (1..$count){
		$x2.=substr($a,int(rand(length($a))),1)
	}
	
#	do {
#		$x1 = int(rand(10));
#		$x2 = int(rand(10));
#	} until($x1 ne '0' || $x2 ne '0');	
		
	return qq{$x1+$x2};
}

sub gen_num {
	my $in = @_;
	my $n = q{123456789};
	my $result = '';
	foreach my $k (1..$in){
		$result .= substr($a,int(rand(length($a))),1);
	}
	return $result;
}

sub out_capture{
my $cap_string = shift;
my $opt=shift;
#my $font = 'times.ttf';
my $font = q{./lib/capcha.ttf};
#my $pointsize = 70;
#my $path = './';

my $image = new Image::Magick;

# 1. Создаём поле 300x100 белого цвета.
$image->Set(size => ($opt->{width}*3).'x'.($opt->{height}*2));
#$opt->{background}='rgba(255, 255, 255, 100)';
$image->ReadImage('xc:'.$opt->{background});
# 2. Печатаем черным с антиалиасингом
$image->Set(
			type 		=> 'TrueColor',
			antialias	=>	'True',
			fill		=>	$opt->{color},
# строку STRING шрифтом $font размером $pointsize
			font		=>	$font,
			pointsize	=>	$opt->{fontsize},
			);
$image->Draw(
			primitive	=>	'text',
			points		=>	'20,75', # ориентация строки текста внутри картинки
			text		=>	$cap_string, # что печатаем
			);

# 3. Подвинуть центр влево на 100 точек +случайная флуктуация
$image->Extent(
			#geometry	=>	'400x120', # меняем размер картинки
			geometry	=>	'400x120', # меняем размер картинки
			);
$image->Roll(
			#x			=>	101+int(rand(4)),
			x			=>	101#+int(rand(4)),
			);
# 4. Первый swirl на случайный угол (от 37 до 51)
$image->Swirl(
			degrees		=>	(rand($opt->{deg2_to}))+$opt->{deg2_from} #37,
			);
# 5. Подвинуть центр вправо на 200 точек, тоже со случайной флуктуацией
$image->Extent(
			#geometry	=>	'600x140', # меняем размер картинки
			geometry	=>	'600x140', # меняем размер картинки
			);
$image->Roll(
			#x			=>	3-int(rand(4)),
			x			=>	3#-int(rand(4)),
			);
# 6. Второй поворот (от 20 до 35)
$image->Swirl(
			degrees		=>	int(rand($opt->{deg1_to}))+$opt->{deg1_from},
			);
# 7. Окончательная обработка и вывод
$image->Crop('230x80+110+7');
$image->Resize($opt->{width}.'x'.$opt->{height});

#$filename = $path . $filename;
#$filename .= '.png';
#open(IMAGE,'>',$filename) or die $!;
#$image->Write(file=>\*IMAGE, filename=>$filename);
#close(IMAGE);

print "Content-type: image/png\n\n";
binmode STDOUT; 
$image->Write('png:-'); 
#return $filename;
}

sub get_options{
	my $par=shift;
	my $opt={
		width=>'150',
		height=>'50',
		deg1_from=>0,
		deg1_to=>30,
		deg2_from=>0,
		deg2_to=>30,
		background=>'#ffffff',
		color=>'#000000',
		fontsize=>'60',
		method=>'0', # 0 -- проверочная строка ; 1 -- пример
#		params=>'',
		
	};
	
	my $domain = $ENV{HTTP_HOST};
	$domain=~s/^www\.//;
	#print "Content-type: text/html\n\n$domain"; exit;
		# считываем параметры
	
	my $sth=$par->{dbh}->prepare(q{
		SELECT cs.* 
		FROM project p, domain d, capture_setting cs 
		WHERE p.project_id = d.project_id and d.template_id=cs.template_id and d.domain = ?
	});
		
	$sth->execute($domain);
	my $opt_tmp=$sth->fetchrow_hashref();
	
	#print "Content-type: text/html\n\n$par->{project_id}<br>";
	foreach my $attr (keys(%{$opt_tmp})){
#		print "a: $attr<br>";
		my $v=$opt_tmp->{$attr};
		my $p=param($attr);
		if($p=~m/^[a-zA-Z0-9#]+$/){ # проверяем параметр через http
#			print "X";
			if($p=~m/^[a-f0-9]{6}$/i && ($attr eq 'color' || $attr eq 'background')){
				$p='#'.$p;
			}
			$opt->{$attr}=$p;
			print "value: $p";
		}
		elsif($v=~m/^[a-zA-Z0-9#]+$/){ # проверяем параметр из БД
			#$opt->{params}.=qq{&$attr=$v};
			if($v=~m/^[a-f0-9]{6}$/i && ($attr eq 'color' || $attr eq 'background')){
				$v='#'.$v;
			}
			$opt->{$attr}=$v;
			
		}
	}
	#use Data::Dumper;
	#print Dumper($opt); exit;

	return $opt;
}
