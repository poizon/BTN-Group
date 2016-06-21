my $t = '255,255,255';
$t = 'asd' unless($t =~ m/^(\d+),(\d+),(\d+)$/);
print $t;

