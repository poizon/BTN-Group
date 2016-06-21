package API::DB;
use strict;
use warnings;
use DBI;

our $VERSION = '1.0.0';

sub new {
	my($class,$opt) = @_;
	my $self = {
		name => 'API::DB',
		version => $VERSION,
		opt => $opt,
	};
	return bless $self, $class;
}

sub dbh($$$;$) {
	my($name,$host,$user,$password) = @_;
	my $dsn = 'DBI:mysql:'.$name.':'.$host;
	return DBI->connect($dsn,$user,$password) or die($!);
}
