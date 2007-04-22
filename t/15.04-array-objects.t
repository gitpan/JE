#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 5;
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
/* Tests 4-5: Make sure toString and toLocaleString die properly */

try { Array.prototype.toString.apply(3) }
catch(it) { ok(it.message == 'Object is not an Array') }
try { Array.prototype.toLocaleString.apply(3) }
catch(it) { ok(it.message == 'Object is not an Array') }

--end--
