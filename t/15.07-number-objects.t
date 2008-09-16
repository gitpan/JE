#!perl -T
do './t/jstest.pl' or die __DATA__

// 1 test
is(peval(
	'my $w = 0;' +
	'local $SIG{__WARN__} = sub { ++$w };' +
	'shift->eval(q"new Number");'+
	'$w',
	this), 0, 'new Number doesn\'t warn');


// ...

// ===================================================
// 15.7.4.2: toString
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'toString',1)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.toString;
	var testname='toString with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// more tests ...


// ===================================================
// 15.7.4.3: toLocaleString
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'toLocaleString',0)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.toLocaleString;
	var testname='toLocaleString with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toLocaleString with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toLocaleString with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// more tests ...


// ===================================================
// 15.7.4.4: valueOf
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'valueOf',0)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.valueOf;
	var testname='valueOf with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='valueOf with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='valueOf with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// more tests ...


// ===================================================
// 15.7.4.5: toFixed
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'toFixed',1)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.toFixed;
	var testname='toFixed with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toFixed with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toFixed with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// more tests ...


// ===================================================
// 15.7.4.6: toExponential
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'toExponential',1)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.toExponential;
	var testname='toExponential with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toExponential with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toExponential with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// more tests ...


// ===================================================
// 15.7.4.7: toPrecision
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'toPrecision',1)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.toPrecision;
	var testname='toPrecision with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toPrecision with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toPrecision with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// more tests ...



diag('TO DO: Finish writing this test script');
