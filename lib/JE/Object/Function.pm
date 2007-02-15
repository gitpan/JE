package JE::Object::Function;

our $VERSION = '0.003';


use strict;
use warnings;

use Scalar::Util 'blessed';

our @ISA = 'JE::Object';

require JE::Object;
require JE::Scope;
require JE::Code;


# ~~~ Make sure that 'new' accepts args the same order as 'new Function()'
#     preceded by ($class, $global). 


=head1 NAME

JE::Function - JavaScript function class

=head1 SYNOPSIS

  use JE::Object::Function;

  # simple constructors:

  $f = new JE::Object::Function $scope, @argnames, $function;
  $f = new JE::Object::Function $scope, sub { ... };
  $f = new_method JE::Object::Function $scope, sub { ... };

  # constructor that lets you do anything:

  $f = new JE::Object::Function {
          name             => $name,
          scope            => $scope,
          length           => $number_of_args,
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
The new function will have a C<prototype> property that is an object with
a C<constructor> property that refers to the function itself.

The return value of the function will be upgraded if necessary (see 
L<UPGRADING VALUES|JE::Types/UPGRADING VALUES> in the JE::Types man page),
which is why C<new> I<has> to be given a reference to the global object
or the scope chain. (But see also L<JE/new_function>.)

A function written in Perl can return an lvalue if it wants to. Use
S<< C<new JE::LValue($object, 'property name')> >> to create it. To create 
an lvalue 
that
refers to a variable visible within the function's scope, use
S<< C<<< $scope->var('varname') >>> >> (this assumes that you have
shifted the scope object off C<@_> and called it C<$scope>;

=item new JE::Object::Function $scope_or_global, @argnames, $function;

C<$scope_or_global> is one of the following:

  - a global (JE) object
  - a scope chain (JE::Scope) object

C<@argnames> is a list of argument names, that JavaScript functions use to access the arguments.

$function is one of

  - a string containing the body of the function (JavaScript code)
  - a JE::Code object
  - a coderef

If C<$function> is a coderef (Perl subroutine), the arguments passed to it
when the function is invoked will be

  0) a scope chain object (see L<JE::Scope>)
  1) the invocant (the object through which the function is invoked)
  2..) the arguments

The function object itself can be accessed via
C<< $_[0]->var('arguments')->prop('callee') >> (though I admit that is a
bit much to type).


=item new JE::Object::Function $scope_or_global, sub { ... };

In this case, the subroutine will be called with the arguments the function
is invoked with, but with no invocant or scope chain.


=item new_method JE::Object::Function $scope_or_global, sub { ... };

If you are writing a method in Perl and are not interested in the scope, 
use this method. The first argument to the sub will be the invocant.
The remaining arguments will be those with which JavaScript called the
function.


=item new JE::Object::Function { ... };

This is the big fancy way of creating a function that lets you do anything.
The elements of the hash ref passed to C<new> are as follows (they are
all optional, except for C<scope>):

=over 4

=item name

The name of the function. This is used only by C<toString>.

=item scope

A global object or scope chain object. If this is omitted, the
body of the function (the C<function> element) must be a Perl coderef, and
not a string of JS code, and it must return a JavaScript value or a simple
scalar (not an unblessed array or hash ref).

=item length

The number of arguments expected. If this is omitted, the number of
elements of C<argnames> will be used. If that is omitted, 0 will be used.
Note that this does not cause the argument list to be checked. It only
provides the C<length> property for inquisitive scripts to look at.

=item argnames

An array ref containing the variable names that a JS function uses to 
access the 
arguments.

=item function

A coderef, string of JS code or JE::Code object (the body of the function).

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
followed by the invocant, and then the arguments (as individual
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

Like C<function_args>, but the C<'this'> string does not apply. If 
C<constructor_args> is
omitted, but C<constructor> is not, the arg list will be set to
C<[ qw( scope args ) ]>.

=item downgrade

This applies only when C<function> or C<constructor> is a code ref. This
is a boolean indicating whether the arguments to the function should have 
their C<value> methods called automatically.; i.e., as though
S<<< C<< map $_->value, @args >> >>> were used instead of C<@args>.

=item no_proto

If this is set to true, the returned function will have no C<prototype>
property.

=back

=back

=head1 METHODS

=over 4

=item new JE::Object::Function

=item new_method JE::Object::Function

See L<OBJECT CREATION>.

=cut

sub new { # ~~~ This sub needs some error-checking
	# ~~~ IT also needs to split argnames on ','
	#     In fact, I need to check the whole thing against E 15.3.2
	my($class,$scope) = (shift,shift);
	my %opts;

	if(ref $scope eq 'HASH') {
		%opts = %$scope;
		$scope = $opts{scope};
	}
	else {
		%opts = ref($_[0]) eq 'CODE'
		? 	( function      => shift,
			  function_args => ['args'], )
		: 	( argnames => [ @_[0..$#_-1] ],
			  function => pop,
			  function_args => [qw<scope this args>] )
		;
	}

	my $self = $class->SUPER::new($scope);
	my $guts = $$self;

	my $global = $scope;

	ref $scope ne 'JE::Scope' and $scope = bless [$scope], 'JE::Scope';
	$$guts{scope} = $scope;

	$self->prototype( $global->prop('Function')->prop('prototype') );

	$opts{no_proto} or $self->prop({
		name     => 'prototype',
		dontenum => 1, # ~~~ anytink else?
		value    => JE::Object->new($scope),
	})->prop({
		name     => 'constructor',
		dontenum => 1, # ~~~ What other attrs does
		               #     'constructor' need?
		value    => $self,
	});

	{ no warnings 'uninitialized';
	$$guts{function} =
	  ref($opts{function}) =~ /^(?:JE::Code|CODE)\z/ ? $opts{function}
	: length $opts{function} ?
		(
		  $$guts{func_src} = $opts{function},
		  JE::Code::parse($scope, $opts{function})
		)
	: ($$guts{func_src} = '');
	} #warnings back on

	$self->prop({
		name     => 'length',
		value    => $opts{length} || 0,
		dontenum => 1,
		dontdel  => 1, 
		readonly => 1
	});
	$$guts{func_argnames} = [
		ref $opts{argnames} eq 'ARRAY' ? @{$opts{argnames}} : ()
	];
	$$guts{func_args} = [
		ref $opts{function_args} eq 'ARRAY'
		? @{$opts{function_args}} :
		('scope', 'this', 'args')
	];

	if(exists $opts{constructor}) {
		$$guts{constructor} = $opts{constructor};
		$$guts{constructor_args} = [
			ref $opts{constructor_args} eq 'ARRAY'
			? @{$opts{constructor_args}} : ('scope', 'args')
		];
	}
	if(exists $opts{name}) {
		$$guts{func_name} = $opts{name};
	}
	 	
	$self;
}

sub new_method {
# ~~~
}




=item call ( @args )

Calls a function with the given arguments. The invocant (the 'this' value)
will be the global object. This is just a wrapper around C<apply>.

=cut

sub call {
	my $self = shift;
	$self->apply($$$self{global}, @_);
}




=item construct

Calls the constructor, if this function has one (functions written in JS
don't have this). Otherwise, an object will be created and passed to the 
function as its invocant. The return value of the function will be
discarded, and the object (possibly modified) will be returned instead.

=cut

sub construct { # ~~~ we need to upgrade the args passed to construct, but 
                #     still retain the unupgraded values to pass to the 
                #     function *if* the function wants them downgraded
	my $self = shift;
	my $guts = $$self;
	if(exists $$guts{constructor}
	   and ref $$guts{constructor} eq 'CODE') {
		my $code = $$guts{constructor};
		my @args;
		for(  @{ $$guts{constructor_args} }  ) {
			push @args,
			  $_ eq 'self'
			?	$self
			: $_ eq 'scope'
			?	_init_scope($self, $$guts{scope},
					[], @_)
			: $_ eq 'args'
			?	@_ # ~~~ downgrade if wanted
			: $_ eq '[args]'
			?	[@_] # ~~~ downgrade if wanted
			: 	undef;
		}
		return $$guts{global}->upgrade($code->(@args));
	}
	else {
		(my $obj = JE::Object->new($$guts{global}))
		->prototype(
			$self->prop('prototype')
		);
		$self->apply($obj, @_);
		return $obj;
	}
}




=item apply ( $obj, @args )

Calls the function with $obj as the invocant and @args as the args.

=cut

sub apply { # ~~~ we need to upgrade the args passed to apply, but still
            #     retain the unupgraded values to pass to the function *if*
            #     the function wants them downgraded
	my ($self, $obj) = (shift, shift->to_object);
	my $guts = $$self;

	if(!blessed $obj or $obj->id eq 'null'
	    or ref $obj eq 'JE::Object::Function::Call') {
		$obj = $$guts{global};
	}

	if(ref $$guts{function} eq 'CODE') {
		my @args;
		for(  @{ $$guts{func_args} }  ) {
			push @args,
			  $_ eq 'self'
			?	$self
			: $_ eq 'scope'
			?	_init_scope($self, $$guts{scope},
					$$guts{func_argnames}, @_)
			: $_ eq 'this'
			?	$obj
			: $_ eq 'args'
			?	@_ # ~~~ downgrade if wanted
			: $_ eq '[args]'
			?	[@_] # ~~~ downgrade if wanted
			: 	undef;
		}
		return $$guts{global}->upgrade($$guts{function}->(@args));
	}
	elsif ($$guts{function}) {
		$$guts{function}->execute($obj, _init_scope($self, 
			$$guts{scope}, $$guts{func_argnames}, @_
		) );
	}
	else {
		return $$guts{global}->undefined;
	}
}

sub _init_scope { # initialise the new scope for the function call
	my($self, $scope, $argnames, @args) = @_;

	bless([ @$scope, JE::Object::Function::Call->new({
		global   => $scope,
		argnames => $argnames,
		args     => [@args],
		function => $self,
	})], 'JE::Scope');
}




=item typeof

This returns the string 'function'.

=cut

sub typeof { 'function' }




=item class

This returns the string 'Function'.

=cut

sub class { 'Function' }




=item value

Not yet implemented.

=cut

#----------- PRIVATE SUBROUTINES ---------------#

# _init_proto takes the Function prototype (Function.prototype) as its sole
# arg and adds all the default properties thereto.

sub _init_proto {
	my $proto = shift;
	my $scope = $$proto->{global};

	# E 15.3.4
	$proto->prop({
		name      => 'toString',
		value     => JE::Object::Function->new({
			scope    => $scope,
			name     => 'toString',
			function_args => ['this'],
			function => sub {
				my $self = shift;
				my $guts = $$self;
				my $str = 'function ';
				JE::String->new($scope,
					'function ' .
					( exists $$guts{func_name} ?
					  $$guts{func_name} : '') .
					'(' .
					join(',', @{$$guts{func_argnames}})
					. ") {" .
					( ref $$guts{function} eq 'CODE' ?
					  "\n    [native code]\n" :
					  $$guts{func_src}
					) . '}'
				);
			},
		}),
		dontenum  => 1, # ~~~ any other attrs?
	});
	$proto->prop({
		name      => 'apply',
		value     => JE::Object::Function->new({
			scope    => $scope,
			name     => 'apply',
			length   => 2,
			function_args => ['this','args'],
			function => sub {
				my($self,$obj,$args) = @_;

				# ~~~ finish writing this with all the
				#     'ifs' described in E 15.3.4.3
				$self->apply($obj, eval{@{+shift}});
			},
		}),
		dontenum  => 1, # ~~~ any other attrs?
	});
	# ~~~ $proto->prop({ ... })
}


#----------- THE REST OF THE DOCUMENTATION ---------------#

=pod

=head1 SEE ALSO

=over 4

=item JE

=item JE::Object

=item JE::Types

=item JE::Scope

=item JE::LValue

=cut


package JE::Object::Function::Call;

our $VERSION = '0.003';

sub new {
	# See sub JE::Object::Function::_init_sub for the usage.

	my($class,$opts) = @_;
	my @args = @{$$opts{args}};
	my %self = map {
		my $arg_val =shift @args;
		$_ => defined $arg_val ? $arg_val :
			$$opts{global}->undefined;
	} @{$$opts{argnames}};

	$self{'-global'}  = $$opts{global};
	# A call object's properties can never be accessed via bracket
	# syntax, so '-global' cannot conflict with properties, since the
	# latter have to be valid identifiers.
	# ~~~ Except that I'm lax with regard to \uHHHH escapes,
	#     so I have to make the parser more strict by disal-
	#     lowing '-' (in escaped form) at the beginning of
	#     an identifier.
	

	unless (exists $self{arguments}) {
		$self{arguments} = 
			JE::Object::Function::Arguments->new(
				$$opts{global},
				$$opts{function},
				\%self,
				$$opts{argnames},
				@{$$opts{args}},
			);
	};

	return bless \%self, $class;
}

sub prop {
	my ($self, $name)  =(shift,shift);

	# This very naughty line assumes it's being called by
	# JE::Scope::new_var:
	return if ref $name eq 'HASH';

	if (@_ ) {
		return $$self{$name} = $$self{'-global'}->upgrade(shift);
	}

	if (exists $$self{$name}) {
		return $$self{$name};
	}

	return
}

sub delete { # ~~~ Can delete be called on a property of a call object?
             #     If so, does the arguments object still retain that prop?
	# 'arguments' has an attribute of 'dontdel'

}




package JE::Object::Function::Arguments;

our $VERSION = '0.003';

our @ISA = 'JE::Object';

sub new {
	my($class,$global,$function,$call,$argnames,@args) = @_;
	
	my $self = $class->SUPER::new($global);
	my $guts = $$self;

	$$guts{args_call} = $call;
	$self->prop({
		name => 'callee',
		value => $function,
		dontenum => 1,
	});
	$self->prop({
		name => 'length',
		value => scalar @args,
		dontenum => 1,
	});
	$$guts{args_length} = @args; # in case the length prop
	                              # gets changed

=begin pseudocode

Go through the named args one by one in reverse order.

If an arg with the same name as the current one has been seen
	Create a regular numbered property for that arg.
Else
	Create a magical property.

=end pseudocode

=cut

	my (%seen,$name,$val);
	for (reverse 0..$#$argnames) {
		($name,$val) = ($$argnames[$_], $args[$_]);
		if($seen{$name}++) {
			$self->prop({
				name => $_,
				value => $val,
				dontenum => 1,
			});
		}
		else {
			$$guts{args_magic}{$_} = $name;
		}
	}

	# deal with any extra properties
	for (@$argnames..$#args) {
		$self->prop({
			name => $_,
			value => $args[$_],
			dontenum => 1,
		});
	}

	$self;
}

sub prop {
	# Some properties are magically linked to properties of
	# the call object.

	my($self,$name) = @_;
	my $guts = $$self;
	if (exists $$guts{args_magic} and exists $$guts{args_magic}{$name})
	{
		return $$guts{args_call}->prop(
			$$guts{args_magic}{$name}, @_[2..$#_]
		);
	}
	SUPER::prop $self @_[1..$#_];
}

sub delete { 
	# Magical properties are still deleteable.
	my($self,$name) = @_;
	my $guts = $$self;
	if (exists $$guts{args_magic} and exists $$guts{args_magic}{$name})
	{
		delete $$guts{args_magic}{$name}
	}
	SUPER::delete $self @_[1..$#_];
}



1;