#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 4;
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
/* Test 4: Make sure Function.prototype.apply dies properly */

var error
try { Function.prototype.apply(3,4) }
catch(it) { it instanceof TypeError && (error = 1) }
ok(error, 'Function.prototype.apply(3,4) throws a TypeError')

--end--
