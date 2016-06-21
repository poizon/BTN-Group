#!/usr/bin/perl
 use Data::Dumper;
 use DBI;
 use CGI qw(:standard);
 use CGI::Carp qw(fatalsToBrowser);
 use Template;

 print "Content-type: text/html\n\n";

 my $type = param('type');

 if ( $type ne 'xml' && $type ne 'csv' ) {
            die "No file type specified! exit.";
 }

 my $project_id = param('project_id');

 if ( param('action') eq 'form_send' ) {
    if ( $project_id =~ /^\d+$/ ) {
        
        my $f = &uploadFile();
        my $pf = $ENV{DOCUMENT_ROOT}.'/manager/parser_scripts/'.$project_id.'_'.$type.'.pl';
#	print Dumper($f);
        do "./parser_scripts/".$project_id."_".$type.".pl";
#	do "$pf";
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
 
 
sub uploadFile {
    
    my $info;
   
    #сохраняем файл, запоминаем его имя и полный путь к файлу
    my $orig_filename=param('file');
        if($orig_filename=~m/([^.]+)$/){
            my $ext=$1;
           # генерим случайное имя файла:
           my $a='123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
           my $filename='';
    
            foreach my $k (1..50){
                $filename.=substr($a,int(rand(length($a))),1)
            }
            
            $filename.='.'.$ext;
                #open F,qq{>./temp/$filename};
                open F,qq{>/www/sv-cms/htdocs/manager/parser_scripts/tmp/$filename};
#		 open F,qq{>$CMSpath/manager/parser_scripts/tmp/$filename};
                    binmode F;
                    print F while(<$orig_filename>);
                    #print while(<$orig_filename>);
                close F;
                    
        $info->{full_path}  = qq{/www/sv-cms/htdocs/manager/parser_scripts/tmp/$filename};
#	$info->{full_path} = qq{$CMSpath/manager/parser_scripts/tmp/$filename};
        #$info->{full_path}  = qq{./temp/$filename};
        
        $info->{filename}   = $orig_filename;
        
        }

   return $info;  
}

sub render {
    
    my $params;
    
    my $in = shift;
    
       $$params{TMPL_VARS}{project_id} = $in->{project_id};
       $$params{TMPL_VARS}{type} = $in->{type};
    
     eval(q{ 
        my $template = Template->new(
        {
            INCLUDE_PATH => "./parser_scripts/template/",
            COMPILE_EXT => '.tt2',
            COMPILE_DIR=>'./parser_scripts/tmp',
            CACHE_SIZE => 512,
            PRE_CHOMP  => 1,
            POST_CHOMP => 1,
            DEBUG_ALL=>1,
            #EVAL_PERL=>1,
            
        
        });
        $template -> process("uploadform.tmpl", $params->{TMPL_VARS} ) || croak "output::add_template: template error: ".$template->error();
        });
     
        if($@){
            print $@;
        }
}

#sub html {
#    
# my $project_id = param('project_id');
# 
# print qq{
#   <html>
#   <h1>Загрузить CSV файл</h1>
#   
#   <form method="POST" enctype="multipart/form-data" action="">
#   <input type='hidden' name='action' value='form_send' />
#   <input type='hidden' name='project_id' value='$project_id' />
#   <input type='file' name='file' />
#    <input type='submit' value='Начать' />
#   </form>
#   
#   </html>
# };
# 
#    
#}
