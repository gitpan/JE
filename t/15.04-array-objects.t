#!perl -T
do './t/jstest.pl' or die __DATA__

function joyne (ary) { // Unlike the built-in, this does not convert
	var ret = '';      // undefined to an empty string.
	for(var i = 0; i<ary.length;++i)
		ret +=(i?',':'')+(i in ary ? ary[i] : '-')
	return ret
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

// ...

// ===================================================
// 15.4.4.10: sort
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'sort',1)

// 1 test from RT #39462 (by Christian Forster)
function UserSubmit(user,submits) 
{
	this.user=user;
	this.submits=submits;
}

function UserSubmitSort (a, b)
{
	return a.submits - b.submits;
}


var um=new Array(
	new UserSubmit("a",3),
	new UserSubmit("bc",1),
	new UserSubmit("add",35),
	new UserSubmit("eaea",23)
);

um.sort(UserSubmitSort);

output = ''
for(i=0;i<um.length;i++)
{
	output+=(um[i].submits+" "+um[i].user+"\n");
}

is(output, '1 bc\n3 a\n23 eaea\n35 add\n', 'sort with a custom routine')


// ~~~ need more sort tests

// ...

// ===================================================
// 15.4.4.12: splice
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'splice',2)

// 6 tests for fewer args than three
a = [1,2,3]
is(joyne(a.splice()), '', 'retval of argless splice')
is(joyne(a), '1,2,3', 'argless splice is of none effect');
is(joyne(a.splice(1)), '', 'retval of splice w/1 arg')
is(joyne(a), '1,2,3', 'splice w/1 arg hath none effect');
is(joyne(a.splice(1,1)), '2', 'retval of splice w/2 argz')
is(joyne(a), '1,3', 'effect of splice w/2 args');

// 9 tests for weird length values
a = {0:7,1:8,2:9,length:2.3}
is(joyne([].splice.call(a,1,7,6)), '8',
	'retval of splice on obj w/fractional len')
is( a[0] + '' + a[1] + a[2] + a.length, '7692',
	'affect of splice on obj with fractional length');
a = {length: -4294967290}
;[].splice.call(a,0,1)
is(a.length, 5, 'splice on obj w/negative length')
delete a.length
;[].splice.call(a,0,0,0)
is(a.length, 1, 'splice on obj w/no length')
a = {length: true}
;[].splice.call(a,0,0,0)
is(a.length, 2, 'splice on obj w/boolean length')
a = {length: null}
;[].splice.call(a,0,0,0)
is(a.length, 1, 'splice on obj w/null length')
a = {length: '2'}
;[].splice.call(a,0,0,0)
ok(a.length === 3, 'splice on obj w/string length') || diag (a.length)
a = {length: void 0}
;[].splice.call(a,0,0,0)
is(a.length, 1, 'splice on obj w/undef length')
a = {length: new String ("3")}
;[].splice.call(a,0,0,0)
ok(a.length === 4, 'splice on obj w/objectionable length')

// 18 tests for different start values
a = [1,2,3,4,5]
is(joyne(a.splice(2,1)), '3',
	'retval of splice with positive integer start')
is(joyne(a), '1,2,4,5', 'effect of splice with positive integer start');
is(joyne(a.splice(-3,1)), '2',
	'retval of splice with negative start')
is(joyne(a), '1,4,5', 'effect of splice with negative start');
is(joyne(a.splice(1.7,1,2,3,4)), '4',
	'retval of splice with fractional start')
is(joyne(a), '1,2,3,4,5', 'effect of splice with fractional start');
is(joyne(a.splice(true,1)), '2',
	'retval of splice with boolean start')
is(joyne(a), '1,3,4,5', 'effect of splice with boolean start');
is(joyne(a.splice(null,1)), '1',
	'retval of splice with null start')
is(joyne(a), '3,4,5', 'effect of splice with null start');
is(joyne(a.splice('2',1)), '5',
	'retval of splice with stringy start')
is(joyne(a), '3,4', 'effect of splice with stringy start');
is(joyne(a.splice(new String(0),1,7,8,9)), '3',
	'retval of splice with object start')
is(joyne(a), '7,8,9,4', 'effect of splice with objectionable start');
is(joyne(a.splice(undefined,1)), '7',
	'retval of splice with undefined start')
is(joyne(a), '8,9,4', 'effect of splice with undefined start');
is(joyne(a.splice(78,1,3)), '',
	'retval of splice with start > length')
is(joyne(a), '8,9,4,3', 'effect of splice with start > length');

// 20 tests for different delete counts
a = [1,2,3,4,5]
is(joyne(a.splice(2,-1)), '',
	'retval of splice with negative delete count')
is(joyne(a), '1,2,3,4,5', 'effect of splice with negative delete count');
is(joyne(a.splice(2,0)), '',
	'retval of splice with 0 for the delete count')
is(joyne(a), '1,2,3,4,5', 'effect of splice with 0 for the delete count');
is(joyne(a.splice(2,2)), '3,4',
	'retval of splice with positive integer delete count')
is(joyne(a), '1,2,5', 'effect of splice w/positive int delete count');
is(joyne(a.splice(0,2.3)), '1,2',
	'retval of splice with fractional delete count')
is(joyne(a), '5', 'effect of splice w/fractional delete count');
a = [1,2,3,4,5]
is(joyne(a.splice(2,7)), '3,4,5',
	'retval of splice with extra large delete count')
is(joyne(a), '1,2', 'effect of splice w/extra large delete count');
a = [1,2,3,4,5]
is(joyne(a.splice(2,true)), '3',
	'retval of splice with boolean delete count')
is(joyne(a), '1,2,4,5', 'effect of splice w/boolean delete count');
is(joyne(a.splice(2,'1')), '4',
	'retval of splice with stringy delete count')
is(joyne(a), '1,2,5', 'effect of splice w/stringy delete count');
is(joyne(a.splice(2,null)), '',
	'retval of splice with null delete count')
is(joyne(a), '1,2,5', 'effect of splice w/null delete count');
is(joyne(a.splice(2,undefined)), '',
	'retval of splice with undefined delete count')
is(joyne(a), '1,2,5', 'effect of splice w/undefined delete count');
is(joyne(a.splice(0,{toString: function(){return 2}})), '1,2',
	'retval of splice with object for the delete count')
is(joyne(a), '5', 'effect of splice w/object for the delete count');

// 5 tests for (non-)existent properties, and shifting of properties
a = [undefined,,3,5,7,,,undefined]
is(joyne(a.splice(0,3,"foo", void 0, void 0)), 'undefined,-,3',
  'splice retval: non-existent props, insert/remove same number of items')
is(joyne(a), 'foo,undefined,undefined,5,7,-,-,undefined',
  'splice effect: non-existent props, insert/remove same number of items')
a.splice(0,3)
is(joyne(a), '5,7,-,-,undefined',
  'splice shifting properties left')
a.splice(1,1,true,false)
is(joyne(a), '5,true,false,-,-,undefined',
  'splice shifting properties right')
a = {0: 7,1:8,2:9,length:3};
[].splice.call(a,0,1);
is(a[0]+''+a[1]+a[2]+' '+a.length, '899 2',
	"splice's weird behaviour when shifting left on a non-array obj");
	// (This is according to spec, but Safari and Opera don’t do this.
	//  SpiderMonkey does.)


// ...


// ---------------------------------------------------
// 4 tests: Make sure toString and toLocaleString die properly */

try { Array.prototype.toString.apply(3) }
catch(it) { ok(it.message.substring(0,22) == 'Object is not an Array')
            ok(it instanceof TypeError) }
try { Array.prototype.toLocaleString.apply(3) }
catch(it) { ok(it.message.substring(0,22) == 'Object is not an Array')
            ok(it instanceof TypeError) }


diag ("To do: Finish writing this script.")

