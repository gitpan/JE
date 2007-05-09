#!perl  -T

use Test::More tests => 5;
use strict;



#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN {
	use_ok 'JE::Object::Function'; # see if it loads without je loaded
	use_ok 'JE';
}


#--------------------------------------------------------------------#
# Test 3-4: object creation

my $j = new JE;
isa_ok $j, 'JE';
my $func = new JE::Object::Function $j, sub { 34 };
isa_ok $func, 'JE::Object::Function';


#--------------------------------------------------------------------#
# Test 5: Overloading

is &$func, 34, '&{} overloading';

diag 'TO DO: Finish writing this script.';

