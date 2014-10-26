#!perl  -T

# Some of the stuff in here needs to be moved elsewhere.
# This is supposed to test JE.pm's Perl interface (as opposed to that of
# its accompanying modules, or its JS features).
# The bind_class method has its own test file.

BEGIN { require './t/test.pl' }

use Test::More tests => 25;
use strict;
use Scalar::Util 'refaddr';
use utf8;


#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok 'JE' }


#--------------------------------------------------------------------#
# Tests 2-3: Object creation

ok our $j = JE->new, 'Create JE global object';
isa_ok $j, 'JE';


#--------------------------------------------------------------------#
# Tests 4-9: Compilation and string concatenation

ok our $code = $j->parse('"aa" + "bb"');
isa_ok $code, 'JE::Code';

isa_ok +(our $result = $code->execute), 'JE::String';
ok $result eq 'aabb', 'JE::String\'s overloaded ops';
ok !ref(our $value = $result->value),
	'(string)->value is scalar';
ok $value eq 'aabb', '(string)->value eq "aabb"';

#--------------------------------------------------------------------#
# Tests 10-15: object literals

ok $code = $j->parse('({a:"b"})');

isa_ok +($result = $code->execute), 'JE::Object';
ok $result eq '[object Object]', 'JE::Object\'s overloaded string op';
ok $result->{a} eq 'b', 'JE::Object\'s overloaded hash ref op';
ok ref($value = $result->value) eq 'HASH',
	'(obj)->value is hash ref';
ok $value->{a} eq 'b', '(obj)->value->{a} eq "b"';

#--------------------------------------------------------------------#
# Tests 16-18: bare identifiers

ok $code = $j->parse('parseFloat');

isa_ok +($result = $code->execute), 'JE::LValue';
isa_ok get $result, 'JE::Object::Function';

#--------------------------------------------------------------------#
# Tests 19-20: various js ops

ok $j->eval("new(String)('𝄐').length")                          eq '2'; 
ok !defined $j->eval('{ a = 6; b= tru\u003d; }');

#--------------------------------------------------------------------#
# Tests 21-25: more complicated js stuff

isa_ok $j->new_function(ok => \&ok), 'JE::Object::Function';

defined $j->eval(<<'---') or die;

var func = new Function('this,and','a','that');
ok(typeof func === 'function');
//TO DO: ok(func.length === 3);

ok(double(-3) === -6);
function double(number) {
	return number*2
}

ok(function double(number) {
	return number*2
}(89) === 178);

$ = '\n,rekcah tpircSAMCE rehtona tsuJ'.split(/(?:)/)
function next_char() { eval('function chr(){}'); delete chr;
var chr = $.pop(); return chr } $_ = ''
while (next_char()) $_ += chr;
ok($_ === 'Just another ECMAScript hacker,\n')


---
