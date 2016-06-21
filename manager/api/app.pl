#!/usr/bin/perl
use strict;
use warnings;
use lib '/www/sv-cms/htdocs/lib';
use CGI qw(:standart);

use API;

my $app = API->new();
$app->test_func();
