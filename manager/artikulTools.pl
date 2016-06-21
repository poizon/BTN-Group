#!/usr/bin/perl -w

 use Data::Dumper;
 use DBI;
 use CGI qw(:standard);
 use CGI::Carp qw(fatalsToBrowser);
 use Template;

 print "Content-type: text/html\n\n";
 
 do './connect';

 our $dbh = DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
     $dbh->do("SET names CP1251");

# my $type = param('type');
#
# if ( $type ne 'xml' && $type ne 'csv' ) {
#            die "No file type specified! exit.";
# }

 my $project_id = param('project_id');

 if ( param('action') eq 'form_send' ) {
    if ( $project_id =~ /^\d+$/ ) {
        
        my $f = &uploadFile();
        do "./parser_scripts/".$project_id."_".$type.".pl";
        
        &parse({ file=>$f->{full_path}, type=>$type });
    }
    else {
        exit;
    }
 }
 else {

    &render({ project_id=>$project_id, type=>$type, });
    #&html();
    
 }
 
 

sub render {
    
    my $params;
    
    my $in = shift;
    
       $$params{TMPL_VARS}{project_id} = $in->{project_id};
       $$params{TMPL_VARS}{type} = $in->{type};
    
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
        $template -> process("photoBundleForm.tmpl", $params->{TMPL_VARS} ) || croak "output::add_template: template error: ".$template->error();
        });
     
        if($@){
            print $@;
        }
}


sub uploadFile {
    
    my $info;
   
    #сохраняем файл, запоминаем его имя и полный путь к файлу
    my $orig_filename=param('file');
        if($orig_filename=~m/([^.]+)$/ && $orig_filename =~ /\.zip/i ){
            
            my $len = $ENV{'CONTENT_LENGTH'};
            
            
            my $ext=$1;
           # генерим случайное имя файла:
           #my $a='123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
           #my $filename='';
    
            #foreach my $k (1..50){
            #    $filename.=substr($a,int(rand(length($a))),1)
            #}
            
            #$filename.='.'.$ext;
            $filename = "project_".$project_id."photobundle";
            $filename.='.zip';
            
            my $size = 0;
            
                #open F,qq{>./temp/$filename};
                open F,qq{>/www/sv-cms/htdocs/files/project_$project_id/$filename};
                    binmode F;
                    while(<$orig_filename>) {
                        print F $_;
                        $size+=length $_; 
                        
                        print $size;
                        
                    }
                    #print while(<$orig_filename>);
                close F;
                    
        $info->{full_path}  = qq{/www/sv-cms/htdocs/manager/parser_scripts/tmp/$filename};
        #$info->{full_path}  = qq{./temp/$filename};
        
        $info->{filename}   = $orig_filename;
        
        }

   return $info;  
}