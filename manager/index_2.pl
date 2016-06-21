#!/usr/bin/perl

use CGI;
use Data::Dumper;

use lib 'lib';
use auth;

my $a = auth->new();

print "Content-Type: text/html\n\n";
if($a eq 'True'){
print qq{
        <title>SvCMS - $ENV{HTTP_HOST}</title>
<frameset cols="200,*" scrolling="auto" frameborder="no" framespacing="0">
           <frame name="left" frameborder="no" marginheight="0" marginwidth="0" src="left.pl">
           <frame name="main" scrolling="auto" topmargin=5 leftmargin=5 marginheight="0" frameborder="yes" marginwidth="0" src="start.html">
</frameset>
};
}
else{
	print "Доступ запрещен!";
}

