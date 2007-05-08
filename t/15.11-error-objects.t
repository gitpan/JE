#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 6;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


## Tests 2-3: Bind the ok and diag functions
#isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
#isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );

diag('TO DO: Finish writing this test script');

my $error_proto_id = id{$j->eval('Error.prototype')};
ok $j->eval('RangeError.prototype')->prototype->id == $error_proto_id,
	"RangeError.prototype's prototype";
ok $j->eval('ReferenceError.prototype')->prototype->id == $error_proto_id,
	"ReferenceError.prototype's prototype";
ok $j->eval('SyntaxError.prototype')->prototype->id == $error_proto_id,
	"SyntaxError.prototype's prototype";
ok $j->eval('TypeError.prototype')->prototype->id == $error_proto_id,
	"TypeError.prototype's prototype";
ok $j->eval('URIError.prototype')->prototype->id == $error_proto_id,
	"URIError.prototype's prototype";

__END__

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
