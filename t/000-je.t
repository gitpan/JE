#!perl  -T

use Test::More tests => 10;
use strict;



#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok 'JE' }


#--------------------------------------------------------------------#
# Test 2: Object creation

ok our $j = JE->new, 'Create JE global object';
isa_ok $j, 'JE';


#--------------------------------------------------------------------#
# Tests 3-9: Compilation and string concatenation

ok our $code = JE->compile('"aa" + "bb"');
isa_ok $code, 'JE::Code';

isa_ok +(our $result = $code->execute), 'JE::String';
ok $result eq 'aabb', 'JE::String\'s overloaded ops';
ok !ref(our $value = $result->value),
	'(Result of execute)->value is scalar';
ok $value eq 'aabb', '(Result of execute)->value eq "aabb"';

#--------------------------------------------------------------------#
# Test 10: Unicode format chars in source

ok +JE->new->compile(qq("aa" + \x{200e}'bb'))->execute eq 'aabb',
	'Unicode format char in source';
