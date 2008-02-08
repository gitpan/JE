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
// 15.3.1 Function()
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
// 15.3.2 new Function()
// ===================================================

// 10 tests
ok(new Function()() === void 0, 'new Function()')
ok(new Function()(838,389,98,8) === void 0,
	'retval of new Function() ignores its args')
ok(new Function().length === 0, 'new Function().length')
ok(new Function('return "a"').length === 0, 'new Function(thing).length')
ok(new Function('return "a"')() === "a",
	'new Function(thing) uses thing as body')
ok(new Function('a,x/*','*/,c ','').length === 3, 
	'new Function parameter lists')
ok(new Function('a,x/*','*/,b\u200et','return[a,x,bt].join(" ")')(27,3,"a")
	=== '27 3 a', 'new Function with format chars in the param list')

error = false
try{new Function('eee,,,','body')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function with bad param list')

error = false
try{new Function('eee','bo++dy')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function with bad body')

0,function(){
	var undefined = 'foo';
	ok(new Function('return undefined')() === void 0,
		'new Function()\'s scope chain')
}()

// 10 tests for type conversion
ok(new Function(undefined)() === undefined, 'new Function(undefined)')
ok(new Function(true)() === undefined, 'new Function(bool)')
ok(new Function(34)()=== undefined, 'new Function(num)')
ok(new Function(null)()=== undefined, 'new Function(null)')
error = false
try{new Function({})}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function (obj)')
ok(new Function(void 0, 'return undefined')(34) === 34,
	'new Function(undefined, body)')
error = false
try{new Function(22, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function (num, body)')

/* These two don’t die, because JE is lenient (which the spec allows):
error = false
try{new Function(true, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function (bool, body)')
error = false
try{new Function(null, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function (null, body)')
*/

// These work with JE, but if I ever make it more strict, I need to replace
// these tests with those above. It’s actually impossible to test that the
// vars named in the param list are created, since they cannot be accessed
// by name, but only through the arguments object.
ok(new Function(true, '')() === undefined, 'new Function(bool, body)')
ok(new Function(null, '')()=== undefined, 'new Function(null, body)')


error = false
try{new Function({})}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function (obj, body)')


// ===================================================
// 15.3.3 Function
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof Function, 'function', 'typeof Function');
is(Object.prototype.toString.apply(Function), '[object Function]',
	'class of Function')
ok(Function.constructor === Function, 'Function\'s prototype')
ok(Function.length === 1, 'Function.length')
ok(!Function.propertyIsEnumerable('length'),
	'Function.length is not enumerable')
ok(!delete Function.length, 'Function.length cannot be deleted')
is((Function.length++, Function.length), 1, 'Function.length is read-only')
ok(!Function.propertyIsEnumerable('prototype'),
	'Function.prototype is not enumerable')
ok(!delete Function.prototype, 'Function.prototype cannot be deleted')
//diag(Function.prototype)
cmp_ok((Function.prototype = 7, Function.prototype), '!=', 7,
	'Function.prototype is read-only')


// ===================================================
// 15.3.4 Function.prototype
// ===================================================

// 4 tests
is(Object.prototype.toString.apply(Function.prototype),
	'[object Function]',
	'class of Function.prototype')
ok(Function.prototype(1,2,{},[],"243987",null,false,undefined) === void 0,
	'Function.prototype()')
ok(peval('shift->prototype',Function.prototype) === Object.prototype,
	'Function.prototype\'s prototype')
ok(!Function.prototype.hasOwnProperty('valueOf'),
	'Function.prototype.valueOf')


// ===================================================
// 15.3.4.1 Function.prototype.constructor
// ===================================================

// 2 tests
ok(Function.prototype.hasOwnProperty('constructor'),
	'Function.prototype has its own constructor property')
ok(Function.prototype.constructor === Function,
	'value of Function.prototype.constructor')


// ===================================================
// 15.3.4.2 Function.prototype.toString
// ===================================================

 // 2 tests
// ok(Function.prototype.hasOwnProperty('constructor'),
//	'Function.prototype has its own constructor property')
 //ok(Function.prototype.constructor === Function,
//	'value of Function.prototype.constructor')



// ---------------------------------------------------
// 1 test:  Make sure Function.prototype.apply dies properly */

var error
try { Function.prototype.apply(3,4) }
catch(it) { it instanceof TypeError && (error = 1) }
ok(error, 'Function.prototype.apply(3,4) throws a TypeError')
