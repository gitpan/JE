package JE::Object::Number;

our $VERSION = '0.011';


use strict;
use warnings;

use constant inf => 9**9**9;

our @ISA = 'JE::Object';

use Scalar::Util 'blessed';

require JE::Number;
require JE::Object;
require JE::Object::Function;
require JE::String;



=head1 NAME

JE::Object::Number - JavaScript Number object class

=head1 SYNOPSIS

  use JE;
  use JE::Object::Number;

  $j = new JE;

  $js_num_obj = new JE::Object::Number $j, 953.7;

  $perl_scalar = $js_num_obj->value;

  0 + $js_num_obj;  # 953.7

=head1 DESCRIPTION

This class implements JavaScript Number objects for JE. The difference
between this and JE::Number is that that module implements
I<primitive> number values, while this module implements the I<objects.>

=head1 METHODS

See L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object::Number is explained here.

=over

=cut

sub new {
	my($class, $global, $val) = @_;
	my $self = $class->SUPER::new($global, {
		prototype => $global->prop('Number')->prop('prototype')
	});

	$$$self{value} = defined $val
		? defined blessed $val
		  && $val->can('to_number')
			? $val->to_number->[0]
			: 0+$val
		: 0;
	$self;
}




=item value

Returns a Perl scalar containing the number that the object holds.

=cut

sub value { $${$_[0]}{value} }



=item class

Returns the string 'Number'.

=cut

sub class { 'Number' }



our @_digits = (0..9, 'a' .. 'z');

sub _new_constructor {
	my $global = shift;
	my $f = JE::Object::Function->new({
		name            => 'Number',
		scope            => $global,
		argnames         => [qw/value/],
		function         => sub {
			defined $_[0] ? $_[0]->to_number :
				__PACKAGE__->new($global, 0);
		},
		function_args    => ['args'],
		constructor      => sub {
			unshift @_, __PACKAGE__;
			goto &new;
		},
		constructor_args => ['scope','args'],
	});

# ~~~ I DON'T KNOW ENOUGH ABOUT NUMBERS!!! :-(
# The max according to ECMA-262 ≈ 1.7976931348623157e+308.
# The max I can get in Perl is 1.797693134862314659999e+308
#	$f->prop({
#		name  => 'MAX_VALUE',
#		value  => JE::Number->new($global, ???????);
#		dontenum => 1,
#		dontdel   => 1,
#		readonly  => 1,
#	});

#	$f->prop({
#		name  => 'MIN_VALUE',
#		value  => JE::Number->new($global, ???????);
#		dontenum => 1,
#		dontdel   => 1,
#		readonly  => 1,
#	});

	$f->prop({
		name  => 'NaN',
		value  => JE::Number->new($global, 'nan'),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});

	$f->prop({
		name  => 'NEGATIVE_INFINITY',
		value  => JE::Number->new($global, '-inf'),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});

	$f->prop({
		name  => 'POSITIVE_INFINITY', # positively infinite
		value  => JE::Number->new($global, 'inf'),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});

	my $proto = bless $f->prop({
		name    => 'prototype',
		dontenum => 1,
		readonly => 1,
	}), __PACKAGE__;

	$$$proto{value} = 0;
	
	$proto->prop({
		name  => 'toString',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toString',
			argnames => ['radix'],
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global,
					"Argument to " .
					"Number.prototype.toString is not"
					. " a " .
					"Number object"
				) unless $self->class eq 'Number';

				my $radix = shift;
				!defined $radix || $radix->id eq 'undef'
					and return
					$self->to_primitive->to_string;

				($radix = $radix->to_number->value)
				 == 10 || $radix < 2 || $radix > 36 ||
				$radix =~ /\./ and return $self->to_string;

				if ($radix == 2) {
					return JE::Number->new($global,
					    sprintf '%b', $self->value);
				}
				elsif($radix == 8) {
					return JE::Number->new($global,
					    sprintf '%o', $self->value);
				}
				elsif($radix == 16) {
					return JE::Number->new($global,
					    sprintf '%x', $self->value);
				}

				my $num = $self->value;
				my $result = '';
				while($num >= 1) {
					substr($result,0,0) =
						$_digits[$num % $radix];
					$num /= $radix;
				}

				return JE::Number->new($global, $num);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toLocaleString',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toLocaleString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global,
					"Argument to " .
					"Number.prototype.toLocaleString ".
					"is not"
					. " a " .
					"Number object"
				) unless $self->class eq 'Number';

				# ~~~ locale stuff

				return JE::String->new($global,
					$self->value);
			},
		}),
		dontenum => 1,
	});
	$proto->prop({
		name  => 'valueOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'valueOf',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global,
					"Argument to " .
					"Number.prototype.valueOf is not"
					. " a " .
					"Number object"
				) unless $self->class eq 'Number';

				return JE::Number->new($global,
					$$$self{value});
			},
		}),
		dontenum => 1,
	});
	$proto->prop({
		name  => 'toFixed',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toFixed',
			no_proto => 1,
			argnames => ['fractionDigits'],
			function_args => ['this'],
			function => sub {
my $self = shift;
die JE::Object::Error::TypeError->new(
	$global,
	"Argument to " .
	"Number.prototype.toFixed is not"
	. " a " .
	"Number object"
) unless $self->class eq 'Number';

my $places = shift;
if(defined $places) {
	$places = ($places = int $places->to_number) == $places && $places;
}
else { $places = 0 }

$places < 0 and throw JE::Object::Error::RangeError->new($global,
	"Invalid number of decimal places: $places " .
	"(negative numbers not supported)"
);

my $num = $self->value;
$num == $num or return JE::String->new($global, 'NaN');

abs $num >= 1000000000000000000000
	and return JE::String->new($global, $num);
# ~~~ if/when JE::Number::to_string is rewritten, make this use the same
#    algorithm

return JE::String->new($global, sprintf "%.${places}f", $num);

			},
		}),
		dontenum => 1,
	});
	$proto->prop({
		name  => 'toExponential',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toExponential',
			no_proto => 1,
			argnames => ['fractionDigits'],
			function_args => ['this'],
			function => sub {
my $self = shift;
die JE::Object::Error::TypeError->new(
	$global,
	"Argument to " .
	"Number.prototype. toExponential is not"
	. " a " .
	"Number object"
) unless $self->class eq 'Number';

my $num = $self->value;
$num == $num or return JE::String->new($global, 'NaN');
abs $num == inf && return JE::String->new($global,
	($num < 0 && '-') . 'Infinity');

my $places = shift;
if(defined $places) {
	$places = ($places = int $places->to_number) == $places && $places;
}
else { $places = 0 }

$places < 0 and throw JE::Object::Error::RangeError->new($global,
	"Invalid number of decimal places: $places " .
	"(negative numbers not supported)"
);

my $result = sprintf "%.${places}e", $num;
$result =~ s/(?<=e[+-])0+(?!\z)//;   # convert 0e+00 to 0e+0

return JE::String->new($global, $result);

			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toPrecision',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toPrecision',
			no_proto => 1,
			argnames => ['precision'],
			function_args => ['this'],
			function => sub {
my $self = shift;
die JE::Object::Error::TypeError->new(
	$global,
	"Argument to " .
	"Number.prototype. toPrecision is not"
	. " a " .
	"Number object"
) unless $self->class eq 'Number';

my $num = $self->value;
$num == $num or return JE::String->new($global, 'NaN');
abs $num == inf && return JE::String->new($global,
	($num < 0 && '-') . 'Infinity');

my $prec = shift;
if(!defined $prec || $prec->id eq 'undef') {
	return JE::String->new($global, $num);
# ~~~ if/when JE::Number::to_string is rewritten, make this use the same
#    algorithm
}

$prec = ($prec = int $prec->to_number) == $prec && $prec;

$prec < 1 and throw JE::Object::Error::RangeError->new($global,
	"Precision out of range: $prec " .
	"(must be >= 1)"
);


# ~~~ Probably not the most efficient alrogithm. maybe I coould optimimse
#    it later. OD yI have tot proooofrfreoad my aown tiyping.?

if ($num == 0) {
	$prec == 1 or $num = '0.' . '0' x ($prec-1);
}
else {
	$num = sprintf "%.${prec}g", $num; # round it off
	my $e = int log(int $num)/log 10;
	if($e < -6 || $e >= $prec) {
		($num = sprintf "%.${prec}e", $num)	
		 =~ s/(?<=e[+-])0+(?!\z)//;   # convert 0e+00 to 0e+0
	}
	else { $num = sprintf "%." . ($prec - 1 - $e) . 'f' }
}

return JE::String->new($global, $num);

			},
		}),
		dontenum => 1,
	});

	$f;
}

return "a true value";

=back

=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::Object

=item JE::Number

=cut
