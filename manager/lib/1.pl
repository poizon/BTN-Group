#!/usr/bin/perl
use strict;
use warnings;
use Plugins::pic;

my $t = Plugins::Pic->new();
my $photos = {
	src =>'test.jpg',
	dst =>[
		{outfile=>'',width=>'100',height=>'200',left=>'100',top=>'100'},
	]
};

