#!perl  -T

# Much of the stuff in here needs to be moved elsewhere.

BEGIN { require './t/test.pl' }

use Test::More tests => 128;
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
# Tests 10-12: numeric addition

ok $code = $j->parse('3+7.9');

isa_ok +($result = $code->execute), 'JE::Number';
ok $result == 10.9, 'JE::Number\'s overloaded ops';

#--------------------------------------------------------------------#
# Tests 13-14: array literals

ok $code = $j->parse('[1, 2,3+4]');

isa_ok +($result = $code->execute), 'JE::Object::Array';

#--------------------------------------------------------------------#
# Tests 15-20: object literals

ok $code = $j->parse('({a:"b"})');

isa_ok +($result = $code->execute), 'JE::Object';
ok $result eq '[object Object]', 'JE::Object\'s overloaded string op';
ok $result->{a} eq 'b', 'JE::Object\'s overloaded hash ref op';
ok ref($value = $result->value) eq 'HASH',
	'(obj)->value is hash ref';
ok $value->{a} eq 'b', '(obj)->value->{a} eq "b"';

#--------------------------------------------------------------------#
# Tests 21-3: bare identifiers

ok $code = $j->parse('parseFloat');

isa_ok +($result = $code->execute), 'JE::LValue';
isa_ok get $result, 'JE::Object::Function';

#--------------------------------------------------------------------#
# Tests 24-30: various js ops

ok $j->eval('x = 5')          eq '5';
ok $j->eval('!true ? x = 3 : y = "do\tenut"; y')    eq "do\tenut";
ok $j->eval('true ? x = 3 : y = "do\tenut"; x')          eq '3';
ok $j->eval("new(String)('𝄐').length")                          eq '2'; 
ok $j->eval("new String.prototype.constructor('A𝄫').length")      eq '3'; 
ok !defined $j->eval('{ a = 6; b= tru\u003d; }');
ok $j->eval("{ a = 6; b= 7; }")                                     eq '7'; 

#--------------------------------------------------------------------#
# Tests 31-40: more complicated js stuff

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

#--------------------------------------------------------------------#
# Tests 41-48: Class bindings: constructor and class names

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
# Tests 49-63: Class bindings: construction and method calls

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
# Tests 64-82: Class bindings: primitivisation

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
	is(     + t7 , NaN)
	error=false;try{'' + t7}catch(e){error = true}ok(error)
	error=false;try{'' + t8}catch(e){error = true}ok(error)
	error=false;try{+ t8}catch(e){error = true}ok(error)
	error=false;try{String(t8)}catch(e){error = true}ok(error)

})()
})() 


#--------------------------------------------------------------------#
# Tests 83-5: Class bindings: inheritance

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
# Test 86: Class bindings: proxy caching

{
	my $thing = bless [], 'RunningOutOfWeirdIdeas';
	is refaddr $j->upgrade($thing), refaddr $j->upgrade($thing),
		'proxy caching';
} 


#--------------------------------------------------------------------#
# Tests 87-126: Class bindings: properties

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
# Test 127: Class bindings: wrappers

$j->bind_class(
	name => 'Wrappee',
	wrapper => sub { bless[], 'Wrapper' },
);

isa_ok $j->upgrade(bless[],'Wrappee'),'Wrapper', 'the wrapper';




#--------------------------------------------------------------------#
# Test 128: Attempt to free unreferenced scalar in perl 5.8.x
# fixed via a workaround for perl bug #24254

# ~~~ This test should probably go in JE::Code, since that's what it's
#     related to.

{
	my $x;
	local $SIG{__WARN__} = sub { $x = $_[0] };
	$j->eval('a(I_hope_thiS_var_doesnt_exist+b)');
	is $x, undef, '"Attempt to free unreferenced scalar" avoided';
}
