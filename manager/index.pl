#!/usr/bin/perl
use lib 'lib';
use auth;
use CGI qw/:standard :param/;
my $a = auth->new();

if(param('action') eq 'logout'){
	$a = 'False';
}

if($a eq 'True'){
	print header(-status=>200,-type=>'text/html',-charset=>'windows-1251');
	print qq{
		<title>SvCMS - $ENV{HTTP_HOST}</title>
		<frameset cols="200,*" scrolling="auto" frameborder="no" framespacing="0">
	           <frame name="left" frameborder="no" marginheight="0" marginwidth="0" src="left.pl">
	           <frame name="main" scrolling="auto" topmargin=5 leftmargin=5 marginheight="0" frameborder="yes" marginwidth="0" src="start.html">
		</frameset>
	};
}else{
	print header(-status=>401,-type=>'text/html',-charset=>'windows-1251');
	#exit print redirect(-uri=>'http://'.$ENV{HTTP_HOST},-status=>'301');
	#print qq{<h1>403</h1><h2>Ошибка авторизации!</h2>};
}
