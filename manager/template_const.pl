#!/usr/bin/perl
# Копирует коды и инфу о страницах из одного шаблона в другой
use DBI;
use Template;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
do './connect';
my $dbh = DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
$dbh->do("SET names cp1251");
print "Content-type: text/html; charset=windows-1251\n\n";

my $template = Template->new({
           INCLUDE_PATH => './templates'
});
my $action=param('action');
my $params;
# 1. Определяем template_id
my $sth=$dbh->prepare(q{
	SELECT t.template_id, d.project_id
	FROM manager m, domain d, template t
	WHERE m.project_id = d.project_id 
	and d.template_id = t.template_id and m.login=?
});
$sth->execute($ENV{REMOTE_USER});
my ($template_id,$project_id)=$sth->fetchrow();
unless($template_id){
	print "Для Вашего шаблона константы не определены ($ENV{REMOTE_USER})";
	
	exit;
}
# получаем список констант в нужном порядке:


$sth=$dbh->prepare("SELECT header name,type,description from template_const where template_id=? order by sort");
$sth->execute($template_id);
$params->{FIELDS}=$sth->fetchall_arrayref({});
my $const_val;
if($action eq 'delfile'){
	my $rname=param('name');
	if($rname=~m/^[a-z_0-9\-]+$/i){
		
		$sth=$dbh->prepare("SELECT name,value from const where name=? and project_id=?");
		$sth->execute($rname,$project_id);
		if($sth->rows()){
			
			my ($name,$value)=$sth->fetchrow();
			#print "($name,$value)";
			if($value=~m/.(jpe?g|png|gif|doc)$/){
				my $fullname="../files/project_$project_id/const_$name.$1";
				unlink($fullname);
				$sth=$dbh->prepare("UPDATE const set value='' where name=? and project_id=?");
				$sth->execute($rname,$project_id);				
			}
		}
	}
}
if($action eq 'update'){ # Обновление констант 
	my $query_set=""; my @values;
	my $j=1;
	foreach my $f (@{$params->{FIELDS}}){
		my $value=$const_val->{$f->{name}}=param($f->{name});
		if(($value && $f->{type} eq 'file') || $f->{type} ne 'file'){
			if($f->{type} eq 'file' && $value){
				if($const_val->{$f->{name}}=~m/^(.+?).(jpe?g|pdf|png|gif|docx?|xlsx?|zip)$/i){
					my $ext=$2;
					$value=$const_val->{$f->{name}}=qq{const_$f->{name}.$ext};
					#print qq{>../files/project_$project_id/const_$filename\.$ext<br>};
					open F,qq{>../files/project_$project_id/$value};
					binmode F;
					my $fdata=param($f->{name});
					
					print F while(<$fdata>);
					close F;
					$j++;
				}
			}

#Isavnin, 04.12.2013
#Fix: Ошибка когда тип чекбокс и он не установлен
                        if($f->{type} eq 'checkbox' && !$value){$value='0';}


			#print "UPDATE const SET value='$const_val->{$f->{name}}' where project_id=$project_id and name='$f->{name}'<br>";
			#print "UPDATE const SET value='$value' where project_id=$project_id and name=$f->{name}<br>";
			my $sth = $dbh->prepare("DELETE FROM const where project_id = $project_id and name = ?");
			$sth->execute($f->{name});
 			$sth=$dbh->prepare("REPLACE INTO const SET value=?,project_id=?,name=?");
			$sth->execute($value,$project_id,$f->{name});

		}
	}
	
}
else{
	$sth=$dbh->prepare("SELECT name,value from const where project_id=?");
	$sth->execute($project_id);
	while(my ($name,$value)=$sth->fetchrow()){	
		$const_val->{$name}=$value;
	}
}

#print '<pre>'.Dumper($const_val).'</pre>';
# Формируем список с полями, получаем значения полей
foreach my $f (@{$params->{FIELDS}}){
	$f->{value}=$const_val->{$f->{name}};
	if($f->{type} eq 'text' || $f->{type} eq 'textarea'){
		$f->{value}=~s/>/&gt;/gs;
		$f->{value}=~s/</&lt;/gs;
		$f->{value}=~s/"/&quot;/gs;
	}
	
	if(!$f->{type} || $f->{type} eq 'text'){
		$f->{field}=qq{<input class="inp" type="text" name="$f->{name}" value="$f->{value}">}
	}
	elsif($f->{type} eq 'checkbox'){
		my $checked='';
		if($f->{value}){
			$checked=' checked';
		}
		$f->{field}=qq{<input type="checkbox" value="1" name="$f->{name}"$checked/>}
	}
	elsif($f->{type} eq 'textarea'){
		$f->{field}=qq{<textarea name="$f->{name}">$f->{value}</textarea>}
	}
	elsif($f->{type} eq 'file'){
		$f->{field}=qq{<input type="file" name="$f->{name}">};
		if($f->{value}){
			$f->{field}.=qq{<a href="/files/project_$project_id/$f->{value}" target="_blank">открыть</a>}.
			qq{ <a href="?action=delfile&name=$f->{name}">удалить</a>}
		}
	}
}
undef($const_val);

$template -> process('template_const.tmpl', $params) || die($!);
undef($params);
