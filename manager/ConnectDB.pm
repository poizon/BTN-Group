package ConnectDB;

use DBI;
use strict;

sub new { bless {} }

sub connect {
    my ($self,$DBuser,$DBhost,$DBname,$DBpassword)=@_;
    my $dbh;

	$dbh = DBI->connect("DBI:mysql:$DBuser:$DBhost","$DBname","$DBpassword",,{ RaiseError => 1 }) || die($!);
	$dbh -> do("SET NAMES cp1251");
	return $dbh;
}

1;
