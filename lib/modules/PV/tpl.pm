package tpl;

###
### Writted by Pavel Vasilyev, June 2009
###
### How to use:
### my $t = tpl->new();
### $t->header('TEST');
### $t->output('tpl.html', {a=>1});
### $t->redirect('ya.ru');
###
### $t->setcookie('name', $value);
###
### VERSION 1.3
###

use strict;
use Template;
use CGI;

#####################################################################
sub header {
	my ($self, $data) = @_;

	unless ($self->{'HEADER_OK'}) {
		$self->{'HEADER_OK'} = 1;

		print "Content-type: text/html; charset=windows-1251\n\n";
	}

	print $data if $data;
}
#####################################################################
sub redirect {
	my ($self, $url) = @_;

	my $q = CGI->new;
	print $q->redirect($url);
}
#####################################################################
=c
sub setcookie {
	my ($self, $name, $value) = @_;

	unless ($self->{'HEADER_OK'}) {
		$self->{'HEADER_OK'} = 1;

		print "Content-type: text/html; charset=windows-1251\n";

	}

	print "Set-Cookie: $name=$value\n\n";
}
=cut
#####################################################################
sub output {
	my ($self, $filename, $hash, $wh) = @_;

	$self->{'HEADER_OK'} = 1 if $wh;

	$self->header;
	$self->{'TPL'}->process($filename, $hash) || die "Template process failed: ", $self->{'TPL'}->error(), "\n";
}
############################## SERVICE ##############################
sub new {
	my $class = shift;
	my $self = {};
	my $path = shift || "templates";

	$self->{'TPL'} = Template->new({
		INCLUDE_PATH => $path,
		POST_CHOMP   => 1,
	}) || die "$Template::ERROR\n";

	return bless($self);
}



return 1;
