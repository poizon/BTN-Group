package upload;
use DBI;
use Data::Dumper;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
#print "Content-Type: text/html; charset=windows-1251;\n\n";
do "config.pl";
$CGI::POST_MAX = $file_size_max;

sub new{
	my $class = shift;
	my $self = {};
	
	$self->{type_sort_file} = $type_sort_file;
	$self->{type_sort_dir} = $type_sort_dir;
	$self->{order_sort_file} = $order_sort_file;
	$self->{order_sort_dir} = $order_sort_dir;
		
	$self->{action} = param('action');
	$self->{type} = 1;
	$self->{type} = param('type_v') || 1;
	$self->{folder} = param('folder');
	$self->{folder} =~ s!\.\./!!sgi;
	$self->{folder} =~ s!^[\.]+!!sgi;
	$self->{type_window} = param('type');
	
	my @dirs = split('/', $self->{folder});pop @dirs;	
	$self->{folder_up} = join('/', @dirs);
	
	$self->{path} = $self->{folder}? "$upload_root_path/$self->{folder}" : "$upload_root_path";
	$self->{path_www} = $self->{folder}? "$upload_path/$self->{folder}" : "$upload_path";
	$self->{tiny_mce_www} = $tiny_mce_www;
		
	bless($self);
	return $self;
}

sub load_file{
	my $self = shift;
	my @files = param('fileload');
	my @types = (@types_file, @types_img);
	my $regexp = '('.join('|', @types).')';
	
	if(scalar(@files)){
		foreach(@files){
			my $file = $_;
			if($file =~ m/\.$regexp$/i){
				$file = $1 if($file =~ /\\([^\\]+)$/i);
				$file = file2translit( $file );
			
				open(FL, ">$self->{path}/$file") or die("not open file write $self->{path}/$file");
				binmode FL;
				binmode $_;
				while(my $line = <$_>){
					print FL $line;
				}
				close FL;
				chmod(0777, "$self->{path}/$file");
			}
		}
		return 1;
	}
	return 0;
}

sub create_dir{
	my $self = shift;
	my $name = file2translit( param('name') );
	
	unless(-e "$self->{path}/$name"){
		mkdir("$self->{path}/$name");
		chmod(0777, "$self->{path}/$name");
	}
}

sub delete{
	my $self= shift;
	my @files = param('file_name');
	
	if(scalar(@files)){
		foreach(@files){
			$_ =~ s!\.\./!!sgi;
			$_ =~ s!^[\.]+!!sgi;
			
			if($_ && -d "$self->{path}/$_"){
				delete_dir("$self->{path}/$_");
			}
			elsif($_ && -e "$self->{path}/$_"){
				unlink("$self->{path}/$_");
			}
		}
	}
}

sub delete_dir{
	my $dname = shift;
	opendir(D, "$dname");
	my @dirs = grep{!(/^\./)} readdir(D);
	closedir(D);
	
	foreach my $dn(@dirs){
		if(-d "$dname/$dn"){
			delete_dir("$dname/$dn");
		}
		elsif(-e "$dname/$dn"){
			unlink("$dname/$dn");
		}
	}
	
	rmdir("$dname");
}

sub get_dir{
	my $self = shift;
	my %files = (
		'dirs' => [],
		'files' => []
	);
	my @types = (@types_file, @types_img);	
	my $regexp = '('.join('|', @types).')';
	
	opendir(D, $self->{path});	
	foreach(readdir(D)){
		if(!($_ =~ /^\./)){
			if($_ =~ /\.($regexp)$/i){
				my $ext = $1;
				$ext =~ tr/A-Z/a-z/;				
				my $name_small = length($_)>10? substr($_, 0, 10).'...' : $_;
				my @info = stat("$self->{path}/$_");				
				push @{$files{files}}, {
					name => $_,
					name_small => $name_small,
					type_img => (grep{/^$ext$/} @types_img)? 1 : 0,
					ico => "icons/$ext.png",
					mtime => $info[9]										
				};
			}			
			elsif( -d "$self->{path}/$_"){
				my @info = stat("$self->{path}/$_");
				push @{$files{dirs}}, {
					name => $_,
					mtime => $info[9]
				}
			}
		}
	}
	closedir(D);
	
	return \%files;
}

sub a2sort{
	my $self = shift;
	my $array = shift;
	my $type_sort = shift;
	my $order = shift;
	my @array2 = ();
	
	if($type_sort == 1){
		@array2 = sort{ $a->{mtime} <=> $b->{mtime} } @{$array};		
	}
	elsif($type_sort == 2){
		my $i = 0;
		my %names = map{$_->{name} => $i++}@{$array};
		foreach(sort keys%names){
			push @array2, $array->[$names{$_}];
		}
	}
	@array2 = reverse @array2 if($order eq 'desc');
	return \@array2 if(scalar(@array2));	
	return $array;
}

sub file2translit{
	my $fname = shift;
	my @fname_chars = split(//, $fname);
	
	my %chars = (
		'é' => 'i','ú' => 'i','ý' => 'e',
		'ö' => 'c','ô' => 'f','ÿ' => 'ya',
		'ó' => 'u','û' => 'i','÷' => 'ch',
		'ê' => 'k','â' => 'v','ñ' => 's',
		'å' => 'e', '¸' => 'yo',
		'à' => 'a','ì' => 'm',
		'í' => 'n','ï' => 'p','è' => 'i',
		'ã' => 'g','ð' => 'r','ò' => 't',
		'ø' => 'sh','î' => 'o','ü' => 'i',
		'ù' => 'sh','ë' => 'l','á' => 'b',
		'ç' => 'z','ä' => 'd','þ' => 'u',
		'õ' => 'h','æ' => 'zh',' ' => '_',
	);
	
	for(my $i = 0; $i < scalar(@fname_chars); $i++){
		my $char_code = ord($fname_chars[$i]);
		my $char = $fname_chars[$i];
		if($char_code > 191 && $char_code < 224){
			$char =~ tr/À-ß/à-ÿ/;
			my $char2 = $chars{$char};
			$char2 =~ tr/a-z/A-Z/;
			$fname_chars[$i] = $char2;
		}
		elsif(exists($chars{$char})){
			$fname_chars[$i] = $chars{$char}; 
		}
	}	
	
	my $file = join('', @fname_chars);
	$file =~ s!\.\./!!sgi;
	$file =~ s!^[\.]+!!sgi;
	return $file;
}

1;
