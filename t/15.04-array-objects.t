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
// 15.4.1 Array()
// ===================================================

// 5 tests (number of args != 1)
ok(Array().constructor === Array, 'prototype of retval of Array()')
is(Object.prototype.toString.apply(Array()), '[object Array]',
	'class of Array()')
ok(Array().length === 0, 'Array().length')
ok(Array(1,3,3).length === 3, 'Array(blah blah blah).length')
a =Array(1,"3",3) 
ok(a[0] === 1 && a[1]==='3' && a[2] ===3,
	'what happens to Array()\'s args')

// 9 tests (number of args == 1)
ok(Array(5).constructor === Array, 'prototype of retval of Array(num)')
is(Object.prototype.toString.apply(Array(4)), '[object Array]',
	'class of Array(num)')

error = false
try{Array(-67)}
catch(e){error = e}
ok(error instanceof RangeError, 'Array(-num)')

error = false
try{Array(38383783738773783)}
catch(e){error = e}
ok(error instanceof RangeError, 'Array(big num)')

ok(Array('5').length === 1, 'Array("num").length')
ok(Array('5')[0] === "5", 'Array("num")[0]')
ok(Array(new Number(6)).length === 1, 'Array(number obj)')
ok(Array("478887438888874347743").length === 1, 'Array("big num")')
is(Array('foo'), 'foo', 'Array(str)')


// ===================================================
// 15.4.2 new Array
// ===================================================

// 5 tests (number of args != 1)
ok(new Array().constructor === Array,	
	'prototype of retval of new Array()')
is(Object.prototype.toString.apply(new Array()), '[object Array]',
	'class of new Array()')
ok(new Array().length === 0, 'new Array().length')
ok(new Array(1,3,3).length === 3, 'new Array(blah blah blah).length')
a =new Array(1,"3",3) 
ok(a[0] === 1 && a[1]==='3' && a[2] ===3,
	'what happens to new Array()\'s args')

// 9 tests (number of args == 1)
ok(new Array(5).constructor === Array,
	'prototype of retval of new Array(num)')
is(Object.prototype.toString.apply(new Array(4)), '[object Array]',
	'class of new Array(num)')

error = false
try{new Array(-67)}
catch(e){error = e}
ok(error instanceof RangeError, 'new Array(-num)')

error = false
try{new Array(38383783738773783)}
catch(e){error = e}
ok(error instanceof RangeError, 'new Array(big num)')

ok(new Array('5').length === 1, 'new Array("num").length')
ok(new Array('5')[0] === "5", 'new Array("num")[0]')
ok(new Array(new Number(6)).length === 1, 'new Array(number obj)')
ok(new Array("478887438888874347743").length === 1, 'new Array("big num")')
is(new Array('foo'), 'foo', 'new Array(str)')


// ---------------------------------------------------
// 2 tests: Make sure toString and toLocaleString die properly */

try { Array.prototype.toString.apply(3) }
catch(it) { ok(it.message.substring(0,22) == 'Object is not an Array') }
try { Array.prototype.toLocaleString.apply(3) }
catch(it) { ok(it.message.substring(0,22) == 'Object is not an Array') }


