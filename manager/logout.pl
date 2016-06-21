#!/usr/bin/perl
use strict;
use warnings;
use CGI qw(:standart :param);


my $q = new CGI;
#print "Content-Type:text/html\n\n";
#print $ENV{REMOTE_USER}
#print "USER: $ENV{REMOTE_USER};";
exit print $q->redirect(-uri=>'http://'.$ENV{HTTP_HOST},-status=>'302');
