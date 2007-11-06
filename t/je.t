#!perl  -T

# Some of the stuff in here needs to be moved elsewhere.
# This is supposed to test JE.pm's Perl interface (as opposed to that of
# its accompanying modules, or its JS features).

BEGIN { require './t/test.pl' }

use Test::More tests => 197;
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

#--------------------------------------------------------------------#
# Tests 26-33: Class bindings: constructor and class names

$j->bind_class(package => 'class1');
eval { $j->{class1}->construct};
ok $@,
	'binding a class w/o a constructor makes a constructor that dies';
{
	my $prx = $j->upgrade(bless [], 'class1');
	isa_ok $prx, 'JE::Object::Proxy', 'the proxy';
	is $prx->class, 'class1',
		'the class name is the same as the package name';
}

$j->bind_class(package => 'class2', name => 'classroom2');
eval { $j->{class2}->construct};
ok $@,
	'binding a class without a constructor (2)';
eval { $j->{classroom2}->construct};
ok $@,
	'binding a class without a constructor (3)';
is $j->upgrade(bless [], 'class2')->class, 'classroom2',
	'class name that differs from the package name';

$j->bind_class(package => 'class3',  constructor => 'new');
isa_ok $j->{class3}, 'JE::Object::Function',
	'constructor named after the package';

$j->bind_class(
	package => 'class4',
	name => 'fourth_class',
	constructor => 'old',
);
isa_ok $j->{fourth_class}, 'JE::Object::Function',
	'constructor named after the class';


#--------------------------------------------------------------------#
# Tests 34-48: Class bindings: construction and method calls

$j->new_function(is => \&is);

{
	package MethodClass;  # tests 'methods => \@array'
	sub knew { bless [] }
	sub method1 { '$a_' . ref($_[0]) . '->method1' }
	sub method2 { '$a_' . ref($_[0]) . '->method2' }
	sub a_static_method { "$_[0]\->static"}
	sub another_static_method { "$_[0]\->another" }
}
$j->bind_class(
	package => 'MethodClass',
	constructor => 'knew',
	methods => [ 'method1', 'method2' ],
	static_methods => [ 'a_static_method','another_static_method' ],
);

{
	package MethodClass2;  # tests 'methods => \%hash' 
	
	sub knew { bless [] }
	sub method1 { '$a_' . ref($_[0]) . '->method1' }
	sub method2 { '$a_' . ref($_[0]) . '->method2' }
	sub a_static_method { "$_[0]\->static"}
	sub another_static_method { "$_[0]\->another" }
}
$j->bind_class(
	package => 'MethodClass2',
	constructor => 'knew',
	methods => { meth1 => 'method1', meth2 => 'method2' },
	static_methods => {
		st1 => 'a_static_method',
		st2 => 'another_static_method' },
);
	
{
	package SubClass;  # tests 'methods => \%hash_of_coderefs' 
	
	sub knew { bless [] }
	sub method1 { '$a_' . ref($_[0]) . '->method1' }
	sub method2 { '$a_' . ref($_[0]) . '->method2' }
	sub a_static_method { "$_[0]\->static"}
	sub another_static_method { "$_[0]\->another" }
}
$j->bind_class(
	package => 'SubClass',
	constructor => sub { knew SubClass },
	methods => { meth1 => \&SubClass::method1, 
		     meth2 => \&SubClass::method2 },
	static_methods => {
		st1 => \&SubClass::a_static_method,
		st2 => \&SubClass::another_static_method },
);
	
defined $j->eval(<<'----') or die;

(function(){
	var m1 = new MethodClass;
	var m2 = new MethodClass2;
	var s1 = new SubClass;

	is(m1, '[object MethodClass]', 'class of new MethodClass');
	is(m2, '[object MethodClass2]', 'class of new MethodClass2');
	is(s1, '[object SubClass]', 'class of new SubClass');

	is(m1.method1(), '$a_MethodClass->method1',
		'MethodClass object method 1')	
	is(m1.method2(), '$a_MethodClass->method2',
		'MethodClass object method 2')
	is(m2.meth1(), '$a_MethodClass2->method1',
		'MethodClass2 object method 1')	
	is(m2.meth2(), '$a_MethodClass2->method2',
		'MethodClass2 object method 2')
	is(s1.meth1(), '$a_SubClass->method1',
		'SubClass object method 1')	
	is(s1.meth2(), '$a_SubClass->method2',
		'SubClass object method 2')

	is(MethodClass.a_static_method(), 'MethodClass->static',
		'MethodClass static method 1')	
	is(MethodClass.another_static_method(),
		'MethodClass->another',
		'MethodClass static method 2')
	is(MethodClass2.st1(), 'MethodClass2->static',
		'MethodClass2 static method 1')	
	is(MethodClass2.st2(), 'MethodClass2->another',
		'MethodClass2 static method 2')
	is(SubClass.st1(), 'SubClass->static',
		'SubClass static method 1')	
	is(SubClass.st2(), 'SubClass->another',
		'SubClass static method 2')
}())
----


#--------------------------------------------------------------------#
# Tests 49-67: Class bindings: primitivisation

$j->{is} = \&is unless $j->{is};
$j->{ok} = \&ok unless $j->{ok};

$j->bind_class(
	package => 'Heffelump',
	constructor => sub { bless [], 'Heffelump' },
	methods => {
		toString => sub { 'Look, we have a '. ref $_[0] },
		valueOf  => sub { 678 }
	}
);
$j->bind_class(
	package => 'Oliphaunt',
	constructor => sub { bless [], 'Oliphaunt' },
	methods => {
		toString => sub { 'Look, I think we have an '. ref $_[0] },
		valueOf  => sub { 91011 }
	},
	to_string => sub { 'Look, we have an '. ref $_[0] },
	to_number => sub { 678 }
);
$j->bind_class(
	package => 'Elephant',
	constructor => sub { bless [], 'Elephant' },
	methods => {
		toString => sub { 'Look, I think we have an '. ref $_[0] },
		valueOf  => sub { 91011 }
	},
	to_string => 'yarn',   # methods, not subs
	to_number => 'numeral'
);
sub Elephant::yarn { 'Look, we have an '. ref $_[0] }
sub Elephant::numeral { 678 }

$j->bind_class(
	package => 'Gorilla',
	constructor => sub { bless [], 'Gorilla' },
	to_primitive => sub {
		$_[1] ? qw(98765 string)[$_[1] eq 'string'] : 'no hint'
	},
);

$j->bind_class(
	package => 'NumberOnly',
	constructor => sub { bless [], 'NumberOnly' },
	to_string => undef,
	to_number => sub { 12345 }
);

$j->bind_class(
	package => 'StringOnly',
	constructor => sub { bless [], 'StringOnly' },
	to_string => sub { 'Here you are' },
	to_number => undef
);

$j->bind_class(
	package => 'HintRequired',
	constructor => sub { bless [], 'HintRequired' },
	to_primitive => undef,
	to_string => sub { 'string' },
	to_number => sub { 'number' },
);

$j->bind_class(
	package => 'NotPrimitive',
	constructor => sub { bless [], 'NotPrimitive' },
	to_primitive => undef
);
$j->{diag} = \&diag unless $j->{diag};

defined $j->eval(<<'})() ') or die;

(function(){
	var t1 = new Heffelump
	var t2 = new Oliphaunt
	var t3 = new Elephant
	var t4 = new Gorilla
	var t5 = new NumberOnly
	var t6 = new StringOnly
	var t7 = new HintRequired
	var t8 = new NotPrimitive
	var error;

	is(String(t1), 'Look, we have a Heffelump')	
	is(   + t1, 678)
	is(String(t2), 'Look, we have an Oliphaunt')	
	is(   + t2, 678)
	is(String(t3), 'Look, we have an Elephant')	
	is(   + t3, 678)
	is('' + t4, 'no hint')	
	is(   + t4, 98765)
	is(String(t4), 'string')
	is(+t5, 12345)
	error=false;try{String(t5)}catch(e){error = true}ok(error)
	is(String(t6), 'Here you are')
	error=false;try{+ t6}catch(e){error = true}ok(error)
	is(String(t7), 'string')
//diag(t7)
//diag(+ (t7))
	is(     + t7 , NaN)
	error=false;try{'' + t7}catch(e){error = true}ok(error)
	error=false;try{'' + t8}catch(e){error = true}ok(error)
	error=false;try{+ t8}catch(e){error = true}ok(error)
	error=false;try{String(t8)}catch(e){error = true}ok(error)

})()
})() 


#--------------------------------------------------------------------#
# Tests 68-70: Class bindings: inheritance

$j->bind_class(
	package => 'HumptyDumpty',
	isa => 'String',
);

is refaddr $j->{String}{prototype},
   refaddr $j->upgrade(bless [], 'HumptyDumpty')->prototype->prototype,
   'isa => "String"';

$j->bind_class(
	package => 'JackHorner',
	isa => $j->{Array}{prototype},
);

is refaddr $j->{Array}{prototype},
   refaddr $j->upgrade(bless [], 'JackHorner')->prototype->prototype,
   'isa => $protoobject';

$j->bind_class( # Test 88 also relies on this binding, so make sure it
                # gets another if this is deleted.
	package => 'RunningOutOfWeirdIdeas',
	isa => undef
);

is_deeply $j->upgrade(bless [], 'RunningOutOfWeirdIdeas')->prototype
	->prototype, undef, 'isa => undef';

#--------------------------------------------------------------------#
# Test 71: Class bindings: proxy caching

{
	my $thing = bless [], 'RunningOutOfWeirdIdeas';
	is refaddr $j->upgrade($thing), refaddr $j->upgrade($thing),
		'proxy caching';
} 


#--------------------------------------------------------------------#
# Tests 72-111: Class bindings: properties

$j->{is} ||= \&is;
$j->{ok} ||= \&ok;

{
	package PropsArray;  # tests 'props => \@array'
	sub knew { bless [] }
	my($thing1,$thing2,$thing3,$thing4);
	sub prop1 { ++$thing1 . ' $a_' . ref($_[0]) . '->prop1' }
	sub prop2 { ++$thing2 . ' $a_' . ref($_[0]) . '->prop2' }
	sub sprop1 { ++$thing3 . " $_[0]\->static"}
	sub sprop2 { ++$thing4 . " $_[0]-\>another" }
}
$j->bind_class(
	package => 'PropsArray',
	constructor => 'knew',
	props => [ 'prop1', 'prop2' ],
	static_props => [ 'sprop1','sprop2' ],
);

{
	package PropsHashMethod;  # tests 'props => { name => "method" }'
	sub knew { bless [] }
	my($thing1,$thing2,$thing3,$thing4);
	sub prop1 { ++$thing1 . ' $a_' . ref($_[0]) . '->prop1' }
	sub prop2 { ++$thing2 . ' $a_' . ref($_[0]) . '->prop2' }
	sub sprop1 { ++$thing3 . " $_[0]\->static"}
	sub sprop2 { ++$thing4 . " $_[0]-\>another" }
}
$j->bind_class(
	package => 'PropsHashMethod',
	constructor => 'knew',
	props => {
		p1 => 'prop1',
		p2 => 'prop2',
	},
	static_props => {
		sp1 => 'sprop1',
		sp2 => 'sprop2',
	},
);

{
	package PropsHashSub;  # tests 'props => { name => sub { ... } }'
	sub knew { bless [] }
	my($thing1,$thing2,$thing3,$thing4);
	sub prop1 { ++$thing1 . ' $a_' . ref($_[0]) . '->prop1' }
	sub prop2 { ++$thing2 . ' $a_' . ref($_[0]) . '->prop2' }
	sub sprop1 { ++$thing3 . " $_[0]\->static"}
	sub sprop2 { ++$thing4 . " $_[0]-\>another" }
}
$j->bind_class(
	package => 'PropsHashSub',
	constructor => 'knew',
	props => {
		p1 => \&PropsHashSub::prop1,
		p2 => \&PropsHashSub::prop2,
	},
	static_props => {
		sp1 => \&PropsHashSub::sprop1,
		sp2 => \&PropsHashSub::sprop2,
	},
);

{
	package PropsHashHashMethod;  # tests 'props => { name => { 
	                              #        fetch => "method" }}'
	sub knew { bless [] }
	my($thing1,$thing2,$thing3,$thing4);
	sub prop1 { "$thing1 \$a_" . ref($_[0]) . '->prop1' }
	sub prop2 { "$thing2 \$a_" . ref($_[0]) . '->prop2' }
	sub sprop1 { "$thing3 $_[0]\->static"}
	sub sprop2 { "$thing4 $_[0]-\>another" }
	sub storeprop1 { ++$thing1 }
	sub storeprop2 { ++$thing2 }
	sub storesprop1 { ++$thing3 }
	sub storesprop2 { ++$thing4 }
}
$j->bind_class(
	package => 'PropsHashHashMethod',
	constructor => 'knew',
	props => {
		p1 => { fetch => 'prop1', store => 'storeprop1' },
		p2 => { fetch => 'prop2', store => 'storeprop2' },
	},
	static_props => {
		sp1 => { fetch => 'sprop1', store => 'storesprop1' },
		sp2 => { fetch => 'sprop2', store => 'storesprop2' },
	},
);

{
	package PropsHashHashSub;  # tests 'props => { name => { 
	                           #        fetch => sub { ... } }}'
	sub knew { bless [] }
	my($thing1,$thing2,$thing3,$thing4);
	sub prop1 { "$thing1 \$a_" . ref($_[0]) . '->prop1' }
	sub prop2 { "$thing2 \$a_" . ref($_[0]) . '->prop2' }
	sub sprop1 { "$thing3 $_[0]\->static"}
	sub sprop2 { "$thing4 $_[0]-\>another" }
	sub storeprop1 { ++$thing1 }
	sub storeprop2 { ++$thing2 }
	sub storesprop1 { ++$thing3 }
	sub storesprop2 { ++$thing4 }
}
$j->bind_class(
	package => 'PropsHashHashSub',
	constructor => 'knew',
	props => {
		p1 => { fetch => \&PropsHashHashSub::prop1,
		        store => \&PropsHashHashSub::storeprop1 },
		p2 => { fetch => \&PropsHashHashSub::prop2,
		        store => \&PropsHashHashSub::storeprop2 },
	},
	static_props => {
		sp1 => { fetch => \&PropsHashHashSub::sprop1,
		         store => \&PropsHashHashSub::storesprop1 },
		sp2 => { fetch => \&PropsHashHashSub::sprop2,
		         store => \&PropsHashHashSub::storesprop2 },
	},
);

{
	package FetchOnly;

	sub knew { bless [] }
	sub prop { '$a_' . ref($_[0]) . '->prop' }
	
	sub sprop { "$_[0]\->static"}
}
$j->bind_class(
	package => 'FetchOnly',
	constructor => 'knew',
	props => {
		p => { fetch => 'prop'  },
	},
	static_props => {
		sp => { fetch => 'sprop'  },
	},
);
$j->{FetchOnly}{prototype}->new_method(
	is_readonly => sub { $_[0]->is_readonly($_[1]) }
);
$j->{FetchOnly}->new_method(
	is_readonly => sub { $_[0]->is_readonly($_[1]) }
);

{
	package StoreOnly;

	my $storage_space;
	sub knew { bless [] }
	sub prop { $storage_space = $_[1] }
	sub look { $storage_space }
}
$j->bind_class(
	package => 'StoreOnly',
	constructor => 'knew',
	props => {
		p => { store => 'prop'  },	
		look => 'look',
	},
	static_props => {
		sp => { store => 'prop'  },
	},
);

{
	package UndefReadOnly;

	sub knew { bless [] }
}
$j->bind_class(
	package => 'UndefReadOnly',
	constructor => 'knew',
	props => {
		p => {  },	
	},
	static_props => {
		sp => {  },
	},
);
$j->{UndefReadOnly}{prototype}->new_method(
	is_readonly => sub { $_[0]->is_readonly($_[1]) }
);
$j->{UndefReadOnly}->new_method(
	is_readonly => sub { $_[0]->is_readonly($_[1]) }
);

	
	
defined $j->eval(<<'----') or die;

(function(){
	var pa = new PropsArray;
	var phm = new PropsHashMethod;
	var phs = new PropsHashSub;
	var phhm = new PropsHashHashMethod;
	var phhs = new PropsHashHashSub;

	is(pa, '[object PropsArray]', 'class of new PropsArray');
	is(phm, '[object PropsHashMethod]',
		'class of new PropsHashMethod');
	is(phs, '[object PropsHashSub]', 'class of new PropsHashSub');
	is(phhm, '[object PropsHashHashMethod]',
		'class of new PropsHashHashMethod');
	is(phhs, '[object PropsHashHashSub]',
		'class of new PropsHashHashSub');

	pa.prop1 = 'something';
	is(pa.prop1, '2 $a_PropsArray->prop1', 'pa.prop1');
	pa.prop2 = 'something';
	is(pa.prop2, '2 $a_PropsArray->prop2', 'pa.prop2');
	phm.p1 = 'something';
	is(phm.p1, '2 $a_PropsHashMethod->prop1', 'phm.p1');
	phm.p2 = 'something';
	is(phm.p2, '2 $a_PropsHashMethod->prop2', 'phm.p2');
	phs.p1 = 'something';
	is(phs.p1, '2 $a_PropsHashSub->prop1', 'phs.p1');
	phs.p2 = 'something';
	is(phs.p2, '2 $a_PropsHashSub->prop2', 'phs.p2');
	phhm.p1 = 'something';
	is(phhm.p1, '1 $a_PropsHashHashMethod->prop1', 'phhm.p1');
	phhm.p2 = 'something';
	is(phhm.p2, '1 $a_PropsHashHashMethod->prop2', 'phhm.p2');
	phhs.p1 = 'something';
	is(phhs.p1, '1 $a_PropsHashHashSub->prop1', 'phhs.p1');
	phhs.p2 = 'something';
	is(phhs.p2, '1 $a_PropsHashHashSub->prop2', 'phhs.p2');

	PropsArray.sprop1 = 'something';
	is(PropsArray.sprop1, '2 PropsArray->static', 'PropsArray.sprop1');
	PropsArray.sprop2 = 'something';
	is(PropsArray.sprop2, '2 PropsArray->another', 
		'PropsArray.sprop2');
	PropsHashMethod.sp1 = 'something';
	is(PropsHashMethod.sp1, '2 PropsHashMethod->static', 
		'PropsHashMethod.sp1');
	PropsHashMethod.sp2 = 'something';
	is(PropsHashMethod.sp2, '2 PropsHashMethod->another', 
		'PropsHashMethod.sp2');
	PropsHashSub.sp1 = 'something';
	is(PropsHashSub.sp1, '2 PropsHashSub->static', 
		'PropsHashSub.sp1');
	PropsHashSub.sp2 = 'something';
	is(PropsHashSub.sp2, '2 PropsHashSub->another', 
		'PropsHashSub.sp2');
	PropsHashHashMethod.sp1 = 'something';
	is(PropsHashHashMethod.sp1, '1 PropsHashHashMethod->static', 
		'PropsHashHashMethod.sp1');
	PropsHashHashMethod.sp2 = 'something';
	is(PropsHashHashMethod.sp2, '1 PropsHashHashMethod->another', 
		'PropsHashHashMethod.sp2');
	PropsHashHashSub.sp1 = 'something';
	is(PropsHashHashSub.sp1, '1 PropsHashHashSub->static', 
		'PropsHashHashSub.sp1');
	PropsHashHashSub.sp2 = 'something';
	is(PropsHashHashSub.sp2, '1 PropsHashHashSub->another', 
		'PropsHashHashSub.sp2');


	var fo = new FetchOnly;
	var so = new StoreOnly;
	var uro = new UndefReadOnly;

	ok(fo.is_readonly('p'), "fo.is_readonly('p')");
	fo.p = 'eonthoe'; // no-op
	is(fo.p, '$a_FetchOnly->prop', 'fo.p')
	ok(FetchOnly.is_readonly('sp'), "FetchOnly.is_readonly('sp')");
	FetchOnly.sp = 'eonthoe'; // no-op
	is(FetchOnly.sp, 'FetchOnly->static', 'FetchOnly.sp')
	
	so.p = 'uhudhdu';
	is(so.look, 'uhudhdu', 'so.p');
	StoreOnly.sp = 'xuokqbq';
	is(so.look, 'xuokqbq', 'StoreOnly.sp');

	ok(uro.is_readonly('p'), "uro.is_readonly('p')");
	ok(uro.p === undefined, 'uro.p')
	ok(UndefReadOnly.is_readonly('sp'),
		"UndefReadOnly.is_readonly('sp')");
	ok(UndefReadOnly.sp === undefined, 'UndefReadOnly.sp')

}())
----

# make sure that $j->upgrade gets called on the return value of fetch
isa_ok $j->upgrade(knew PropsArray)->{prop1}, 'JE::String',
      '$j->upgrade(knew PropsArray)->{prop1}';
isa_ok $j->upgrade(knew PropsHashMethod)->{p1}, 'JE::String',
      '$j->upgrade(knew PropsHashMethod)->{p1}';
isa_ok $j->upgrade(knew PropsHashSub)->{p1},      'JE::String',
      '$j->upgrade(knew PropsHashSub)->{p1}';
isa_ok $j->upgrade(knew PropsHashHashMethod)->{p1}, 'JE::String',
      '$j->upgrade(knew PropsHashHashMethod)->{p1}';
isa_ok $j->upgrade(knew PropsHashHashSub)->{p1},      'JE::String',
      '$j->upgrade(knew PropsHashHashSub)->{p1}';


#--------------------------------------------------------------------#
# Test 112: Class bindings: wrappers

$j->bind_class(
	name => 'Wrappee',
	wrapper => sub { bless[], 'Wrapper' },
);

isa_ok $j->upgrade(bless[],'Wrappee'),'Wrapper', 'the wrapper';


#--------------------------------------------------------------------#
# Tests 113-46: Class bindings: arrays and hashes

@{$j->{Object}{prototype}}{0,'doodad'} = qw "something weird";

$j->bind_class(qw:
	name Arghh!
	array 1
:) ;

{
	my $a = $j->upgrade(bless \my @a, 'Arghh!');

	is $$a{0}, 'something',
		'proto array elems >length show through';
	$a[0]='12 plumbers plumbing';
	is $$a{0}, '12 plumbers plumbing';
	is $$a{length}++, 1;
	is @a, 2;
	is join(':-)', sort keys %$a), '0:-)doodad';
	delete $$a{0};
	is join(':-)', sort keys %$a), '0:-)doodad';
	is $$a{0}, 'undefined',
		'nonexistent array elem <length overrides proto';
	$$a{7} = 'aaa';
	is $$a{length}, 2, 'ary len after assing property >length (1-way)';
}

$j->bind_class(qw:
	name Arghh!
	array 2-way
:) ;

{
	my $a = $j->upgrade(bless \my @a, 'Arghh!');

	is $$a{0}, 'something',
		'proto array elems >length show through';
	$a[0]='12 plumbers plumbing';
	is $$a{0}, '12 plumbers plumbing';
	is $$a{length}++, 1;
	is @a, 2;
	is join(':-)', sort keys %$a), '0:-)doodad';
	delete $$a{0};
	is join(':-)', sort keys %$a), '0:-)doodad';
	is $$a{0}, 'undefined',
		'nonexistent array elem <length overrides proto';
	$$a{7} = 'aaa';
	is $$a{length}, 8, 'ary len after assing property >length (2-way)';
}



$j->bind_class(qw:
	name Hush!
	hash 1
:) ;

{
	my $a = $j->upgrade(bless \my %a, 'Hush!');
	$a{doodad}='10 prawns a creeping';
	$a{thing}++;

	is $$a{doodad}, '10 prawns a creeping';
	$$a{doodad} = '9 babies prancing';
	is $a{doodad}, '9 babies prancing';
	is join(':-)', sort keys %$a), '0:-)doodad:-)thing';
	delete $a{doodad};
	is join(':-)', sort keys %$a), '0:-)doodad:-)thing';
	is $$a{doodad}, 'weird';
}

$j->bind_class(qw:
	name Hush!
	hash 2
:) ;

{
	my $a = $j->upgrade(bless \my %a, 'Hush!');
	$a{doodad}='10 prawns a creeping';
	$a{thing}++;

	is $$a{doodad}, '10 prawns a creeping';
	$$a{doodad} = '9 babies prancing';
	is $a{doodad}, '9 babies prancing';
	is join(':-)', sort keys %$a), '0:-)doodad:-)thing';
	delete $a{doodad};
	is join(':-)', sort keys %$a), '0:-)doodad:-)thing';
	is $$a{doodad}, 'weird'; # test 138
}

{package Arrash;
	use overload fallback=>1,
		'@{}' => sub { \@{*{+shift}} },
		'%{}' => sub { \%{*{+shift}} };
}

$j->bind_class(qw 5
	name Arrash
	array 2
	hash 2.5
) ;

{
	use Symbol;
	bless my $g = gensym, 'Arrash';
	${*$g}{length} = 17;
	${*$g}{0} = '4 jolly nerds';
	${*$g}{doodad} = '3 henchmen';

	my $ugh = $j->upgrade($g);

	is $ugh->{0}, '4 jolly nerds';
	is $ugh->{length}, 0;
	$ugh->{length} = 17;
	is @{*$g}, 17;
	is $ugh->{doodad}, '3 henchmen';

	delete ${*$g}{0};
	delete ${*$g}{doodad};

	is $ugh->{0}, 'undefined';
	$ugh->{length} = 0;
	is $ugh->{0}, 'something';
	is $ugh->{doodad}, 'weird';

	is join(':-)', sort keys %$ugh), '0:-)doodad:-)length';
}


delete $j->{Object}{$_} for qw _0 doodad_;

#--------------------------------------------------------------------#
# Tests 147-90 (17+17+9+1=44): Class bindings: method return types

sub ___::AUTOLOAD{scalar reverse $___::AUTOLOAD}
sub ___::oof{}
sub ___::ooph{}

$j->bind_class(
	name => '___',
	methods => [qw[ foo:Number ___::bar ___::baz:null oof:null ]],
	static_methods =>[qw[FOO:Number ___::BAR ___::BAZ:null oof:null]],
	to_primitive => 'prim:Boolean',
	props => [qw[phoo:Number ___::barr ___::bazz:null ooph:null ]],
	static_props=>[qw[PHOO:Number ___::BARR ___::BAZZ:null ooph:null]],
);

{ # 17 tests here:
	my $foo = $j->upgrade(bless[],'___');
	is $foo->method('foo'), 'NaN', 'methods => [method:func]';
	is $foo->method('___::bar'), 'rab::___',
		'methods => [Package::method]';
	is $foo->method('___::baz'), 'zab::___',
		'methods => [Package::method:thing]';
	is $foo->method('oof'), 'null', 'methods => [method:null]';

	my $con#structor
		= $j->{___};
	is $con->method('FOO'), 'NaN', 'static_methods => [method:func]';
	is $con->method('___::BAR'), 'RAB::___',
		'static_methods => [Package::method]';
	is $con->method('___::BAZ'), 'ZAB::___',
		'static_methods => [Package::method:thing]';
	is $con->method('oof'), 'null', 'static_methods => [method:null]';

	is $foo->to_primitive, 'true', 'to_primtive => method:func';

	is $foo->{phoo}, 'NaN', 'props => [method:func]';
	is $foo->{'___::barr'}, 'rrab::___',
		'props => [Package::method]';
	is $foo->{'___::bazz'}, 'zzab::___',
		'props => [Package::method:thing]';
	is $foo->{ooph}, 'null', 'props => [method:null]';

	is $con->{PHOO}, 'NaN', 'static_props => [method:func]';
	is $con->{'___::BARR'}, 'RRAB::___',
		'static_props => [Package::method]';
	is $con->{'___::BAZZ'}, 'ZZAB::___',
		'static_props => [Package::method:thing]';
	is $con->{ooph}, 'null', 'static_props => [method:null]';

}

sub __::AUTOLOAD{scalar reverse $__'AUTOLOAD}
sub __::oof{}

$j->bind_class(
	name => '__',
	methods => {qw{
		phew foo:Number
		bare __::bar
		bass __::baz:null
		poof oof:null
	}},
	static_methods => {qw{
		PHEW foo:Number
		BARE __::BAR
		BASS __::BAZ:null
		POOF oof:null
	}},
	to_primitive => '__::prim:null',
	props => {qw{
		hati foo:Number
		uraa __::barr
		orut __::bazz:null
		hwha oof:null
	}},
	static_props => {qw{
		AHTI foo:Number
		URAI __::BARR
		ORUT __::BAZZ:null
		WHAT oof:null
	}},
);

{ # 17 tests here:
	my $foo = $j->upgrade(bless[],'__');
	is $foo->method('phew'), 'NaN',
		'methods => {name => method:func}';
	is $foo->method('bare'), 'rab::__',
		'methods => {name => Package::method}';
	is $foo->method('bass'), 'zab::__',
		'methods => {name => Package::method:thing}';
	is $foo->method('poof'), 'null',
		'methods => {name => method:null}';

	my $con#structor
		= $j->{__};
	is $con->method('PHEW'), 'NaN',
		'static_methods => {name => method:func}';
	is $con->method('BARE'), 'RAB::__',
		'static_methods => {name => Package::method}';
	is $con->method('BASS'), 'ZAB::__',
		'static_methods => {name => Package::method:thing}';
	is $con->method('POOF'), 'null',
		'static_methods => {name => method:null}';

	is $foo->to_primitive, 'mirp::__',
		'to_primtive => Pack::method:null';

	is $foo->{hati}, 'NaN', 'props => {name => method:func}';
	is $foo->{'uraa'}, 'rrab::__',
		'props => {name => Package::method}';
	is $foo->{'orut'}, 'zzab::__',
		'props => {name => Package::method:thing}';
	is $foo->{hwha}, 'null', 'props => {mname => ethod:null}';

	is $con->{AHTI}, 'NaN', 'static_props => {name => method:func}';
	is $con->{'URAI'}, 'RRAB::__',
		'static_props => {name => Package::method}';
	is $con->{'ORUT'}, 'ZZAB::__',
		'static_props => {name => Package::method:thing}';
	is $con->{WHAT}, 'null', 'static_props => {name => method:null}';

}

sub _::AUTOLOAD{scalar reverse $_'AUTOLOAD}
sub _::oof{}

$j->bind_class(
	name => '_',
	to_primitive => '_::prim',
	props => {
		hati => { fetch => 'foo:Number' },
		uraa => { fetch => '_::bar'     },
		orut => { fetch => '_::baz:null'},
		hwha => { fetch => 'oof:null'   },
	},
	static_props => {
		AHTI => { fetch => 'foo:Number' },
		URAI => { fetch => '_::BAR'     },
		ORUT => { fetch => '_::BAZ:null'},
		WHAT => { fetch => 'oof:null'   },
	},
);

{ # 9 tests here:
	my $foo = $j->upgrade(bless[],'_');

	is $foo->to_primitive, 'mirp::_',
		'to_primtive => Pack::method:null';

	is $foo->{hati}, 'NaN',
		'props => {name => {fetch => method:func}}';
	is $foo->{'uraa'}, 'rab::_',
		'props => {name => {fetch => Package::method}}';
	is $foo->{'orut'}, 'zab::_',
		'props => {name => {fetch => Package::method:thing}}';
	is $foo->{hwha}, 'null',
		'props => {mname => {fetch => ethod:null}}';

	my $con#structor
		= $j->{_};
	is $con->{AHTI}, 'NaN',
		'static_props => {name => {fetch => method:func}}';
	is $con->{'URAI'}, 'RAB::_',
		'static_props => {name => {fetch => Package::method}}';
	is $con->{'ORUT'}, 'ZAB::_',
		'static_props => {name => {fetch => Pack::method:thing}}';
	is $con->{WHAT}, 'null',
		'static_props => {name => {fetch => method:null}}';

}


sub ____::oof{}

$j->bind_class(
	name => '____',
	to_primitive => 'oof:null',
);

# 1 test here:
is $j->upgrade(bless[],'____')->to_primitive, 'null',
	'to_primitive => method:null';


#--------------------------------------------------------------------#
# Test 191: Class bindings: inherited property [gs]etters

$j->bind_class(package => 'base_class',
               props => { property => sub { ${+shift} } });
$j->bind_class(package => 'subclarce', isa => 'base_class');

{
	bless my $x = \(my $y = 'fo'), 'subclarce';
	is $j->upgrade($x)->{property}, 'fo',
		'inhertied property [gs]etters';
}

#--------------------------------------------------------------------#
# Tests 192-7: Class bindings: respect of Perl's overloading

{package ov; use overload '""' => sub { 43 }}
$j->bind_class(name => 'ov');
$j->bind_class(name => 'un');
is ($j->upgrade(bless [], 'ov')->to_string, 43,
	'Perl\'s string overloading in JS');
is ($j->upgrade(bless [], 'ov')->to_number, 43,
	'Perl\'s number overloading in JS');
is ($j->upgrade(bless [], 'ov')->to_primitive, 43,
	'Perl\'s overloading in JS');
is ($j->upgrade(bless [], 'un')->to_string, '[object un]',
	'Perl\'s stringification ignored without overloading');
is ($j->upgrade(bless [], 'un')->to_number, 'NaN',
	'Perl\'s numbification ignored without overloading');
is ($j->upgrade(bless [], 'un')->to_primitive, '[object un]',
	'Perl\'s stringification ignored without overloading (2)');

