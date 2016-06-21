package Picedit;
use strict;
use warnings;
use Image::Magick;

sub new {
	my($class,$opt) = @_;
	my $self = {};
	$self->{opt}=$opt if($opt);
	return bless $self,$class;
}

sub crop {}
sub resize {}
sub scale {}

1;
