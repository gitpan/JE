#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 9;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };

my $j = new JE;

# Test 2: Bind the ok function
isa_ok( $j->new_function( ok => \&ok ), 'JE::Object::Function' );


# Run JS tests

defined $j->eval( <<'--end--' ) or die;

// test 3
ok(
	function() {
		return
		true
	}() === undefined, '"return\\ntrue" returns undefined'
);

// test 4
try {
	throw
	up
}
catch (fire) {
	ok( fire === undefined, '"throw\\nup" throws undefined');
}


// test 5
x = true
do {
	loose: {
		break
		loose
	}
	x = false
} while(0)
ok(x, '"break\\<identifier>" ignores the identifier');


// test 6
x = true
do {
	eavesdropping: {
		continue
		eavesdropping
	}
	x = false
} while(0)
ok(x, '"continue\\<identifier>" ignores the identifier');


// test 7
a = b = 5
a
++
b
ok(a === 5 && b === 6, '"a\\n++\\nb" means "a; ++b"')

// test 8
a = b = 5
a
--
b
ok(a === 5 && b === 4, '"a\\n--\\nb" means "a; --b"')


// test 9
ok
(true, 'semicolons are not inserted before argument lists')



--end--