#!perl  -T

use Test::More tests => 6;
use strict;



#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN {
	use_ok 'JE::Object::Function'; # see if it loads without je loaded
	use_ok 'JE';
}


#--------------------------------------------------------------------#
# Tests 3-4: object creation

my $j = new JE;
isa_ok $j, 'JE';
my $func = new JE::Object::Function $j, sub { 34 };
isa_ok $func, 'JE::Object::Function';


#--------------------------------------------------------------------#
# Test 5: Overloading

is &$func, 34, '&{} overloading';

#--------------------------------------------------------------------#
# Test 6: no_proto makes construct die

{
	my $func = new JE::Object::Function {
		scope => $j,
		function => sub { 34 },
		no_proto => 1,
	};
	ok !eval { $func->construct;1 }, 'construct dies with no_proto';
}

diag 'TO DO: Finish writing this script.';

