#!perl -T

# Test both prefix and postfix unary expressions

use Test::More tests => 20;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  t4 = delete Object
  t5 = delete(rious) // no space
  t6 = void 3
  t7 = typeof 4

  a=b=c=d=5

  a
  ++
  b
  ;

  c
  --
  d
  ;
 
  // now a==5 && b==6 && c==5 && d==4

  t8 = ++a   //6
  t9 = ++++b //8
  t10 = --c   //4
  t11 = ----d //2
  t12 = + 1
  t13 = - 1
  t14 = ~ 1
  t15 = ~~ 1
  t16 = !1
  t17 = !!1
  t18 = - - 1

  t19 = a++ //6
  t20 = b-- //8
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-21: Check side-effects

is( $j->prop('t4'), 'true' );
is( $j->prop('t5'), 'true'    );
is( $j->prop('t6'), 'undefined' );
is( $j->prop('t7'), 'number'     );
is( $j->prop('t8'), 6            );
is( $j->prop('t9'), 8           );
is( $j->prop('t10'), 4        );
is( $j->prop('t11'), 2      );
is( $j->prop('t12'), 1     );
is( $j->prop('t13'), -1   );
is( $j->prop('t14'), -2   );
is( $j->prop('t15'),  1    );
is( $j->prop('t16'), 'false' );
is( $j->prop('t17'), 'true'   );
is( $j->prop('t18'), 1        );
is( $j->prop('t19'), 6       );
is( $j->prop('t20'), 8     );
