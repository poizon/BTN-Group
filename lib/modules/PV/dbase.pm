package dbase;

###
### Writted by Pavel Vasilyev, June 2009
###
###
### How to use:
### my $dbh = dbase->new('localhost','dbname', 'login', 'password', 80);
### my $rows_affected = $dbh->query('insert into table set field=?', ('test'));
### my $row = $dbh->select_one('select * from table where table_id=?', (1));
### my ($data, $info) = $dbh->select_all('select * from table where field=?', ('test'));
### $dbh->last_insert_id();
### $dbh->quote($value);
###
### VERSION 1.2
###

use strict;
use DBI;
use Carp;
use Data::Dumper;

#####################################################################
sub query {
	my ($self, $statement, @bind_values, $attr) = @_;

	my $rows_affected = $self->{'DBH'}->do($statement, $attr, @bind_values) || die($!);

	return $rows_affected;
}
#####################################################################
sub select_one {
	my ($self, $statement, @bind_values) = @_;

	$self->{'DBH'}->do("SET lc_time_names = 'ru_RU'");
	my $sth = $self->{'DBH'}->prepare($statement);
	$sth->execute(@bind_values) || die($!);
	my $row = $sth->fetchrow_hashref;

	return $row;
}
#####################################################################
sub select_all {
	my ($self, $statement, @bind_values) = @_;

	$self->{'DBH'}->do("SET lc_time_names = 'ru_RU'");
	my $sth = $self->{'DBH'}->prepare($statement);
	$sth->execute(@bind_values) || die($!);

	my ($rows_total) = $self->{'DBH'}->selectrow_array("SELECT FOUND_ROWS()") if ($statement =~ /SQL_CALC_FOUND_ROWS/);

	my @data = ();
	my $count = 0;
	while(my $rq = $sth->fetchrow_hashref){
		$count++;
		push @data, $rq;
	}

	my $info = {};
	$info->{rows_total} = $rows_total;
	$info->{rows_selected} = $count;

	return \@data, $info;
}
#####################################################################
sub last_insert_id {
	my $self = shift;
	return $self->{'DBH'}->last_insert_id(undef, undef, undef, undef);
}
#####################################################################
sub quote {
	my ($self, $value, $data_type) = @_;
	return $self->{'DBH'}->quote($value, $data_type);
}
############################## SERVICE ##############################
sub new {
	my $class = shift;
	my $self = {};
	my ($dbhost, $dbname, $dbuser, $dbpassword, $dbport) = @_;

	if($dbhost && $dbname && $dbuser){
		$dbhost .= $dbport ? ':'.$dbport : '';
		$self->{'DBH'} = DBI->connect("dbi:mysql:$dbname:$dbhost", "$dbuser", "$dbpassword", {
			AutoCommit => 1,
			RaiseError => 1,
			PrintError => 1,
		}) || croak "Can't connect to database (".$DBI::errstr.")\n";

		$self->{'DBH'}->do("SET NAMES 'cp1251'");
		$self->{'DBH'}->do("SET CHARACTER SET 'cp1251'");
	}

	return bless($self);
}

return 1;
