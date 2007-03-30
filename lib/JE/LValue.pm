package JE::LValue;

our $VERSION = '0.006';

use strict;
use warnings;

use Scalar::Util 'blessed';
use List::Util 'first';

# ~~~ We need a C<can> method.


# ~~~ Make it so that a TypeError is thrown when an lvalue is *created*
#     with undefined or null as the base object. JE::Scope::var needs to
#     be modified to pass undef as the base object when creating a ref to
#     a non-existent var. When undef is passed to new, store an unblessed
#     ref to the global object instead of null.
#     -- Actually this won't work properly because the lvalue needs a ref
#        to the global object, so I need to think this through more.

# ~~~ Make 'call' use ->method instead of ->apply???


our $ovl_infix = join ' ', @overload::ops{qw[
	with_assign assign num_comparison 3way_comparison str_comparison	binary
]};
our $ovl_prefix = join ' ', @overload::ops{qw[ mutators func ]};

use overload eq => sub {  # 'eq' is not campatible with 'nomethod' in
	                  # perl 5.8.8
	$_[0]->get eq $_[1];
}, nomethod => sub {
	local $@;
	my ($self, $other, $reversed, $symbol) = @_;
	$self = $self->get;
	my $val;
	if ($overload::ops{conversion} =~ /(?:^| )$symbol(?:$| )/) {
		return $self;
	}
	elsif($ovl_infix =~ /(?:^| )$symbol(?:$| )/) {
		$val = eval( $reversed ? "\$other $symbol \$self"
		                       : "\$self $symbol \$other" );
	}
	elsif($symbol eq 'neg') {
		$val = eval { -$self };
	}
	elsif($ovl_prefix =~ /(?:^| )$symbol(?:$| )/) {
		$val = eval "$symbol \$self";
	}
	$@ and die $@;
	return $val;
}, '@{}' => sub {
	caller eq __PACKAGE__ and return shift;	
	$_[0]->get;
}, '%{}' => 'get', '&{}' => 'get', '*{}' => 'get';


sub new {
	my ($class, $obj, $prop) = @_; # prop is a string
	bless [$obj, $prop], $class;
}

sub get {
	my $self = shift;
	my $val = $self->[0]->prop($self->[1]);
	defined $val ? $val : $self->[0]->global->undefined;
		# If we have a Perl undef, then the property does not
		# not exist, and we have to return a JS undefined val.
}

sub set {
	my $obj = (my $self = shift)->[0];
	$obj->id eq 'null' and $obj = $$self[0] = $$obj;
	$obj->prop($self->[1], shift);
	$self;
}

sub call {
	my $base_obj = (my $self = shift)->[0];
	my $prop = $self->get;
	blessed $prop and can $prop 'apply' or die; # ~~~ TypeError, I fink
	$prop->apply($base_obj, @_);
}

sub base { shift->[0] }

sub property { shift->[1] }

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

This class implements JavaScript lvalues (called "Reference Types" by the
ECMAScript specification).

=head1 METHODS AND OVERLOADING

If a method is called that is not listed here, it will be passed to the 
property referenced by the lvalue. (See the last item in the L<SYNOPSIS>,
above.) For this reason, you should never call C<UNIVERSAL::can> on a
JE::LValue, but, rather, call it as a method (C<< $lv->can(...) >>), unless
you really know what you are doing.

B<To do:> Implement the C<can> method, since it doesn't exist yet.

Similarly, if you try to use an overloaded operator, it will be passed on 
to
the object that the lvalue references, such that C<!$lvalue> is the same
as calling C<!$lvalue->get>. Note, however, that this does I<not> apply to
the iterator (C<< <> >>) operator, the scalar dereference op (C<${}>) and 
the special copy operator (C<=>).

=over 4

=item $lv = new JE::LValue $obj, $property

Creates an lvalue/reference with $obj as the base object and $property
as the property name.

=item $lv->get

Gets the value of the property.

=item $lv->set($value)

Sets the property to $value and returns $lv.

=item $lv->call(@args)

If the property is a function, this calls the function with the
base object as the 'this' value.

=item $lv->base

Returns the base object.

=item $lv->property

Returns the property name.

=cut




1;
