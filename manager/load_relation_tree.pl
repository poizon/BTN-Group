#!/usr/bin/perl
#use Strict;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
use DBI;
use struct_admin;
use lib 'lib';
use read_conf;
my $c=new CGI;
our $sys;
our $sys->{config}=$c->param('config');
our $sys->{field_name}=$c->param('field');
our $sys->{key}=$c->param('key'); # значение дл€ внешнего ключа
my $parent_id=$c->param('parent_id');
my $action=$c->param('action');
print "Content-type: text/html; charset=windows-1251\n\n";

#unless(-f "./conf/$sys->{config}"){
#    print "конфиг отсутствует";
#    exit;
#}
our $form=&read_config;
do "./conf/$sys->{config}";

#if(-f "connect_$config"){
#    do "connect_$config";
#}
#else{
#    do './connect';
#}


our $dbh = $form->{dbh}; #DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
my $this_element=&return_element;
#print "this_element: $this_element";
$this_element->{tree_table}=$this_element->{relation_table} unless($this_element->{tree_table});
$this_element->{tree_header}=$this_element->{relation_table_header} unless($this_element->{tree_header});
$this_element->{tree_table_id}=$this_element->{relation_table_id} unless($this_element->{tree_table_id});
# «десь нужно отлавливать старый формат
	
    if(!$this_element->{relation_table}=~m/^[a-z_0-9]+$/){
        print "нет элемента relation_table<br/>";
        exit;
    }
    if(!$this_element->{relation_table_header}=~m/^[a-z_0-9]+$/i){
        print "нет элемента relation_table_header<br/>";
        exit;
    }
    if(!$this_element->{relation_table_id}=~m/^[a-z_0-9]+$/i){
        print "нет элемента relation_table_id<br/>";
        exit;
    }

    our $order='';
    if($element->{tree_order}=~m/^[a-z_0-9]+$/){
        $order=qq{order by $element->{tree_order}};
    }

{

    # получаем список тех разделов, которые €вл€ютс€ выбранными:
    #print "SELECT $this_element->{tree_table_id} from $this_element->{relation_save_table} WHERE $form->{work_table_id}=$sys->{key}";
    if($sys->{key}=~m/^\d+$/){
        my $sth=$dbh->prepare("SELECT $this_element->{relation_table_id} from $this_element->{relation_save_table} WHERE $form->{work_table_id}=$sys->{key}");
        $sth->execute();
        our %SELECTED_TREE_ID=();
        while(my $tree_id=$sth->fetchrow()){
            $SELECTED_TREE_ID{$tree_id}=1;
        }
    }
    # вывод корн€ дерева со всеми подразделами

    $sth=$dbh->prepare("SELECT $this_element->{relation_table_header},$this_element->{relation_table_id} from $this_element->{relation_table} WHERE (parent_id=0 OR parent_id is null) $order");
    #print "SELECT $this_element->{tree_header},$this_element->{tree_table_id} from $this_element->{tree_table} WHERE (parent_id=0 OR parent_id is null) $order";
    $sth->execute();
    while(my ($header,$tree_id)=$sth->fetchrow()){
        my $checked='';
        $checked=' checked' if($SELECTED_TREE_ID{$tree_id});
        print<<eof;
               <div id='$this_element->{name}$tree_id' class='tree'>
                <a href="javascript: switch_element($tree_id,'$this_element->{name}')">
                    <img src='/icon/plusx.gif' id='ico_$this_element->{name}\_$tree_id'></a><input type='checkbox' name='$this_element->{name}' value='$tree_id' $checked> $header
eof


                print &out_included($this_element,$tree_id);

        print '</div>';
    }
    $sth->finish();
}

sub out_included{
    # выводим элементы, наход€щиес€ внутри ветки
    my ($this_element,$parent_id)=@_;
    my $sth=$dbh->prepare("SELECT $this_element->{relation_table_header},$this_element->{relation_table_id} from $this_element->{relation_table} WHERE parent_id=? $order");
    $sth->execute($parent_id);
    print "<div id='include_$this_element->{name}\_$parent_id' style='display: none;'>";
    if($sth->rows()){
        while(my ($header,$tree_id)=$sth->fetchrow()){
            my $checked='';
            $checked=' checked' if($SELECTED_TREE_ID{$tree_id});
            print<<eof;
                <div id='$this_element->{name}$tree_id'>
                  <a href="javascript: switch_element($tree_id,'$this_element->{name}')">
                    <img src='/icon/plusx.gif' id='ico_$this_element->{name}\_$tree_id'></a><input type='checkbox' name='$this_element->{name}' value='$tree_id' $checked> $header
eof

                print out_included($this_element,$tree_id);
            print '</div>';

        }
    }
    else{
            print 'пусто';
    }
    print "</div>";
    return '';
}

sub return_element{
    foreach my $element (@{$form->{fields}}){
        if($element->{type} eq 'relation_tree' and $element->{name} eq $sys->{field_name}){
            return $element;
        }
    }
    return 0;
}
