#!perl  -T

use Test::More tests => 3;
use strict;



#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok 'JE::String' } # Make sure it can load without JE
BEGIN { use_ok 'JE' }         # already loaded


# Bug in 0.016 (was returning a Perl scalar):
isa_ok +JE::String->new(new JE, 'aoeu')->prop('length'), "JE::Number",
	'result of ->prop("length")';

diag "TODO: Finish writing this script";