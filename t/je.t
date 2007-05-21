#!perl  -T

BEGIN { require './t/test.pl' }

use Test::More tests => 46;
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
# Tests 10-14: numeric addition

ok $code = $j->parse('3+7.9');

isa_ok +($result = $code->execute), 'JE::Number';
ok $result == 10.9, 'JE::Number\'s overloaded ops';
ok !ref($value = $result->value),
	'(number)->value is scalar';
ok $value == 10.9, '(number)->value == 10.9';

#--------------------------------------------------------------------#
# Tests 15-20: array literals

ok $code = $j->parse('[1, 2,3+4]');

isa_ok +($result = $code->execute), 'JE::Object::Array';
ok $result eq '1,2,7', 'JE:: Object::Array\'s overloaded string op';
ok $result->[1] == 2, 'JE:: Object::Array\'s overloaded array ref op';
ok ref($value = $result->value) eq 'ARRAY',
	'(array obj)->value is array ref';
ok $value->[2] == 7, '(array obj)->value->[2] == 7';

#--------------------------------------------------------------------#
# Tests 21-26: object literals

ok $code = $j->parse('({a:"b"})');

isa_ok +($result = $code->execute), 'JE::Object';
ok $result eq '[object Object]', 'JE::Object\'s overloaded string op';
ok $result->{a} eq 'b', 'JE::Object\'s overloaded hash ref op';
ok ref($value = $result->value) eq 'HASH',
	'(obj)->value is hash ref';
ok $value->{a} eq 'b', '(obj)->value->{a} eq "b"';

#--------------------------------------------------------------------#
# Tests 27-9: bare identifiers

ok $code = $j->parse('parseFloat');

isa_ok +($result = $code->execute), 'JE::LValue';
isa_ok get $result, 'JE::Object::Function';

#--------------------------------------------------------------------#
# Tests 30-6: various js ops

ok $j->eval('x = 5')          eq '5';
ok $j->eval('!true ? x = 3 : y = "do\tenut"; y')    eq "do\tenut";
ok $j->eval('true ? x = 3 : y = "do\tenut"; x')          eq '3';
ok $j->eval("new(String)('𝄐').length")                          eq '2'; 
ok $j->eval("new String.prototype.constructor('A𝄫').length")      eq '3'; 
ok !defined $j->eval('{ a = 6; b= tru\u003d; }');
ok $j->eval("{ a = 6; b= 7; }")                                     eq '7'; 

#--------------------------------------------------------------------#
# Tests 37-46: more complicated js stuff

isa_ok $j->new_function(ok => \&ok), 'JE::Object::Function';

defined $j->eval(<<'---') or die;

var func = new Function('this,and','a','that');
ok(typeof func === 'function');
//TO DO: ok(func.length === 3);

ok(xx === undefined, 'vars declared later are undefined');
var xx = 5;
ok(xx === 5, 'var initialisation');

if (3==4);
else {ok(true)};

var x =0, str = '';
do str += 7656 
while (++x < 7)
ok(str === '7656765676567656765676567656');

var object = {0:1,2:3,4:5,6:7,8:9};
var keys = [];
for(keys[keys.length] in object);
ok(keys == '0,2,4,6,8');

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
