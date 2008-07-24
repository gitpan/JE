#!perl -T
do './t/jstest.pl' or die __DATA__


Array.prototype.joyne = function(){return peval('join ",",@{+shift}',this)}

/// ~~~ I need a test for new String().length’s type

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
// 15.5.3.2: fromCharCode
// ===================================================

// 10 tests
method_boilerplate_tests(String,'fromCharCode',1)

// 1 tests
is(String.fromCharCode(
	undefined,null,true,false,'a','3',{},NaN,+0,-0,Infinity,-Infinity,
	1,32.5,2147483648,3000000000,4000000000.23,5000000000,4294967296,
	4294967298.479,6442450942,6442450943.674,6442450944,6442450945,
	6442450946.74,-1,-32.5,-3000000000,-4000000000.23,-5000000000,
	-4294967298.479,-6442450942,-6442450943.674,-6442450944,
	-6442450945,-6442450946.74
), "\x00\x00\x01\x00\x00\x03\x00\x00\x00\x00\x00\x00\x01\x20\x00帀⠀\uf200"+
   "\x00\x02\ufffe\uffff\x00\x01\x02\uffff￠ꈀ\ud800\u0e00\ufffe\x02\x01" +
   "\x00\uffff\ufffe", 'fromCharCode')

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

// ...

// ===================================================
// 15.5.4.10: match
 // 18 tests or so
// ===================================================

/* cases to test

different input types for the this value

regexp.[[Class]] is RegExp
	if global is false
	if global is true
		if there is a match with an empty string
		if there is no match with an empty string
regexp of different types
	if global is false
	if global is true
		if there is a match with an empty string
		if there is no match with an empty string
omitted regexp
	if global is false
	if global is true
		if there is a match with an empty string
		if there is no match with an empty string

*/

// ===================================================
// 15.5.4.11: replace
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'replace',2)

// 3 tests: different types for this
0,function(){
	var f = String.prototype.replace;
	ok(f.call(78,'8',93) === '793', 'replace with number for this')
	is(f.call({}, /c/g, 'd'), '[objedt Objedt]',
		'replace with object for this')
	is(f.call(false, 'a', 'bx'), 'fbxlse', 'replace with boolean this')
}()

// 2 tests: missing args
is('fundefinedoo'.replace(), 'fundefinedoo', 'replace without args')
is('fundefinedoo'.replace(/f/g), 'undefinedundeundefinedinedoo',
	'replace with one arg')

// 19 tests: non-global regular expression
0,function(){
	var stuff = []
	is(' foo fbb'.replace(/f(.)()\1/, function(){
		stuff.push(arguments)
	   }), ' undefined fbb',
	   'replace with non-global re and function returning undefined')
	is(stuff.length, 1,
		'non-global re causes function to be called just once')
	is(stuff[0].length, 5,
		'(non-global re) number of arguments passed to function')
	is(stuff[0][0], 'foo',
		'(non-global re) arg 0 is the matched text')
	is(stuff[0][1], 'o', 
		'(non-global re) arg 1 is the first capture')
	is(stuff[0][2], '', 
		'(non-global re) arg 2 is the next capture')
	ok(stuff[0][3] === 1, 
		'(non-global re) arg -2 is the offset')
	is(stuff[0][4], ' foo fbb', 
		'(non-global re) arg -2 is the original string')
	is('foo'.replace(/o/, function(){return 'string'}), 'fstringo',
		'replace with non-global re and function returning string')
	is('foo'.replace(/o/, function(){return 38.3}), 'f38.3o',
		'replace with non-global re and function returning number')
	is('annoying'.replace(/noy/, function(){return null}), 'annulling',
		'replace with non-global re and function returning null')
	is('foo'.replace(/o/, function(){return {}}), 'f[object Object]o',
		'replace with non-global re and function returning object')
	is('foo'.replace(/o/, function(){return false}), 'ffalseo',
		'replace with non-global re and function returning bool')
	is('foo'.replace(/o/, undefined), 'fundefinedo',
		'replace with non-global re and undefined replacement')
	is('foo'.replace(/o/, null), 'fnullo',
		'replace with non-global re and null replacement')
	is('foo'.replace(/o/, 5), 'f5o',
		'replace with non-global re and numeric replacement')
	is('foo'.replace(/o/, {}), 'f[object Object]o',
		'replace with non-global re and objectionable replacement')
	is('foo'.replace(/o/, true), 'ftrueo',
		'replace with non-global re and veracious replacement')
	is('fordo'.replace(
		/(o)(.)|(?!f)()/,
		"[$$-$&-$`-$'-$1-$2-$3-$01-$02-$03]"
	   ),'f[$-or-f-do-o-r--o-r-]do',
	   'replace with non-global re and $ replacements')
}()

// 25 tests: global regular expression
0,function(){
	var stuff = []
	is(' foo fbb'.replace(/f(.)()\1/g, function(){
		stuff.push(arguments)
	   }), ' undefined undefined',
	   'replace with global re and function returning undefined')
	is(stuff.length, 2,
		'global re causes function to be called multiple times')
	is(stuff[0].length, 5,
		'(global re) num of arguments passed to function 1st time')
	is(stuff[0][0], 'foo',
		'(global re) arg 0 is the matched text 1st time')
	is(stuff[0][1], 'o', 
		'(global re) arg 1 is the first capture 1st time')
	is(stuff[0][2], '', 
		'(global re) arg 2 is the next capture 1st time')
	ok(stuff[0][3] === 1, 
		'(global re) arg -2 is the offset 1st time')
	is(stuff[0][4], ' foo fbb', 
		'(global re) arg -2 is the original string 1st time')
	is(stuff[1].length, 5,
		'(global re) num of arguments passed to function 2nd time')
	is(stuff[1][0], 'fbb',
		'(global re) arg 0 is the matched text 2nd time')
	is(stuff[1][1], 'b', 
		'(global re) arg 1 is the first capture 2nd time')
	is(stuff[1][2], '', 
		'(global re) arg 2 is the next capture 2nd time')
	ok(stuff[1][3] === 5, 
		'(global re) arg -2 is the offset 2nd time')
	is(stuff[1][4], ' foo fbb', 
		'(global re) arg -2 is the original string 2nd time')
	is('foo'.replace(/o/g, function(){return 'str'}), 'fstrstr',
		'replace with global re and function returning string')
	is('foo'.replace(/o/g, function(){return 38.3}), 'f38.338.3',
		'replace with global re and function returning number')
	is('nnoigno'.replace(/no/g,function(){return null}), 'nnullignull',
		'replace with global re and function returning null')
	is('foo'.replace(/o/g, function(){return {}}),
	   'f[object Object][object Object]',
		'replace with global re and function returning object')
	is('foo'.replace(/o/g, function(){return false}), 'ffalsefalse',
		'replace with global re and function returning bool')
	is('foo'.replace(/o/g, undefined), 'fundefinedundefined',
		'replace with global re and undefined replacement')
	is('foo'.replace(/o/g, null), 'fnullnull',
		'replace with global re and null replacement')
	is('foo'.replace(/o/g, 5), 'f55',
		'replace with global re and numeric replacement')
	is('foo'.replace(/o/g, {}), 'f[object Object][object Object]',
		'replace with global re and objectionable replacement')
	is('foo'.replace(/o/g, true), 'ftruetrue',
		'replace with global re and boolean replacement')
	is('fordo'.replace(
		/(o)(.?)|x()/g,
		"[$$-$&-$`-$'-$1-$2-$3-$01-$02-$03]"
	   ),'f[$-or-f-do-o-r--o-r-]d[$-o-ford--o---o--]',
	   'replace with global re and $ replacements')
}()

// 5 tests: different types for the searchValue
is('foo7'.replace(7,8), 'foo8', 'replace with numeric first arg')
is('footrue'.replace(true,8), 'foo8', 'replace with boolean first arg')
is('foo[object Object]'.replace({},8), 'foo8',
	'replace with objectionable first arg')
is('foonull'.replace(null,8), 'foo8', 'replace with null first arg')
is('fooundefined'.replace(void 0,8), 'foo8',
	'replace with undefined first arg')

// 17 tests: string search
0,function(){
	var stuff = []
	is('f.foo fbb'.replace('f.', function(){
		stuff.push(arguments)
	   }), 'undefinedfoo fbb',
	   'replace with search string and function returning undefined')
	is(stuff.length, 1,
		'string search causes function to be called just once')
	is(stuff[0].length, 3,
		'(string search) number of arguments passed to function')
	is(stuff[0][0], 'f.',
		'(string search) arg 0 is the matched text')
	ok(stuff[0][1] === 0, 
		'(string search) arg 1 is the offset')
	is(stuff[0][2], 'f.foo fbb', 
		'(string search) arg 2 is the original string')
	is('foo'.replace('o', function(){return 'string'}), 'fstringo',
		'replace with search string and function returning string')
	is('foo'.replace('o', function(){return 38.3}), 'f38.3o',
		'replace with search string and function returning number')
	is('annoying'.replace('noy', function(){return null}), 'annulling',
		'replace with search string and function returning null')
	is('foo'.replace('o', function(){return {}}), 'f[object Object]o',
		'replace with search string and function returning object')
	is('foo'.replace('o', function(){return false}), 'ffalseo',
		'replace with search string and function returning bool')
	is('foo'.replace('o', undefined), 'fundefinedo',
		'replace with search string and undefined replacement')
	is('foo'.replace('o', null), 'fnullo',
		'replace with search string and null replacement')
	is('foo'.replace('o', 5), 'f5o',
		'replace with search string and numeric replacement')
	is('foo'.replace('o', {}), 'f[object Object]o',
		'replace with search string and objectionable replacement')
	is('foo'.replace('o', true), 'ftrueo',
		'replace with search string and boolean replacement')
	is('fordo'.replace(
		'or',
		"[$$-$&-$`-$']"
	   ),'f[$-or-f-do]do',
	   'replace with search string and $ replacements')
}()

// 1 test
is("$1,$2".replace(/(\$(\d))/g, "$$1-$1$2"), "$1-$11,$1-$22",
	"$ example from the spec.")


// ...

// ===================================================
// 15.5.4.14: split
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'split',2)

// 8 tests
0,function(){
	var f = String.prototype.split;
	is(f.call(78,'8'), '7,', 'split with number for this')
	is(f.call({}, 'c'), '[obje,t Obje,t]',
		'split with object for this')
	is(f.call(false, 'a'), 'f,lse', 'split with boolean this')
}()
ok(Object.prototype.toString.apply('foo'.split('bar')) == '[object Array]',
   'split return type')
is('o-o-o-o-o'.split('-',-4294967200).joyne(), 'o,o,o,o,o',
	'split w/negative limit')
is('o-o-o-o-o'.split('-',3.2).joyne(), 'o,o,o','split w/fractional limit')
is('foo'.split(), 'foo', '"foo".split without args')
is(''.split(), '','"".split without args')

// 9 tests
is(''.split(/foo/,undefined).length, 1,
	'failed splitting of empty string on regexp with undefined limit')
is(''.split(/(?:)/,undefined).length, 0,
	'successful splitting of empty string on re with undefined limit')
is('ofxfoo'.split(/(?:f(?!o))?(?!fo)/,undefined).joyne(), 'o,xf,o,o',
	'splitting of non-empty string on re with undefined limit')
is('ofxfoo'.split(/f(x)?/,undefined).joyne(), 'o,x,,undefined,oo',
	'splitting of non-empty string on re w/captures & undefined limit')
is(''.split('foo',undefined).length, 0,
	'failed splitting of empty string on string with undefined limit')
is(''.split('',undefined).joyne(), '',
	'successful splitting of empty string on str with undefined limit')
is('foo'.split('o',undefined).joyne(), 'f,,',
	'split non-empty string on string with undefined limit')
is('foo'.split('',undefined).joyne(), 'f,o,o',
	'split non-empty string on empty string with undefined limit')
is('foo'.split(undefined,undefined).joyne(), 'foo',
	'split non-empty string on undefined with undefined limit')

// 9 tests
is(''.split(/foo/).length, 1,
	'failed splitting of empty string on regexp with no limit')
is(''.split(/(?:)/).length, '0',
	'successful splitting of empty string on re with no limit')
is('ofxfoo'.split(/(?:f(?!o))?(?!fo)/).joyne(), 'o,xf,o,o',
	'splitting of non-empty string on re with no limit')
is('ofxfoo'.split(/f(x)?/).joyne(), 'o,x,,undefined,oo',
	'splitting of non-empty string on re w/captures & no limit')
is(''.split('foo').length, 0,
	'failed splitting of empty string on string with no limit')
is(''.split('').joyne(), '',
	'successful splitting of empty string on str with no limit')
is('foo'.split('o').joyne(), 'f,,',
	'split non-empty string on string with no limit')
is('foo'.split('').joyne(), 'f,o,o',
	'split non-empty string on empty string with no limit')
is('foo'.split(undefined).joyne(), 'foo',
	'split non-empty string on undefined with no limit')

// 11 tests
is(''.split(/foo/,0).length, 0,
	'failed splitting of empty string on regexp with limit')
is(''.split(/(?:)/,7).length, 0,
	'successful splitting of empty string on re with limit')
is('ofxfoo'.split(/(?:f(?!o))?(?!fo)/,3).joyne(), 'o,xf,o',
	'splitting of non-empty string on re with limit')
is('ofxfooooo'.split(/x(f)(o)(o)/,3).joyne(), 'of,f,o',
	'splitting of non-empty string on re w/captures & limit')
is('ofxfooooo'.split(/x(f)(o)(o)/,29).joyne(), 'of,f,o,o,ooo',
	'splitting of non-empty string on re w/captures & unreached limit')
is(''.split('foo',7).length, 0,
	'failed splitting of empty string on string with limit')
is(''.split('',0).length, 0,
	'successful splitting of empty string on str with limit')
is('foo'.split('o',2).joyne(), 'f,',
	'split non-empty string on string with limit')
is('foo'.split('',2).joyne(), 'f,o',
	'split non-empty string on empty string with limit')
is('foo'.split('',23).joyne(), 'f,o,o',
	'split non-empty string on empty string with unreached limit')
is('foo'.split(undefined,2).joyne(), 'foo',
	'split non-empty string on undefined with limit')

// 4 tests
is('fo[object Object]o'.split({}), 'fo,o', 'split on object')
is('fo[trueo'.split(true), 'fo[,o', 'split on boolean')
is('fo[tru5o'.split(5), 'fo[tru,o', 'split on number')
is('fo[nulltru5o'.split(null), 'fo[,tru5o', 'split on null')

// 3 tests: Examples from the spec.
is('ab'.split(/a*?/), 'a,b', 'split on /a*?/')
is('ab'.split(/a*/).joyne(), ',b', 'split on /a*/')
is("A<B>bold</B>and<CODE>coded</CODE>".split(/<(\/)?([^<>]+)>/).joyne(),
	'A,undefined,B,bold,/,B,and,undefined,CODE,coded,/,CODE,',
	'long spec. example')

// 2 tests more
is('aardvark'.split(/a*?/), 'a,a,r,d,v,a,r,k', 'aardvark')
is('aardvark'.split(/(?=\w)a*?/), 'a,a,r,d,v,a,r,k', 'the aardvark again')

// ...

diag('TO DO: Finish writing this test script');
