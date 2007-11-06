#!perl  -T

# In here I'm throwing tests that don't quite fit anywhere else. All the
# other test files deal with an ECMAScript section (test written in JS) or
# the Perl interface of a module. Some tests written in Perl for JS run-
# time things have been thrown in here, for instance.

BEGIN { require './t/test.pl' }

use Test::More tests => 1;
use strict;
use utf8;

use JE;
our $j = JE->new;

#--------------------------------------------------------------------#
# Test 1: Attempt to free unreferenced scalar in perl 5.8.x
# fixed via a workaround for perl bug #24254

{
	my $x;
	local $SIG{__WARN__} = sub { $x = $_[0] };
	$j->eval('a(I_hope_thiS_var_doesnt_exist+b)');
	is $x, undef, '"Attempt to free unreferenced scalar" avoided';
}

