package JE::Object::Array;

our $VERSION = '0.004';


use strict;
use warnings;

use overload fallback => 1,
	'@{}'=> 'value';


our @ISA = 'JE::Object';

require JE::Object;
require JE::String;
require JE::Number;

=head1 NAME

JE::Object - JavaScript Array object class

=head1 SYNOPSIS

  use JE;
  use JE::Object::Array;

  $j = new JE;

  $js_array = new JE::Object::Array $j, 1, 2, 3;

  $perl_arrayref = $js_array->value; # returns [1, 2, 3]

  $js_array->[1]; # same as $js_array->value->[1]

  "$js_array"; # returns "1,2,3"

=head1 DESCRIPTION

This module implements JavaScript Array objects.

The C<@{}> (array ref) operator is overloaded and returns the array that
the object uses underneath.

=head1 METHODS

See L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object::Array is explained here.

=over 4

=item $a = JE::Object::Array->new($global, \@elements)

=item $a = JE::Object::Array->new($global, $length)

=item $a = JE::Object::Array->new($global, @elements)

This creates a new Array object.

If the second argument is an unblessed array ref, the elements of that
array become the elements of the new array object.

If there are two arguments and the second
is a JE::Number, a new array is created with that number as the length.

Otherwise, all arguments starting from the second one become elements of
the new array object.

=cut

sub new {
	my($class,$global) = (shift,shift);

	my @array;
	if (ref $_[0] eq 'ARRAY') {
		@array = $global->upgrade(@{+shift});
	} elsif (@_ == 1 && UNIVERSAL::isa $_[0], 'JE::Number') {
		my $num = 0+shift;
		$num == int($num) % 2**32 or die; # ~~~ RangeError
		$#array = $num - 1;
	}
	else {
		@array = $global->upgrade(@_);
	}
	(my $self = SUPER::new $class $global)
	->prototype( $global->prop('Array')->prop('prototype') );

	my $guts = $$self;

	$$guts{array} = \@array;
	bless $self, $class;
}




# ~~~ Finish writing methods.

sub prop {
	my ($self, $name, $val) =  (shift, @_);
	my $guts = $$self;

	if ($name eq 'length') {
		if (@_ > 1) { # assignment
			$val == int($val) % 2**32 or die; # ~~~ RangeError
			$#{$$guts{array}} = $val - 1;
			return JE::Number->new($$guts{global}, $val);
		}
		else {
			return JE::Number->new($$guts{global},
				$#{$$guts{array}} + 1);
		}
	}
	elsif ($name =~ /^(?:0|[1-9]\d*)\z/ and $name < 4294967295) {
		if (@_ > 1) { # assignment
			return $$guts{array}[$name] =
				$$guts{global}->upgrade($val);
		}
		else {
			return exists $$guts{array}[$name]
				? $$guts{array}[$name] : undef;
		}
	}
	$self->SUPER::prop(@_);
}


#sub props # ~~~ I nee to find out wmhat this does.

#sub delete # ~~~ array indices are deletable
	# length is not




=item $a->value

This returns a reference to an array ref. This is the actual array that
the object uses internally, so you can modify the Array object by modifying
this array.

=cut

sub value { $${+shift}{array} };


sub class { 'Array' }



sub new_constructor {
	shift->SUPER::new_constructor(shift,
		sub {
			__PACKAGE__->new(@_);
		},
		sub {
			my $proto = shift;
			my $global = $$proto->{global};
			$proto->prop({
				name  => 'toString',
				value => JE::Object::Function->new({
					scope  => $global,
					name   => 'toString',
					length => 1,
					function_args => ['this'],
					function => sub {
						my $guts = ${+shift};
						JE::String->new(
							$$guts{global},
							join ',', @{
							     $$guts{array}
							}
						);
					}
				}),
				dontenum => 1,
			});
		},
	);
}

=back

=head1 SEE ALSO

L<JE>

L<JE::Types>

L<JE::Object>

=cut

1;
