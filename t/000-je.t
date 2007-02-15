#!perl  -T

use Test::More tests => 67;
use strict;
use Scalar::Util 'refaddr';



#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok 'JE' }


#--------------------------------------------------------------------#
# Tests 2-3: Object creation

ok our $j = JE->new, 'Create JE global object';
isa_ok $j, 'JE';


#--------------------------------------------------------------------#
# Tests 4-9: Compilation and string concatenation

ok our $code = $j->compile('"aa" + "bb"');
isa_ok $code, 'JE::Code';

isa_ok +(our $result = $code->execute), 'JE::String';
ok $result eq 'aabb', 'JE::String\'s overloaded ops';
ok !ref(our $value = $result->value),
	'(string)->value is scalar';
ok $value eq 'aabb', '(string)->value eq "aabb"';

#--------------------------------------------------------------------#
# Test 10: Unicode format chars in source

ok +JE->new->compile(qq("aa" + \x{200e}'bb'))->execute eq 'aabb',
	'Unicode format char in source';

#--------------------------------------------------------------------#
# Tests 11-15: numeric addition

ok $code = $j->compile('3+7.9');

isa_ok +($result = $code->execute), 'JE::Number';
ok $result == 10.9, 'JE::Number\'s overloaded ops';
ok !ref($value = $result->value),
	'(number)->value is scalar';
ok $value == 10.9, '(number)->value == 10.9';

#--------------------------------------------------------------------#
# Tests 16-21: array literals

ok $code = $j->compile('[1, 2,3+4]');

isa_ok +($result = $code->execute), 'JE::Object::Array';
ok $result eq '1,2,7', 'JE:: Object::Array\'s overloaded string op';
ok $result->[1] == 2, 'JE:: Object::Array\'s overloaded array ref op';
ok ref($value = $result->value) eq 'ARRAY',
	'(array obj)->value is array ref';
ok $value->[2] == 7, '(array obj)->value->[2] == 7';

#--------------------------------------------------------------------#
# Tests 22-27: array literals

ok $code = $j->compile('({a:"b"})');

isa_ok +($result = $code->execute), 'JE::Object';
ok $result eq '[object Object]', 'JE::Object\'s overloaded string op';
ok $result->{a} eq 'b', 'JE::Object\'s overloaded hash ref op';
ok ref($value = $result->value) eq 'HASH',
	'(obj)->value is hash ref';
ok $value->{a} eq 'b', '(obj)->value->{a} eq "b"';

#--------------------------------------------------------------------#
# Tests 28-30: this

ok $code = $j->compile('this');

isa_ok +($result = $code->execute), 'JE';
ok refaddr $result == refaddr $j, '"this" is the same as the global obj';

#--------------------------------------------------------------------#
# Tests 31-32: bare identifiers

ok $code = $j->compile('parseFloat');

isa_ok +($result = $code->execute), 'JE::Object::Function';
# This will be broken once I make 'execute' return lvalues.

#--------------------------------------------------------------------#
# Tests 33-67: various js ops

ok $j->eval('delete toString')   eq 'true';
ok $j->eval('delete undefined')   eq 'false';
ok $j->eval('delete everything')    eq 'true'; # non-existent property
ok $j->eval('void delete undefined') eq 'undefined';
ok $j->eval('true')                 eq 'true';
ok $j->eval('false')              eq 'false';
ok $j->eval('typeof undefined')  eq 'undefined';
ok $j->eval('typeof null')        eq 'object';
ok $j->eval('typeof true')          eq 'boolean';
ok $j->eval('typeof new Function')    eq 'function';
ok $j->eval('typeof new new Function') eq 'object';
ok $j->eval('typeof 3')               eq 'number';
ok $j->eval("typeof '3'")           eq 'string';
ok $j->eval("typeof '3'.toStoo") eq 'undefined';
ok $j->eval('x = 5')         eq '5';
ok $j->eval('x++')        eq '5';
ok $j->eval('x--')      eq '6';
ok $j->eval('--x')     eq '4';
ok $j->eval('++x')    eq '5';
ok $j->eval("+'3.00'") eq '3';
ok $j->eval('- -5')      eq '5';
ok $j->eval('- "-5"')     eq '5';
ok $j->eval('~2147483647') eq '-2147483648';
ok $j->eval('~1')         eq '-2';
ok $j->eval('!1')          eq 'false';
ok $j->eval('!false')        eq 'true';
ok $j->eval('!"false"')         eq 'false';
ok $j->eval("!\ntrue")              eq 'false';
ok $j->eval('6.7 - .5')                 eq '6.2';
ok $j->eval('-3>>1')                        eq '-2';
ok $j->eval('3>>1')                              eq '1';
ok $j->eval('-3>>>1')                                eq '2147483646';
ok $j->eval('!true ? x = 3 : y = "do\tenut"; y')        eq "do\tenut";
ok $j->eval('true ? x = 3 : y = "do\tenut"; x')           eq '3';
ok $j->eval('{"this"    : "that", "the":"other"}["this"]') eq 'that'; 



# I need to add these, when I write all the tests. These are for the
# syntax of NewExpressions (ECMA-262 11.2):

#new(String)('𝄐').length                      //2
#new String.prototype.constructor('A𝄫').length //3

#new new new new Object().constructor()['cons' + "tructor"]().constructor(
#	'aoeu', 'htsn').aoeu








