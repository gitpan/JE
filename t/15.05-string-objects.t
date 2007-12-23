#!perl -T
do './t/jstest.pl' or die __DATA__

function is_nan(n){ // checks to see whether the number is *really* NaN
                    // & not something which converts to NaN when numified
	return n!=n
}

// ===================================================
// 15.5.1: String as a function
// ?? tests
// ===================================================

// to be written

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

