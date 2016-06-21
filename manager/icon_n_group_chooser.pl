#!/usr/bin/perl

 use Data::Dumper;
 use DBI;
 use Data::Dumper;
 use DBI;
 use CGI qw(:standard);
 use CGI::Carp qw(fatalsToBrowser);

#  	do '/www/sv-cms/htdocs/manager/connect';
	do './connect';
	use vars qw($DBname $DBhost $DBuser $DBpassword);
	my $dbh=DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
        
        my $icons = $dbh->selectall_hashref("SELECT  *, id as id, concat('/files/project_3306/icons/',photo) as photo_and_path , concat('/files/project_3306/icons/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 , concat('/files/project_3306/icons/',substring_index(photo,'.',1),'_mini2','.',substring_index(photo,'.',-1)) as photo_and_path_mini2 , concat('/files/project_3306/icons/',substring_index(photo,'.',1),'_mini3','.',substring_index(photo,'.',-1)) as photo_and_path_mini3 FROM struct_icons", "id");
	my $groups = $dbh->selectall_hashref("SELECT  *, rubricator_id as id, concat('/files/project_3306/types_icons/',photo) as photo_and_path , concat('/files/project_3306/types_icons/',substring_index(photo,'.',1),'_mini1','.',substring_index(photo,'.',-1)) as photo_and_path_mini1 , concat('/files/project_3306/types_icons/',substring_index(photo,'.',1),'_mini2','.',substring_index(photo,'.',-1)) as photo_and_path_mini2 , concat('/files/project_3306/types_icons/',substring_index(photo,'.',1),'_mini3','.',substring_index(photo,'.',-1)) as photo_and_path_mini3 FROM struct_groups WHERE path='' ", "rubricator_id");


    #вывести список групп и иконок
    if ( param('action') ne 'form_send' ) {
        
        print  qq{
          <h1>Выбор иконки или группы для текущей сущности</h1>
          
          <form>
            <input type='hidden' name='action' value='form_send' />
            <p>Группы сервисов</p>
            
            <select name='group_id'>
                <option value='0'>---</option>
        };
        
                foreach ( @{ $groups } ) {
                    print "<option value='$_->{id}'>$_->{header}</option>\n"
                }
        
        print qq{
            </select>
            
            <p>Иконки для нетипичных сервисов</p>
              <select name='icon_id'>
                <option value='0'>---</option>
        };
        
                foreach ( @{ $icons } ) {
                    print "<option value='$_->{id}'>$_->{header}</option>\n"
                }
        
        print qq{
            </select>
            <input type='submit' value='Сохранить' />
            
            </form>
        
        };
    
    }
    #обновить таблицу struct и выставить нужную группу или иконку
    else {
    
        my $struct_id = param('id');
        my $icon_id = param('icon_id');
        my $group_id = param('group_id');
    
    }
				
				
