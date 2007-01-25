package JE::Object::Function;


=begin stuff for MakeMaker

use JE; our $VERSION = $JE::VERSION;

=end

=cut


use strict;
use warnings;

our @ISA = 'JE::Object';

require JE::Object;
require JE::Code;


our $constructor = __PACKAGE__->make_constructor; # ~~~ Does this con-
                                                  #     structor pass
                                                  #     the arguments
                                                  #     in  the right
                                                  #     order?  
our $prototype = $constructor->prop('prototype');


=head1 NAME

JE::Function - JavaScript function class

=head1 SYNOPSIS

  use JE::Object::Function;

  # simple constructors:

  $f = new JE::Object::Function $scope, @argnames, $function;
  $f = new_method JE::Object::Function sub { ... };
  $f = new JE::Object::Function sub { ... };
  $f = simple JE::Object::Function sub { ... };

  # constructor that lets you do anything:

  $f = new JE::Object::Function {
          scope            => $scope,
          argnames         => [ @argnames ],
          function         => $function,
          function_args    => [ $arglist ],
          constructor      => sub { ... },
          constructor_args => [ $arglist ],
          downgrade        => 0,
  };


  $f->call(@args);
  $f->construct(@args); # if this is a constructor function
  $f->apply($obj, @args);

=head1 DESCRIPTION

All JavaScript functions are instances of this class.

=head1 OBJECT CREATION

=over 4

=item new 

Creates and returns a new function (see the next few items for its usage).
The new function will have a C<prototype> property that is an empty
object with I<its> prototype set to null.

The return value of the function will be upgraded if necessary (see 
L<UPGRADING VALUES> in the JE::Object man page).

A function written in Perl can return an lvalue if it wants to. Use
S<< C<new JE::LValue($object, 'property name')>. >> To return an lvalue 
that
refers to a variable visible within the function's scope, use
S<< C<<< $scope->lvalue('varname') >>> >> (this assumes that you have
shifted the scope object off C<@_> and called it C<$scope>;

=item new JE::Object::Function $scope, @argnames, $function;

C<$scope> is one of the following:

  - a global (JE) object
  - a scope chain (JE::Scope) object
  - an array ref whose elements are a global object,  followed by
    zero or more hash refs, each representing a call object

C<@argnames> is a list of argument names, that JavaScript functions use to access the arguments.

$function is one of

  - a string containing the body of the function (JavaScript code)
  - an existing function object (unimplemented; I don't remember
    why I included this in the list)
  - a coderef

If C<$function> is a coderef (Perl subroutine), the arguments passed to it
when the function is invoked will be

  0) a scope chain object (see L<JE::Scope>)
  1) the invocant (the object through which the function is invoked)
  2..) the arguments

The function object itself can be accessed via
C<< $_[0]->var('arguments')->prop('callee') >> (though I admit that is a
bit much to type).


=item new_method JE::Object::Function sub { ... };

If you are writing a method in Perl and are not interested in the scope, 
use this method. The first argument to the sub will be the invocant.
The remaining arguments will be those with which JavaScript called the
function.

=item new JE::Object::Function sub { ... };

In this case, the subroutine will be called with the arguments the function
is invoked with, but with no invocant or scope chain. The arguments will
still be JavaScript objects.


=item simple JE::Object::Function sub { ... };

The simplest type of function (I'm sure this will be very useful) is
created like this. 

The difference between this and the one above is that the objects passed
as arguments will all have the C<value> method called, which will then be
used in the arguments passed to the subroutine.

=item new JE::Object::Function { ... };

This is the big fancy way of creating a function that lets you do anything.
The elements of the hash ref passed to C<new> are as follows (they are
all optional):

=over 4

=item scope

A global object, scope chain object, or array ref. If this is omitted, the
body of the function (the C<function> element) must be a Perl coderef, and
not a string of JS code.

=item argnames

The variable names that a JS function uses to access the 
arguments.

=item function

A coderef or string of JS code (the body of the function).

This will be run when the function is called from JavaScript without the
C<new> keyword, or from Perl via the C<call> method.

=item function_args

This only applies when C<function> is a code ref. C<function_args> is an 
array ref, the elements being strings that indicated what arguments should
be passed to the Perl subroutine. The strings, and what they mean, are
as follows:

  self    the function object itself
  scope   the scope chain
  this    the invocant
  args    the arguments passed to the function (as individual
          arguments)
  [args]  the arguments passed to the function (as an array ref)

If C<function_args> is omitted, the first argument will be the scope chain,
if any, followed by the invocant, and then the arguments (as individual
elements in C<@_>, not as an array ref).

=item constructor

A code ref that creates and initialises a new object. This is called when
the C<new> keyword is used in JavaScript, or when the C<construct> method
is used in Perl.

If this is omitted, when C<new> or C<construct> is used, a new empty object 
will be created and passed to the
sub specified under C<function>. The return value of the sub will be
discarded, and the (possibly modified) object will be returned.

=item constructor_args

Like C<function_args>, but the C<'this'> string does not apply.

=item downgrade

This applies only when C<function> or C<constructor> is a code ref. This
is a boolean indicating whether the arguments to the function should have 
their C<value> methods called automatically.; i.e., as though
S<<< C<< map $_->value, @args >> >>> were used instead of C<@args>.

=back

=back

=head1 METHODS

=over 4

=item new JE::Object::Function

=item new_method JE::Object::Function

=item simple JE::Object::Function

See L<OBJECT CREATION>.

=cut

sub new { # ~~~ This sub needs some error-checking
	my $class = shift;
	my %opts =
	  ref($_[0]) eq 'HASH'
	?	%{+shift}
	: ref($_[0]) eq 'CODE'
	? 	( function      => shift,
		  function_args => ['args'], )
	: 	( scope    => shift,
		  argnames => [ @_[0..$#_-1] ],
		  function => pop,
		  function_args => [qw<scope this args>] )
	;

	(my $self = __PACKAGE__->SUPER::new)
	   ->prototype($prototype);
	$self->prop(prototype => JE::Object->new);

	{ no warnings 'uninitialized';
	$$self{function} =
	  ref $opts{function}    ? $opts{function}
	: length $opts{function} ? JE::Code::parse($opts{scope},
	                                           $opts{function})
	: '';
	} #warnings back on

	# ~~~ still need to save constructor, arg & scope info
	bless $self, $class;
}

sub new_method {
# ~~~
}

sub simple {
# ~~~~
}




=item

  $f->call(@args); # needs to set up the call object with an arguments property
  $f->construct(@args); # if this is a constructor function
  $f->apply($obj, @args);


=cut

=item prop ( $name, $value )
=item prop ( $name )

If $value is not given, C<prop> returns the value of the property. With an 
argument, it sets the value of the property named $name to $value. The
value may be upgraded.  (See L<UPGRADING>, below.)

=item props

Returns a list of property names. This is used for C<for...in>
loops in JavaScript.

=item property
=item properties

These are synonyms for C<prop> and C<props>, respectively. If you are
subclassing this module, you should not override these, but the short forms
instead, since these call those.

=item method ( $name, @args )

This calls a method with the specified name and arguments.

=item typeof

This returns the string that the C<typeof> JavaScript operator produces.

=item class

This returns the name of the class to which the object belongs. This is
currently used only by the default JavaScript C<toString> method.

=item value

This returns a value that is supposed to be useful in Perl. For the base
class, it returns a hash ref. Derived classes should override this such
that it produces whatever makes sense. C<< JE::Object::Array->value >>,
for instance, produces an array ref.

=item primitive

This returns a boolean indicating whether an object is treated as a simple
value (a primitive) in JavaScript, or an object. The distinction is simply 
whether an
assignment will copy the value/object, or merely copy a reference. (See
more discussion of this on the man page for C<JE::Object::StrVal>.) The
base class returns false when this method is called. If a derived class
changes it to return true, it should also provide a C<clone> method for
cloning the object.

It is
necessary to use objects in Perl for simple JavaScript values, because JS
makes a distinction between numbers, strings, booleans, etc. The only way
(or is it simply the easiest way?)
to keep this distinction in Perl is to use objects--but JavaScript doesn't
need to know that it's dealing with objects.

=cut

#----------- PRIVATE SUBROUTINES ---------------#



#----------- THE REST OF THE DOCUMENTATION ---------------#

=pod

=head1 UPGRADING VALUES

~~~ rename UPGRADING above to UPGRADING VALUES
=head1 AUTHOR

Father Chrysostomos <sprout [at] cpan [dot] org>

=head1 SEE ALSO

=over 4

other stuff

=cut




