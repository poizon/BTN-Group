package API;
use strict;
use warnings;
use Attribute::Handlers;
use CGI qw(:standard);
use API::DB;

our $VERSION = '1.0.0';

sub new {
	my($class,$opt) = @_;
	my $self = {
		name => 'API',
		version => $VERSION,
		opt => $opt,
	};
	return bless $self, $class;
}

sub isAuth : ATTR(CODE) {
	my($package,$symbol,$referent,$attr,$data,$phase,$filename,$linenum) = @_;
	no warnings 'redefine';
	unless (is_auth($ENV{REMOTE_USER})){
		*{$symbol} = sub { 
			error_msg('403',"User '$ENV{REMOTE_USER}' dont have access");
#			print 
#			require Carp;
#			Carp::croak "Error auth\n";
		};
	}
}

sub is_auth ($) {
	my($login) = @_;
	$login = $ENV{REMOTE_USER} unless($login);
	return (defined($login) && $login eq 'isavnin' ? 1 : 0);
}

sub test_func : isAuth {
	print header(-type=>'text/html',-charset=>'windows-1251');
	print "asdasdasd";
}

sub error_msg ($$) {
	my($code,$msg) = @_;
	print header(-type=>'text/html',-charset=>'windows-1251',-status=>$code);
	print "<!doctype html><html><head><title>Error</title></head><body><h1>$code</h1><p><i>$msg</i></p></body></html>";
}
