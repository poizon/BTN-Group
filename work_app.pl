#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use YAML::XS qw/LoadFile/;
use Data::Dumper;

use lib 'lib';

my $cfg = LoadFile($ENV{DOCUMENT_ROOT}.'/conf/config.yaml');

print "Content-Type:text/html;\n\n";
#print Dumper($cfg);
#print "<h1>$cfg->{DB}->{host}</h1>";
