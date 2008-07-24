#!perl -T
do './t/jstest.pl' or die __DATA__

function is_nan(n) { return n != n }

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
	ok(!proto.propertyIsEnumerable(meth),
		meth + ' is not enumerable')
	if(!noargobjs)return;
	for (var i = 0; i < noargobjs.length; ++i)
		ok(noargobjs[i][meth]() === noargresults[i],
			noargobjs[i] + '.' + meth + ' without args')
}

// ===================================================
// 15.9.2 Date()
// ===================================================

// 8 tests
thyme = Date();
peval('sleep 2');
rosemary = Date(1,2.3,45);

ok(thyme.match(/^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ]
                 (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]
                 ([ \d]\d)\ (\d\d):(\d\d):(\d\d)\ (\d{4})
                 [ ][+-]\d{4}
               \z/x), // stolen from perl’s own tests (and modified)
	'thyme is the right format')
interval = new Date(thyme).getTimezoneOffset();
sign = interval > 0 ? '-' : '+';
interval = Math.abs(interval);
ok(thyme.substr(-5, 1) == sign &&
   (interval - interval % 60) / 60 == thyme.substr(-4,2) &&
   (interval % 60) == thyme.substring(thyme.length-2),
	'Date() time zone');

ok(rosemary.match(/^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ]
                    (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]
                    ([ \d]\d)\ (\d\d):(\d\d):(\d\d)\ (\d{4})
                    [ ][+-]\d{4}
                  \z/x),
	'rosemary is the right format')
interval = new Date(rosemary).getTimezoneOffset();
sign = interval > 0 ? '-' : '+';
interval = Math.abs(interval);
ok(rosemary.substr(-5, 1) == sign &&
   (interval - interval % 60) / 60 ==
	rosemary.substr(-4,2) &&
   (interval % 60) == rosemary.substring(rosemary.length-2),
	'time zone when Date() has args');

is(typeof thyme, 'string', 'Date() returns a string')
is(typeof rosemary, 'string', 'Date() with args returns a string')
cmp_ok( rosemary, 'ne', thyme,
	'Date() returns something different 2 secs later')
cmp_ok( Date.parse(thyme), '<', Date.parse(rosemary),
	'what it returns is a later time')

// # ~~~ need to test whether the time zone is set correctly


// ===================================================
// 15.9.3.1 new Date (2-7 args)
// ===================================================

// 18 tests

thyme = new Date(89, 4)
ok(thyme.constructor === Date, 'prototype of retval of new Date(foo,foo)')
is(Object.prototype.toString.call(thyme), '[object Date]',
	'class of new Date(foo,foo)')
is(thyme.getFullYear(), 1989, '2-digit first arg to new Date(foo,foo)')
is(thyme.getMonth(), 4, '2nd arg to new Date(foo,foo)')
is(new Date(0,3).getFullYear(), 1900, 'new Date(0,foo)')
is(new Date(99,2).getFullYear(), 1999, 'new Date(99,foo)')
is(new Date(100,3).getFullYear(), 100, 'new Date(100,foo)')
is(new Date(NaN,3).valueOf(), NaN, 'new Date(NaN, foo)')
is(new Date(2007,11,24).getDate(), 24, '3rd arg to new Date')
is(new Date(2007,11).getDate(), 1, 'implied 3rd arg to new Date')
is(new Date(2007,11,24,23).getHours(), 23, '4th arg to new Date')
is(new Date(2007,11,24).getHours(), 0, 'implied 4th arg to new Date')
is(new Date(2007,11,24,23,36).getMinutes(), 36, '5th arg to new Date')
is(new Date(2007,11,24,23).getMinutes(), 0, 'implied 5th arg to new Date')
is(new Date(2007,11,24,23,36,20).getSeconds(), 20, '6th arg to new Date')
is(new Date(2007,11,24,23,36).getSeconds(), 0,
	'implied 6th arg to new Date')
is(new Date(2007,11,24,23,36,20,865).getMilliseconds(), 865,
	'7th arg to new Date')
is(new Date(2007,11,24,23,36,20).getMilliseconds(), 0,
	'implied 7th arg to new Date')

// 11 tests (MakeDay)
is(new Date(0,NaN).valueOf(), NaN, 'new Date with NaN month')
is(new Date(0,0,NaN).valueOf(), NaN, 'new Date with nan date within month')
is(new Date(Infinity,0).valueOf(), NaN, 'new Date with inf year')
is(new Date(0,Infinity).valueOf(), NaN, 'new Date with inf month')
is(new Date(0,0,Infinity).valueOf(), NaN, 'new Date with inf mdate')
is(new Date(2007.87,0).getFullYear(), 2007, 'new Date with float year')
is(new Date(0,7.87).getMonth(), 7, 'new Date with float month')
is(new Date(0,0,27.87).getDate(), 27, 'new Date with float mdate')
is(new Date(0,0,32).getMonth(), 1, 'new Date\'s date overflow')
is(new Date(0,0,32).getDate(), 1, 'new Date\'s date overflow (again)')
is(new Date(0,85,32).valueOf(), NaN, 'new Date with month out of range')

// 12 tests for MakeTime
is(new Date(0,0,1,6.5,0,0).getHours(), 6, 'new Date with float hours')
is(new Date(0,0,1,0,5.8,0).getMinutes(), 5, 'new Date with float mins')
is(new Date(0,0,1,0,5.8,7.9).getSeconds(), 7, 'new Date with float secs')
is(new Date(0,0,1,0,0,0,7.9).getMilliseconds(), 7, 'new Date w/ float ms')
is(new Date(0,0,1,26).getHours(), 2, 'new Date with hour overflow')
is(new Date(0,0,1,26).getDate(), 2, 'new Date with hour overflow (again)')
is(new Date(0,0,1,0,61).getMinutes(), 1, 'new Date w/min overflow')
is(new Date(0,0,1,0,61).getHours(), 1, 'new Date w/min overflow (again)')
is(new Date(0,0,1,0,0,65).getSeconds(), 5, 'new Date with sec overflow')
is(new Date(0,0,1,0,0,65).getMinutes(), 1, 'new Date w/sec overflow again')
is(new Date(0,0,1,0,0,0,1200).getMilliseconds(), 200,
	'new Date with ms overflow')
is(new Date(0,0,1,0,0,0,1200).getSeconds(), 1,
	'new Date with ms overflow (again)')

// 4 tests for MakeDate
is(new Date(0,0,1,Infinity).valueOf(), NaN, 'new Date with infinite hours')
is(new Date(0,0,1,0,Infinity).valueOf(), NaN, 'new Date w/infinite mins')
is(new Date(0,0,1,0,0,Infinity).valueOf(), NaN, 'new Date w/infinite secs')
is(new Date(0,0,1,0,0,0,Infinity).valueOf(), NaN, 'new Date w/infinite ms')

// 2 tests for ThymeClip
is(new Date(285619+1970,0).valueOf(), NaN,
	'new Date with year out of range')
is(new Date(1970-285619,0).valueOf(), NaN,
	'new Date with negative year out of range')

// 1 test for UTC
thyme = new Date(7,8)
is(thyme.valueOf() - Date.UTC(7,8), thyme.getTimezoneOffset() * 60000,
	'new Date(foo,foo)\'s local-->GMT conversion')

// 5 tests for type conversion
d = new Date(null,null,null,null,null,null,null)
is(+d, -2209075200000 + d.getTimezoneOffset()*60000,
	'new Date(nullx7)')
is(+new Date(void 0,void 0,void 0,void 0,void 0,void 0,void 0), NaN,
	'new Date(undefinedx7)')
d = new Date(true,true,true,true,true,true,true)
is(+d, -2174770738999 + d.getTimezoneOffset()*60000,
	'new Date(boolx7)')
d = new Date('1','1','1','1','1','1','1')
is(+d, -2174770738999 + d.getTimezoneOffset()*60000,
	'new Date(strx7)')
is(+new Date({},{},{},{},{},{},{}), NaN,
	'new Date(objx7)')


// ===================================================
// 15.9.3.2 new Date (1 arg)
// ===================================================

// 10 tests

thyme = new Date(89)
ok(thyme.constructor === Date, 'prototype of retval of new Date(foo)')
is(Object.prototype.toString.call(thyme), '[object Date]',
	'class of new Date(foo)')
ok(thyme.valueOf()===89, 'value of new Date(num)')
ok(new Date(new Number(673)).valueOf()===673,
	'value of new Date(new Number)')
is(new Date(8.65e15).valueOf(), NaN, 'value of new Date(8.65e15)')
is(new Date('Wed, 28 May 268155 05:20:00 GMT').valueOf(), 8400000000000000,
	'new Date(gmt string)')
is(new Date(new String('Mon, 31 Dec 2007 17:59:32 GMT')).valueOf(),
	1199123972000, 'new Date(gmt string obj)')
is(new Date('Tue Apr 11 08:06:40 271324 -0700').getTime(),
	8500000000000000, 'new Date(c string)')
is(new Date(new String('Mon Dec 31 11:42:40 2007 -0800')).getTime(),
	1199130160000, 'new Date(c string object)')
is(+new Date('1 apr 2007 GMT'), 1175385600000,
	'new Date(str) using Date::Parse')

// 4 tests for type conversion
is(+new Date(undefined), NaN, 'new Date(undefined)')
is(+new Date(true), 1, 'new Date(bool)')
is(+new Date(null), 0, 'new Date(null)')
is(new Date({
	toString: function(){return '4 apr 2007'},
	valueOf: function(){ return '1 apr 2007' /* april fools’ */ }
}).getDate(), 4,
'new Date(foo) parses foo, not foo->primitive, when the latter is a string'
)


// ===================================================
// 15.9.3.3 new Date
// ===================================================

// 3 tests

thyme = new Date()
ok(thyme.constructor === Date, 'prototype of retval of new Date')
is(Object.prototype.toString.call(thyme), '[object Date]',
	'class of new Date()')
peval('sleep 2')
rosemary = new Date
cmp_ok(rosemary, ">", thyme,
	'new Date returns a different time 2 secs later')


// ===================================================
// 15.9.4 Date
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof Date, 'function', 'typeof Object');
is(Object.prototype.toString.apply(Date), '[object Function]',
	'class of Date')
ok(Date.constructor === Function, 'Date\'s prototype')
ok(Date.length === 7, 'Date.length')
ok(!Date.propertyIsEnumerable('length'),
	'Date.length is not enumerable')
ok(!delete Date.length, 'Date.length cannot be deleted')
is((Date.length++, Date.length), 7, 'Date.length is read-only')
ok(!Date.propertyIsEnumerable('prototype'),
	'Date.prototype is not enumerable')
ok(!delete Date.prototype, 'Date.prototype cannot be deleted')
cmp_ok((Date.prototype = 24, Date.prototype), '!=', 24,
	'Date.prototype is read-only')


// ===================================================
// 15.9.4.2 Date.parse
// ===================================================

// 10 tests
method_boilerplate_tests(Date,'parse',1)

// 5 tests
ok(is_nan(Date.parse()), 'Date.parse without args')
ok(Date.parse('Wed, 28 May 268155 05:20:00 GMT') === 8400000000000000,
	'Date.parse(gmt string)')
is(Date.parse(new String('Mon, 31 Dec 2007 17:59:32 GMT')),
	1199123972000, 'Date.parse(gmt string obj)')
is(Date.parse('Tue Apr 11 08:06:40 271324 -0700'),
	8500000000000000, 'Date.parse(c string)')
is(Date.parse('1 apr 2007 GMT'), 1175385600000,
	'Date.parse(str) using Date::Parse')

// 4 tests for type conversion
is(Date.parse(null), NaN, 'Date.parse(null)')
is(Date.parse(void 0), NaN, 'Date.parse(undefined)')
is(Date.parse(true), NaN, 'Date.parse(bool)')
is(Date.parse(678), Date.parse('678'), 'Date.parse(number)')


// ===================================================
// 15.9.4.3 Date.UTC
// ===================================================

// 10 tests
method_boilerplate_tests(Date,'UTC',7)

// 12 tests
ok(is_nan(Date.UTC()), 'Date.UTC()')
ok(is_nan(Date.UTC(1)),'Date.UTC(1 arg)')
ok(Date.UTC(89,4) === 609984000000,
	'Date.UTC(foo,foo) with 2-digit first arg')
is(Date.UTC(0,3), -2201212800000, 'Date.UTC(0,foo)')
is(Date.UTC(99,2), 920246400000, 'Date.UTC(99,foo)')
is(Date.UTC(100,3), -59003683200000, 'Date.UTC(100,foo)')
is(Date.UTC(NaN,3), NaN, 'Date.UTC(NaN, foo)')
is(Date.UTC(2007,11,24), 1198454400000, 'Date.UTC(3 args)')
is(Date.UTC(2007,11,24,23), 1198537200000, 'Date.UTC(4 args)')
is(Date.UTC(2007,11,24,23,36), 1198539360000, 'Date.UTC(5 args)')
is(Date.UTC(2007,11,24,23,36,20), 1198539380000, 'Date.UTC (6 args)')
is(Date.UTC(2007,11,24,23,36,20,865), 1198539380865,
	'Date.UTC (7 args)')

// 10 tests (MakeDay)
is(Date.UTC(0,NaN), NaN, 'Date.UTC with NaN month')
is(Date.UTC(0,0,NaN), NaN, 'Date.UTC with nan date within month')
is(Date.UTC(Infinity,0), NaN, 'Date.UTC with inf year')
is(Date.UTC(0,Infinity), NaN, 'Date.UTC with inf month')
is(Date.UTC(0,0,Infinity), NaN, 'Date.UTC with inf mdate')
is(Date.UTC(2007.87,0), 1167609600000, 'Date.UTC with float year')
is(Date.UTC(0,7.87), -2190672000000, 'Date.UTC with float month')
is(Date.UTC(0,0,27.87), -2206742400000, 'Date.UTC with float mdate')
is(Date.UTC(0,0,32), -2206310400000, 'Date.UTC\'s date overflow')
is(Date.UTC(0,85,32), NaN, 'Date.UTC with month out of range')

// 8 tests for MakeTime
is(Date.UTC(0,0,1,6.5,0,0), -2208967200000, 'Date.UTC with float hours')
is(Date.UTC(0,0,1,0,5.8,0), -2208988500000, 'Date.UTC with float mins')
is(Date.UTC(0,0,1,0,5.8,7.9), -2208988493000, 'Date.UTC with float secs')
is(Date.UTC(0,0,1,0,0,0,7.9), -2208988799993, 'Date.UTC w/ float ms')
is(Date.UTC(0,0,1,26), -2208895200000, 'Date.UTC with hour overflow')
is(Date.UTC(0,0,1,0,61), -2208985140000, 'Date.UTC w/min overflow')
is(Date.UTC(0,0,1,0,0,65), -2208988735000, 'Date.UTC with sec overflow')
is(Date.UTC(0,0,1,0,0,0,1200), -2208988798800,
	'Date.UTC with ms overflow')

// 4 tests for MakeDate
is(Date.UTC(0,0,1,Infinity), NaN, 'Date.UTC with infinite hours')
is(Date.UTC(0,0,1,0,Infinity), NaN, 'Date.UTC w/infinite mins')
is(Date.UTC(0,0,1,0,0,Infinity), NaN, 'Date.UTC w/infinite secs')
is(Date.UTC(0,0,1,0,0,0,Infinity), NaN, 'Date.UTC w/infinite ms')

// 2 tests for ThymeClip
is(Date.UTC(285619+1970,0), NaN,
	'Date.UTC with year out of range')
is(Date.UTC(1970-285619,0), NaN,
	'Date.UTC with negative year out of range')

// 5 tests for type conversion
is(+Date.UTC(null,null,null,null,null,null,null), -2209075200000,
	'Date.UTC(nullx7)')
is(+Date.UTC(void 0,void 0,void 0,void 0,void 0,void 0,void 0), NaN,
	'Date.UTC(undefinedx7)')
is(+Date.UTC(true,true,true,true,true,true,true), -2174770738999,
	'Date.UTC(boolx7)')
is(+Date.UTC('1','1','1','1','1','1','1'), -2174770738999,
	'Date.UTC(strx7)')
is(+Date.UTC({},{},{},{},{},{},{}), NaN,
	'Date.UTC(objx7)')


// ===================================================
// 15.9.5 Date.prototype
// ===================================================

// 3 tests
is(Object.prototype.toString.apply(Date.prototype), '[object Date]',
	'class of Date.prototype')
ok(is_nan(Date.prototype.valueOf()), 'value of Date.prototype')
peval('is shift->prototype, shift, "Date.prototype\' prototype"',
	Date.prototype, Object.prototype)

// ===================================================
// 15.9.5.1 Date.prototype.constructor
// ===================================================

// 2 tests
ok(Date.prototype.constructor === Date, 'Date.prototype.constructor')
ok(!Date.prototype.propertyIsEnumerable('constructor'),
	'Date.prototype.constructor is not enumerable')


// ===================================================
// 15.9.5.2 Date.prototype.toString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toString',0)

// 21 tests
match = new Date(1199275200000).toString().match(
    /^(T(?:ue|hu)|Wed) Jan  (\d) (\d\d):(\d\d):00 2008 ([+-])(\d\d)(\d\d)$/
)
ok(match && (
	match[1] == 'Tue' && match[2] == 1 && match[5] == '-' &&
		36-match[3]*60-match[4] == -match[6]*60+match[7]
	  ||
	match[1] == 'Wed' && match[2] == 2 &&
	    (match[5]+match[6])*-60+ +match[7] +
	     match[3]*60+ +match[4]          == 720
	  ||
	match[1] == 'Thu' && match[2] == 3 && match[5] == '+' &&
		match[6]*60+ +match[7]-match[3]*60-match[4] == 720
), 'toString')

is(new Date(2008,0,6).toString().substring(0,3), 'Sun', 'toString - Sun')
is(new Date(2008,0,7).toString().substring(0,3), 'Mon', 'toString - Mon')
is(new Date(2008,0,8).toString().substring(0,3), 'Tue', 'toString - Tue')
is(new Date(2008,0,9).toString().substring(0,3), 'Wed', 'toString - Wed')
is(new Date(2008,0,10).toString().substring(0,3), 'Thu', 'toString - Thu')
is(new Date(2008,0,11).toString().substring(0,3), 'Fri', 'toString - Fri')
is(new Date(2008,0,12).toString().substring(0,3), 'Sat', 'toString - Sat')
is(new Date(2008,0).toString().substring(4,7), 'Jan', 'toString - Jan')
is(new Date(2008,1).toString().substring(4,7), 'Feb', 'toString - Feb')
is(new Date(2008,2).toString().substring(4,7), 'Mar', 'toString - Mar')
is(new Date(2008,3).toString().substring(4,7), 'Apr', 'toString - Apr')
is(new Date(2008,4).toString().substring(4,7), 'May', 'toString - May')
is(new Date(2008,5).toString().substring(4,7), 'Jun', 'toString - Jun')
is(new Date(2008,6).toString().substring(4,7), 'Jul', 'toString - Jul')
is(new Date(2008,7).toString().substring(4,7), 'Aug', 'toString - Aug')
is(new Date(2008,8).toString().substring(4,7), 'Sep', 'toString - Sep')
is(new Date(2008,9).toString().substring(4,7), 'Oct', 'toString - Oct')
is(new Date(2008,10).toString().substring(4,7), 'Nov', 'toString - Nov')
is(new Date(2008,11).toString().substring(4,7), 'Dec', 'toString - Dec')

error = false
try{Date.prototype.toString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toString death')

// ===================================================
// 15.9.5.3 Date.prototype.toDateString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toDateString',0)

// 21 tests
match = (d = new Date(1199275200000)).toDateString().match(
    /^(T(?:ue|hu)|Wed) Jan (\d) 2008$/
)
o = d.getTimezoneOffset();
ok(match && (
	o > 720 ? match[1] == 'Tue' && match[2] == 1 :
	o > -720 ? match[1] == 'Wed' && match[2] == 2 :
	            match[1] == 'Thu' && match[2] == 3
), 'toDateString')

is(new Date(2008,0,6).toDateString().substring(0,3), 'Sun',
	'toDateString - Sun')
is(new Date(2008,0,7).toDateString().substring(0,3), 'Mon',
	'toDateString - Mon')
is(new Date(2008,0,8).toDateString().substring(0,3), 'Tue',
	'toDateString - Tue')
is(new Date(2008,0,9).toDateString().substring(0,3), 'Wed',
	'toDateString - Wed')
is(new Date(2008,0,10).toDateString().substring(0,3), 'Thu',
	'toDateString - Thu')
is(new Date(2008,0,11).toDateString().substring(0,3), 'Fri',
	'toDateString - Fri')
is(new Date(2008,0,12).toDateString().substring(0,3), 'Sat',
	'toDateString - Sat')
is(new Date(2008,0).toDateString().substring(4,7), 'Jan',
	'toDateString - Jan')
is(new Date(2008,1).toDateString().substring(4,7), 'Feb',
	'toDateString - Feb')
is(new Date(2008,2).toDateString().substring(4,7), 'Mar',
	'toDateString - Mar')
is(new Date(2008,3).toDateString().substring(4,7), 'Apr',
	'toDateString - Apr')
is(new Date(2008,4).toDateString().substring(4,7), 'May',
	'toDateString - May')
is(new Date(2008,5).toDateString().substring(4,7), 'Jun',
	'toDateString - Jun')
is(new Date(2008,6).toDateString().substring(4,7), 'Jul',
	'toDateString - Jul')
is(new Date(2008,7).toDateString().substring(4,7), 'Aug',
	'toDateString - Aug')
is(new Date(2008,8).toDateString().substring(4,7), 'Sep',
	'toDateString - Sep')
is(new Date(2008,9).toDateString().substring(4,7), 'Oct',
	'toDateString - Oct')
is(new Date(2008,10).toDateString().substring(4,7), 'Nov',
	'toDateString - Nov')
is(new Date(2008,11).toDateString().substring(4,7), 'Dec',
	'toDateString - Dec')

error = false
try{Date.prototype.toDateString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toDateString death')


// ===================================================
// 15.9.5.4 Date.prototype.toTimeString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toTimeString',0)

// 2 tests
match = (d = new Date(1199275200000)).toTimeString().match(
    /^(\d\d):(\d\d):00$/
)
t = 720-d.getTimezoneOffset();
ok(match && match[1] == (t-t%60)/60%24 && match[2] == t%60, 'toTimeString')

error = false
try{Date.prototype.toTimeString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toTimeString death')


// ===================================================
// 15.9.5.5 Date.prototype.toLocaleString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toLocaleString',0)

// 21 tests
match = new Date(1199275200000).toLocaleString().match(
    /^(T(?:ue|hu)|Wed) Jan  (\d) (\d\d):(\d\d):00 2008 ([+-])(\d\d)(\d\d)$/
)
ok(match && (
	match[1] == 'Tue' && match[2] == 1 && match[5] == '-' &&
		36-match[3]*60-match[4] == -match[6]*60+match[7]
	  ||
	match[1] == 'Wed' && match[2] == 2 &&
	    (match[5]+match[6])*-60+ +match[7] +
	     match[3]*60+ +match[4]          == 720
	  ||
	match[1] == 'Thu' && match[2] == 3 && match[5] == '+' &&
		match[6]*60+ +match[7]-match[3]*60-match[4] == 720
), 'toLocaleString')

is(new Date(2008,0,6).toLocaleString().substring(0,3), 'Sun',
	'toLocaleString - Sun')
is(new Date(2008,0,7).toLocaleString().substring(0,3), 'Mon',
	'toLocaleString - Mon')
is(new Date(2008,0,8).toLocaleString().substring(0,3), 'Tue',
	'toLocaleString - Tue')
is(new Date(2008,0,9).toLocaleString().substring(0,3), 'Wed',
	'toLocaleString - Wed')
is(new Date(2008,0,10).toLocaleString().substring(0,3), 'Thu',
	'toLocaleString - Thu')
is(new Date(2008,0,11).toLocaleString().substring(0,3), 'Fri',
	'toLocaleString - Fri')
is(new Date(2008,0,12).toLocaleString().substring(0,3), 'Sat',
	'toLocaleString - Sat')
is(new Date(2008,0).toLocaleString().substring(4,7), 'Jan',
	'toLocaleString - Jan')
is(new Date(2008,1).toLocaleString().substring(4,7), 'Feb',
	'toLocaleString - Feb')
is(new Date(2008,2).toLocaleString().substring(4,7), 'Mar',
	'toLocaleString - Mar')
is(new Date(2008,3).toLocaleString().substring(4,7), 'Apr',
	'toLocaleString - Apr')
is(new Date(2008,4).toLocaleString().substring(4,7), 'May',
	'toLocaleString - May')
is(new Date(2008,5).toLocaleString().substring(4,7), 'Jun',
	'toLocaleString - Jun')
is(new Date(2008,6).toLocaleString().substring(4,7), 'Jul',
	'toLocaleString - Jul')
is(new Date(2008,7).toLocaleString().substring(4,7), 'Aug',
	'toLocaleString - Aug')
is(new Date(2008,8).toLocaleString().substring(4,7), 'Sep',
	'toLocaleString - Sep')
is(new Date(2008,9).toLocaleString().substring(4,7), 'Oct',
	'toLocaleString - Oct')
is(new Date(2008,10).toLocaleString().substring(4,7), 'Nov',
	'toLocaleString - Nov')
is(new Date(2008,11).toLocaleString().substring(4,7), 'Dec',
	'toLocaleString - Dec')

error = false
try{Date.prototype.toLocaleString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toLocaleString death')


// ===================================================
// 15.9.5.6 Date.prototype.toLocaleDateString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toLocaleDateString',0)

// 21 tests
match = (d = new Date(1199275200000)).toLocaleDateString().match(
    /^(T(?:ue|hu)|Wed) Jan (\d) 2008$/
)
o = d.getTimezoneOffset();
ok(match && (
	o > 720 ? match[1] == 'Tue' && match[2] == 1 :
	o > -720 ? match[1] == 'Wed' && match[2] == 2 :
	            match[1] == 'Thu' && match[2] == 3
), 'toLocaleDateString')

is(new Date(2008,0,6).toLocaleDateString().substring(0,3), 'Sun',
	'toLocaleDateString - Sun')
is(new Date(2008,0,7).toLocaleDateString().substring(0,3), 'Mon',
	'toLocaleDateString - Mon')
is(new Date(2008,0,8).toLocaleDateString().substring(0,3), 'Tue',
	'toLocaleDateString - Tue')
is(new Date(2008,0,9).toLocaleDateString().substring(0,3), 'Wed',
	'toLocaleDateString - Wed')
is(new Date(2008,0,10).toLocaleDateString().substring(0,3), 'Thu',
	'toLocaleDateString - Thu')
is(new Date(2008,0,11).toLocaleDateString().substring(0,3), 'Fri',
	'toLocaleDateString - Fri')
is(new Date(2008,0,12).toLocaleDateString().substring(0,3), 'Sat',
	'toLocaleDateString - Sat')
is(new Date(2008,0).toLocaleDateString().substring(4,7), 'Jan',
	'toLocaleDateString - Jan')
is(new Date(2008,1).toLocaleDateString().substring(4,7), 'Feb',
	'toLocaleDateString - Feb')
is(new Date(2008,2).toLocaleDateString().substring(4,7), 'Mar',
	'toLocaleDateString - Mar')
is(new Date(2008,3).toLocaleDateString().substring(4,7), 'Apr',
	'toLocaleDateString - Apr')
is(new Date(2008,4).toLocaleDateString().substring(4,7), 'May',
	'toLocaleDateString - May')
is(new Date(2008,5).toLocaleDateString().substring(4,7), 'Jun',
	'toLocaleDateString - Jun')
is(new Date(2008,6).toLocaleDateString().substring(4,7), 'Jul',
	'toLocaleDateString - Jul')
is(new Date(2008,7).toLocaleDateString().substring(4,7), 'Aug',
	'toLocaleDateString - Aug')
is(new Date(2008,8).toLocaleDateString().substring(4,7), 'Sep',
	'toLocaleDateString - Sep')
is(new Date(2008,9).toLocaleDateString().substring(4,7), 'Oct',
	'toLocaleDateString - Oct')
is(new Date(2008,10).toLocaleDateString().substring(4,7), 'Nov',
	'toLocaleDateString - Nov')
is(new Date(2008,11).toLocaleDateString().substring(4,7), 'Dec',
	'toLocaleDateString - Dec')

error = false
try{Date.prototype.toLocaleDateString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toLocaleDateString death')


// ===================================================
// 15.9.5.7 Date.prototype.toLocaleTimeString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toLocaleTimeString',0)

// 2 tests
match = (d = new Date(1199275200000)).toLocaleTimeString().match(
    /^(\d\d):(\d\d):00$/
)
t = 720-d.getTimezoneOffset();
ok(match && match[1] == (t-t%60)/60%24 && match[2] == t%60,
	'toLocaleTimeString')

error = false
try{Date.prototype.toLocaleTimeString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toLocaleTimeString death')


// ===================================================
// 15.9.5.8 Date.prototype.valueOf
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'valueOf',0)

// 2 tests
ok(new Date(1199275200000).valueOf() === 1199275200000,'valueOf')

error = false
try{Date.prototype.valueOf.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'valueOf death')


// ===================================================
// 15.9.5.9 Date.prototype. getTime
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getTime',0)

// 2 tests
ok(new Date(1199275200000). getTime() === 1199275200000,'getTime')

error = false
try{Date.prototype. getTime.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getTime death')


// ===================================================
// 15.9.5.10 Date.prototype. getFullYear
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getFullYear',0)

/* I hope no one changes dst on new year’s day. These tests assume that
   never happens. */

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 12 tests
ok(is_nan(new Date(NaN).getFullYear()), 'getFullYear (NaN)')
ok(new Date(26223868800000+offset).getFullYear() === 2801,
	'getFullYear with 1 Jan quadricentennial+1')
ok(new Date(26223868799999+offset).getFullYear() === 2800,
	'getFullYear with 1 Jan quadricentennial+1 year - 1 ms')
ok(new Date(26197387200000+offset).getFullYear()===2800,
	'getFullYear with quadricentennial leap day')
ok(new Date(23068108800000+offset).getFullYear() === 2701,
	'getFullYear - turn of the century...')
ok(new Date(23068108799999+offset).getFullYear() === 2700,
	'              ... when year % 400')
ok(new Date(1230768000000+offset).getFullYear()===2009,
	'getFullYear - first day after a leap year')
ok(new Date(1230767999999+offset).getFullYear()===2008,
	'getFullYear - last millisecond of a leap year')
ok(new Date(13827153600000+offset).getFullYear()===2408,
	'getFullYear - leap day')
ok(new Date(13632624000000+offset).getFullYear()===2402,
	'getFullYear - regular...')
ok(new Date(13632623999999+offset).getFullYear()===2401,
	'getFullYear - ...year')

error = false
try{Date.prototype. getFullYear.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getFullYear death')


// ===================================================
// 15.9.5.11 Date.prototype. getUTCFullYear
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCFullYear',0)

// 12 tests
ok(is_nan(new Date(NaN).getUTCFullYear()), 'getUTCFullYear (NaN)')
ok(new Date(26223868800000).getUTCFullYear() === 2801,
	'getUTCFullYear with 1 Jan quadricentennial+1')
ok(new Date(26223868799999).getUTCFullYear() === 2800,
	'getUTCFullYear with 1 Jan quadricentennial+1 year - 1 ms')
ok(new Date(26197387200000).getUTCFullYear()===2800,
	'getUTCFullYear with quadricentennial leap day')
ok(new Date(23068108800000).getUTCFullYear() === 2701,
	'getUTCFullYear - turn of the century...')
ok(new Date(23068108799999).getUTCFullYear() === 2700,
	'              ... when year % 400')
ok(new Date(1230768000000).getUTCFullYear()===2009,
	'getUTCFullYear - first day after a leap year')
ok(new Date(1230767999999).getUTCFullYear()===2008,
	'getUTCFullYear - last millisecond of a leap year')
ok(new Date(13827153600000).getUTCFullYear()===2408,
	'getUTCFullYear - leap day')
ok(new Date(13632624000000).getUTCFullYear()===2402,
	'getUTCFullYear - regular...')
ok(new Date(13632623999999).getUTCFullYear()===2401,
	'getUTCFullYear - ...year')

error = false
try{Date.prototype. getUTCFullYear.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCFullYear death')


// ===================================================
// 15.9.5.12 Date.prototype. getMonth
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getMonth',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 50 tests
ok(is_nan(new Date(NaN).getMonth()), 'getMonth (NaN)')

ok(new Date(1199188800000 +offset).getMonth() === 0,
	'getMonth - 1 Jan in leap year')
is(new Date(1201780800000 +offset).getMonth(),  0,
	'getMonth - 31 Jan in leap year')
is(new Date(1201867200000 +offset).getMonth(),  1,
	'getMonth - 1 Feb in leap year')
is(new Date(1204286400000 +offset).getMonth(),  1,
	'getMonth - 29 Feb in leap year')
is(new Date(1204372800000 +offset).getMonth(),  2,
	'getMonth - 1 Mar in leap year')
is(new Date(1206964800000 +offset).getMonth(),  2,
	'getMonth - 31 Mar in leap year')
is(new Date(1207051200000 +offset).getMonth(),  3,
	'getMonth - 1 Apr in leap year')
is(new Date(1209556800000 +offset).getMonth(),  3,
	'getMonth - 30 Apr in leap year')
is(new Date(1209643200000 +offset).getMonth(),  4,
	'getMonth - 1 May in leap year')
is(new Date(1212235200000 +offset).getMonth(),  4,
	'getMonth - 31 May in leap year')
is(new Date(1212321600000 +offset).getMonth(),  5,
	'getMonth - 1 Jun in leap year')
is(new Date(1214827200000 +offset).getMonth(),  5,
	'getMonth - 30 Jun in leap year')
is(new Date(1214913600000 +offset).getMonth(),  6,
	'getMonth - 1 Jul in leap year')
is(new Date(1217505600000 +offset).getMonth(),  6,
	'getMonth - 31 Jul in leap year')
is(new Date(1217592000000 +offset).getMonth(),  7,
	'getMonth - 1 Aug in leap year')
is(new Date(1220184000000 +offset).getMonth(),  7,
	'getMonth - 31 Aug in leap year')
is(new Date(1220270400000 +offset).getMonth(),  8,
	'getMonth - 1 Sep in leap year')
is(new Date(1222776000000 +offset).getMonth(),  8,
	'getMonth - 30 Sep in leap year')
is(new Date(1222862400000 +offset).getMonth(),  9,
	'getMonth - 1 Oct in leap year')
is(new Date(1225454400000 +offset).getMonth(),  9,
	'getMonth - 31 Oct in leap year')
is(new Date(1225540800000 +offset).getMonth(),  10,
	'getMonth - 1 Nov in leap year')
is(new Date(1228003200000 +offset).getMonth(),  10,
	'getMonth - 30 Nov in leap year')
is(new Date(1228132800000 +offset).getMonth(),  11,
	'getMonth - 1 Dec in leap year')
is(new Date(1230724800000 +offset).getMonth(),  11,
	'getMonth - 31 Dec in leap year')

is(new Date(1230811200000 +offset).getMonth(), 0,
	'getMonth - 1 Jan in common year')
is(new Date(1233403200000 +offset).getMonth(),  0,
	'getMonth - 31 Jan in common year')
is(new Date(1233489600000 +offset).getMonth(),  1,
	'getMonth - 1 Feb in common year')
is(new Date(1235822400000 +offset).getMonth(),  1,
	'getMonth - 28 Feb in common year')
is(new Date(1235908800000 +offset).getMonth(),  2,
	'getMonth - 1 Mar in common year')
is(new Date(1238500800000 +offset).getMonth(),  2,
	'getMonth - 31 Mar in common year')
is(new Date(1238587200000 +offset).getMonth(),  3,
	'getMonth - 1 Apr in common year')
is(new Date(1241092800000 +offset).getMonth(),  3,
	'getMonth - 30 Apr in common year')
is(new Date(1241179200000 +offset).getMonth(),  4,
	'getMonth - 1 May in common year')
is(new Date(1243771200000 +offset).getMonth(),  4,
	'getMonth - 31 May in common year')
is(new Date(1243857600000 +offset).getMonth(),  5,
	'getMonth - 1 Jun in common year')
is(new Date(1246363200000 +offset).getMonth(),  5,
	'getMonth - 30 Jun in common year')
is(new Date(1246449600000 +offset).getMonth(),  6,
	'getMonth - 1 Jul in common year')
is(new Date(1249041600000 +offset).getMonth(),  6,
	'getMonth - 31 Jul in common year')
is(new Date(1249128000000 +offset).getMonth(),  7,
	'getMonth - 1 Aug in common year')
is(new Date(1251720000000 +offset).getMonth(),  7,
	'getMonth - 31 Aug in common year')
is(new Date(1251806400000 +offset).getMonth(),  8,
	'getMonth - 1 Sep in common year')
is(new Date(1254312000000 +offset).getMonth(),  8,
	'getMonth - 30 Sep in common year')
is(new Date(1254398400000 +offset).getMonth(),  9,
	'getMonth - 1 Oct in common year')
is(new Date(1256990400000 +offset).getMonth(),  9,
	'getMonth - 31 Oct in common year')
is(new Date(1257076800000 +offset).getMonth(),  10,
	'getMonth - 1 Nov in common year')
is(new Date(1259582400000 +offset).getMonth(),  10,
	'getMonth - 30 Nov in common year')
is(new Date(1259668800000 +offset).getMonth(),  11,
	'getMonth - 1 Dec in common year')
is(new Date(1262260800000 +offset).getMonth(),  11,
	'getMonth - 31 Dec in common year')

error = false
try{Date.prototype. getMonth.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getMonth death')


// ===================================================
// 15.9.5.13 Date.prototype. getUTCMonth
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCMonth',0)

// 50 tests
ok(is_nan(new Date(NaN).getUTCMonth()), 'getUTCMonth (NaN)')

ok(new Date(1199188800000 ).getUTCMonth() === 0,
	'getUTCMonth - 1 Jan in leap year')
is(new Date(1201780800000 ).getUTCMonth(),  0,
	'getUTCMonth - 31 Jan in leap year')
is(new Date(1201867200000 ).getUTCMonth(),  1,
	'getUTCMonth - 1 Feb in leap year')
is(new Date(1204286400000 ).getUTCMonth(),  1,
	'getUTCMonth - 29 Feb in leap year')
is(new Date(1204372800000 ).getUTCMonth(),  2,
	'getUTCMonth - 1 Mar in leap year')
is(new Date(1206964800000 ).getUTCMonth(),  2,
	'getUTCMonth - 31 Mar in leap year')
is(new Date(1207051200000 ).getUTCMonth(),  3,
	'getUTCMonth - 1 Apr in leap year')
is(new Date(1209556800000 ).getUTCMonth(),  3,
	'getUTCMonth - 30 Apr in leap year')
is(new Date(1209643200000 ).getUTCMonth(),  4,
	'getUTCMonth - 1 May in leap year')
is(new Date(1212235200000 ).getUTCMonth(),  4,
	'getUTCMonth - 31 May in leap year')
is(new Date(1212321600000 ).getUTCMonth(),  5,
	'getUTCMonth - 1 Jun in leap year')
is(new Date(1214827200000 ).getUTCMonth(),  5,
	'getUTCMonth - 30 Jun in leap year')
is(new Date(1214913600000 ).getUTCMonth(),  6,
	'getUTCMonth - 1 Jul in leap year')
is(new Date(1217505600000 ).getUTCMonth(),  6,
	'getUTCMonth - 31 Jul in leap year')
is(new Date(1217592000000 ).getUTCMonth(),  7,
	'getUTCMonth - 1 Aug in leap year')
is(new Date(1220184000000 ).getUTCMonth(),  7,
	'getUTCMonth - 31 Aug in leap year')
is(new Date(1220270400000 ).getUTCMonth(),  8,
	'getUTCMonth - 1 Sep in leap year')
is(new Date(1222776000000 ).getUTCMonth(),  8,
	'getUTCMonth - 30 Sep in leap year')
is(new Date(1222862400000 ).getUTCMonth(),  9,
	'getUTCMonth - 1 Oct in leap year')
is(new Date(1225454400000 ).getUTCMonth(),  9,
	'getUTCMonth - 31 Oct in leap year')
is(new Date(1225540800000 ).getUTCMonth(),  10,
	'getUTCMonth - 1 Nov in leap year')
is(new Date(1228003200000 ).getUTCMonth(),  10,
	'getUTCMonth - 30 Nov in leap year')
is(new Date(1228132800000 ).getUTCMonth(),  11,
	'getUTCMonth - 1 Dec in leap year')
is(new Date(1230724800000 ).getUTCMonth(),  11,
	'getUTCMonth - 31 Dec in leap year')

is(new Date(1230811200000 ).getUTCMonth(), 0,
	'getUTCMonth - 1 Jan in common year')
is(new Date(1233403200000 ).getUTCMonth(),  0,
	'getUTCMonth - 31 Jan in common year')
is(new Date(1233489600000 ).getUTCMonth(),  1,
	'getUTCMonth - 1 Feb in common year')
is(new Date(1235822400000 ).getUTCMonth(),  1,
	'getUTCMonth - 28 Feb in common year')
is(new Date(1235908800000 ).getUTCMonth(),  2,
	'getUTCMonth - 1 Mar in common year')
is(new Date(1238500800000 ).getUTCMonth(),  2,
	'getUTCMonth - 31 Mar in common year')
is(new Date(1238587200000 ).getUTCMonth(),  3,
	'getUTCMonth - 1 Apr in common year')
is(new Date(1241092800000 ).getUTCMonth(),  3,
	'getUTCMonth - 30 Apr in common year')
is(new Date(1241179200000 ).getUTCMonth(),  4,
	'getUTCMonth - 1 May in common year')
is(new Date(1243771200000 ).getUTCMonth(),  4,
	'getUTCMonth - 31 May in common year')
is(new Date(1243857600000 ).getUTCMonth(),  5,
	'getUTCMonth - 1 Jun in common year')
is(new Date(1246363200000 ).getUTCMonth(),  5,
	'getUTCMonth - 30 Jun in common year')
is(new Date(1246449600000 ).getUTCMonth(),  6,
	'getUTCMonth - 1 Jul in common year')
is(new Date(1249041600000 ).getUTCMonth(),  6,
	'getUTCMonth - 31 Jul in common year')
is(new Date(1249128000000 ).getUTCMonth(),  7,
	'getUTCMonth - 1 Aug in common year')
is(new Date(1251720000000 ).getUTCMonth(),  7,
	'getUTCMonth - 31 Aug in common year')
is(new Date(1251806400000 ).getUTCMonth(),  8,
	'getUTCMonth - 1 Sep in common year')
is(new Date(1254312000000 ).getUTCMonth(),  8,
	'getUTCMonth - 30 Sep in common year')
is(new Date(1254398400000 ).getUTCMonth(),  9,
	'getUTCMonth - 1 Oct in common year')
is(new Date(1256990400000 ).getUTCMonth(),  9,
	'getUTCMonth - 31 Oct in common year')
is(new Date(1257076800000 ).getUTCMonth(),  10,
	'getUTCMonth - 1 Nov in common year')
is(new Date(1259582400000 ).getUTCMonth(),  10,
	'getUTCMonth - 30 Nov in common year')
is(new Date(1259668800000 ).getUTCMonth(),  11,
	'getUTCMonth - 1 Dec in common year')
is(new Date(1262260800000 ).getUTCMonth(),  11,
	'getUTCMonth - 31 Dec in common year')

error = false
try{Date.prototype. getUTCMonth.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCMonth death')


// ===================================================
// 15.9.5.14 Date.prototype. getDate
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getDate',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 50 tests
ok(is_nan(new Date(NaN).getDate()), 'getDate (NaN)')

ok(new Date(1199188800000 +offset).getDate() === 1,
	'getDate - 1 Jan in leap year')
is(new Date(1201780800000 +offset).getDate(),  31,
	'getDate - 31 Jan in leap year')
is(new Date(1201867200000 +offset).getDate(),  1,
	'getDate - 1 Feb in leap year')
is(new Date(1204286400000 +offset).getDate(),  29,
	'getDate - 29 Feb in leap year')
is(new Date(1204372800000 +offset).getDate(),  1,
	'getDate - 1 Mar in leap year')
is(new Date(1206964800000 +offset).getDate(),  31,
	'getDate - 31 Mar in leap year')
is(new Date(1207051200000 +offset).getDate(),  1,
	'getDate - 1 Apr in leap year')
is(new Date(1209556800000 +offset).getDate(),  30,
	'getDate - 30 Apr in leap year')
is(new Date(1209643200000 +offset).getDate(),  1,
	'getDate - 1 May in leap year')
is(new Date(1212235200000 +offset).getDate(),  31,
	'getDate - 31 May in leap year')
is(new Date(1212321600000 +offset).getDate(),  1,
	'getDate - 1 Jun in leap year')
is(new Date(1214827200000 +offset).getDate(),  30,
	'getDate - 30 Jun in leap year')
is(new Date(1214913600000 +offset).getDate(),  1,
	'getDate - 1 Jul in leap year')
is(new Date(1217505600000 +offset).getDate(),  31,
	'getDate - 31 Jul in leap year')
is(new Date(1217592000000 +offset).getDate(),  1,
	'getDate - 1 Aug in leap year')
is(new Date(1220184000000 +offset).getDate(),  31,
	'getDate - 31 Aug in leap year')
is(new Date(1220270400000 +offset).getDate(),  1,
	'getDate - 1 Sep in leap year')
is(new Date(1222776000000 +offset).getDate(),  30,
	'getDate - 30 Sep in leap year')
is(new Date(1222862400000 +offset).getDate(),  1,
	'getDate - 1 Oct in leap year')
is(new Date(1225454400000 +offset).getDate(),  31,
	'getDate - 31 Oct in leap year')
is(new Date(1225540800000 +offset).getDate(),  1,
	'getDate - 1 Nov in leap year')
is(new Date(1228003200000 +offset).getDate(),  30,
	'getDate - 30 Nov in leap year')
is(new Date(1228132800000 +offset).getDate(),  1,
	'getDate - 1 Dec in leap year')
is(new Date(1230724800000 +offset).getDate(),  31,
	'getDate - 31 Dec in leap year')

is(new Date(1230811200000 +offset).getDate(), 1,
	'getDate - 1 Jan in common year')
is(new Date(1233403200000 +offset).getDate(),  31,
	'getDate - 31 Jan in common year')
is(new Date(1233489600000 +offset).getDate(),  1,
	'getDate - 1 Feb in common year')
is(new Date(1235822400000 +offset).getDate(),  28,
	'getDate - 28 Feb in common year')
is(new Date(1235908800000 +offset).getDate(),  1,
	'getDate - 1 Mar in common year')
is(new Date(1238500800000 +offset).getDate(),  31,
	'getDate - 31 Mar in common year')
is(new Date(1238587200000 +offset).getDate(),  1,
	'getDate - 1 Apr in common year')
is(new Date(1241092800000 +offset).getDate(),  30,
	'getDate - 30 Apr in common year')
is(new Date(1241179200000 +offset).getDate(),  1,
	'getDate - 1 May in common year')
is(new Date(1243771200000 +offset).getDate(),  31,
	'getDate - 31 May in common year')
is(new Date(1243857600000 +offset).getDate(),  1,
	'getDate - 1 Jun in common year')
is(new Date(1246363200000 +offset).getDate(),  30,
	'getDate - 30 Jun in common year')
is(new Date(1246449600000 +offset).getDate(),  1,
	'getDate - 1 Jul in common year')
is(new Date(1249041600000 +offset).getDate(),  31,
	'getDate - 31 Jul in common year')
is(new Date(1249128000000 +offset).getDate(),  1,
	'getDate - 1 Aug in common year')
is(new Date(1251720000000 +offset).getDate(),  31,
	'getDate - 31 Aug in common year')
is(new Date(1251806400000 +offset).getDate(),  1,
	'getDate - 1 Sep in common year')
is(new Date(1254312000000 +offset).getDate(),  30,
	'getDate - 30 Sep in common year')
is(new Date(1254398400000 +offset).getDate(),  1,
	'getDate - 1 Oct in common year')
is(new Date(1256990400000 +offset).getDate(),  31,
	'getDate - 31 Oct in common year')
is(new Date(1257076800000 +offset).getDate(),  1,
	'getDate - 1 Nov in common year')
is(new Date(1259582400000 +offset).getDate(),  30,
	'getDate - 30 Nov in common year')
is(new Date(1259668800000 +offset).getDate(),  1,
	'getDate - 1 Dec in common year')
is(new Date(1262260800000 +offset).getDate(),  31,
	'getDate - 31 Dec in common year')

error = false
try{Date.prototype. getDate.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getDate death')


// ===================================================
// 15.9.5.15 Date.prototype. getUTCDate
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCDate',0)

// 50 tests
ok(is_nan(new Date(NaN).getUTCDate()), 'getUTCDate (NaN)')

ok(new Date(1199188800000 ).getUTCDate() === 1,
	'getUTCDate - 1 Jan in leap year')
is(new Date(1201780800000 ).getUTCDate(),  31,
	'getUTCDate - 31 Jan in leap year')
is(new Date(1201867200000 ).getUTCDate(),  1,
	'getUTCDate - 1 Feb in leap year')
is(new Date(1204286400000 ).getUTCDate(),  29,
	'getUTCDate - 29 Feb in leap year')
is(new Date(1204372800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Mar in leap year')
is(new Date(1206964800000 ).getUTCDate(),  31,
	'getUTCDate - 31 Mar in leap year')
is(new Date(1207051200000 ).getUTCDate(),  1,
	'getUTCDate - 1 Apr in leap year')
is(new Date(1209556800000 ).getUTCDate(),  30,
	'getUTCDate - 30 Apr in leap year')
is(new Date(1209643200000 ).getUTCDate(),  1,
	'getUTCDate - 1 May in leap year')
is(new Date(1212235200000 ).getUTCDate(),  31,
	'getUTCDate - 31 May in leap year')
is(new Date(1212321600000 ).getUTCDate(),  1,
	'getUTCDate - 1 Jun in leap year')
is(new Date(1214827200000 ).getUTCDate(),  30,
	'getUTCDate - 30 Jun in leap year')
is(new Date(1214913600000 ).getUTCDate(),  1,
	'getUTCDate - 1 Jul in leap year')
is(new Date(1217505600000 ).getUTCDate(),  31,
	'getUTCDate - 31 Jul in leap year')
is(new Date(1217592000000 ).getUTCDate(),  1,
	'getUTCDate - 1 Aug in leap year')
is(new Date(1220184000000 ).getUTCDate(),  31,
	'getUTCDate - 31 Aug in leap year')
is(new Date(1220270400000 ).getUTCDate(),  1,
	'getUTCDate - 1 Sep in leap year')
is(new Date(1222776000000 ).getUTCDate(),  30,
	'getUTCDate - 30 Sep in leap year')
is(new Date(1222862400000 ).getUTCDate(),  1,
	'getUTCDate - 1 Oct in leap year')
is(new Date(1225454400000 ).getUTCDate(),  31,
	'getUTCDate - 31 Oct in leap year')
is(new Date(1225540800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Nov in leap year')
is(new Date(1228003200000 ).getUTCDate(),  30,
	'getUTCDate - 30 Nov in leap year')
is(new Date(1228132800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Dec in leap year')
is(new Date(1230724800000 ).getUTCDate(),  31,
	'getUTCDate - 31 Dec in leap year')

is(new Date(1230811200000 ).getUTCDate(), 1,
	'getUTCDate - 1 Jan in common year')
is(new Date(1233403200000 ).getUTCDate(),  31,
	'getUTCDate - 31 Jan in common year')
is(new Date(1233489600000 ).getUTCDate(),  1,
	'getUTCDate - 1 Feb in common year')
is(new Date(1235822400000 ).getUTCDate(),  28,
	'getUTCDate - 28 Feb in common year')
is(new Date(1235908800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Mar in common year')
is(new Date(1238500800000 ).getUTCDate(),  31,
	'getUTCDate - 31 Mar in common year')
is(new Date(1238587200000 ).getUTCDate(),  1,
	'getUTCDate - 1 Apr in common year')
is(new Date(1241092800000 ).getUTCDate(),  30,
	'getUTCDate - 30 Apr in common year')
is(new Date(1241179200000 ).getUTCDate(),  1,
	'getUTCDate - 1 May in common year')
is(new Date(1243771200000 ).getUTCDate(),  31,
	'getUTCDate - 31 May in common year')
is(new Date(1243857600000 ).getUTCDate(),  1,
	'getUTCDate - 1 Jun in common year')
is(new Date(1246363200000 ).getUTCDate(),  30,
	'getUTCDate - 30 Jun in common year')
is(new Date(1246449600000 ).getUTCDate(),  1,
	'getUTCDate - 1 Jul in common year')
is(new Date(1249041600000 ).getUTCDate(),  31,
	'getUTCDate - 31 Jul in common year')
is(new Date(1249128000000 ).getUTCDate(),  1,
	'getUTCDate - 1 Aug in common year')
is(new Date(1251720000000 ).getUTCDate(),  31,
	'getUTCDate - 31 Aug in common year')
is(new Date(1251806400000 ).getUTCDate(),  1,
	'getUTCDate - 1 Sep in common year')
is(new Date(1254312000000 ).getUTCDate(),  30,
	'getUTCDate - 30 Sep in common year')
is(new Date(1254398400000 ).getUTCDate(),  1,
	'getUTCDate - 1 Oct in common year')
is(new Date(1256990400000 ).getUTCDate(),  31,
	'getUTCDate - 31 Oct in common year')
is(new Date(1257076800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Nov in common year')
is(new Date(1259582400000 ).getUTCDate(),  30,
	'getUTCDate - 30 Nov in common year')
is(new Date(1259668800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Dec in common year')
is(new Date(1262260800000 ).getUTCDate(),  31,
	'getUTCDate - 31 Dec in common year')

error = false
try{Date.prototype. getUTCDate.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCDate death')


// ===================================================
// 15.9.5.16 Date.prototype. getDay
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getDay',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 9 tests
ok(is_nan(new Date(NaN).getDay()), 'getDay (NaN)')
ok(new Date(1200225600000+offset).getDay() === 0, 'getDay (Sunday)')
ok(new Date(1200312000000+offset).getDay() === 1, 'getDay (Monday)')
ok(new Date(1200398400000+offset).getDay() === 2, 'getDay (Tuesday)')
ok(new Date(1200484800000+offset).getDay() === 3, 'getDay (Wednesday)')
ok(new Date(1200571200000+offset).getDay() === 4, 'getDay (Thursday)')
ok(new Date(1200657600000+offset).getDay() === 5, 'getDay (Friday)')
ok(new Date(1200744000000+offset).getDay() === 6, 'getDay (Saturday)')

error = false
try{Date.prototype. getDay.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getDay death')


// ===================================================
// 15.9.5.17 Date.prototype. getUTCDay
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCDay',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 9 tests
ok(is_nan(new Date(NaN).getUTCDay()), 'getUTCDay (NaN)')
ok(new Date(1200225600000+offset).getUTCDay() === 0, 'getUTCDay (Sunday)')
ok(new Date(1200312000000+offset).getUTCDay() === 1, 'getUTCDay (Monday)')
ok(new Date(1200398400000+offset).getUTCDay() === 2, 'getUTCDay (Tuesday)')
ok(new Date(1200484800000+offset).getUTCDay() === 3,
	'getUTCDay (Wednesday)')
ok(new Date(1200571200000+offset).getUTCDay() === 4,
	'getUTCDay (Thursday)')
ok(new Date(1200657600000+offset).getUTCDay() === 5, 'getUTCDay (Friday)')
ok(new Date(1200744000000+offset).getUTCDay() === 6,
	'getUTCDay (Saturday)')

error = false
try{Date.prototype. getUTCDay.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCDay death')


// ===================================================
// 15.9.5.18 Date.prototype. getHours
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getHours',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 3 tests
ok(is_nan(new Date(NaN).getHours()), 'getHours (NaN)')
ok(new Date(1200225612345+offset).getHours() === 12, 'getHours')

error = false
try{Date.prototype. getHours.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getHours death')


// ===================================================
// 15.9.5.19 Date.prototype. getUTCHours
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCHours',0)

// 3 tests
ok(is_nan(new Date(NaN).getUTCHours()), 'getUTCHours (NaN)')
ok(new Date(1200225612345).getUTCHours() === 12, 'getUTCHours')

error = false
try{Date.prototype. getUTCHours.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCHours death')


// ===================================================
// 15.9.5.20 Date.prototype. getMinutes
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getMinutes',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 3 tests
ok(is_nan(new Date(NaN).getMinutes()), 'getMinutes (NaN)')
ok(new Date(1200225612345+offset).getMinutes() === 0, 'getMinutes')

error = false
try{Date.prototype. getMinutes.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getMinutes death')


// ===================================================
// 15.9.5.21 Date.prototype. getUTCMinutes
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCMinutes',0)

// 3 tests
ok(is_nan(new Date(NaN).getUTCMinutes()), 'getUTCMinutes (NaN)')
ok(new Date(1200225612345).getUTCMinutes() === 0, 'getUTCMinutes')

error = false
try{Date.prototype. getUTCMinutes.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCMinutes death')


// ===================================================
// 15.9.5.22 Date.prototype.getSeconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getSeconds',0)

// 3 tests
ok(is_nan(new Date(NaN).getSeconds()), 'getSeconds (NaN)')
ok(new Date(1200225613345).getSeconds() === 13, 'getSeconds')

error = false
try{Date.prototype. getSeconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getSeconds death')


// ===================================================
// 15.9.5.23 Date.prototype.getUTCSeconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCSeconds',0)

// 3 tests
ok(is_nan(new Date(NaN).getUTCSeconds()), 'getUTCSeconds (NaN)')
ok(new Date(1200225613345).getUTCSeconds() === 13, 'getUTCSeconds')

error = false
try{Date.prototype. getUTCSeconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCSeconds death')


// ===================================================
// 15.9.5.24 Date.prototype.getMilliseconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getMilliseconds',0)

// 3 tests
ok(is_nan(new Date(NaN).getMilliseconds()), 'getMilliseconds (NaN)')
ok(new Date(1200225613345).getMilliseconds() === 345, 'getMilliseconds')

error = false
try{Date.prototype. getMilliseconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getMilliseconds death')


// ===================================================
// 15.9.5.25 Date.prototype.getUTCMilliseconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCMilliseconds',0)

// 3 tests
ok(is_nan(new Date(NaN).getUTCMilliseconds()), 'getUTCMilliseconds (NaN)')
ok(new Date(1200225613345).getUTCMilliseconds() === 345, 'getUTCMilliseconds')

error = false
try{Date.prototype. getUTCMilliseconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCMilliseconds death')


// ===================================================
// 15.9.5.26 Date.prototype.getTimezoneOffset
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getTimezoneOffset',0)

// I’m not sure how to test this here. But many tests above rely on its
// correct behaviour, so maybe that’s enough.

// 1 test
error = false
try{Date.prototype. getUTCMilliseconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCMilliseconds death')


// ===================================================
// 15.9.5.27 Date.prototype.setTime
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setTime',1)

// 7 tests
ok(is_nan(d = new Date().setTime(285619*365*24000*3600)),
	'retval of setTime out of range')
ok(is_nan(+d), 'affect of setTime out of range')
ok(is_nan(d = new Date().setTime()),
	'retval of setTime w/o args')
ok(is_nan(+d), 'affect of setTime w/o args')
is((d=new Date).setTime(785), 785, 'setTime retval')
is(+d, 785, 'affect of setTime')

error = false
try{Date.prototype. setTime.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setTime death')


// ===================================================
// 15.9.5.28 Date.prototype.setMilliseconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setMilliseconds',1)

// 6 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setMilliseconds(85)===+e-e.getMilliseconds()+85,
	'retval of setMilliseconds')
is(d.getTime(),e-e.getMilliseconds()+85,
	 'affect of setMilliseconds')
d = new Date(+(e = new Date)); // two identical objects
ok(d.setMilliseconds(1000)===+e-e.getMilliseconds()+1000,
	'retval of setMilliseconds(1000)')
is(d.getMilliseconds(),0,
	 'affect of setMilliseconds(1000)')
is(d.getTime(),e-e.getMilliseconds()+1000,
	 'affect of setMilliseconds(1000)')

error = false
try{Date.prototype. setMilliseconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setMilliseconds death')


// ===================================================
// 15.9.5.29 Date.prototype.setMilliseconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setMilliseconds',1)

// 6 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setMilliseconds(85)===+e-e.getMilliseconds()+85,
	'retval of setMilliseconds')
is(d.getTime(),e-e.getMilliseconds()+85,
	 'affect of setMilliseconds')
d = new Date(+(e = new Date)); // two identical objects
ok(d.setMilliseconds(1000)===+e-e.getMilliseconds()+1000,
	'retval of setMilliseconds(1000)')
is(d.getMilliseconds(),0,
	 'affect of setMilliseconds(1000)')
is(d.getTime(),e-e.getMilliseconds()+1000,
	 'affect of setMilliseconds(1000)')

error = false
try{Date.prototype. setMilliseconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setMilliseconds death')


// # ~~~ Eye knead two Finnish righting this.
