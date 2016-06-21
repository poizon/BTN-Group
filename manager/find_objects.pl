#!/usr/bin/perl

use CGI::Carp qw (fatalsToBrowser);
use CGI qw(:standard);
use CGI qw(params);
use DBI;
use struct_admin_find;
use lib 'lib';
use read_conf;
print "Content-type: text/html; charset=cp1251\n\n";
my $config=param('config');

our $form=&read_config($config);


$perpage=20;
$AND_OR=param('and_or');
if($AND_OR){$AND_OR='OR'} else {$AND_OR='AND'}

my $page=param('__page');
if(!$page){$page=0}



$form->{page}=$page;

$dbh = $form->{dbh};

my $on_plug=param('plugin'); # проверяем, включен ли плагин
if($on_plug){
        my $plugin;
        # проверяем, есть ли такой плагин в конфиге:
        foreach my $plug_name (@{$form->{plugins}}){
                if($plug_name=~m/^find::$on_plug$/){
                        # плагин включен в конфиге! исполняем
                        open F, qq{./plugins/find/$on_plug};
                        while(<F>){$code.=$_;}close F;
                        eval($code);
                        print $@ if($@);
                        &get_where_find($form);
                        &get_result($form);
                        eval($plugin->{code_out});
                        print $@ if($@);
                        exit;
                }
                
        }
}
else{
}


#print "add_where: $form{add_where}</br>";
# получаем условие поиска (where), способ сортировки (order)
&get_where_find($form);
#exit;
# получаем контент (результаты поиска)
&get_result($form, $dbh);

# выводим шаблон с контекстом
&out_find_results($form);
