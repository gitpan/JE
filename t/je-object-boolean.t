#!perl  -T

BEGIN { require './t/test.pl' }

use Test::More tests => 95;
use Scalar::Util 'refaddr';
use strict;
use utf8;


#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN { use_ok 'JE::Object::Boolean' }; # Make sure it loads without JE
                                # already loaded.
BEGIN { use_ok 'JE' };


#--------------------------------------------------------------------#
# Tests 3-6: Object creation

our $j = JE->new,;
isa_ok $j, 'JE', 'global object';

our $t = new JE::Object::Boolean $j ,1;
our $f = new JE::Object::Boolean $j, 0.;
our $n = new JE::Object::Boolean $j,;
isa_ok $t, 'JE::Object::Boolean', 'true';
isa_ok $f, 'JE::Object::Boolean', 'folse';
isa_ok $n, 'JE::Object::Boolean', 'default boolean';


#--------------------------------------------------------------------#
# Tests 7-24: prop

{
	is $t->prop(thing => 'value'), 'value',
		'prop returns the assigned value';
	is $t->prop('thing'), 'value', 'the assignment worked';

	# Hash ref arg:

	is $t->prop({
		name => 'notes',
		value => 'abcdefg',
	}), 'abcdefg', 'prop({}) returns the assigned value';
	is $t->prop({ name => 'notes' }), 'abcdefg',
		'prop({}) returns the property\'s value';
	is $t->prop({
		name => 'notes',
		dontenum => 1,
	}), 'abcdefg', 'prop({dontenum}) returns the value';
	unlike join('-', $t->keys), qr/\bnotes\b/,
		'prop({dontenum}) works';
	is $t->prop({
		name => 'notes',
		dontdel => 1,
	}), 'abcdefg', 'prop({dontdel}) returns the value';
	ok !$t->delete('notes'), 'prop({dontdel}) works';
	is $t->prop({
		name => 'notes',
		readonly => 1,
	}), 'abcdefg', 'prop({readonly}) returns the value';
	$t->prop(notes => 'ne pa bou ga di ke zo ne');
	is $t->{notes}, 'abcdefg', 'prop({readonly}) works';
	$t->prop({name => 'notes', value => 'do re mi fa sol'});
	is $t->{notes}, 'do re mi fa sol',
		'prop({value}) changes read-only properties';

	# Autoload

	$t->prop({
		name => 'notes',
		value => 'ne pa bou ga di', 
		autoload => 'die',
	});
	is $t->prop('notes'), 'ne pa bou ga di',
		'autoload is ignored when value is present';
	$t->prop({
		autoload => '$::autoloaded = 1; $global->null',
		name => 'notes',
	});
	is $t->{notes}, 'null', 'result of autoload string';
	ok $::autoloaded, 'side-effect of autoload string';
	$::autoloaded = 0; () = $t->{notes}; # () suppresses void warnings
	ok !$::autoloaded, 'string autoload happens once';

	# This test caused a bus error, because &JE::Code::execute (which
	# had a goto exiting an eval) is being called from a tie handler.
	my $auto;
	$t->prop({
		autoload => sub { $auto = 1; $j->eval('"string"') },
		name => 'notes',
	});
	is $t->{notes}, 'string', 'result of autoload sub';

	ok $auto, 'side-effect of autoload sub';
	$auto = 0; () = $t->{notes}; # () suppresses void warnings
	ok !$auto, 'sub autoload happens once';
}


#--------------------------------------------------------------------#
# Tests 25-6: keys

is_deeply [$t->keys], ['thing'], 'keys (1)';
is_deeply [$f->keys], [], 'keys (2)';


#--------------------------------------------------------------------#
# Test 27-9: delete

is_deeply $t->delete('anything'), 1, 'delete nonexistent property';
is_deeply $t->delete('thing'), 1, 'delete property';
is_deeply $t->delete('notes'), !1, 'delete undeletable property';


#--------------------------------------------------------------------#
# Tests 30-31: method

{
	isa_ok my $ret = $t->method('toString'), 'JE::String',
		'result of method("toString")';
	ok $ret eq 'true',
		'$t->method("toString") returns "true"';
}

#--------------------------------------------------------------------#
# Tests 32-4: value

is_deeply $t->value,  1, '$t->value';
is_deeply $f->value, !1, '$f->value';
is_deeply $n->value, !1, '$n->value';

#--------------------------------------------------------------------#
# Test 35: call

eval {
	$t->call
};
like $@, qr/^Can't locate object method/, 'call dies';


#--------------------------------------------------------------------#
# Test 36: apply

eval {
	$t->apply
};
like $@, qr/^Can't locate object method/, 'apply dies';


#--------------------------------------------------------------------#
# Test 37: construct

eval {
	$t->construct
};
like $@, qr/^Can't locate object method/, 'construct dies';


#--------------------------------------------------------------------#
# Tests 38-9: exists

$t->prop(thing => undef);

is_deeply $t->exists('anything'), !1, 'exists(nonexistent property)';
is_deeply $t->exists('thing'), 1, 'exists(property)';


#--------------------------------------------------------------------#
# Tests 40-42: is_readonly

is_deeply $t-> is_readonly('anything'), !1,
	'is_readonly(nonexistent property)';
is_deeply $t-> is_readonly('thing'), !1, 'is_readonly(property)';
is_deeply $t-> is_readonly('notes'), 1,
	'is_readonly(read-only property)';


#--------------------------------------------------------------------#
# Tests 43-6: is_enum

is_deeply $t-> is_enum('anything'), !1,
	'is_enum(nonexistent property)';
is_deeply $t-> is_enum('thing'), 1, 'is_enum(property)';
is_deeply $t-> is_enum('notes'), !1, 'is_enum(unenumerable property)';


#--------------------------------------------------------------------#
# Test 47: typeof

is_deeply typeof $t, 'object', 'typeof returns "object"';


#--------------------------------------------------------------------#
# Test 48: class

is_deeply $t->class, 'Boolean', 'class returns "Boolean"';


#--------------------------------------------------------------------#
# Test 49: id

is_deeply $t->id, refaddr $t, 'id';


#--------------------------------------------------------------------#
# Test 50: primitive

is_deeply $t->primitive, !1, 'primitive returns !1';


#--------------------------------------------------------------------#
# Tests 51-6: to_primitive

{
	my $thing;
	isa_ok $thing = $t->to_primitive, 'JE::Boolean',
		'$t->to_primitive';
	is $thing, 'true',  '$t->to_primitive';
	isa_ok $thing = $f->to_primitive, 'JE::Boolean',
		'$f->to_primitive';
	is $thing, 'false', '$f->to_primitive';
	isa_ok $thing = $n->to_primitive, 'JE::Boolean',
		'$n->to_primitive';
	is $thing, 'false', '$n->to_primitive';
}


#--------------------------------------------------------------------#
# Tests 57: to_boolean

{
	isa_ok my $thing = $f->to_boolean, 'JE::Boolean',
		'result of to_boolean';
	is $thing, 'true',  'to_boolean returns true';
}


#--------------------------------------------------------------------#
# Tests 58-63: to_string

{
	my $thing;
	isa_ok $thing = $t->to_string, 'JE::String',
		'$t->to_string';
	is $thing, 'true',  '$t->to_string';
	isa_ok $thing = $f->to_string, 'JE::String',
		'$f->to_string';
	is $thing, 'false', '$f->to_string';
	isa_ok $thing = $n->to_string, 'JE::String',
		'$n->to_string';
	is $thing, 'false', '$n->to_string';
}


#--------------------------------------------------------------------#
# Test 64-9: to_number

{
	my $thing;
	isa_ok $thing = $t->to_number, 'JE::Number',
		'$t->to_number';
	is $thing, 1,  '$t->to_number';
	isa_ok $thing = $f->to_number, 'JE::Number',
		'$f->to_number';
	is $thing, 0, '$f->to_number';
	isa_ok $thing = $n->to_number, 'JE::Number',
		'$n->to_number';
	is $thing, 0, '$n->to_number';
}

#--------------------------------------------------------------------#
# Test 70: to_object

cmp_ok refaddr $t-> to_object, '==', refaddr $t, 'to_object';


#--------------------------------------------------------------------#
# Test 71: global

is refaddr $j, refaddr global $t, '->global';


#--------------------------------------------------------------------#
# Tests 72-8: Overloading

# %{} is dealt with further down

is "$t", 'true', 'string overloading of true';
is "$f", 'false',        'string overloading of false';;
is "$n", 'false',        'string overloading of default boolean';;

is !$f,  '',         '!$f';

is 0+$t, 1, '0+$t';
is 0+$f, 0, '0+$f';
is 0+$n, 0, '0+$n';


#--------------------------------------------------------------------#
# Tests 79-93: Hash ties

our %h;
*h = \%$t;
$t->delete(0);

is $h{thing}, 'undefined', 'FETCH property';
is_deeply $h{auue}, undef, 'FETCH nonexistent property';
$h{aoeu} = 'htns';
is $t->prop('aoeu'), 'htns', 'STORE property';
is delete $h{aoeu}, 'htns', 'return value of DELETE (hash)';
is_deeply $t->prop('htns'), undef, 'DELETE works';
ok !exists $h{snth}, 'EXISTS(nonexistent prop)';
ok  exists $h{thing}, 'EXISTS(prop)';
ok !exists $h{toString}, 'EXISTS(inherited prop)';
is join('-', keys %h), 'thing', 'keys %{}';

eval {
	%h = ();
};
like $@, qr/^Can't locate object method/, '%$t = () dies';
$h{0}{1} = 3;
isa_ok $h{0}, 'JE::Object', '$h{0} (after {}{} autovivifcation)';
is $h{0}{1}, 3, '$h{0}{1} after {}{} autovivification';
delete $h{0};
$h{0}[1] = 3;
isa_ok $h{0}, 'JE::Object::Array', '$h{0} (after {}[] autovivifcation)';
is $h{0}[1], 3, '$h{0}[1] after {}[] autovivification';
delete $h{0};
$h{0} = \%@;
ok !tied(%@),
	'explicit hash assignment is not confused with autovivification';


#--------------------------------------------------------------------#
# Tests 94-5: Freezing with ties present

SKIP: {
	eval 'require Data::Dump::Streamer' or
		skip 'Data::Dump::Streamer not present', 2;
	import Data::Dump::Streamer;

	ok exists $$$t{tie}, 'hash tie is present before freeze';
	{
		require IO::Handle; # DDS (2.03) loads this, but I don't
		                    # know that it always will.
		my $black_hole = 'IO::Handle'->new;
		Dump($t)->To($black_hole)->Out;
	}
	ok !exists $$$t{tie}, 'hash tie\'s gone';
}
