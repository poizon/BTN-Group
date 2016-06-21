package App; 
require Exporter;
use strict;
use warnings;

@ISA = qw(Exporter);
@EXPORT = qw(run new);

use CGI qw/:standart/;
use CGI::Carp qw/fatalsToBrowser/;

BEGIN {}

sub new {
	my $class = @_;
	return bless {name=>'App',version=>'1.0'},$class;
}

sub run {
	my $self = @_;
	my $q = CGI->new;
	print $q->header(-type=>'text/html').$ENV{HTTP_HOST};
	return $q;
}

END {}

1;
