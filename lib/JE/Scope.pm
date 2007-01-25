package JE::Scope;

require 5.006;

use strict;
use warnings;

require JE; our $VERSION = $JE::VERSION;


sub var {
	my $self = shift;
	my($var,$newval) = @_;
	for(reverse @$self[1..$#$self]) {
		exists $$_{$var} or next;
		@_ > 1 and $$_{$var} = JE::Object::upgrade $newval;
		return $$_{$var};
	}
	# if we get this far, then we deal with the global scope
	my $ret = $$self[0]->prop(@_);
	defined $ret ? $ret : die \"$var has not been declared";
}

# ~~~ sub new_var
# ~~~ sub lvalue

=head1 NAME

JE::Scope - JavaScript scope chain (what makes closures work)

=head1 DESCRIPTION

JavaScript functions run within the scope in which they are defined. Each
function has a call object (aka activation object) that contains any vars
defined in the function. When a variable is accessed, the one in the call
object will be used, if any. Otherwise the one in the
containing function will be used, if the function is nested, and so on
until the search reaches the global scope.

Objects of this class consist of a reference to an array, the first element
of which is the global object. Subsequent elements are call objects. (Think
of it as a stack.)

A call object is quite a simple creature, so I've not seen any need to make
a special Perl class for it. I've just used a hashref.

=head1 THE METHOD

The only method provided by this package is C<var>, which searches through
the call chain, starting at the end of the array, until it finds the
variable named by the first argument. If a second argument is provided, it
is assigned to the variable. If the variable cannot be found, it is created
if an assignment is being made. An exception is thrown otherwise.

B<To do:> This class needs another method, C<new_var>, for creating a new
variable on the nearest end of the scope chain (the top of the scope 
stack)

B<To do:> And an C<lvalue> method, which will return a JE::LValue object,
to be used by JE::Code.

=head1 CONSTRUCTOR

None. Just bless an array reference. You should not need to do
this because it is done for you by the C<JE::Object::Function> class.

=head1 SEE ALSO

=over 4

L<JE>, L<JE::Object> and all the other JE:: modules.

=cut




