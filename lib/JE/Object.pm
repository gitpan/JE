package JE::Object;


=begin stuff for MakeMaker

use JE; our $VERSION = $JE::VERSION;

=end

=cut


use strict;
use warnings;
use subs 'upgrade';

use List::Util 'first';
use Data::Dumper;

require Exporter;
our @ISA='Exporter';


# I  can't  create  $prototype  with  new(),  because  new()  requires
# $prototype to be defined. And we have to set up the prototype before
# any JE::Object::  classes are loaded,  since they use  it  when they
# initialise their constructor functions.

our $prototype = bless { props => {}, keys => [] }, __PACKAGE__;


require JE::Object::Function;
require JE::Object::Array;
require JE::String;
require JE;


# Finish setting up the prototype and the constructor function

$prototype->prop(toString =>
	new_method JE::Object::Function \&to_string
  );

# ~~~ Problem: toString is enumerable if I put it in this way. I need a
#     way to add unenumerable properties without gutting the objects.

our $constructor = __PACKAGE__->make_constructor;
$constructor->prop(prototype => $prototype);





=head1 NAME

JE::Object - Base class for all JavaScript objects

=head1 SYNOPSIS

  use JE::Object;

  $obj = new JE::Object
          property1 => $obj1,
          property2 => $obj2;

  $obj->prop('property1');              # returns $obj1;
  $obj->prop('property1', $new_value);  # sets the property

  $obj->props; # returns a list of the names of enumerable property

  $obj->delete('property_name');

  $obj->method('method_name', 'arg1', 'arg2');
    # calls a method with the given arguments

  $obj->value ;    # returns a value useful in Perl (a hashref)

  "$obj"; # "[object Object]"
          # same as $obj->to_string->value


  # The rest are mostly for internal use:

  $obj->typeof;      # returns 'object'
  $obj->class ;      # returns 'Object'
  $obj->id    ;      # returns a unique id
  $obj->call  ;      # dies
  $obj->primitive;   # returns false
  $obj->def_value;   # default value, either toString or valueOf
                     # (see ECMAScript spec, clause 8.6.2.6)
  $obj->prototype;   # get/set the prototype object

  $obj->to_primitive;
  $obj->to_string;
  $obj->to_number;


=head1 DESCRIPTION

Prepare to get bored. This will put you to sleep.

A JavaScript object is an associative array, the keys of which are I<ordered,>
unlike hashes in Perl. A method is a property that happens to be an instance
of the
C<Function> class (C<JE::Object::Function>).

This class overrides the stringification operator by calling
C<< $obj->method('toString') >>.

If you try to invoke a method that does not exist, it will
return the value of the JavaScript property with the same name; i.e.,
C<< $obj->toString >> is the same as C<< $obj->method('toString') >>,
I<unless> there is a Perl method called C<toString> (which there isn't by
default). This is not implemented yet, and I am having second
thoughts about it.

=head1 METHODS

=over 4

=item new ( LIST )

This class method constructs and returns a new object. LIST is a hash-style
list of keys and values. If the values are not blessed references, they
will be upgraded. (See L<UPGRADING VALUES>, below.)

=cut

sub new {
	my($class, $self, %hash, @keys) = shift;
	my $key;
	while (@_) { # I have to loop through them to keep the order.
		$key = shift;
		push @keys, $key
			unless exists $hash{$key};
		$hash{$key} = upgrade shift;
	}

	bless { prototype => $prototype,
	        props     => \%hash,
	        keys      => \@keys  }, $class;
}




=item prop ( $name, $value )

=item prop ( $name )

If $value is given, C<prop> sets the value of the property named $name to 
$value. The
value may be upgraded.  (See L<UPGRADING VALUES>, below.) Whether $value
is given or not, it returns the value of the property. (Hmm, this is
beginning to sound like
real estate.)

=cut

sub prop {
	my ($self, $name) = (shift, shift);
	if (@_) { # we is doing a assignment
# ~~~ we need to make sure this does not obscure a read-only property
#     of a prototype (and just ignore the assignment)
		$$self{props}{$name} = upgrade shift;
		push @{ $$self{keys} }, $name
			unless first {$_ eq $name} @{ $$self{keys} }; 
		return $$self{$name};
	}
	else {
		my $props = $$self{props};
		return exists $$props{$name} ? $$props{$name} :
			$self->prototype ? $self->prototype->prop($name) :
			undef;
	}	
}




=item props

Returns a list of property names. This is used for C<for...in>
loops in JavaScript. This does not include all values accessible via
C<prop>. C<toString>, for instance is not in this list.

=cut

sub props {
	@{ shift->{keys} };
}




=item method ( $name, @args )

This calls a method with the specified name and arguments.

=item typeof

This returns the string that the C<typeof> JavaScript operator produces,
as a JE::String.

=item class

This returns the name of the class to which the object belongs. This is
currently used only by the default JavaScript C<toString> method.

=item value

This returns a value that is supposed to be useful in Perl. For the base
class, it returns a hash ref. Derived classes should override this such
that it produces whatever makes sense. C<< JE::Object::Array->value >>,
for instance, produces an array ref.

=item id

This returns a unique id for the object, used by the JavaScript C<===>
operator. This id is unique as a I<string,> but not as a number (even
though the base class returns a number). You should not have to override
this in a subclass.

=item prototype

=item prototype ( $obj )

This method returns the prototype of the object. If C<$obj> is specified,
the prototype is set to that object first. The C<prop> method uses this
method. You should not normally need
to call it yourself, unless you are subclassing JE::Object. 

=cut

sub prototype {
	@_ > 1 ? (shift->{prototype} = $_[1]) : shift->{prototype};
}




=item to_string

Returns a string equivalent of the object ("[object Object]").

=cut

sub to_string {
	JE::String->new('[object ' . shift->class . ']');
}


=item JE::Object->make_constructor

=item JE::Object->make_constructor( sub { ... } )

You should not call this method--or read its description--unless you are 
subclassing JE::Object. 

This class method creates and returns a function (JE::Object::Function) 
that is thought by JavaScript to have created all objects of this class.
The new
function will, when its C<construct> method is invoked, call C<new> in the 
package through which
C<make_constructor> is invoked, using the same arguments, but with the 
package name prepended to the argument list (as though
C<<< I<< <package name> >>->new >>> had been called.

If you provide a coderef as the sole argument, it will be used
as the body of the function when it is invoked normally (i.e., without
C<new> in JavaScript; using the C<call> method from Perl). If this is
omitted, the function will simply return undefined.

The prototype of the function's C<prototype> JS property will be set to
$JE::Object::prototype (known as C<Object.prototype> in JS). The
I<constructor> property of the C<prototype> property will be set to the
function itself.

Here is an example of how you might set up the
constructor function and add methods to the prototype (to be run just 
once--when the module is loaded):

  our @ISA = 'JE::Object';

  our $constructor = __PACKAGE__->make_constructor;
  our $prototype = $constructor->prop('prototype');
  for($prototype) {
          $_->prop(toString => new_method JE::Object::Function sub {
                  ...
          };
          # etc
  }

You can, of course, 
create your
own constructor function with C<new JE::Object::Function> if this does not 
do what you want.

=cut

sub make_constructor {
	my $package = shift;
	my $f = JE::Object::Function->new({
		function         => shift,
		function_args    => ['args'],
		constructor      => sub {
			no strict 'refs';
			&{"$package\::new"}($package, @_);
		},
		constructor_args => ['args'],
	});
	(my $p = $f->prop('prototype'))->prop(constructor => $f);
	$p->prototype($JE::Object::prototype)
		unless __PACKAGE__ eq $package; # We don't want
		                                # circular prototype
		                                # chains, do we?
	$f;
}




=back

=head1 VARIABLES

=over 4

=item $JE::Object::constructor

The C<Object> constructor function. This is the same as the
C<Object> property of the global object.

=back

=head1 FUNCTIONS

=over 4

=item JE::Object::upgrade

This function upgrades the value or values given to it. Read the next 
section for more detail. You may import this function if you like.


If you pass it more
than one
argument in scalar context, it returns the number of arguments--but that 
is subject to change, so don't do that.


=back

=head1 UPGRADING VALUES

Values are upgraded as follows: If the value is a blessed reference, it is
left alone (we assume you know what you are doing). Otherwise the
conversion is as follows:

  From            To
  -------------------------
  undef           undefined
  array ref       Array
  hash ref        Object
  code ref        Function (using the "simple" method)
  other scalar    string

=cut

sub upgrade { # ~~~ I need to make '0' into a number,  so that, when
              #     used as a bool in JS, it will still be false, as
              #     in Perl
	my @__;
	for (@_) {
		push @__,
		  UNIVERSAL::isa($_, 'UNIVERSAL')
		?	$_
		: !defined()
		?	$JE::undef
		: ref($_) eq 'ARRAY'
		?	JE::Object::Array->new(@$_)
		: ref($_) eq 'HASH'
		?	JE::Object->new(%$_)
		:	JE::String->new($_)
		;
	}
	@__ > 1 ? @__ : $__[0];
}




#sub AUTOLOAD {
	# ~~~ I plan to use this for accesing JS properties, but per-
	#     haps it's a  bad idea.
#}


#----------- THE REST OF THE DOCUMENTATION ---------------#

=pod

=head1 INNARDS

Each C<JE::Object> instance is a blessed hash ref. The contents of the hash
are as follows:

  $self->{props}        a hash ref of properties, the values being
                        JavaScript objects
  $self->{keys}         an array of the names of enumerable properties
  $self->{constructor}  the constructor function for this object (used
                        by _constructor)

In derived classes, if you need to store extra information, you may safely
begin the hash keys with an underscore. Such keys will never be used by the
classes that come with the JE distribution.

=head1 AUTHOR

Father Chrysostomos <sprout [at] cpan [dot] org>

=head1 SEE ALSO

L<JE> and all the modules listed in the L<WHICH CLASSES ARE WHICH> section
above.

L<JE::Types>

=cut


1;

