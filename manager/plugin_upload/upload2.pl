#!/usr/bin/perl

use Template;
use upload;
use Data::Dumper;

$upload_root_path = '../../files';
my $header = "Content-Type: text/html; charset=windows-1251;";

my $template = Template->new();

my $up = upload->new();
my $vars = {
	action => $up->{action},
	folder => $up->{folder},
	folder_up => $up->{folder_up},
	path_www => $up->{path_www},
	type => $up->{type},
	tiny_mce_www => $up->{tiny_mce_www},
	type_window => $up->{type_window}
};

if($up->{action} eq 'upload'){
	if($up->load_file()){
		$header = "Location: ?type_v=$up->{type}".($up->{folder}?"&folder=$up->{folder}":"");
	}
}
elsif($up->{action} eq 'folder_new'){
	$up->create_dir();
	$header = "Location: ?type_v=$up->{type}".($up->{folder}?"&folder=$up->{folder}":"");
}
elsif($up->{action} eq 'delete'){
	$up->delete;
	$header = "Location: ?type_v=$up->{type}".($up->{folder}?"&folder=$up->{folder}":"");
}
else{
	$files = $up->get_dir();
	my @f1 = sort{ $a->{name} <=> $b->{name} } @{$files->{files}};
	$vars->{files} = $up->a2sort($files->{files}, $up->{type_sort_file}, $up->{order_sort_file});
	$vars->{dirs} = $up->a2sort($files->{dirs}, $up->{type_sort_dir}, $up->{order_sort_dir});
}

print "$header\n\n";

$template->process('upload2.html', $vars);
