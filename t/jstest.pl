#!/usr/bin/perl

BEGIN { require './t/test.pl' }

use Test::More;
use Encode 'decode_utf8';
use JE;

$je = new JE;
$je->new_function(peval => sub { local *ARGV = \@_; eval shift })
	->{forTesting}++;
$je->new_function($_ => \&$_)->{forTesting}++
	for grep /^\w/, @Test::More::EXPORT;

{
	local $/;
	$code = <DATA>;
}

my $tests;
while($code =~ /^\/\/ (\d+) tests?\b/gm) {
	$tests += $1;
}
plan tests => $tests if $tests;

$code = $je->compile(decode_utf8($code), $0, 3);
$@ and die __FILE__ . ": Couldn't compile $0: $@";
execute $code;
$@ and die __FILE__ . ": $0: $@";

1;