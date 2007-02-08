package JE::LValue;

our $VERSION = '0.002';

use strict;
use warnings;

# ~~~ I need to figure out how to delegate overloaded ops to the object
#     contained (referenced) by the JE::LValue, such that $lvalue->{0}
#     will produce the same as $lvalue->get->{0}. I may need to make
#     JE::LValue objects into references to array refs \[ ... ]. Right
#     now they are just array refs [ ... ].

#use overload nomethod => sub {
#	
#};


sub new {
	my ($class, $obj, $prop) = @_; # prop is a string
	bless [$obj, $prop], $class;
}

sub get {
	my $self = shift;
	$self->[0]->prop($self->[1]);
}

sub set {
	my $obj = (my $self = shift)->[0];
	$obj->id eq 'null' and $obj = $$obj;
	$obj->prop($self->[1], shift);
}

our $AUTOLOAD;

sub AUTOLOAD {
	my($method) = $AUTOLOAD =~ /([^:]+)\z/;

	 # deal with DESTROY, etc. # ~~~ Am I doing the right
	                           #     thing?
	return if $method =~ /^[A-Z]+\z/;

	shift->get->$method(@_); # ~~~ Maybe I should use goto
	                         #     to remove AUTOLOAD from
	                         #     the call stack.
}


=head1 NAME

JE::LValue - JavaScript lvalue class

=head1 SYNOPSIS

  use JE::LValue;

  $lv = new JE::LValue $some_obj, 'property_name';

  $lv->get;         # get property
  $lv->set($value)  # set property

  $lv->some_other_method  # same as $lv->get->some_other_method

=head1 DESCRIPTION

This class implements JavaScript lvalue (called "Reference Types" by the
ECMAScript specification).

=head1 METHODS

If a method is called that is not listed here, it will be passed to the 
property referenced by the lvalue. (See the last item in the L<SYNOPSIS>,
above.)

=over 4

=item $lv = new JE::LValue $obj, $property

Creates an lvalue/reference with $obj as the base object and $property
as the property name.

=item $lv->get

Gets the value of the property.

=item $lv->set($value)

Sets the property to $value.

=cut




1;
