#!/usr/bin/perl

 use warnings;
 use Data::Dumper;
 use DBI;
 use CGI qw(:standard);
 use CGI::Carp qw(fatalsToBrowser);
 use Template;

 do '/www/sv-cms/htdocs/manager/connect';
 use vars qw($DBname $DBhost $DBuser $DBpassword);
 my $dbh=DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);    
   
 print "Content-type: text/html\n\n";
 
#/**************************************************
#/* Опции для проектов и сервисов
#/*
#/*  имеется дополняемый набор опций option [id, header, description, NAME, /type/, /icon/]
#/*  опции линкуются в таблицу options_links по project_id и struct_id и туда жа записывется VALUE, значение опции 
#/* 
#/**************************************************

 #incoming params [project_id], [struct_id]
 my $project_id = param('project_id');
 my $struct_id = param('struct_id');
 
 my $params;
 
 #current action, show options list if empty
 my $action = param('action');
 if ( $action !~ m/list|edit|add/i ) { $action = 'list'; }
     
 #check work table existance
 &check_setup;

 #service(struct) options
 if ( $struct_id && $struct_id =~ m/\d+/ ) {
   my $info = struct_info($struct_id);
   
   if ( $action eq 'list' ) {
      
   }
   elsif ( $action eq 'add' ) {
      
      $$params{TMPL_VARS}{ACTION} = 'add';
      $$params{TMPL_VARS}{OPTIONS} = $dbh->selectall_arrayref("select * from options where enabled=1 order by id desc", {Slice=>{}});
      
   }
   
   render({ template=>$action});
   
 }
 #project options
 else {
   
 }

 
 #/******************************************
 # SUBS
 
 sub check_setup {

 my $def = "
      CREATE TABLE IF NOT EXISTS struct_".$project_id."_options_links (
      id int(11) NOT NULL AUTO_INCREMENT,
      header varchar(255) NOT NULL DEFAULT '',
      project_id int(11) NOT NULL DEFAULT '0',
      enabled tinyint(1) DEFAULT '1',
      struct_id int(11) DEFAULT NULL,
      value text,
      option_id int(11) NOT NULL,
      PRIMARY KEY (id),
      KEY project_id (project_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=cp1251;  
    ";
 
 
   my $sth = $dbh->table_info('', '', "struct_".$project_id."_options_links");
   
      if ( $sth->fetch() ) {
         #print "EXIST!";
      }
      else {
           $dbh->do($def) || warn;
      }
 }
 
 sub struct_info {
   #number, struct_id
   my $in = shift;
   my $info;
   
   if ( $in =~ /\d+/ ) {
      $info = $dbh->selectrow_hashref("select * from struct where struct_id=".$in);
      return $info;
   }
 }
 
 sub render {
     
    my $in = shift;
    
       $$params{TMPL_VARS}{project_id} = $project_id;
       $$params{TMPL_VARS}{struct_id} = $struct_id;
    
     eval(q{ 
        my $template = Template->new(
        {
            INCLUDE_PATH => "./templates/",
            COMPILE_EXT => '.tt2',
            COMPILE_DIR=>'./parser_scripts/tmp',
            CACHE_SIZE => 512,
            PRE_CHOMP  => 1,
            POST_CHOMP => 1,
            DEBUG_ALL=>1,
            #EVAL_PERL=>1,
            
        
        });
        $template -> process("options_".$in->{template}.".tmpl", $params->{TMPL_VARS} ) || croak "output::add_template: template error: ".$template->error();
        });
      
        if($@){
            print $@;
        }
 }