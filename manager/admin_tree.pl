#!/usr/bin/perl
use DBI;
use CGI qw(:standard);
use CGI::Carp qw (fatalsToBrowser);
use Encode;
use lib 'lib';
use read_conf;
use Data::Dumper;
# Инструмент для создание деревьев

print "Content-type: text/html; charset=windows-1251\n\n";


our $form=&read_config;
#print Dumper($form->{fields});
$form->{header_field}='header' unless($form->{header_field});
$form->{sort_field}='sort' unless($form->{sort_field});


our $dbh=$form->{dbh};
our $script='admin_tree.pl';
our $parent_id=param('parent_id');
unless($parent_id=~m/^\d+$/){$parent_id=0}


if($form->{action} eq 'add_razdel'){
	&add_razdel;
}
elsif($form->{action} eq 'delete_razdel'){
	&delete_razdel;
}
elsif($form->{action} eq 'move_up'){
	&move_up;
}
elsif($form->{action} eq 'move_down'){
	&move_down;
}
elsif($form->{action} eq 'show_razdel'){
	print &get_razdels;
	exit;
}

our $razdels=&get_razdels;
&out;

sub out{
	print<<eof;
<html>
	<head>
	<link href='ncss/base.css' rel="stylesheet" />
<link href='ncss_css/ie.css' rel="stylesheet" />
<link href='ncss/window.css' rel="stylesheet" />
	<link href="css/style.css" rel="stylesheet" type="text/css" media="screen, projection" />
<!--// Незабываем прописывать и здесь путь к файлам и в файле ie.css  //-->
<!--[if lte IE 8]>
<link href="css/ie.css" rel="stylesheet" type="text/css" media="screen, projection" />
<script type="text/jscript" src="javascript/ie.pack.js"></script>
<![endif]-->
		<title>Администрирование текстовых разделов</title>
		<style>
			
			img {border: none;}
		
		</style>
		<script src='./ajax.js'></script>
		<script src='./main.js'></script>
		<script>
				var go_new=0;
				function add_razdel(){
					go_new=1;
					document.getElementById('add').innerHTML="<form name='add_new_razdel' OnSubmit='save_new_razdel(1); return false;'><input type='text' name='newheader' id='newheader' onKeyPress='if(event.keyCode==27)save_new_razdel(0)'> <input type='submit' value='ok'> <input type='button' value='отменить' OnClick='save_new_razdel(0)'></form> "
					document.add_new_razdel.newheader.focus();
				}

				function save_new_razdel(v){
					go_new=0;
					if(v){
						v=document.getElementById('newheader').value;
						v=encodeURIComponent(v);
						var par=document.getElementById('parent_id').value;
						loadDoc('$script?config=$form->{config}&action=add_razdel&h='+v+'&parent_id='+par, 'razdels');
					}
					document.getElementById('add').innerHTML="<a href='javascript: add_razdel()'><img src='/icon/new.gif'></a>"
					return false;
				}

				function delete_razdel(id){
						var par=document.getElementById('parent_id').value;
						loadDocAsync('./delete_element.pl?config=$form->{config}&id='+id, 200,200);
						show_razdel(document.getElementById('parent_id').value)

				}

				function move_up(id){
					var par=document.getElementById('parent_id').value;
					loadDoc('$script?config=$form->{config}&action=move_up&id='+id+'&parent_id='+par, 'razdels');
				}

				function move_down(id){
					var par=document.getElementById('parent_id').value;
					loadDoc('$script?config=$form->{config}&action=move_down&id='+id+'&parent_id='+par, 'razdels');
				}

				function show_razdel(id){
					document.getElementById('parent_id').value=id;
					loadDoc('$script?config=$form->{config}&action=show_razdel&parent_id='+id, 'razdels');
				}

				function loadDoc(link, id){
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

		</script>
	</head>
	<body onkeypress = "if(event.charCode==110 && !go_new){ add_razdel();} ">
	<div class="wrapper">
	<div class="content">
		<div class="h2">$form->{title}</div>
		<input type='hidden' id='parent_id' value='$parrent_id'>
		<div id='razdels'>
			$razdels
		</div>
		</div>
		</div>
	</body>
</html>
eof
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

sub get_razdels{

	my $path=q{<a href='javascript: show_razdel(0)'>Главная </a>};
	my $cur_level=0; # Уровень вложенности в дерево
	my $where;
	if($parent_id>0){
		$where=qq{where $form->{work_table_id}=$parent_id};
		$where=&add_where_foreign_key($where);
		my $sth=$dbh->prepare("SELECT path from $form->{work_table} $where");
		$sth->execute();
		my $pathstr=$sth->fetchrow()."/$parent_id";
		$sth->finish();
		while($pathstr=~m/\//g){$cur_level++;}
		while($pathstr=~m|\/(\d+)|g){
			my $id=$1;
				if($id){
					 my $where=qq{$form->{work_table} where $form->{work_table_id}=$id};
					 $where=&add_where_foreign_key($where);
					 my $sth=$dbh->prepare("SELECT $form->{header_field} from $where");
					 $sth->execute();
					 $path.=" / <a href='javascript: show_razdel($id)'>".$sth->fetchrow()."</a>";
					 $sth->finish();
					 undef($where);
				}

		}
	}


	my $sql_query;
	my $where='';
	my $add_select_fields='';
	if($form->{sort}){
		$add_select_fields=qq{, $form->{sort_field}};
	}
	if($form->{tree_use}){

		$sql_query="SELECT $form->{header_field}, $form->{work_table_id},path $add_select_fields FROM $form->{work_table}";
		unless($parent_id){ # для верхнего уровня
			$where=qq{ where (parent_id is null or parent_id=0) };
		}
		else{ # для последующих уровней
			$where=qq{ $form->{work_table} where parent_id=$parent_id};
		}
	}
	else{
		$sql_query="SELECT $form->{header_field}, $form->{work_table_id} $add_select_fields FROM $form->{work_table}";
	}
	$where=&add_where_foreign_key($where);
	$sql_query.=qq{ $where };
	$sql_query.=qq{ORDER BY $form->{sort_field}} if($form->{sort});
	my $sth=$dbh->prepare($sql_query);
	$sth->execute();
	my $out=qq{
		<div class="hr"></div><p class="mb-10 blue1 ml-40 f-14">$path</p><div class="hr"></div>		
		<table class="razdels">
	};

	my $count_query;
	my $count_record=0; my $count_uniq_sort; my $min_id = 0;
#print "Content-type: text/html\n\n";
	while( my $item=$sth->fetchrow_hashref()){
		my $header=$item->{$form->{header_field}};
		my $id=$item->{$form->{work_table_id}};
		if(!$min_id){
			$min_id = $id
		}
		elsif($id < $min_id){
			$min_id = $id
		}
		
		my $path=$item->{path};
		my $sort=$item->{$form->{sort_field}};
		if($form->{sort}){
			$count_record++;
			$count_uniq_sort->{$sort}=1;
		}
		#print "s: $sort<br>";
		my $where='';
		$count_query="SELECT count(*) from $form->{work_table}";
		if($form->{tree_use}){
			if($id){ # parent_id указан
				$where=" WHERE parent_id=$id";
			}
			else{ # parent_id не указан
				$where.=" WHERE (parent_id is null)";
				$id=0;
			}
		}
		$where=&add_where_foreign_key($where);
		$count_query.=qq{ $where};

		my $sth_count=$dbh->prepare($count_query);
		$sth_count->execute();
		my $cnt=$sth_count->fetchrow();
		my $edit_button=qq{<a href="javascript: openWindow('./edit_form.pl?action=edit&config=$form->{config}&id=$id',800,800)"><img src='/icon/edit.gif'></a>};
		#my $delete_button=qq{<a href='javascript: delete_razdel($id)'><img src='/icon/delete.gif'></a>};
				$delete_button=qq{<a href="javascript: 
						if(confirm('Вы действительно хотите удалить запись?'))
							delete_razdel($id)">
								<img src="/icon/delete.gif">
					</a>
				};

		my $sort='';
		if($form->{sort}){
			$sort=qq{<td><a href='javascript: move_up($id)'><img src='/icon/up.jpg'></a>&nbsp;<a href='javascript: move_down($id)'><img src='/icon/down.jpg'></a></td>};
		}

		if($form->{tree_use} && (!$form->{max_level} || ($cur_level<$form->{max_level}))){ # Если дерево -- возможно войти в раздел
			$out.=qq{<tr>$sort<td><a href='javascript: show_razdel($id)'>$header</a> <span class="psmall">($cnt)</span></td><td>$edit_button</td><td>$delete_button</td></tr>};
		}
		else{
			$out.=qq{<tr>$sort<td>$header </td><td>$edit_button</td><td>$delete_button</td></tr>};
		}
	}
	$sth->finish();
	my $changed_sort=0;
	if($form->{sort}){
		if($count_record && $count_record!=scalar(keys(%{$count_uniq_sort}))){ # какая-то херня с сортировкой ; надо бы поправить
			$changed_sort=1;
			my $sth=$form->{dbh}->prepare(&add_where_foreign_key("UPDATE $form->{work_table} set sort=$form->{work_table_id}-$min_id+1 where 1 "));
			$sth->execute();
			
		}
#		print "min_id: $min_id ; count_record: $count_record ; count_uniq_sort: ".scalar(keys(%{$count_uniq_sort}));
	}
	$out=qq{$out</table>};

	$out=qq{<div class="mb-10 ml-20 f-11" id='add'><a class="blue" href='javascript: add_razdel()'><img class="mr-5" src='/icon/new.gif'>Добавить</a></div>$out} if(!$form->{max_level} || ($cur_level<$form->{max_level}));
	if($changed_sort){
		#print "chanded_sort";
		$out = &get_razdels;
	}
	return $out;
}

sub add_razdel{
	my $h=param('h');

	if($h){
		Encode::from_to($h, 'utf8', 'cp1251');
		my $cur_path='';
		my $cur_sort=0;
		if($parent_id){
				my $sth=$dbh->prepare("SELECT path from $form->{work_table} where $form->{work_table_id}=?");
				$sth->execute($parent_id);
				$cur_path=$sth->fetchrow();
				$sth->finish();
		}
		else{$parent_id=0}
		if($form->{sort}){
			my $qw='';
            if($form->{tree_use}){
                $qw="SELECT max($form->{sort_field}) from $form->{work_table}";
                if($parent_id){
					$qw.=" WHERE parent_id=$parent_id";
				}
				else{
					$qw.=" WHERE parent_id is NULL";
				}
            }
            else{
                $qw="SELECT max($form->{sort_field}) from $form->{work_table}";
            }
            
            my $sth=$dbh->prepare($qw);
			$sth->execute();
			$cur_sort=$sth->fetchrow();
			$sth->finish();
			$cur_sort++;
		}

		if($parent_id){
			$cur_path.=qq{/$parent_id};
		}

		my $sql_query;
		my @values=();
		my @fields=();

		if($form->{tree_use}){ # Дерево
			if($parent_id){ # для каскадного удаления нужно, чтобы parent_id на нулевом уровне был  NULL
				if($form->{sort}){
					@fields=($form->{header_field}, 'parent_id', 'path', $form->{sort_field});
					@values=($h, $parent_id, $cur_path,$cur_sort);
				}
				else{
					@fields=($form->{header_field}, 'parent_id', 'path');
					@values=($h, $parent_id, $cur_path);
				}
			}
			else{
				if($form->{sort}){
					@fields=($form->{header_field}, 'path', $form->{sort_field});
					@values=($h, $cur_path, $cur_sort);
				}
				else{
					@fields=($form->{header_field}, 'path');
					@values=($h, $cur_path);
				}
			}
		}
		else{
			@values=($h);
			if($form->{sort}){
				@fields=($form->{header_field},$form->{sort_field});
				push @values, $cur_sort;
			}
			else{
				@fields=($form->{header_field});
			}

		}

		if($form->{work_table_foreign_key}=~m/^[a-z0-9_\-]+$/ && $form->{work_table_foreign_key_value}=~m/^\d+$/){
			push @fields, $form->{work_table_foreign_key};
			push @values, $form->{work_table_foreign_key_value};
		}
		#print "v::";
		eval($form->{events}->{before_insert});
		my $vopr= join ",",(split //,("?"x ($#fields+1)));
		$sth=$dbh->prepare("INSERT INTO $form->{work_table}(".join(',',@fields).") values($vopr)");
		$sth->execute(@values);
		$form->{id}=$sth->{mysql_insertid};
		#print "id: $form->{id} $form->{events}->{after_insert}";
		eval($form->{events}->{after_insert});
		print $@ if($@);
		$sth->finish();
	}

	print &get_razdels;
	exit;
}


sub delete_razdel{

	my $id=$form->{id};
	if($id=~m/^\d+$/){
			# Удаляем элемент
			my $where=qq{ WHERE $form->{work_table_id}=?};
			$where=&add_where_foreign_key($where);
			my $sth=$dbh->prepare("DELETE FROM $form->{work_table} $where");
			undef($where);
			$sth->execute($id);
			$sth->finish();
			# Удаляем все дочерние элементы
			if($form->{tree_use}){
				my $where=qq{ WHERE path like '%/$id/%' or path like '/%$id'};
				$where=&add_where_foreign_key($where);
				$sth=$dbh->prepare("DELETE FROM $form->{work_table} $where");
				undef($where);
				$sth->execute();
				$sth->finish();
			}
			undef($sth);
	}

	print &get_razdels;
	exit;
}

sub move_up{
	my $id=$form->{id};
	if($id=~m/^\d+$/){
		$cur_sort=0 unless($cur_sort);
		my ($q, $q2, $cur_sort, $cur_parent);
		if($form->{tree_use}){
			$q="SELECT $form->{sort_field},parent_id from $form->{work_table} WHERE ".&add_where_foreign_key(qq{$form->{work_table_id}=?});
			$sth=$dbh->prepare($q);
			$sth->execute($id);
			if($sth->rows()){
				($cur_sort, $cur_parent)=$sth->fetchrow();
				my $parent_where;
				if($cur_parent){
					$parent_where=qq{parent_id=$cur_parent}
				}
				else{
					$parent_where=q{parent_id is null}
				}
				
				$q2="SELECT $form->{sort_field}, $form->{work_table_id} from $form->{work_table} WHERE ".&add_where_foreign_key(qq{$parent_where and $form->{sort_field}<$cur_sort})." order by $form->{sort_field} desc  limit 1";
			}
		}
		else{
			$q="SELECT $form->{sort_field} from $form->{work_table} WHERE ".&add_where_foreign_key(qq{$form->{work_table_id}=?});
			my $sth=$dbh->prepare($q);
			$sth->execute($id);
			($cur_sort, $cur_parent)=$sth->fetchrow();
			$q2="SELECT $form->{sort_field}, $form->{work_table_id} from $form->{work_table} WHERE ".&add_where_foreign_key(qq{$form->{sort_field}<$cur_sort})." order by $form->{sort_field} desc  limit 1";
		}


		if($q2){
				$sth=$dbh->prepare($q2);
				$sth->execute();
				if($sth->rows()){
					my ($new_sort, $other_id)=$sth->fetchrow();
					$dbh->do("UPDATE $form->{work_table} SET $form->{sort_field}=$new_sort WHERE $form->{work_table_id}=$id");
					$dbh->do("UPDATE $form->{work_table} SET $form->{sort_field}=$cur_sort WHERE $form->{work_table_id}=$other_id");
				}
				$sth->finish();
		}
	}
	print &get_razdels;
	exit;
}

sub move_down{
	my $id=$form->{id};
	if($id=~m/^\d+$/){
		my $q1,$q2, $cur_sort, $cur_parent;

		if($form->{tree_use}){
			my $where=qq{$form->{work_table_id}=$id};
			$where=&add_where_foreign_key($where);
			$q1="SELECT $form->{sort_field},parent_id from $form->{work_table} WHERE $where";
			my $sth=$dbh->prepare($q1);
			$sth->execute();
			if($sth->rows()){
				($cur_sort, $cur_parent)=$sth->fetchrow();
				my $parent_where;
				if($cur_parent){
					$parent_where=qq{parent_id=$cur_parent}
				}
				else{
					$parent_where=q{parent_id is null}
				}
				$parent_where=&add_where_foreign_key($parent_where);
				
				$q2="SELECT $form->{sort_field}, $form->{work_table_id} from $form->{work_table} WHERE $parent_where and $form->{sort_field}>$cur_sort order by $form->{sort_field}  limit 1";
			}
			$sth->finish();
		}
		else{
			my $where=qq{$form->{work_table_id}=$id};
			$where=&add_where_foreign_key($where);
			$q1="SELECT $form->{sort_field} from $form->{work_table} WHERE $where";			
			my $sth=$dbh->prepare($q1);
			$sth->execute();
			if($cur_sort=$sth->fetchrow()){
				my $wh=&add_where_foreign_key(qq{$form->{sort_field}>$cur_sort});
				$q2="SELECT $form->{sort_field}, $form->{work_table_id} from $form->{work_table} WHERE $wh order by $form->{sort_field}  limit 1";
			}
			$sth->finish();
		}

		if($q2){

				$sth=$dbh->prepare($q2);
				$sth->execute();

				if($sth->rows()){
					my ($new_sort, $other_id)=$sth->fetchrow();
					$dbh->do("UPDATE $form->{work_table} SET $form->{sort_field}=$new_sort WHERE $form->{work_table_id}=$id");
					$dbh->do("UPDATE $form->{work_table} SET $form->{sort_field}=$cur_sort WHERE $form->{work_table_id}=$other_id");
				}
		}
	}
	print &get_razdels;
	exit;
}
