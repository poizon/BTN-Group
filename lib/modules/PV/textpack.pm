package PV::textpack;

###
### Writted by Pavel Vasilyev, June 2009
###

use strict;
use CGI qw(:standard);
use HTML::Strip;
use Data::Dumper;

require Exporter;
use vars qw (@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw (Exporter);
@EXPORT_OK = qw ();
@EXPORT = qw (&word_limit &symbol_limit &cutHTML &generate);
$VERSION = 1.00;

### Ограничить текст по кол-ву слов
sub word_limit{
	my ($text, $limit) = @_;

	my @words = split /\s+/, $text;
	my $textsize = scalar(@words);
	pop @words for(($limit+1)..$textsize);
	push @words, '...' if ($limit < $textsize);

	return join(' ', @words);
}
### Ограничить текст по кол-ву символов
sub symbol_limit{
	my ($text, $limit) = @_;

	my @symb = split //, $text;
	my $textsize = scalar(@symb);
	pop @symb for(($limit+1)..$textsize);
	push @symb, '...' if ($limit < $textsize);

	return join('', @symb);
}
### Вырезать из текста HTML код
sub cutHTML {
	my $text = shift;

	my $hs = HTML::Strip->new();
	$text =~ s/\&[\da-zA-Z]+\;//gs;
	my $newtext = $hs->parse($text);
	$hs->eof;

	return $newtext;
}
### Сгенерировать строку из случайных символов
sub generate{
	my $length = shift;

	my @table = ('A'..'Z','1'..'9','a'..'z');
	my $str = '';
	for (1..$length) {
	    $str .= $table[int(rand(scalar(@table)))];
	}

	return $str;
}

1;
