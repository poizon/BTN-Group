package Mail;

our $VERSION = '0.0.1';
our $params;

sub new {
	my($self)=@_;
	my $opt = {To=>[],Files=>[],HTML=>[]};
	return bless $opt, $self;
}

sub add_file {
	my($self) = @_;
	push @{$self->{Files}},{}

}

sub send {}

return 1;
