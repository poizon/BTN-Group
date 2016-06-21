#!/usr/bin/perl -w

use CGI qw(:standard);
$CGI::POST_MAX = 5*1024*1024;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

exit;
do 'hconf';



# by morg, 2007, wmorgan[]mail.ru
# 
# versions && upgrad^-e^s
# 0.1, 2007, oct
# 0.2, 2007, oct
# 0.3, 2007, oct



# где на внешке растут картинки
my $img_path = '/files';
# куда рисовать картинки
my $img_root_path = '../files/';
my $img_root_path_wt = '../files/';



my $prefix = param('prefix');
my $folder = param('folder');
if($folder){
           $folder = '/'.$folder.'/';
           $folder =~ s!\.!!g;
           $folder =~ s!//!/!g;
           $folder =~ s!/$!!;
           if($folder){
                      $img_root_path_wt .= $folder;
                      
                      unless(-d $img_root_path_wt){
                                 mkdir $img_root_path_wt;
                                 chmod 0777, $img_root_path_wt;
                      }
           }
           
}


print "content-type:text/html; charset=windows-1251;\n\n";
print q{
           <html><head><title>morgImgBrowser</title>
           <style>
           body, td, p{
                      font-family: verdana;
                      font-size: 10pt;
           }
           img.im{
                      margin: 10;
                      border: 1px solid gray;
                      cursor: pointer;
           }
           div.h{
                      width: 770;
                      height: 550;
                      
                      overflow: auto;
           }
           .oneelement{
                      width: 99%;
           }
           </style>
           
           <script language="javascript" type="text/javascript" src="/tinymce/tiny_mce.js"></script>
           <script language="javascript" type="text/javascript" src="/tinymce/tiny_mce_popup.js"></script>
           
           </head>
           <!--body onload="tinyMCEPopup.executeOnLoad('init();')"-->
           <body>
           <script>
           /*
           function returnImg(iist){
                      var win = tinyMCE.getWindowArg("window");
                      
                      win.document.getElementById(tinyMCE.getWindowArg("input")).value = iist;
                      
                      if (win.getImageData) win.getImageData();
                      
                      win.showPreviewImage(iist);
                      
                      tinyMCEPopup.close();
           }
           */
           
           var FileBrowserDialogue = {
                      init : function () {
                      },
                      mySubmit : function (iist) {
                                 var URL = iist;
                                 var win = tinyMCEPopup.getWindowArg("window");
                                 
                                 // insert information now
                                 win.document.getElementById(tinyMCEPopup.getWindowArg("input")).value = URL;
                                                       
                                 // for image browsers: update image dimensions
                                 if (win.ImageDialog.getImageData) win.ImageDialog.getImageData();
                                 
                                 win.ImageDialog.showPreviewImage(iist);
                                 
                                 // close popup window
                                 tinyMCEPopup.close();
                      }
           }
           
           
           
           </script>
};

my $p = param('p'); $p = 1 unless($p);

if(param('action') eq 'delete'){
	my $f = param('f');
	print "$img_root_path_wt/$f";
	unlink("$img_root_path_wt/$f") if($f =~ m![^/]+!si);
}

if($p == 1){
           
           #my @filelist = ();
           #my @modif = ();
           my %filelist = ();
           opendir(DR, $img_root_path_wt) or die "can't opendir $img_root_path_wt: $!";
           while(my $f = readdir(DR)){
                      next unless (-f "$img_root_path_wt/$f");
                      next unless ($f =~ /(gif|jpg|jpeg|gif|png|rar|zip|doc|pdf)$/i);
                      
                      
                      my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$img_root_path_wt/$f");
                      
                      if($filelist{$mtime}){
                                 while($filelist{$mtime}){
                                            $mtime++;
                                 }
                                 $filelist{$mtime} = $f;
                      }else{
                                 $filelist{$mtime} = $f;
                      }
           }
           closedir DR;
           
           my $cou = scalar keys %filelist;
           
           print 'Всего найдено файлов: ', $cou, "&nbsp;&nbsp; <a href='?p=2&prefix=$prefix&folder=$folder'>закачать новую фотографию &raquo;</a><hr size=0 width=99% align=center><div class=h>";
           
           foreach my $t(reverse sort keys %filelist){
                      my $f = $filelist{$t};
                      $f =~ m!\.([a-z0-9]+)$!si;
                      my $ext = $1;                      
                      my $fname = (grep{/^$ext$/} qw(gif jpg jpeg png))? "$img_path$folder/$f" : "ico/$ext.png";
                      print qq{
                      	<div style="float: left;" align="center">
                      		<img class=im src="$fname" border=0 width=120 height=120 onclick="FileBrowserDialogue.mySubmit('$img_path$folder/$f');">
                      		<center> <a href="?action=delete&f=$f">Удалить</a> </center>                      		
                      	</div>
                      };
           }
           
           print '</div>';
           
}else{
           my $filelist = param('filelist'); $filelist = 1 unless($filelist);
           
           if(param('allilyja')){
                      
                      
                      for(0..$filelist){
                                 my $i = $_+1;
                                 
                                 my $prm = 'fileload'.$i;
                                 my $file = param($prm);
                                 
                                 
                                 if($file){
                                            $file =~ /\.(.*?)$/;
                                            my $ext = $1; $ext = 'jpg' unless($ext);
                                            
                                            $file = $prefix.i_generator(15);
                                            
                                            
                                            open FL, '>'.$img_root_path_wt.'/'.$file.'.'.$ext or die 'dont open file for write';
                                            my $file = param($prm);
                                            binmode FL;
                                            binmode $file;
                                            while(<$file>){
                                                       print FL $_;
                                            }
                                            close FL;
                                 }
                                 
                      }
                      
           }
           
           print "&nbsp;&nbsp;&nbsp; <a href='?p=1&prefix=$prefix&folder=$folder'>&laquo; список фотографий</a><hr size=0 width=99% align=center>";
           print q{
                      <form method=post enctype='multipart/form-data'><input type=hidden name=p value=2>
                      <table border=0 width=99%>
                                 <tr><td width=40% align=right>количество файлов: &nbsp;
                                     <td width=60%>
                                     <select class=oneelement name=filelist onchange="location.replace('?p=$p&filelist='+this.value);">
           };
           for(1..12){
                      print qq{<option value="$_">$_</option>} unless($filelist == $_);
                      print qq{<option value="$_" selected>$_</option>} if($filelist == $_);
           }
           print q{
                                     </select>
           };
           
           
           for(1..$filelist){
                      
                      print qq{
                                 <tr><td width=40% align=right>Файл $_ &nbsp;
                                     <td width=60%><input class=oneelement name="fileload$_" type=file>
                                 
                      };
                      
           }
           
           print qq{
                                 <tr><td width=40% align=right>
                                     <td width=60%><input class="oneelement" type="submit" value="Закачать" name="allilyja">
                      </table>
                      <input type=hidden name=prefix value="$prefix">
                      <input type=hidden name=folder value="$folder">
                      </form>
           };
}


print q{
           </body>
           </html>
};


sub i_generator{
           my $count = shift; $count = 100 unless($count);
           my $res = '';
           my $swtch = int(rand 3);
           
           for(my $a = 0;$a<$count;$a++){
                      $res .= chr(97 + int(rand 26)) if ($swtch==0);
                      $res .= chr(48 + int(rand 10)) if ($swtch==1);
                      $res .= uc chr(97 + int(rand 26)) if ($swtch==2);
                      
                      $swtch = int(rand 3);
           }
           
           return $res;
           
}

