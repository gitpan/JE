#!perl  -T

BEGIN { require './t/test.pl' }

use Test::More tests => 102;
use Scalar::Util 'refaddr';
use strict;
use utf8;


#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN { use_ok 'JE::Object::Array' }; # Make sure it loads without JE
                                # already loaded.
BEGIN { use_ok 'JE' };


#--------------------------------------------------------------------#
# Tests 3-6: Object creation

our $j = JE->new,;
isa_ok $j, 'JE', 'global object';

our $a1 = new JE::Object::Array $j ,[qw/an array ref/];
our $a2 = new JE::Object::Array $j, $j->eval(6);
our $a3 = new JE::Object::Array $j, qw/a list/;
isa_ok $a1, 'JE::Object::Array', 'array from array ref';
isa_ok $a2, 'JE::Object::Array', 'array with specified length';
isa_ok $a3, 'JE::Object::Array', 'array from list';


#--------------------------------------------------------------------#
# Tests 7-9: string overloading (check that the arrays were initialised
#            properly before we go and mangle them)

is "$a1", 'an,array,ref', 'string overloading (1)';
is "$a2", ',,,,,',        'string overloading (2)';;
is "$a3", 'a,list',       'string overloading (3)';

#--------------------------------------------------------------------#
# Tests 10-13: prop

{
	is $a1->prop(thing => 'value'), 'value',
		'prop returns the assigned value';
	is $a1->prop('thing'), 'value', 'the assignment worked';
	is $a1->prop(0), 'an', 'get property';
	isa_ok $a1->prop(0), 'JE::String', 'the property';
}


#--------------------------------------------------------------------#
# Test 14: keys

is_deeply [sort $a1->keys], [qw/0 1 2 thing/], 'keys';


#--------------------------------------------------------------------#
# Test 15-24: delete

is_deeply $a1->delete('anything'), 1, 'delete nonexistent property';
is_deeply $a2->delete('0'), 1, 'delete nonexistent array elem';
is_deeply $a1->delete('thing'), 1, 'delete property';
is_deeply $a1->prop('thing'), undef, 'was the property deleted?';
is_deeply $a1->delete('2'), 1, 'delete array elem';
is_deeply $a1->prop(2), undef, 'was it deleted?';
is $a1->prop('length'), 3, 'was length left untouched?';
is_deeply $a2->delete('0'), 1, 'delete nonexistent array elem';
is_deeply $a1->delete('length'), !1, 'delete length';
is $a1->prop('length'), 3, 'does length still exist?';


#--------------------------------------------------------------------#
# Tests 25-6: method

{
	isa_ok my $ret = $a1->method('toString'), 'JE::String',
		'result of method("toString")';
	ok $ret eq 'an,array,',
		'$a1->method("toString") returns "an,array,"';
}


#--------------------------------------------------------------------#
# Tests 27-47: value

{
	my $value;

	is ref($value = $a1->value), 'ARRAY',
		'$a1->value returns an ARRAY';
	is scalar(@$value), 3, 'scalar @{$a1->value}';
	isa_ok $value->[0], 'JE::String', '$a1->value->[0]';
	is $value->[0], 'an', '$a1->value->[0]';
	isa_ok $value->[1], 'JE::String', '$a1->value->[1]';
	is $value->[1], 'array', '$a1->value->[1]';
	is_deeply $value->[2], undef, '$a1->value->[2]';

	is ref($value = $a2->value), 'ARRAY',
		'$a2->value returns an ARRAY';
	is scalar(@$value), 6, 'scalar @{$a2->value}';
	for(0..5) {
		is_deeply $value->[$_], undef, "\$a2->value->[$_]";
	}

	is ref($value = $a3->value), 'ARRAY',
		'$a3->value returns an ARRAY';
	is scalar(@$value), 2, 'scalar @{$a3->value}';
	isa_ok $value->[0], 'JE::String', '$a3->value->[0]';
	is $value->[0], 'a', '$a3->value->[0]';
	isa_ok $value->[1], 'JE::String', '$a3->value->[1]';
	is $value->[1], 'list', '$a3->value->[1]';
}

#--------------------------------------------------------------------#
# Test 48: call

eval {
	$a1->call
};
like $@, qr/^Can't locate object method/, 'call dies';


#--------------------------------------------------------------------#
# Test 49: apply

eval {
	$a1->apply
};
like $@, qr/^Can't locate object method/, 'apply dies';


#--------------------------------------------------------------------#
# Test 50: construct

eval {
	$a1->construct
};
like $@, qr/^Can't locate object method/, 'construct dies';


#--------------------------------------------------------------------#
# Tests 51-5: exists

$a1->prop(thing => undef);

is_deeply $a1->exists('anything'), !1, 'exists(nonexistent property)';
is_deeply $a1->exists(2), !1, 'exists(nonexistent elem)';
is_deeply $a1->exists('thing'), 1, 'exists(property)';
is_deeply $a1->exists(0), 1, 'exists(elem)';
is_deeply $a1->exists('length'), 1, 'exists(length)';


#--------------------------------------------------------------------#
# Tests 56-61: is_readonly

# Arrays never have any readonly properties

is_deeply $a1-> is_readonly('anything'), !1,
	'is_readonly(nonexistent property)';
is_deeply $a1-> is_readonly(2), !1, 'is_readonly(nonexistent elem)';
is_deeply $a1-> is_readonly('thing'), !1, 'is_readonly(property)';
is_deeply $a1-> is_readonly(0), !1, 'is_readonly(elem)';
is_deeply $a1-> is_readonly('length'), !1, 'is_readonly(length)';
is_deeply $a1-> is_readonly('toString'), !1, 'is_readonly(inherited prop)';


#--------------------------------------------------------------------#
# Tests 62-7: is_enum

is_deeply $a1-> is_enum('anything'), !1,
	'is_enum(nonexistent property)';
is_deeply $a1-> is_enum(2), !1, 'is_enum(nonexistent elem)';
is_deeply $a1-> is_enum('thing'), 1, 'is_enum(property)';
is_deeply $a1-> is_enum(0), 1, 'is_enum(elem)';
is_deeply $a1-> is_enum('length'), !1, 'is_enum(length)';
is_deeply $a1-> is_enum('toString'), !1, 'is_enum(inherited prop)';


#--------------------------------------------------------------------#
# Test 68: typeof

is_deeply typeof $a1, 'object', 'typeof returns "object"';


#--------------------------------------------------------------------#
# Test 69: class

is_deeply $a1->class, 'Array', 'class returns "Array"';


#--------------------------------------------------------------------#
# Test 70: id

is_deeply $a1->id, refaddr $a1, 'id';


#--------------------------------------------------------------------#
# Test 71: primitive like an ape

is_deeply $a1->primitive, !1, 'primitive returns !1';


#--------------------------------------------------------------------#
# Tests 72-7: to_primitive

{
	my $thing;
	isa_ok $thing = $a1->to_primitive, 'JE::String',
		'$a1->to_primitive';
	is $thing, 'an,array,',  '$a1->to_primitive';
	isa_ok $thing = $a2->to_primitive, 'JE::String',
		'$a2->to_primitive';
	is $thing, ',,,,,', '$a2->to_primitive';
	isa_ok $thing = $a3->to_primitive, 'JE::String',
		'$a3->to_primitive';
	is $thing, 'a,list', '$a3->to_primitive';
}


#--------------------------------------------------------------------#
# Tests 78-9: to_boolean

{
	isa_ok my $thing = $a1->to_boolean, 'JE::Boolean',
		'result of to_boolean';
	is $thing, 'true',  'to_boolean returns true';
}


#--------------------------------------------------------------------#
# Tests 80-85: to_string

{
	my $thing;
	isa_ok $thing = $a1->to_string, 'JE::String',
		'$a1->to_string';
	is $thing, 'an,array,',  '$a1->to_string';
	isa_ok $thing = $a2->to_string, 'JE::String',
		'$a2->to_string';
	is $thing, ',,,,,', '$a2->to_string';
	isa_ok $thing = $a3->to_string, 'JE::String',
		'$a3->to_string';
	is $thing, 'a,list', '$a3->to_string';
}


#--------------------------------------------------------------------#
# Test 86-91: to_number

{
	my $thing;
	isa_ok $thing = $a1->to_number, 'JE::Number',
		'$a1->to_number';
	is $thing, 'NaN',  '$a1->to_number';
	isa_ok $thing = $a2->to_number, 'JE::Number',
		'$a2->to_number';
	is $thing, 'NaN', '$a2->to_number';
	isa_ok $thing = $a3->to_number, 'JE::Number',
		'$a3->to_number';
	is $thing, 'NaN', '$a3->to_number';
}


#--------------------------------------------------------------------#
# Test 92: to_object

cmp_ok refaddr $a1-> to_object, '==', refaddr $a1, 'to_object';


#--------------------------------------------------------------------#
# Test 93: global

is refaddr $j, refaddr global $a1, '->global';


#--------------------------------------------------------------------#
# Tests 94-102: Overloading

cmp_ok \@$a1, '==', value $a1, '@{}';  # same array -- this will change

is !$a1,  '',         '!$a1';

cmp_ok 0+$a1, '!=', 0+$a1,  '0+$a1';
cmp_ok 0+$a2, '!=', 0+$a2,  '0+$a2';
cmp_ok 0+$a3, '!=', 0+$a3,  '0+$a3';

my %hash = %$a1;
is join('-', sort keys %hash), '0-1-thing', 'keys %{}';
is $hash{0}, 'an', '$a1->{0}';
is $hash{1}, 'array', '$a1->{1}';
is $hash{thing}, 'undefined', '$a1->{thing}';


