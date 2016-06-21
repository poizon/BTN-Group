#!/usr/bin/perl
use CGI::Carp qw/fatalsToBrowser/;
use CGI::Fast qw(:standard);
#use strict;
use DBI;
use lib 'lib';
use odt_file2;
use Encode;

do './admin/connect';
our $dbh=DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
my $project_id='196';
my $blank_id=1;
my $sth=$dbh->prepare("SELECT attach FROM document_blank where project_id=? and id=?");
$sth->execute($project_id, $blank_id);
my $attach=$sth->fetchrow();

my $data=
{
	bill_number=>'777',
	address=>'ADDRESS',
	summa_rub=>'55',
	summa_kop=>'0'
};

foreach my $k (keys(%{$data})){
	Encode::from_to($data->{k}, 'cp1251', 'utf8');
}




#print "Content-type: text/html\n\n";
&odt_process(
{
	#template=>'act_with_nds.odt', # шаблон, можно без пути если указан template_path
	template=>$attach, # шаблон, можно без пути если указан template_path
	template_path=>"./files/project_$project_id/blank_doc/", # там лежат бланки шаблонов
	tmp_dir=>'./tmp',
	result_dir=>'./tmp', # путь куда класть результат если нада
	result_file_name=>'', # если нужно куда нить положить (просто имя если указан result_dir есле не указан то полный путь)
	format=>'doc',
	upload_file_name=>'bill.doc',
	vars=>{
		data=>$data
	}
});


