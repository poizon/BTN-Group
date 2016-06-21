#!/usr/bin/perl
#  опирует коды и инфу о страницах из одного шаблона в другой
use DBI;
use Template;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
do './connect';
my $dbh = DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
print "Content-type: text/html; charset=windows-1251\n\n";
my $params;
# 1. ќпредел€ем template_id
my $sth=$dbh->prepare(q{
	SELECT t.template_id, d.project_id
	FROM manager m, domain d, template t
	WHERE m.project_id = d.project_id
	and d.template_id = t.template_id and m.login=? and d.domain=?
});
$sth->execute($ENV{REMOTE_USER}, $ENV{HTTP_HOST});
my ($template_id,$project_id)=$sth->fetchrow();
if(!$template_id || !$project_id){
	print "Ќе удалось определить проект и щаблон";
	exit;
}
my $action=param('action');
if($action eq 'set_promo'){
	my $promoblock_id=param('promoblock_id');
	if($promoblock_id=~m/^\d+$/){
		#SELECT promoblock_id from project_group_site where project_id=$project_id
		$dbh->do("UPDATE project_group_site SET promoblock_id=$promoblock_id where project_id=$project_id");
	}
	#print "<script>alert('выбрано')</script>";
	exit;
}

# 2. получаем значение переменной promo_size
my @add_where=();
$sth=$dbh->prepare("SELECT value from template_group_site where template_id=? and header='promo_size'");
$sth->execute($template_id);
unless($sth->rows()){
	print 'переменна€ <b>promo_size</b> в настройках типового шаблона не определена';
	exit;
}
my $size=$sth->fetchrow();
my @add_where=();
if($size=~m/^(\d+)x(\d+)$/){
	my $w=$1; my $h=$2;
	push @add_where,"width = $1" if($w);
	push @add_where,"height = $2" if($h);
}

# список подход€щих промо-изображений:
my $where_string=join(' AND ',@add_where);
$where_string=qq{WHERE $where_string} if($where_string);
$sth=$dbh->prepare("SELECT * from template_group_promoblock $where_string");
$sth->execute();
$params->{promolist}=$sth->fetchall_arrayref({});
foreach my $p (@{$params->{promolist}}){
	$p->{file_big}=$p->{file};
	if($p->{file}=~m/^(.+)\.(.+)$/){
		$p->{file}=qq{$1\_mini1.$2};
	}
}

$sth=$dbh->prepare("SELECT promoblock_id from project_group_site where project_id=$project_id");
$sth->execute();
$params->{cur_promo}=$sth->fetchrow();

my $template = Template->new({
    INCLUDE_PATH => './templates'
});

$template -> process('change_promoblock.tmpl', $params) || croak "output::add_template: template error: ".$template->error();
