#!perl -T
do './t/jstest.pl' or die __DATA__

plan('tests', 1)

// ---------------------------------------------------
/* Test 1: Make sure exec can be called */

try{is(/a/.exec('a'), 'a', 'exec doesn\'t simply die')}
catch(e){fail('exec doesn\'t simply die')}

diag('TO DO: Finish writing this test script');
