package JE::Scope;

our $VERSION = '0.003';

use strict;
use warnings;

require JE::LValue;

our $AUTOLOAD;

# ~~~ We probably need a C<can> method.

sub var {
	my ($self,$var) = @_;
	my $lvalue;
	for(reverse @$self) {
		defined $_->prop($var) or next;
		$lvalue = new JE::LValue $_, $var;
		goto FINISH;
	}
	# if we get this far, then we creat lvalue(null,prop)
	$lvalue = new JE::LValue $self->[0]->null, $var;

	FINISH:
	@_ > 2 and $lvalue->set(shift);
	return $lvalue;
}

sub new_var {
	my ($self,$var) = @_;
	if (defined $$self[-1]->prop($var)) {
		$$self[-1]->prop($var, shift) if @_ > 2;
	}
	else {
		$$self[-1]->prop($var, @_ > 2 ? shift :
			$$self[0]->undefined);
	}

	# This is very naughty code, but it works.	
	$JE::Code::Expression::_eval or $$self[-1]->prop({
		name => var,
		dontdel => 1,
	});


	return new JE::LValue $self->[0]->null, $var
		unless not defined wantarray;
}

sub AUTOLOAD { # This delegates the method to the global object
	my($method) = $AUTOLOAD =~ /([^:]+)\z/;

	 # deal with DESTROY, etc. # ~~~ Am I doing the right
	                           #     thing?
	return if $method =~ /^[A-Z]+\z/;

	shift->[0]->$method(@_); # ~~~ Maybe I should use goto
	                         #     to remove AUTOLOAD from
	                         #     the call stack.
}

1;

=head1 NAME

JE::Scope - JavaScript scope chain (what makes closures work)

=head1 DESCRIPTION

JavaScript code runs within an execution context which has a scope chain
associated with it. This class implements this scope chain. When a variable 
is accessed the objects in the scope chain are searched till the variable
is found.

A JE::Scope object can also be used as global (JE) object. Any methods it
does not understand will be delegated to the object at the bottom of the
stack (the far end of the chain), so that C<< $scope->null >> means the
same thing as C<< $scope->[0]->null >>.

Objects of this class consist of a reference to an array, the elements of
which are the objects in the chain (the first element
being the global object). (Think
of it as a stack.)

=head1 METHODS

=over 4

=item var($name, $value)

=item var($name)

This method searches through
the scope chain, starting at the end of the array, until it 
finds the
variable named by the first argument. If the second argument is
present, it sets the variable. It then returns an lvalue (a
JE::LValue object) that references the variable. Note that, even though
it has the same name as the C<var> JS keyword, it does I<not> create a new
variable.

=item new_var($name, $value)

=item new_var($name)

This method creates (and optionally sets the value of) a new
variable on the nearest end of the scope chain (the top of the scope 
stack) and returns an lvalue.

=head1 CONSTRUCTOR

None. Just bless an array reference. You should not need to do
this because it is done for you by the C<JE> and C<JE::Object::Function> 
classes.

=head1 SEE ALSO

=item L<JE>

=item L<JE::LValue>

=item L<JE::Object::Function>

=cut




