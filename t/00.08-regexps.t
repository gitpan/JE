#!perl -T

use Test::More tests => 11;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->compile( <<'--end--' ), 'JE::Code');

t4 = /.*/i
t5 = /.*/g
t6 = /.*/m
t7 = /.*/mg
t8 = /.*/gi
t9 = /.*/mi
t10 = /.*/mgi
t11 = /.*/

--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-11: Check side-effects

my $tmp;
is(        $j->prop('t4'),    '(?-xism:(?i:.*))', '/i' );
ok( ($tmp = $j->prop('t5')) eq '(?-xism:(?:.*))' &&
     $tmp     ->prop('global'),                   '/g' );
is(         $j->prop('t6'),    '(?-xism:(?m:.*))', '/m' );
ok( ($tmp = $j->prop('t7')) eq '(?-xism:(?m:.*))' &&
     $tmp     ->prop('global'),                    '/mg' );
ok( ($tmp = $j->prop('t8')) eq '(?-xism:(?i:.*))' &&
     $tmp     ->prop('global'),                    '/gi' );
is(         $j->prop('t9'),    '(?-xism:(?mi:.*))', '/mi' );
ok( ($tmp = $j->prop('t10')) eq '(?-xism:(?mi:.*))' &&
    $tmp      ->prop('global'),                    '/mgi' );
is(        $j->prop('t11'),     '(?-xism:(?:.*))', 'no modifiers' );
