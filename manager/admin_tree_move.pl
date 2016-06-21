#!/usr/bin/perl
use DBI;
use CGI qw(:standard);
use CGI::Carp qw (fatalsToBrowser);
use Encode;
use lib 'lib';
use read_conf;
use Data::Dumper;
print "Content-type: text/html; charset=windows-1251\n\n";
=cut
Инструмент, позволяющий копировать или перемещать ветки дерева
=cut

our $form=&read_config;
our $dbh = $form->{dbh};

#$action=param('action');
#our $config=param('config');

our $parent_id_left=param('parent_id_left');
unless($parent_id_left=~m/^\d+$/){$parent_id_left=0}
our $parent_id_right=param('parent_id_right');
unless($parent_id_right=~m/^\d+$/){$parent_id_right=0}
unless($parent_id=~m/^\d+$/){$parent_id=0}
#do qq{./conf/$config};
#our $work_table=$form{work_table};

#our $form_link=\%form;

$form->{header_field}='header' unless($form->{header_field});
our $script='admin_tree_move.pl';


our $move_checked=' checked';
my $mode=param('mode');

if($form->{action} eq 'move'){
	#print "переместить";
	my ($from_parent_id, $to_parent_id, $cur_id);
	my $cur_id=param('cur_id');
	unless($cur_id=~m/^\d+$/){
		print "не верный вызов621";
		exit;
	}

	if($mode eq 'left'){
		$from_parent_id=$parent_id_left;
		$to_parent_id=$parent_id_right;
	}
	elsif($mode eq 'right'){
		$from_parent_id=$parent_id_right;
		$to_parent_id=$parent_id_left;
	}

	my $sth=$dbh->prepare("SELECT path from $form->{work_table} WHERE $form->{work_table_id}=?");
	$sth->execute($cur_id);
	my $from_path=$sth->fetchrow();

	$sth=$dbh->prepare("SELECT path from $form->{work_table} WHERE $form->{work_table_id}=?");
	$sth->execute($to_parent_id);
	my $to_path=$sth->fetchrow();
	$sth->finish();
#	print "$parent_id_left, $parent_id_right";
	if( ($to_parent_id==$cur_id) || ($to_path=~m|$from_path/$cur_id$|) || $to_path=~m|$from_path/$cur_id/|)
	{
		print "Ошибка! нельзя переместить в себя<br>";

	}
	elsif($parent_id_left!=$parent_id_right)
	{
		# обновляем перемещаемый элемент
		my $new_path='';
		if($to_parent_id || $to_path)
		{
			$new_path=qq{$to_path/$to_parent_id};
		}

		$to_parent_id='null' unless($to_parent_id);
		$sth=$dbh->prepare("UPDATE $form->{work_table} SET parent_id=$to_parent_id, path=? WHERE $form->{work_table_id}=?");
		$sth->execute($new_path,$cur_id);
		$sth->finish();


		# обновляем дочерние элементы
		$sth=$dbh->prepare("SELECT $form->{work_table_id}, path from $form->{work_table} WHERE path=? OR path like ?");
		$sth->execute(qq{$from_path/$cur_id}, qq{$from_path/$cur_id/%});
		my $sth2=$dbh->prepare("UPDATE $form->{work_table} SET path=? WHERE $form->{work_table_id}=?");
		while(my ($id, $path)=$sth->fetchrow())
		{
			$path=~s/^$from_path$/$new_path/;
			$path=~s/^$from_path\/(.+)$/$new_path\/$1/;
			$sth2->execute($path, $id);
		}
		$sth2->finish();
	}
}

elsif($form->{action} eq 'copy'){
	# сохраняем состояние галочек "переместить / копировать"
	our $copy_checked=' checked';
	our $move_checked='';

	my ($from_parent_id, $to_parent_id, $cur_id);
	my $cur_id=param('cur_id');
	unless($cur_id=~m/^\d+$/){
		print "не верный вызов632";
		exit;
	}

	if($mode eq 'left'){
		$from_parent_id=$parent_id_left;
		$to_parent_id=$parent_id_right;
	}
	elsif($mode eq 'right'){
		$from_parent_id=$parent_id_right;
		$to_parent_id=$parent_id_left;
	}

	my $sth=$dbh->prepare("SELECT path from $form->{work_table} WHERE $form->{work_table_id}=?");
	$sth->execute($cur_id);
	my $from_path=$sth->fetchrow();

	$sth=$dbh->prepare("SELECT path from $form->{work_table} WHERE $form->{work_table_id}=?");
	$sth->execute($to_parent_id);
	my $to_path=$sth->fetchrow();
	$sth->finish();
	if( ($to_parent_id==$cur_id) || ($to_path=~m|$from_path/$cur_id$|) || $to_path=~m|$from_path/$cur_id/|){
		print "Ошибка копирования! Нельзя копировать в себя!<br>";
	}
	else{
		# копирум головной элемент
		my $new_path='';
		if($to_parent_id || $to_path){
			$new_path=qq{$to_path/$to_parent_id};
		}

		# Получаем данные о головном элементе:
		my @fields=();
		my @values=();
		foreach my $element (@{$form->{fields}}){
			push @fields, $element->{name};
		}

		# Копируем дочерние элементы
		my @nodes=();
		my %replace=();
		$sth=$dbh->prepare("SELECT * from $form->{work_table} WHERE $form->{work_table_id}=? OR path=? OR path like ? order by path");
		$sth->execute($cur_id, qq{$from_path/$cur_id}, qq{$from_path/$cur_id/%});
		my $flag=0;
		while(my $items=$sth->fetchrow_hashref()){

			unless($flag){
				$items->{parent_id}=$to_parent_id;
			}
			else{

			}
			$flag=1;
			my $sth2=$dbh->prepare("INSERT INTO $form->{work_table}() values()");
			$sth2->execute();
			#print "id: $items->{$form->{work_table_id}} path: $items->{path}<br/>";
			my $new_id=$sth2->{mysql_insertid};

			my $path=$items->{path};
			$path=~s|^$from_path(\/.+)?$|$new_path$1|;
			#print "заменяем $from_path на $new_path<br>path: $path<br>";
			foreach my $r (%replace){
				if($replace{$r}){
					$items->{parent_id}=~s/$r/$replace{$r}/;
					$path=~s!/$r(/|$)!/$replace{$r}$1!;
					#print "заменяем $r на $replace{$r}<br>path: $path<br/>";
				}
			}
			$items->{path}=$path;
			$replace{$items->{$form->{work_table_id}}}=$new_id;
			$items->{$form->{work_table_id}}=$new_id;
			#print "id: $items->{$form->{work_table_id}} path: $path<br/><br/>";
			#print "id: $items->{$form->{work_table_id}}<br/>parent_id: $items->{parent_id}<br/><br/>";
			my @values=();
			my @fieldlist=();
			foreach my $f (@fields){
				#print "f: $f<br>";
				#print "v: $items->{$f}<br>";
				push @values, $items->{$f};
				push @fieldlist, $f.'=?';
			}
			my $sth3=$dbh->prepare("UPDATE $form->{work_table} SET path=?, parent_id=?, ".join(',',@fieldlist)." WHERE $form->{work_table_id}=?");
			$sth3->execute($items->{path},$items->{parent_id}, @values, $items->{$form->{work_table_id}});
			$sth3->finish();
		}

	}


}
elsif($form->{action} eq 'show_razdel'){


	print &get_razdels($mode);
	exit;
}


&out;


sub out{
	my($out_left, $out_right)=(&get_razdels('left'),&get_razdels('right'));
	print qq{
		<html>
			<head>
				<title>Копирование или перемещение разделов дерева</title>
				<link href='ncss/base.css' rel="stylesheet" />
	<link href='ncss_css/ie.css' rel="stylesheet" />
	<link href='ncss/window.css' rel="stylesheet" />
	<link href="css/style.css" rel="stylesheet" type="text/css" media="screen, projection" />
	<!--// Незабываем прописывать и здесь путь к файлам и в файле ie.css  //-->
	<!--[if lte IE 8]>
	<link href="css/ie.css" rel="stylesheet" type="text/css" media="screen, projection" />
	<script type="text/jscript" src="javascript/ie.pack.js"></script>
	<![endif]-->
			</head>
			<style>
				body {margin: 20px;}
				table.main {width: 100%; border-collapse: collapse;}
				table.main td {width: 50%; border: 1px solid black; padding: 5px; vertical-align: top;}
				img {border: none;}
				table.razdels{
					border-collapse: collapse;
				}
				table.razdels td{border: none;}
				h1{font-size: 16pt}
			</style>
			<script>
				function show_razdel(id, mode){
					document.getElementById('parent_id_'+mode).value=id;

					if(mode=='left')
						razdels='out_left'
					else razdels='out_right'
					loadDoc('$script?mode='+mode+'&config=$form->{config}&action=show_razdel&parent_id_'+mode+'='+id, razdels);
				}

				function loadDoc(link, id)
				{
  				var req;
  				if (window.XMLHttpRequest){
     				req = new XMLHttpRequest();
  				} else if (window.ActiveXObject) {
     				req = new ActiveXObject("Microsoft.XMLHTTP");
  				}

  				if (req){
     				req.onreadystatechange = function () {
        			// Статус 4 означает успешное выполнение
        			if (req.readyState == 4) {

          			if (req.status == 200) {
             			var response = req.responseText;
             			document.getElementById(id).innerHTML = response;
          			} else {alert('Невозможно получить данные с сервера: ' + req.statusText);}
        			}
     				}

     				link = link + '&random=' + Math.random();
     				req.open("GET", link, true);
     				req.send(null);
  				}
				}

				function copy(id, mode){
					var parent_id_right=document.getElementById('parent_id_right').value;
					var parent_id_left=document.getElementById('parent_id_left').value;
					var action='move'
					if(document.getElementById('copy').checked)
						action='copy'

					document.location.href='$script?cur_id='+id+'&action='+action+'&mode='+mode+'&config=$form->{config}&parent_id_left='+parent_id_left+'&parent_id_right='+parent_id_right

				}
			</script>
			<body>
				<div class="h2">Копирование и перемещение разделов</div>
				<div class="mb-10">
				<input class="mr-10" type='checkbox' id='move' $move_checked value='1' OnClick="if( document.getElementById('move').checked) document.getElementById('copy').checked=false; else document.getElementById('move').checked=true">переместить
				<input class="mr-10" type='checkbox' id='copy' value='1' $copy_checked OnClick="if( document.getElementById('copy').checked) document.getElementById('move').checked=false; else document.getElementById('copy').checked=true">копировать
				</div>
				<table class='main'>
					<tr>
						<td id='out_left'>
							$out_left
						</td>
						<td id='out_right'>
							$out_right
						</td>
					</tr>
				</table>
			</body>
		</html>
	};
}

sub get_razdels{
	my $mode=$_[0]; # left или right
	my $parent_id;
	if($mode eq 'left'){$parent_id=$parent_id_left}
	elsif($mode eq 'right'){$parent_id=$parent_id_right}
	else{
		return "ошибка выбора режима";
	}
	unless($parent_id){$parent_id=0}
	my $path=qq{<a href='javascript: show_razdel(0,"$mode")'>Главная </a>};
	if($parent_id>0){
		my $sth=$dbh->prepare("SELECT path from $form->{work_table} where $form->{work_table_id}=$parent_id");
		$sth->execute();
		my $pathstr=$sth->fetchrow()."/$parent_id";
		$sth->finish();
		while($pathstr=~m|\/(\d+)|g){
			my $id=$1;
				if($id){
					 my $sth=$dbh->prepare("SELECT $form->{header_field} from $form->{work_table} where $form->{work_table_id}=$id");
					 $sth->execute();
					 $path.=qq{ / <a href='javascript: show_razdel($id, "$mode")'>}.$sth->fetchrow().qq{</a>};
					 $sth->finish();
				}
		}
	}
	my $sql_query;
	if($form->{tree_use}){
		my $where=qq{where parent_id=$parent_id};
		$where.=" OR (parent_id is null)" unless($parent_id);
		$where=&add_where_foreign_key($where);
		$sql_query="SELECT $form->{header_field}, $form->{work_table_id} FROM $form->{work_table} $where";		
	}
	else{
		$sql_query="SELECT $form->{header_field}, $form->{work_table_id} FROM $form->{work_table}";
	}

	my $sth=$dbh->prepare($sql_query);
	$sth->execute();

	my $out=qq{
		<p>$path</p>
		<input type='hidden' id='parent_id_$mode' value='$parent_id'>
		</p><table class="razdels">
	};
	while( my ($header, $id)=$sth->fetchrow()){
		$out.=q{<tr><td>};
		if($mode eq 'right' && $form->{tree_use}){
			$out.=qq{<a href="javascript: copy($id,'$mode')">&lt;&lt</a>&nbsp;&nbsp;}
		}

		if ( $form->{tree_use} ){
			$out.=qq{<a href='javascript: show_razdel($id, "$mode")'>$header</a>};
		}
		else {
			$out.=qq{$header};
		}

		if($mode eq 'left' && $form->{tree_use}){
			$out.=qq{&nbsp;&nbsp;<a href="javascript: copy($id,'$mode')">&gt;&gt</a>}
		}
		$out.=q{</td></tr>};
	}
	$sth->finish();
	$out.=q{</table>};
	return $out;
}


sub add_where_foreign_key{
	my $where=shift;
	if($form->{work_table_foreign_key}=~m/^[a-z0-9_\-]+$/ && $form->{work_table_foreign_key_value}=~m/^\d+$/){
			if($where){
				$where.=' AND ';
			}
			else{
				$where=' WHERE ';
			}
			$where.=qq{ ($form->{work_table_foreign_key}=$form->{work_table_foreign_key_value})};

	}
	return $where;
}
