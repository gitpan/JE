#!perl -T
do './t/jstest.pl' or die __DATA__

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

// 1 test from RT #39462
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




// ---------------------------------------------------
// 4 tests: Make sure toString and toLocaleString die properly */

try { Array.prototype.toString.apply(3) }
catch(it) { ok(it.message.substring(0,22) == 'Object is not an Array')
            ok(it instanceof TypeError) }
try { Array.prototype.toLocaleString.apply(3) }
catch(it) { ok(it.message.substring(0,22) == 'Object is not an Array')
            ok(it instanceof TypeError) }


diag ("To do: Finish writing this script.")

