#!perl -T
do './t/jstest.pl' or die __DATA__

function is_nan(n){ // checks to see whether the number is *really* NaN
                    // & not something which converts to NaN when numified
	return n!=n
}

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
// 15.5.1: String as a function
// 7 tests
// ===================================================

ok(String() === '', 'String()')
ok(String(void 0) === 'undefined', 'String(undefined)')
ok(String(876) === '876', 'String(number)')
ok(String(true) === 'true', 'String(boolean)')
ok(String('ffo') === 'ffo', 'String(str)')
ok(String(null) === 'null', 'String(null)')
ok(String({}) === '[object Object]', 'String(object)')


// ===================================================
// 15.5.2: new String
// 9 tests
// ===================================================

ok(new String().constructor === String, 'prototype of new String')
is(Object.prototype.toString.apply(new String()), '[object String]',
	'class of new String')
ok(new String().valueOf() === '', 'value of new String')
ok(new String('foo').valueOf() === 'foo', 'value of new String(foo)')

ok(new String(void 0).valueOf() === 'undefined', 'new String(undefined)')
ok(new String(876).valueOf() === '876', 'new String(number)')
ok(new String(true).valueOf() === 'true', 'new String(boolean)')
ok(new String(null).valueOf() === 'null', 'new String(null)')
ok(new String({}).valueOf() === '[object Object]', 'new String(object)')


// ...

// ===================================================
// 15.5.4.8: lastIndexOf
// 18 tests
// ===================================================

0,function(){
	var f = String.prototype.lastIndexOf;
	ok(f.call(778, '7') === 1, 'lastIndexOf with number for this')
	ok(f.call({}, 'c') === 12, 'lastIndexOf with object for this')
	ok(f.call(false, 'a') === 1, 'lastIndexOf with boolean this')
}()
ok('undefined undefined'.lastIndexOf(undefined) === 10,
	'lastIndexOf with undefined search string')
ok('true true'.lastIndexOf(true) === 5, 'lastIndexOf w/boolean search str')
ok('null null'.lastIndexOf(null) === 5, 'lastIndexOf w/null search str');
ok ('3 3'.lastIndexOf(3) === 2, 'lastIndex of with numeric serach string')
ok('[object Object] [object Object]'.lastIndexOf({}) === 16,
	'lastIndexOf with objectionable search string')

ok('   '.lastIndexOf('', undefined) === 3, 'lastIndexOf w/undefined pos')
ok('   '.lastIndexOf('', false) === 0, 'lastIndexOf w/boolean pos');
ok('   '.lastIndexOf(' ', '1') === 1, 'lastIndexOf w/str pos');
ok('   '.lastIndexOf(' ', {}) === 2, 'lastIndexOf w/objectionable pos')
ok('   '.lastIndexOf(' ', null) === 0, 'lastIndexOf w/null pos');

ok('   '.lastIndexOf(' ', 1.2) === 1, 'lastIndexOf w/ fractional pos');
ok('   '. lastIndexOf(' ', -3) === -1, 'lastIndexOf w/neg pos (failed)');
ok('   '. lastIndexOf('', -3) === 0, 'lastIndexOf w/neg pos (matched)');
ok('   '. lastIndexOf(' ', 76) === 2, 'lastIndexOf w pos > length');

ok('   '.lastIndexOf('ntue') === -1, 'lastIndexOf w/failed match')

