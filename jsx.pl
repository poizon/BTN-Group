#!/usr/bin/perl

use warnings;
use JSON::XS;
use utf8;
use Data::Dumper;

print "Content-type:text/plain; charset=utf-8\n\n";


my $form={

base=>{
 config => 'content',
 db_engine => 'InnoDB',
 title => 'Статичные страницы',
 table => 'content',
 #work_table_id => 'content_id',
 make_delete => '1',
 default_find_filter => 'header',
 read_only => '0',
 tree_use => '0',
},
events=>{
 add_project_id=>'1',
},
plugins=>{
 add_h1=>1,
 transliterate=>1,
},

fields =>
[
	{
		type=>'hidden',
		name=>'id',
		sql=>'int(11) not null auto_increment',
		pk=>1,
	},
        {
                name => 'header',
                description => 'Название страницы',
                type => 'text',
		sql=>'varchar(250) not null default \'\'',
        },
        {
                name => 'body',
                description => 'Содержимое',
                type => 'wysiwyg',
		sql=>'text not null',
        },
        {
                name => 'url',
                description => 'url',
                type => 'text',
		unique=>1,
		sql=>'varchar(250) not null default \'\'',
        }
]
};

#	{
#		type=>'hidden',
#		name=>'user_id',
#		sql=>'int(11) not null default 0',
#		key=>1,
#	},

$coder = JSON::XS->new->utf8;

my $json =  JSON::XS->new->pretty->utf8->indent->encode ($form);

print $json;

my $json2 = $coder->decode ($json);
#$json2 = JSON::XS->new->pretty->utf8->decode ($json);

#print Dumper $json2;
#exit;

my $table = $json2->{base}->{table};
my $table_id;
my @fields;
my @uniques;
my $pk;
my @keys;
my @keys_strings;

foreach my $first ( keys ( %$json2 ) ) {	
	if ( $first eq 'fields' ) {
		foreach my $second ( @{ $json2->{$first} } ) {
			
			push @fields, $second->{name}." ".$second->{sql};
			
			if ( $second->{name} =~ m/id/us ) {
				$table_id = $second->{name};
			}
			if ( defined $second->{key} && $second->{key} eq '1') {
				push @keys, $second->{name};
			}			
			if ( defined $second->{unique} && $second->{unique} eq '1')  {
				push @uniques, $second->{name};
			}
			
			
		}
	}
}

#/id/ is alwais primary key
push @keys_strings, "PRIMARY KEY ($table_id) ";

#keys
if ( scalar(@keys)>0 ) {
	my $_keys = join(', ', map {  "KEY $_ ($_)" } @uniques );
	@keys=[];
	push @keys_strings, $_keys;
}

#unique keys
if ( scalar(@uniques)>0 ) {
	my $uni_keys = join(', ', map {  "UNIQUE KEY $_ ($_)" } @uniques );
	push @keys_strings, $uni_keys;
}

my $all_keys = join(', ', map {  $_ } @keys_strings );

my $string = "CREATE TABLE IF NOT EXISTS $table (".join(', ', @fields ).", $all_keys ) ENGINE=InnoDB ";

print $string;



