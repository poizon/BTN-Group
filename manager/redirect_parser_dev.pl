#!/usr/bin/perl
 use Data::Dumper;
 use DBI;
 use CGI qw(:standard);
 use CGI::Carp qw(fatalsToBrowser);
 use Template;
 use Spreadsheet::ParseExcel;
 use Encode;# 'from_to';

my $params;

#print "Content-type: text/html; charset=cp1251\n\n";
print header(-type=>'text/html',-charset=>'cp1251');

my $struct;
$struct->{fields} = [
  { name => 'url_from', description => 'Откуда', regexp => '[a-z0-9\-\.\_\?\=\/\:]+$' },
  { name => 'url_to', description => 'Куда', regexp => '[a-z0-9\-\.\_\?\=\/\:]+$' },
  { name => 'enabled', description=> 'Вкл' },
];

my $project_id = param('project_id');
$$params{TMPL_VARS}{project_id} = $project_id;

if ( param('action') eq 'upload' ) {
  if ( $project_id =~ /^\d+$/ ) {
    my $f = &uploadFile();    
    preview($f->{full_path});             
  }
  else { exit; }
}
elsif ( param('action') eq 'import' ) {
  import();
}
else {
  $$params{TMPL_VARS}{page_type} = 'upload';
  &render();    
}
 
unlink($f->{full_path});
 
sub uploadFile {
  my $info;
  #сохраняем файл, запоминаем его имя и полный путь к файлу
  my $orig_filename=param('file');
  if($orig_filename=~m/([^.]+)$/){
    my $ext=$1;
    # генерим случайное имя файла:
    my $a='123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    my $filename='';
    foreach my $k (1..50){ $filename.=substr($a,int(rand(length($a))),1) }           
    $filename.='.'.$ext;
    open F,qq{>/www/sv-cms/htdocs//temp/$filename};
    binmode F;
    print F while(<$orig_filename>);
    close F;   
    $info->{full_path}  = qq{/www/sv-cms/htdocs/temp/$filename};
    $info->{filename}   = $orig_filename;
  }
  return $info;  
}

#/*****************************************************************/#
#/*****************************************************************/#
#/*****************************************************************/#

sub render {
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
        $template -> process("pp_redirect_dev.tmpl", $params->{TMPL_VARS} ) || croak "output::add_template: template error: ".$template->error();
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
  if ( !defined $workbook ) { die $parser->error(), ".\n"; }        
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
          if ($cell && $cell->{Code} && $cell->{Code}=~/ucs2/){
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
    my @p = param;
    my $cnum,$cfld;
    my @cf,@cn;
    foreach(@p){
      if($_ =~ /colomnnumber_(\d+)/){
        push @{$cnum},param($_);
	push @cn,param($_);
      }
      elsif($_ =~ /colomnfield_/){
        push @{$cfld}, param($_);
        push @cf, param($_);
      }
    }
    
    my $filename = param('filename');
    my $data = parser($filename);
    do './connect';
    use vars qw{$DBname $DBhost $DBuser $DBpassword $CMSpath};
    my $dbh = DBI->connect("DBI:mysql:$DBname:$DBhost", $DBuser, $DBpassword, , {RaiseError => 1}) || die($!);
    if(param('clear') eq '1'){
      $sql="DELETE FROM site_redirect WHERE project_id = $project_id";
      $dbh->do($sql);
    }

    $c=0;
    foreach my $row (@{$data}){
      $i=0;
      $values='';
      $columns='';
      my @d;
      foreach(@cf){
	push @d, $row->{rows}[$i]->{value};
	$values.='?,';
	$i++;
      }
      $columns=join(',',@cf);
      $values.=$project_id;

      $sql="REPLACE INTO site_redirect($columns,project_id) VALUES($values)";
      $dbh->do($sql,undef,@d);#($d->{$cfld->[0]},$d->{$cfld->[1]},$d->{$cfld->[2]},$d->{$cfld->[3]},$d->{$cfld->[4]},$d->{$cfld->[5]}));
      $c++;
      @d=undef;
    }
    print "Обработано $c записей.";
#    foreach ( @{$struct->{fields}} ) {
#      
#    }
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

#		print 'Строк '.$row_max.' в файле';
#		print 'Начинать с '.param('datastart').' строки';
                
                #row_max строки, col_max столбцы
                if ( $row_max>0 &&  $col_max>0 ) {
                # если данные не нулевые
                
                    my @data;
                    my $z;
                    
                        if ( $row_max > 1) { $z=$row_max; } else { $z = 1; }
                        
                            for ( my $r=param('datastart') ? param('datastart') : 0; $r<=$z; $r++ ) {                    

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
