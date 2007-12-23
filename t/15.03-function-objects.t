#!perl -T
do './t/jstest.pl' or die __DATA__

// Every call to this runs 10 tests + the number of no-arg tests
function method_boilerplate_tests(proto,meth,length,noargobjs,noargresults)
{
	is(typeof proto[meth], 'function', 'typeof ' + meth);
	is(Object.prototype.toString.apply(proto[meth]),
		'[object Function]',
		'class of ' + meth)
	ok(proto[meth].constructor === Function, meth + '\'s prototype')
	var $catched = false;
	try{ new proto[meth] } catch(e) { $catched = e }
	ok($catched, 'new ' + meth + ' fails')
	ok(!('prototype' in proto[meth]), meth +
		' has no prototype property')
	ok(proto[meth].length === length, meth + '.length')
	ok(! proto[meth].propertyIsEnumerable('length'),
		meth + '.length is not enumerable')
	ok(!delete proto[meth].length, meth + '.length cannot be deleted')
	is((proto[meth].length++, proto[meth].length), length,
		meth + '.length is read-only')
	ok(!Object.prototype.propertyIsEnumerable(meth),
		meth + ' is not enumerable')
	for (var i = 0; i < noargobjs.length; ++i)
		ok(noargobjs[i][meth]() === noargresults[i],
			noargobjs[i] + '.' + meth + ' without args')
}

// ===================================================
// 15.3.2 Function()
// ===================================================

// 10 tests
ok(Function()() === void 0, 'Function()')
ok(Function()(838,389,98,8) === void 0,
	'retval of Function() ignores its args')
ok(Function().length === 0, 'Function().length')
ok(Function('return "a"').length === 0, 'Function(thing).length')
ok(Function('return "a"')() === "a", 'Function(thing) uses thing as body')
ok(Function('a,x/*','*/,c ','').length === 3, 'Function parameter lists')
ok(Function('a,x/*','*/,b\u200et','return[a,x,bt].join(" ")')(27,3,"a") ===
	'27 3 a', 'Function with format chars in the param list')

error = false
try{Function('eee,,,','body')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function with bad param list')

error = false
try{Function('eee','bo++dy')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function with bad body')

0,function(){
	var undefined = 'foo';
	ok(Function('return undefined')() === void 0,
		'Function()\'s scope chain')
}()

// 10 tests for type conversion
ok(Function(undefined)() === undefined, 'Function(undefined)')
ok(Function(true)() === undefined, 'Function(bool)')
ok(Function(34)()=== undefined, 'Function(num)')
ok(Function(null)()=== undefined, 'Function(null)')
error = false
try{Function({})}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function (obj)')
ok(Function(void 0, 'return undefined')(34) === 34,
	'Function(undefined, body)')
error = false
try{Function(22, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function (num, body)')

/* These two don’t die, because JE is lenient (which the spec allows):
error = false
try{Function(true, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function (bool, body)')
error = false
try{Function(null, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function (null, body)')
*/

// These work with JE, but if I ever make it more strict, I need to replace
// these tests with those above. It’s actually impossible to test that the
// vars named in the param list are created, since they cannot be accessed
// by name, but only through the arguments object.
ok(Function(true, '')() === undefined, 'Function(bool, body)')
ok(Function(null, '')()=== undefined, 'Function(null, body)')


error = false
try{Function({})}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function (obj, body)')


// ===================================================
// 15.3.2 Function()
// ===================================================

/// 2 tests
//ok(Function()() === void 0, 'Function()')
//ok(Function()(838,389,98,8) === void 0,
//	'retval of Function() ignores its args')

// ---------------------------------------------------
// 1 test:  Make sure Function.prototype.apply dies properly */

var error
try { Function.prototype.apply(3,4) }
catch(it) { it instanceof TypeError && (error = 1) }
ok(error, 'Function.prototype.apply(3,4) throws a TypeError')
