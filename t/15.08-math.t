#!perl -T
do './t/jstest.pl' or die __DATA__

function approx(num,str,name) {
 is(num.toString().substring(0,str.toString().length) + typeof num,
    str+'number', name)
}

// ===================================================
// 15.8: Math
// 6 tests
// ===================================================

ok(Math.constructor === Object, 'prototype of Math')
is(Math, '[object Math]', 'default stringification of Math')
is(Object.prototype.toString.call(Math), '[object Math]', 'class of Math')
is(typeof Math, 'object','typeof Math is object, not function')
error=false
try{Math()}
catch(e){error=e}
ok(error instanceof TypeError, 'Math cannot be called as a function')
error = false
try{new Math()}
catch(e){error=e}
ok(error instanceof TypeError, 'Math cannot be called as a constructor')


// ===================================================
// 15.8.1.1: E
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('E'),
	'Math.E is not enumerable')
ok(!delete Math.E, 'Math.E cannot be deleted')
cmp_ok((Math.E = 7, Math.E), '!=', 7,
	'Math.E is read-only')
is(Math.E.toString().substring(0,12) + typeof Math.E, '2.7182818284number',
 'value of E')


// ===================================================
// 15.8.1.2: LN10
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('LN10'),
	'Math.LN10 is not enumerable')
ok(!delete Math.LN10, 'Math.LN10 cannot be deleted')
cmp_ok((Math.LN10 = 7, Math.LN10), '!=', 7,
	'Math.LN10 is read-only')
is(Math.LN10.toString().substring(0,12) + typeof Math.LN10,
 '2.3025850929number', 'value of LN10')


// ===================================================
// 15.8.1.3: LN2
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('LN2'),
	'Math.LN2 is not enumerable')
ok(!delete Math.LN2, 'Math.LN2 cannot be deleted')
cmp_ok((Math.LN2 = 7, Math.LN2), '!=', 7,
	'Math.LN2 is read-only')
is(Math.LN2.toString().substring(0,12) + typeof Math.LN2,
 '0.6931471805number', 'value of LN2')


// ===================================================
// 15.8.1.4: LOG2E
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('LOG2E'),
	'Math.LOG2E is not enumerable')
ok(!delete Math.LOG2E, 'Math.LOG2E cannot be deleted')
cmp_ok((Math.LOG2E = 7, Math.LOG2E), '!=', 7,
	'Math.LOG2E is read-only')
is(Math.LOG2E.toString().substring(0,12) + typeof Math.LOG2E,
 '1.4426950408number', 'value of LOG2E')


// ===================================================
// 15.8.1.5: LOG10E
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('LOG10E'),
	'Math.LOG10E is not enumerable')
ok(!delete Math.LOG10E, 'Math.LOG10E cannot be deleted')
cmp_ok((Math.LOG10E = 7, Math.LOG10E), '!=', 7,
	'Math.LOG10E is read-only')
is(Math.LOG10E.toString().substring(0,12) + typeof Math.LOG10E,
 '0.4342944819number', 'value of LOG10E')


// ===================================================
// 15.8.1.6: PIE
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('PI'),
	'Math.PI is not enumerable')
ok(!delete Math.PI, 'Math.PI cannot be deleted')
cmp_ok((Math.PI = 7, Math.PI), '!=', 7,
	'Math.PI is read-only')
is(Math.PI.toString().substring(0,12) + typeof Math.PI,
 '3.1415926535number', 'value of PI')


// ===================================================
// 15.8.1.7: SQRT1_2
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('SQRT1_2'),
	'Math.SQRT1_2 is not enumerable')
ok(!delete Math.SQRT1_2, 'Math.SQRT1_2 cannot be deleted')
cmp_ok((Math.SQRT1_2 = 7, Math.SQRT1_2), '!=', 7,
	'Math.SQRT1_2 is read-only')
ok(Math.SQRT1_2 === Math.pow(.5,.5), 'value of SQRT1_2')


// ===================================================
// 15.8.1.8: SQRT2
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('SQRT2'),
	'Math.SQRT2 is not enumerable')
ok(!delete Math.SQRT2, 'Math.SQRT2 cannot be deleted')
cmp_ok((Math.SQRT2 = 7, Math.SQRT2), '!=', 7,
	'Math.SQRT2 is read-only')
ok(Math.SQRT2 === Math.pow(2,.5), 'value of SQRT2')


// ===================================================
// 15.8.2.1: abs
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'abs',1)

// 5 tests for type conversion
ok(is_nan(Math.abs(undefined)), 'abs(undefined)')
ok(is_nan(Math.abs({})), 'abs(object)')
ok(Math.abs("-3") === 3, 'abs(string)')
ok(Math.abs(true) === 1, 'abs(bool)')
ok(Math.abs(null) === 0, 'abs(null)')

// 5 tests more
ok(Math.abs(-5)===5, 'abs(neg)')
ok(Math.abs(7)===7, 'abs(pos)')
is(Math.abs(NaN),NaN,' abs(NaN)')
is(1/Math.abs(-0), 'Infinity', 'abs(-0)')
is(Math.abs(-Infinity),Infinity,'abs(-inf)')


// ===================================================
// 15.8.2.2: acos
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'acos',1)

// 5 tests for type conversion
ok(is_nan(Math.acos(undefined)), 'acos(undefined)')
ok(is_nan(Math.acos({})), 'acos(object)')
approx(Math.acos("-.5"),2.09439510, 'acos(string)')
ok(Math.acos(true) === 0, 'acos(bool)')
approx(Math.acos(null), 1.57079632, 'acos(null)')

// 5 tests more
approx(Math.acos(.36), '1.202528433358', 'acos(.36)')
is(Math.acos(NaN),NaN,' acos(NaN)')
is(Math.acos(-2),NaN,' acos(<-1)')
is(Math.acos(1.1),NaN,' acos(>1)')
is(1/Math.acos(1), 'Infinity', 'acos(1)')


// ===================================================
// 15.8.2.3: asin
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'asin',1)

// 5 tests for type conversion
ok(is_nan(Math.asin(undefined)), 'asin(undefined)')
ok(is_nan(Math.asin({})), 'asin(object)')
approx(Math.asin("-.5"),-0.523598775598, 'asin(string)')
approx(Math.asin(true),1.57079632679, 'asin(bool)')
is(1/Math.asin(null), Infinity, 'asin(null)')

// 6 tests more
approx(Math.asin(.36), '0.3682678934366', 'asin(.36)')
is(Math.asin(NaN),NaN,' asin(NaN)')
is(Math.asin(-2),NaN,' asin(<-1)')
is(Math.asin(1.1),NaN,' asin(>1)')
is(1/Math.asin(0), 'Infinity', 'asin(0)')
try{skip("-0 is not supported",1);
    is(1/Math.asin(-0), '-Infinity', 'asin(-0)') }
catch(_){}

// ===================================================
// 15.8.2.4: atan
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'atan',1)

// 1 test
is(typeof Math.atan(0), 'number', 'Math.atan returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.5: atan2
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'atan2',2)

// 1 test
is(typeof Math.atan2(0), 'number', 'Math.atan2 returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.6: ceil
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'ceil',1)

// 1 test
is(typeof Math.ceil(0), 'number', 'Math.ceil returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.7: cos
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'cos',1)

// 1 test
is(typeof Math.cos(0), 'number', 'Math.cos returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.8: exp
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'exp',1)

// 1 test
is(typeof Math.exp(0), 'number', 'Math.exp returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.9: floor
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'floor',1)

// 1 test
is(typeof Math.floor(0), 'number', 'Math.floor returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.10: log
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'log',1)

// 1 test
is(typeof Math.log(0), 'number', 'Math.log returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.11: max
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'max',2)

// ... tests for type conversion ...

// 4 test
ok(Math.max() === -Infinity, 'argless max')
ok(is_nan(Math.max(3,NaN,4)), 'max with a nan arg')
ok(Math.max(1,3,-50,2) === 3, 'max with just numbers')
try{ skip("negative zero is not supported",1)
     is(1/Math.max(-0,0), Infinity, 'max considers 0 greater than -0') }
catch(_){}


// ===================================================
// 15.8.2.12: min
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'min',2)

// ... tests for type conversion ...

// 4 test
ok(Math.min() === Infinity, 'argless min')
ok(is_nan(Math.min(3,NaN,4)), 'min with a nan arg')
ok(Math.min(1,3,-50,2) === -50, 'min with just numbers')
try{ skip("negative zero is not supported",1)
     is(1/Math.min(-0,0), -Infinity, 'min considers 0 greater than -0') }
catch(_){}


// ===================================================
// 15.8.2.13: pow
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'pow',2)

// 1 test
is(typeof Math.pow(0,0), 'number', 'Math.pow returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.14: random
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'random',0)

// 1 test
is(typeof Math.random(),'number','Math.random returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.15: round
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'round',1)

// 1 test
is(typeof Math.round(0), 'number', 'Math.round returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.16: sin
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'sin',1)

// 1 test
is(typeof Math.sin(0), 'number', 'Math.sin returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.17: sqrt
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'sqrt',1)

// 1 test
is(typeof Math.sqrt(0), 'number', 'Math.sqrt returns number, not object')
// ... more tests ...

// ===================================================
// 15.8.2.18: tan
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'tan',1)

// 1 test
is(typeof Math.tan(0), 'number', 'Math.tan returns number, not object')
// ... more tests ...

diag('TO DO: Finish writing this test script');
