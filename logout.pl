#!/usr/bin/perl
use strict;
use warnings;
use CGI qw(:standart :param);


my $q = new CGI;
exit print $q->redirect(-uri=>'http://'.$ENV{HTTP_HOST},-status=>'302');
