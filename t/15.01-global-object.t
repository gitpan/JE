#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 9;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-3: Bind the ok and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );


# Run JS tests

defined $j->eval( <<'--end--' ) or die;

diag('TO DO: Finish writing this test script')

// ---------------------------------------------------
/* Tests 4-9: eval */

ok(eval('3+3; 4+4;') === 8,      'successful eval with return value')
ok(eval('var x')     === void 0, 'successful eval with no return value')

$catched = false;
try { eval('throw void 0') }
catch(phrase) {	phrase === undefined && ($catched = true) }
ok($catched, 'eval(\'throw\') (see whether errors propagate)')

$catched = false;
try { eval('Y@#%*^@#%*(^$') }
catch(phrase) {	phrase instanceof SyntaxError && ($catched = true) }
ok($catched, 'eval(invalid syntax)')

ok(eval(0) === 0, 'eval(number)')
ok(eval(new String('this isn\'t really a string')) instanceof String,
	'eval(new String)')

--end--
