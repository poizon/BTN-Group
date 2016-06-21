#!/usr/bin/perl
use CGI;

print "Content-Type: text/html;\n\n";
print "Hello dolly<hr>";


$dir = '/www/sv-cms/htdocs/templates/utek/tmp';
$f_in = "$dir/1408075865.odt";
$f_out = "$dir/test.doc";

$e = "unoconv -f doc --output=\"$f_out\" $f_in";
print "$e\n<br>";
$r = system($e) or die "Error $!;";
print "<hr>";
print $r;
print "<hr>$!";
