#!perl -T
do './t/jstest.pl' or die __DATA__

plan('tests', 4)

// ---------------------------------------------------
/* Test 1: Make sure exec can be called */

try{is(/a/.exec('a'), 'a', 'exec doesn\'t simply die')}
catch(e){fail('exec doesn\'t simply die')}

// ---------------------------------------------------
/* Tests 2-4: Regexps with surrogates */

testname = 'surrogates in regexps don\'t cause fatal errors';
try{ new RegExp('\ud800'); pass(testname) }
catch(e){fail(testname)}

testname = 'surrogates in regexp char classes don\'t cause fatal errors';
try{ new RegExp('[\ud800]'); pass(testname) }
catch(e){fail(testname)}

ok('\ud800'.match(new RegExp('\ud800')),
	'regexps with surrogates in them work')


diag('TO DO: Finish writing this test script');
