#!perl -T

use Test::More tests => 27;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->compile( <<'--end--' ), 'JE::Code');
  a = 4;
  $ = 5;
  _ = 6;
  κάτι = 7;
  π = 8;

  a1 = 9;
  a$ = 10;
  a_ = 11;
  aπ = 12;

  $1 = 13;
  $$ = 14;
  $_ = 15;
  $π = 16;
  
  _1 = 17;
  _$ = 18;
  __ = 19;
  _π = 20;
  
  π1 = 21;
  π$ = 22;
  π_ = 23;
  ππ = 24;

  \ufb01nal = 25;
  di\uFb03cult = 26;

  \u03c0\u03bf\u03c5\u03b8\ud801\udc29\u03bd\u1f70 = 27;
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-27: Check side-effects

is( $j->prop('a'), 4 );
is( $j->prop('$'), 5 );
is( $j->prop('_'), 6 );
is( $j->prop('κάτι'), 7 );
is( $j->prop('π'), 8 );
is( $j->prop('a1'), 9 );
is( $j->prop('a$'), 10 );
is( $j->prop('a_'), 11 );
is( $j->prop('aπ'), 12 );
is( $j->prop('$1'), 13 );
is( $j->prop('$$'), 14 );
is( $j->prop('$_'), 15 );
is( $j->prop('$π'), 16 );
is( $j->prop('_1'), 17 );
is( $j->prop('_$'), 18 );
is( $j->prop('__'), 19 );
is( $j->prop('_π'), 20 );
is( $j->prop('π1'), 21 );
is( $j->prop('π$'), 22 );
is( $j->prop('π_'), 23 );
is( $j->prop('ππ'), 24  );
is( $j->prop('ﬁnal'), 25 );
is( $j->prop('diﬃcult'), 26 );
is( $j->prop('πουθ𐐩νὰ'), 27 );
