package Order;
use Digest::MD5 qw(md5_hex);
use strict;
use warnings;
use lib $ENV{DOCUMENT_ROOT}.'/lib/';
use appdbh;

our $VERSION = '0.0.1';

sub new {
	my ($cls,$self) = @_;
	return bless $self, $cls;
}


return 1;
