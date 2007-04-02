#!perl -T

use Test::More tests => 4;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->compile(qq("aa" + \x{200e}'b\x{200e}b')),
	'JE::Code');

#--------------------------------------------------------------------#
# Tests 3-4: Run code

is($code->execute, 'aabb', 'execute code');
is($@, '', 'code should not return an error');
