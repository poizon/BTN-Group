#!/usr/bin/perl
 use Data::Dumper;
 use DBI;
 use CGI qw(:standard);
 use CGI::Carp qw(fatalsToBrowser);
 use Template;
 use Spreadsheet::ParseExcel;
 use Encode;# 'from_to';

my $params;



print "Content-type: text/html; charset=cp1251\n\n";

#/**********************************************
# Структура таблицы promo

my $struct;
 $struct->{fields} = [
    {
        name=>'url',
        description=>'URL',
        
    },
    {
        name=>'promo_title',
        description=>'Заголовок',
    },
    {
        name=>'promo_description',
        description=>'Описание',
    },
    {
        name=>'promo_keywords',
        description=>'Ключевые слова',
    },
    {
        name=>'add_tags',
        description=>'Дополнительные тэги',
    },    
    {
        name=>'promo_body',
        description=>'BODY',
    },
   ];

#/***********************************************   
#  Логика 
#

 my $project_id = param('project_id');

    $$params{TMPL_VARS}{project_id} = $project_id;


 if ( param('action') eq 'upload' ) {
    if ( $project_id =~ /^\d+$/ ) {
        
        my $f = &uploadFile();
        
        preview($f->{full_path});
        
        
    }
    else {
        exit;
    }
 }
 elsif ( param('action') eq 'import' ) {
    import();
 }
 else {

    $$params{TMPL_VARS}{page_type} = 'upload';
    &render();    
 }
 
 
 unlink($f->{full_path});
 
#/*****************************************************************/#
#/*****************************************************************/#
#/*****************************************************************/#
 
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
                open F,qq{>/www/sv-cms/htdocs//temp/$filename};
                    binmode F;
                    print F while(<$orig_filename>);
                    #print while(<$orig_filename>);
                close F;
                    
        $info->{full_path}  = qq{/www/sv-cms/htdocs/temp/$filename};
        #$info->{full_path}  = qq{./temp/$filename};
        
        $info->{filename}   = $orig_filename;
        
        }

   return $info;  
}

#/*****************************************************************/#
#/*****************************************************************/#
#/*****************************************************************/#

sub render {

    #my $in = shift;    
        
     eval(q{ 
        my $template = Template->new(
        {
            INCLUDE_PATH => "./",
            COMPILE_EXT => '.tt2',
            COMPILE_DIR=>'../temp/',
            CACHE_SIZE => 512,
            PRE_CHOMP  => 1,
            POST_CHOMP => 1,
            DEBUG_ALL=>1,
            #EVAL_PERL=>1,
            
        
        });
        $template -> process("pp_uploadform.tmpl", $params->{TMPL_VARS} ) || croak "output::add_template: template error: ".$template->error();
        });
     
        if($@){
            print $@;
        }
}

#/*****************************************************************/#
#/*****************************************************************/#
#/*****************************************************************/#

sub preview {
        
        my $in = shift;
        
        my $parser   = Spreadsheet::ParseExcel->new();
        my $workbook = $parser->parse($in);

            if ( !defined $workbook ) {
                die $parser->error(), ".\n";
            }        
        
           for my $worksheet ( $workbook->worksheets() ) {

                my ( $row_min, $row_max ) = $worksheet->row_range();
                my ( $col_min, $col_max ) = $worksheet->col_range();
                
                #row_max строки, col_max столбцы
                if ( $row_max>0 &&  $col_max>0 ) {
                # если данные не нулевые
                
                    my @data;
                    my $z;
                    
                        if ( $row_max<9) { $z=$row_max; } else { $z = 9; }
                        
                            for ( my $r=0; $r<=$z; $r++ ) {                    

                                my @rows;
                            
                                for ( my $c=0; $c<=$col_max; $c++ ) {
        

                        
                                    my $cell=$worksheet->get_cell($r,$c);
                                    my $val=($cell)?$cell->unformatted:'';

                            
                			if($cell && $cell->{Code} && $cell->{Code}=~/ucs2/){
                                            $val=encode('CP1251',decode("UCS-2BE", $val));
                                        }

                                        $val=~s/^\s+|\s+$//g;
                                       
                                        push @rows, { 'col' => $c, 'row' => $r, 'value' => $val };

                                }                                
                                push @data, { 'rows'=> \@rows };
                            }
                            
                    $$params{TMPL_VARS}{DATA} = \@data;
                    $$params{TMPL_VARS}{page_type} = 'preview';
                    $$params{TMPL_VARS}{filename} = $in;
                    $$params{TMPL_VARS}{STRUCT} = $struct->{fields};
                    &render(); 

                            
                }
           }
}

#/*****************************************************************/#
#/*****************************************************************/#
#/*****************************************************************/#

sub import {
    print "Импорт";
    
    my $filename = param('filename');
    
    my $data = parser($filename);
    
    print Dumper ($data);
    
    foreach ( @{$struct->{fields}} ) {
      
    }
}

#/*****************************************************************/#
#/*****************************************************************/#
#/*****************************************************************/#

sub parser {
   
        my $in = shift;
        
        my $parser   = Spreadsheet::ParseExcel->new();
        my $workbook = $parser->parse($in);

            if ( !defined $workbook ) {
                die $parser->error(), ".\n";
            }        
        
           for my $worksheet ( $workbook->worksheets() ) {

                my ( $row_min, $row_max ) = $worksheet->row_range();
                my ( $col_min, $col_max ) = $worksheet->col_range();
                
                #row_max строки, col_max столбцы
                if ( $row_max>0 &&  $col_max>0 ) {
                # если данные не нулевые
                
                    my @data;
                    my $z;
                    
                        if ( $row_max<9) { $z=$row_max; } else { $z = 9; }
                        
                            for ( my $r=0; $r<=$z; $r++ ) {                    

                                my @rows;
                            
                                for ( my $c=0; $c<=$col_max; $c++ ) {
        

                        
                                    my $cell=$worksheet->get_cell($r,$c);
                                    my $val=($cell)?$cell->unformatted:'';

                            
                			if($cell && $cell->{Code} && $cell->{Code}=~/ucs2/){
                                            $val=encode('CP1251',decode("UCS-2BE", $val));
                                        }

                                        $val=~s/^\s+|\s+$//g;
                                       
                                        push @rows, { 'col' => $c, 'row' => $r, 'value' => $val };

                                }                                
                                push @data, { 'rows'=> \@rows };
                            }
                            
                    return \@data;
                }
           }  
}