#!/usr/bin/perl
# Быстрое сохраниние фотографий для товаров 
#Made by PMK
#files: fast_load_photo_good.js; ./template/fast_load_photo_good.tmpl; ./javascript/jquery-1.3.2.js; ./javascript/ajaxupload;  ./javascript/lightbox/jquery.lightbox-0.5.css; ./javascript/lightbox/jquery.lightbox-0.5.pack.js; 
use DBI;
use Template;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
#use strict;
our $params;
do './connect';

my $dbh = DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
print "Content-type: text/html; charset=windows-1251\n\n";


if(param('action') eq 'start'){
#Первый запуск. Вывод 1 уровня рубрикатора
    our $template = Template->new({
             INCLUDE_PATH => './templates'
    });

    &start;

    undef($params);
    sub start{
        &init;
        if(defined $good_table){
        # получаем 1 уровень рубрикатора
        $params->{select_rub_level_1}=&get_rub_level({
            rubricator_table=>$rubricator_table,
            rubricator_table_id=>$rubricator_table_id,
            level=>'1',
        });
        
        $template -> process('fast_load_photo_good.tmpl', $params) || die($!);
        }else{
            print "Таблица товаров отсутствует.";
        }
    }

}elsif(param('action') eq 'all_goods'){
    &init;
    my $count_good_from=param('count_good_from');
    print &all_goods({
        good_table=>$good_table,
        good_table_id=>$good_table_id,
        count_good_from=>$count_good_from
    });
}elsif(param('action') eq 'get_rub_level'){
    &init;
    my $level=param('level')+1;
    my $rubricator_id=param('rubricator_id');
    my $count_good_from=param('count_good_from');
    
    print &get_rub_level({
        rubricator_table=>$rubricator_table,
        rubricator_table_id=>$rubricator_table_id,
        good_table=>$good_table,
        good_table_id=>$good_table_id,
        level=>$level,
        rubricator_id=>$rubricator_id,
        count_good_from=>$count_good_from
        
    });
}elsif(param('action') eq 'more_goods'){
    &init;
    my $rubricator_id=param('rubricator_id');
    my $count_good_from=param('count_good_from');

    print &more_goods({
        good_table=>$good_table,
        good_table_id=>$good_table_id,
        level=>$level,
        rubricator_id=>$rubricator_id,
        count_good_from=>$count_good_from
    });
}elsif(param('action') eq 'del_photo'){
    &init;  
    my $good_id=param('good_id');

    print &del_photo({
        good_table=>$good_table,
        good_table_id=>$good_table_id,
        good_id=>$good_id
    });
}elsif(param('action') eq 'upload_photo'){
    &init;  
    my $good_id=param('good_id');
    my $file=param('myfile');
    print &upload_photo({
        good_table=>$good_table,
        good_table_id=>$good_table_id,
        good_id=>$good_id,
        file=>$file
    });
}elsif(param('action') eq 'count_all_goods'){
    &init;
    my $rubricator_id=param('rubricator_id');
    print &count_all_goods({
        good_table=>$good_table,
        rubricator_id=>$rubricator_id,
    });
}





#subs
sub init{
    # узнаём, из какой структуры тянем рубрикатор
    our $sth=$dbh->prepare("SELECT project_id from manager where login = ?");
    $sth->execute($ENV{REMOTE_USER});
    our $project_id=$sth->fetchrow();

    $sth=$dbh->prepare("SELECT options from project_group_site where project_id=?");
    $sth->execute($project_id);
    our $rubricator_table; our $rubricator_table_id;
    our $good_table; our $good_table_id;
    if(my $options=$sth->fetchrow()){ # типовой!
        $rubricator_table='rubricator';
        $rubricator_table_id='rubricator_id';
        $good_table='good';
        $good_table_id='good_id';
    }else{#Не типовой проект
        $sth=$dbh->prepare("SELECT table_name FROM struct where project_id=? and (table_name='struct_".$project_id."_rubricator' or table_name='rubricator')");
        $sth->execute($project_id);
        if(my $table_name=$sth->fetchrow()){
            $rubricator_table=$table_name;
            $rubricator_table_id='rubricator_id';
        }

        $sth=$dbh->prepare("SELECT table_name FROM struct where project_id=? and (table_name='struct_".$project_id."_good' or table_name='good')");
        $sth->execute($project_id);
        if(my $table_name=$sth->fetchrow()){
            $good_table=$table_name;
            $good_table_id='good_id';
        }
    }
}

sub get_rub_level{
    my $par=shift;
    my $query='';
    my $select_rub='';
    my $good_list='';
    my $count_good_from=$par->{count_good_from};
    if($par->{rubricator_table}=~/struct/){ 
        if(defined $par->{rubricator_id}){
            $query="SELECT $par->{rubricator_table_id},header FROM $par->{rubricator_table} where parent_id=$par->{rubricator_id} order by sort";
        }else{
            $query="SELECT $par->{rubricator_table_id},header FROM $par->{rubricator_table} where parent_id is NULL order by sort";
        }
    }else{
        if(defined $par->{rubricator_id}){
            $query="SELECT $par->{rubricator_table_id},header FROM $par->{rubricator_table} where project_id=$project_id and parent_id=$par->{rubricator_id} order by sort";
        }else{
            $query="SELECT $par->{rubricator_table_id},header FROM $par->{rubricator_table} where project_id=$project_id and parent_id is NULL order by sort";
        }
    }
    my $sth=$dbh->prepare($query);
    $sth->execute();
    my $list=$sth->fetchall_arrayref({});
    
    if(scalar(@{$list})){
        $select_rub="<br><label for='select_rub_".$par->{level}."'>".$par->{level}." уровень: </label><select class='select_rub' id='select_rub_".$par->{level}."'><option value='0'>--Выберите рубрику--</option>";
        foreach my $tmp (@{$list}){ 
            $tmp->{header}=~s/\"/\'/g;
            $select_rub.="<option value='".$tmp->{$par->{rubricator_table_id}}."'>".$tmp->{header}."</option>";
        }
        $select_rub.="</select>";
        if($par->{level}!=1){       
            return qq{({"body":"$select_rub"})};
        }else{
            return $select_rub;     
        }
    }else{
        if($par->{good_table}=~/struct/){           
            $query=qq{SELECT $par->{good_table_id},header, photo, concat('/files/project_$project_id/good/',photo) as photo_and_path,concat('/files/project_$project_id/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 FROM $par->{good_table} where rubricator_id=$par->{rubricator_id} order by header limit $count_good_from,5};
        }else{
            $query=qq{SELECT $par->{good_table_id},header, photo, concat('/files/project_$project_id/good/',photo) as photo_and_path,concat('/files/project_$project_id/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 FROM $par->{good_table} where project_id=$project_id and rubricator_id=$par->{rubricator_id} order by header limit $count_good_from,5};
        }
        my $sth=$dbh->prepare($query);
        $sth->execute();
        my $list=$sth->fetchall_arrayref({});       
            
        if(scalar(@{$list})){
            my $count=0;
            $good_list="<br><hr><br><ul>";
            foreach my $tmp (@{$list}){ 
                $tmp->{header}=~s/\"/\'/g;
                $good_list.="<li><a id='good_a_".$tmp->{$par->{good_table_id}}."' href='".$tmp->{photo_and_path}."' rel='lightbox'><table><tr><td><img id='good_img_".$tmp->{$par->{good_table_id}}."' alt='' src='".$tmp->{photo_and_path_mini1}."'></td></tr></table></a><div class='o'><p><a href='/good/".$tmp->{$par->{good_table_id}}."'>".$tmp->{header}."</a></p><p><button class='button' value=''><font>Загрузить</font><br><img id='load' src='./javascript/ajaxupload/loadstop.gif'/></button><input type='hidden' value='".$tmp->{$par->{good_table_id}}."'></p><p><a href='javascript:del_photo(".$tmp->{$par->{good_table_id}}.")'>удалить</a></p></div></li>";
                $count++;           
            }
                $good_list.="</ul>";
            return qq{({"body":"$good_list","count":"$count"})};                    
        }else{
            return qq{({"body":"<br><hr><br><div  class='goods'>Товары для данной рубрики отсутствуют.</div>"})};
        }
    }

}


sub more_goods{
    my $par=shift;
    my $query='';
    my $good_list='';
    my $count_good_from=$par->{count_good_from};
    if($par->{good_table}=~/struct/){   
        $query=qq{SELECT $par->{good_table_id},header, photo, concat('/files/project_$project_id/good/',photo) as photo_and_path,concat('/files/project_$project_id/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 FROM $par->{good_table} where  rubricator_id=$par->{rubricator_id} order by header limit $count_good_from,5};
    }else{
        $query=qq{SELECT $par->{good_table_id},header, photo, concat('/files/project_$project_id/good/',photo) as photo_and_path,concat('/files/project_$project_id/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 FROM $par->{good_table} where project_id=$project_id and rubricator_id=$par->{rubricator_id} order by header limit $count_good_from,5};
    }
    my $sth=$dbh->prepare($query);
    $sth->execute();
    my $list=$sth->fetchall_arrayref({});       
            
    if(scalar(@{$list})){
        my $count=0;
        $good_list="<br><hr><br><ul>";
            foreach my $tmp (@{$list}){
                $tmp->{header}=~s/\"/\'/g;  
                $good_list.="<li><a id='good_a_".$tmp->{$par->{good_table_id}}."' href='".$tmp->{photo_and_path}."' rel='lightbox'><table><tr><td><img id='good_img_".$tmp->{$par->{good_table_id}}."' alt='' src='".$tmp->{photo_and_path_mini1}."'></td></tr></table></a><div class='o'><p><a href='/good/".$tmp->{$par->{good_table_id}}."'>".$tmp->{header}."</a></p><p><button class='button' value=''><font>Загрузить</font><br><img id='load' src='./javascript/ajaxupload/loadstop.gif'/></button><input type='hidden' value='".$tmp->{$par->{good_table_id}}."'></p><p><a href='javascript:del_photo(".$tmp->{$par->{good_table_id}}.")'>удалить</a></p></div></li>";
                $count++;           
            }
                $good_list.="</ul>";
            return qq{({"body":"$good_list","count":"$count"})};
            
    }else{
        return 0;
    }
}

sub get_body{
my $good_table=shift;
our $query='';
our $body; 
my $sth=$dbh->prepare("select t.value from domain d, template_group_site t where d.template_id=t.template_id and d.project_id=? and t.header=?");
$sth->execute($project_id,'resize_for_good');
if(my $value=$sth->fetchrow()){ # Типовой, определяем конфиг и разрешение
    $body='';
    open F, 'conf/good_ct1';
    while(<F>){$body.=$_};
    close F;
    $body=~s/\[%resize_for_good%\]/$value/gs;
}else{
    if($good_table=~/struct/){
        $sth=$dbh->prepare(qq{select body from struct where table_name="$good_table"});
    }else{
        $sth=$dbh->prepare(qq{select body from struct where project_id=$project_id and table_name="$good_table"});
    }
    $sth->execute();
    $body=$sth->fetchrow();
}
eval($body);
}


sub del_photo{
    my $par=shift;
    &get_body($par->{good_table});
    $sth=$dbh->prepare("select photo from $par->{good_table} where good_id=?");
    $sth->execute($par->{good_id});
    if(my $old_file=$sth->fetchrow()){
        foreach my $field (@{$form{fields}}){
            if($field->{type} eq 'file' && $field->{before_delete_code}){
                our $before_delete_code=$field->{before_delete_code};
                our $element;
                $element->{filedir}=$field->{filedir};
                #my $file_dir="tmp_for_fast_load_photo_good";
                $element->{filedir}=~s/\[%project_id%\]/$project_id/gs;
                $element->{file_for_del}=$old_file;
            }
        }
    }
    $sth=$dbh->prepare("UPDATE $par->{good_table} SET photo='' where good_id=?");
    $sth->execute($par->{good_id}); 
unlink("$element->{filedir}/$element->{file_for_del}");
eval($before_delete_code);
return 1;
}

sub upload_photo{
    my $par=shift;
    my $file_name;
    my $file=$par->{file};
    $file=~/\.(jpeg|jpg|gif|png|JPEG|JPG|GIF|PNG)/;  
    my $file_type=$1;
    if($file_type){
        my $file_word=rand_file_name();
        $file_name="$file_word.$file_type";
        &get_body($par->{good_table});  
        foreach my $field (@{$form{fields}}){
            if($field->{type} eq 'file' && $field->{converter}){
                our $converter=$field->{converter};
                my $file_dir=$field->{filedir};
                #my $file_dir="tmp_for_fast_load_photo_good";
                $file_dir=~s/\[%project_id%\]/$project_id/gs;
                our $full_file_name=qq{$file_dir/$file_name};
                my $input=$file_word;
                my $input_ext=$file_type;
                $converter=~s/\[%input%\]/$file_dir\/$input/gs;
                $converter=~s/\[%input_ext%\]/$input_ext/gs;
                $converter=~s/\[%filename%\]/$full_file_name/gs;
                $converter=~s/\n/ /gs;
                $converter=~s/\s+/ /gs;
                $converter=~s/\s+$//gs;
                $converter=~s/\s+/ /gs;

                $sth=$dbh->prepare("select photo from $par->{good_table} where good_id=?");
                $sth->execute($par->{good_id});
                if(my $old_file=$sth->fetchrow()){
                    our $before_delete_code=$field->{before_delete_code};
                    our $element;
                    $element->{filedir}=$file_dir;
                    $element->{file_for_del}=$old_file;
                    unlink("$element->{filedir}/$element->{file_for_del}");
                    eval($before_delete_code);
                }
            }
        }
        
        
        $sth=$dbh->prepare("UPDATE $par->{good_table} set photo=? where good_id=?");
        $sth->execute("$file_name",$par->{good_id});

        open (FILE, ">$full_file_name") || die "Can not open file! $full_file_name!";
        binmode FILE;
        flock (FILE, 2);
        print FILE while (<$file>);
        close FILE;
        chmod 0644, $file_name;
        `$converter`;
        $full_file_name=~s/^\.\.//;     
        return $full_file_name;
    }
}

sub rand_file_name{
    my @charArray=('8','a','b','7','c','d','e','5','f','g','i','j','k','2','m','n','4','p','s','t','9','u','q','6','v','w','z','3','h');
    my $word="";
    $word.= $charArray[int(rand(29))] for (1 .. 10);
    return $word;
}

sub all_goods{
    my $par=shift;
    my $query='';
    my $good_list='';
    my $count_good_from=$par->{count_good_from};
    if($par->{good_table}=~/struct/){   
        $query=qq{SELECT $par->{good_table_id},header, photo, concat('/files/project_$project_id/good/',photo) as photo_and_path,concat('/files/project_$project_id/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 FROM $par->{good_table} order by header limit $count_good_from,5};
    }else{
        $query=qq{SELECT $par->{good_table_id},header, photo, concat('/files/project_$project_id/good/',photo) as photo_and_path,concat('/files/project_$project_id/good/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 FROM $par->{good_table} where project_id=$project_id order by header limit $count_good_from,5};
    }
        
        my $sth=$dbh->prepare($query);
        $sth->execute();
        my $list=$sth->fetchall_arrayref({});       
        my $count=0;    
        if(scalar(@{$list})){
            $good_list="<br><hr><br><ul>";
            foreach my $tmp (@{$list}){
                $tmp->{header}=~s/\"/\'/g;  
                $good_list.="<li><a id='good_a_".$tmp->{$par->{good_table_id}}."' href='".$tmp->{photo_and_path}."' rel='lightbox'><table><tr><td><img id='good_img_".$tmp->{$par->{good_table_id}}."' alt='' src='".$tmp->{photo_and_path_mini1}."'></td></tr></table></a><div class='o'><p><a href='/good/".$tmp->{$par->{good_table_id}}."'>".$tmp->{header}."</a></p><p><button class='button' value=''><font>Загрузить</font><br><img id='load' src='./javascript/ajaxupload/loadstop.gif'/></button><input type='hidden' value='".$tmp->{$par->{good_table_id}}."'></p><p><a href='javascript:del_photo(".$tmp->{$par->{good_table_id}}.")'>удалить</a></p></div></li>";
                $count++;   
            }
                $good_list.="</ul>";
            return qq{({"body":"$good_list","count":"$count"})};                    
        }else{
            return 0;
        }
}

sub count_all_goods{
    my $par=shift;
    my $query='';
    if($par->{good_table}=~/struct/){       
        if($par->{rubricator_id}){
            $query=qq{SELECT count(*) FROM $par->{good_table} where rubricator_id=$par->{rubricator_id}};
        }else{
            $query=qq{SELECT count(*) FROM $par->{good_table}};
        }
    }else{
        if($par->{rubricator_id}){
            $query=qq{SELECT count(*) FROM $par->{good_table} where project_id=$project_id and rubricator_id=$par->{rubricator_id}};
        }else{
            $query=qq{SELECT count(*) FROM $par->{good_table} where project_id=$project_id};
        }
    }   
    my $sth=$dbh->prepare($query);
    $sth->execute();
    return $sth->fetchrow();
}print
