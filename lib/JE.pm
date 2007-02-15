package JE;

# If you are looking at the source code (which you are obviously doing
# if you are reading this),  note that  '# ~~~'  is my way of  marking
# something to be done still (except in this sentence).

# Note also that comments like "# E 7.1" refer to the indicated
# clause (7.1 in this case) in the ECMA-262 standard.

require 5.008;
use strict;
use warnings;

our $VERSION = '0.003';

our @ISA = 'JE::Object';

require JE::Object::Function;
require JE::Object::Array  ;
require JE::Undefined     ;
require JE::Number       ;
require JE::Object      ;
require JE::String     ;
require JE::Scope     ;
require JE::Null     ;
require JE::Code    ;

=head1 NAME

JE - Pure-Perl ECMAScript (JavaScript) Engine

"JE" is short for "JavaScript::Engine."

=head1 VERSION

Version 0.003

B<WARNING:> This module is still at an experimental stage. Only a few
features have been implemented so far. The API is subject to change without
notice.

Wait a minute! I shouldn't say that. I'll end up scaring people away. :-)
If
you have the time and the interest, please go ahead and experiment with
this module and let me know if you have any ideas as to how the API might
be
improved (or redesigned if need be).

So far it supports expression statements. See the README file for a list
of 'to-dos.'

=head1 SYNOPSIS

  use JE;

  $j = new JE; # create a new global object

  $j->eval('{"this": "that", "the": "other"}["this"]');
  # returns "that"

  $compiled = $j->compile('new Array(1,2,3)');
 
  $rv = $compiled->execute; # returns a JE::Object::Array
  $rv->value;               # returns a Perl array ref

  $obj = $j->eval('new Object');
  # create a new object

  $j->prop(document => $obj); # set property
  $j->prop(document => {});   # same thing (more or less)
  $j->prop('document'); # get a property

  $j->method(alert => "text"); # invoke a method

  # create global functions:
  $j->new_function(correct => sub {
          my $x = shift;
          $x =~ y/AEae/EAea/;
          substr($x,1,3) =~ y/A-Z/a-z/;
          return $x;
  } );
  $j->new_function(print => sub { print @_, "\n" } );

  $j->eval('print(correct("ECMAScript"))'); # :-)
  
=head1 DESCRIPTION

This is a pure-Perl JavaScript engine. All JavaScript values  are actually 
Perl objects underneath. When you create a new C<JE> object, you are 
basically 
creating
a new JavaScript "world," the C<JE> object itself being the global object. 
To
add properties and methods to it, and to access those properties, see 
L<< C<JE::Types> >> and L<< C<JE::Object> >>, which this
class inherits from.

If you want to create your own global object class (such as a web browser
window), inherit from JE.

=head1 METHODS

=over 4

=item $j = JE->new

This class method constructs and returns a new global scope (C<JE> object).

=cut

sub new {
	my $class = shift;

	# I can't use the usual object and function constructors, since
	# they both rely on the existence of  the global object and its
	# 'Object' and 'Function' properties.

	# Commented lines here are just for reference:
	my $self = bless \{
		#prototype => (Object.prototype)
		#global => ...
		keys => [],
		props => {
			Object => bless(\{
				#prototype => (Function.prototype)
				#global => ...
				#scope => bless [global], JE::Scope
				func_name => 'Object',
				func_argnames => [],
				func_args => ['scope','args'],
				function => sub { # E 15.2.1
					my $scope = shift;
					my $arg1 = $_[0];
					if(!defined $arg1 or
					   !defined $arg1->value) {
						return JE::Object->new(
							$scope, @_ );
					}
					else {
						return $_[0]->to_object;
					}
				},
				constructor_args => ['scope','args'],
				constructor => sub {
					JE::Object->new(@_);
				},
				keys => [],
				props => {
					#length => JE::Number->new(1),
					prototype => bless(\{
						#global => ...
						keys => [],
						props => {},
					}, 'JE::Object')
				},
				prop_readonly => {
					prototype => 1,
					length    => 1,
				 },
				prop_dontdel  => {
					prototype => 1,
					length    => 1,
				 },
			}, 'JE::Object::Function'),
			Function => bless(\{
				#prototype => (Function.prototype)
				#global => ...
				#scope => bless [global], JE::Scope
				func_name => 'Function',
				func_length => 1,
				func_argnames => [],
				func_args => ['scope','args'],
				function => sub { # E 15.3.1
					JE::Object::Function->new(@_);
				},
				constructor_args => ['scope','args'],
				constructor => sub {
					JE::Object::Function->new(@_);
				},
				keys => [],
				props => {
					#length => JE::Number->new(1),
					prototype => bless(\{
						#prototype=>(Object.proto)
						#global => ...
						keys => [],
						props => {},
					}, 'JE::Object')
				},
				prop_readonly => {
					prototype => 1,
					length    => 1,
				 },
				prop_dontdel  => {
					prototype => 1,
					length    => 1,
				 },
			}, 'JE::Object::Function'),
		},
	}, $class;

	my $obj_proto =
	    (my $obj_constr  = $self->prop('Object'))  ->prop('prototype');
	my $func_proto =
	    (my $func_constr = $self->prop('Function'))->prop('prototype');

	$self->prototype( $obj_proto );
	$$$self{global} = $self;

	$obj_constr->prototype( $func_proto );
	$$$obj_constr{global} = $self;
	my $scope = $$$obj_constr{scope} =  bless [$self], 'JE::Scope';

	$func_constr->prototype( $func_proto );
	$$$func_constr{global} = $self;
	$$$func_constr{scope} = $scope;

	$$$obj_proto{global} = $self;

	$func_proto->prototype( $obj_proto );
	$$$func_proto{global} = $self;

	$obj_constr ->prop({name=>'length', value=>1, dontenum=>1,
		dontdel=>1, readonly=>1});
	$func_constr->prop({name=>'length', value=>1, dontenum=>1,
		dontdel=>1, readonly=>1});

	JE::Object::_init_proto($obj_proto);
	JE::Object::Function::_init_proto($func_proto);


	# The rest of the constructors
	# E 15.1.4
	$self->prop({
		name => 'Array',
		value => JE::Object::Array->new_constructor($self),
		readonly => 1,
		dontenum => 1,
		dontdel  => 1,
	});
	# ~~~ add the rest

	# E 15.1.1
	$self->prop({
		name      => 'NaN',
		value     => JE::Number->new($self, 'NaN'),
		dontenum  => 1,
		dontdel   => 1,
	});
	$self->prop({
		name      => 'Infinity',
		value     => JE::Number->new($self, 'Infinity'),
		dontenum  => 1,
		dontdel   => 1,
	});
	$self->prop({
		name      => 'undefined',
		value     => $self->undefined,
		dontenum  => 1,
		dontdel   => 1,
	});


	# E 15.1.2
	$self->prop({
		name      => 'eval',
		value     => JE::Object::Function->new({
			scope    => $self,
			name     => 'eval',
			length   => 1,
			function_args => [qw< scope args >],
			function => sub {
				my($scope,$code) = @_;
				return $code if not
					UNIVERSAL::isa($code,'JE::String');
				$scope->eval($code);
				# ~~~ Find out what the spec means by
				#     'if the completion value is empty'
				# ~~~ Add exception handling
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'parseInt',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'parseInt', # E 15.1.2.2
			length => 2,
			function_args => [qw< scope args >],
			function => sub {
				# ~~~ implement ToInt32 and
				#     StrWhiteSpaceChar acc. to
				#     spec
				my($scope,$str,$radix) = @_;
				
				($str = $str->to_string) =~ s/^\s//;
				my $sign = $str =~ s/^([+-])//
					? (-1,1)[$1 eq '+']
					:  1;
				$radix ||= $str =~ /^0x/i
				?	16
				:	10
				;
				$radix == 16 and
					$str =~ s/^0x//i;
				
				my @digits = (0..9, 'a'..'z')[0
					..$radix-1];
				my $digits = join '', @digits;
				$str =~ /^([$digits]*)/;
				$str = $1;

				return 'nan' if !length $str;

				if($radix == 10) {
					return $sign * $str;
				}
				elsif($radix == 16) {
					return $sign * hex $str;
				}
				elsif($radix == 8) {
					return $sign * oct $str;
				}
				elsif($radix == 2) {
					return $sign * eval
						"0b$str";
				}
				else { my($num, $place);
				for (reverse split //, $str){
					$num += ($_ =~ /\d/ ? $_
					    : ord(uc) - 55) 
					    * $radix**$place++
				}
				return $num;
				}
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'parseFloat',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'parseFloat', # E 15.1.2.3
			length => 1,
			function_args => [qw< scope args >],
			function => sub {
				# ~~~ implement StrWhiteSpaceChar and
				#     StrDecimalLiteral acc. to
				#     spec
				my($scope,$str,$radix) = @_;
				
				$str =~ s/^\s//;
				
				return $scope->prop('NaN') if !/^\d/;

				return $str+0;
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'isNaN',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'isNaN',
			length => 1,
			function_args => ['args'],
			function => sub {
				shift->to_number eq 'NaN';
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'isFinite',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'isFinite',
			length => 1,
			function_args => ['args'],
			function => sub {
				shift->to_number !~ /[an]/;
				# NaN, Infinity, and -Infinity are the only
				# values with letters in them.
			},
		}),
		dontenum  => 1,
	});

	# E 15.1.3
	# ~~~ Add the rest of the properties from clause 15.1

	$self;
}




=item $j->compile( STRING )

C<compile> parses the code contained in C<STRING> and returns a parse
tree (a JE::Code object).

The JE::Code class provides the method 
C<execute> for executing the 
pre-compiled syntax tree.

=cut

sub compile {
	JE::Code::parse(@_);
}


=item $j->eval ( STRING )

C<eval> evaluates the JavaScript code contained in string. E.g.:

  $j->eval('[1,2,3]') # returns an array ref

If an error occurs, C<undef> will be returned and C<$@> will contain the
error message. If no error occurs, C<$@> will be a null string.

 This is actually just
a wrapper around C<compile> and the C<execute> method of the
C<JE::Code> class.

B<Note:> I'm planning to add an option to return an lvalue (a
JE::LValue object), but I have yet to decide what to call it.

=cut

sub eval {
	my $code = shift->compile(shift);
	$@ and return;

	$code->execute;
}




=item $j->new_function($name, sub { ... })

=item $j->new_function(sub { ... })

This creates and returns a new function written in Perl. If $name is given,
it will become a property of the global object.

For more ways to create functions, see L<JE::Object::Function>.

=cut

# ~~~ sub new_function





=item $j->upgrade( @values )

This method upgrades the value or values given to it. See 
L<JE::Types/UPGRADING VALUES> for more detail.


If you pass it more
than one
argument in scalar context, it returns the number of arguments--but that 
is subject to change, so don't do that.

=cut

sub upgrade { # ~~~ I need to make '0' into a number,  so that, when
              #     used as a bool in JS, it will still be false, as
              #     in Perl. And I still need to make code refs into funcs
	my @__;
	my $self = shift;
	for (@_) {
		push @__,
		  UNIVERSAL::isa($_, 'UNIVERSAL')
		?	$_
		: !defined()
		?	$self->undefined
		: ref($_) eq 'ARRAY'
		?	JE::Object::Array->new($self, $_)
		: ref($_) eq 'HASH'
		?	JE::Object->new($self, %$_)
		:	JE::String->new($self, $_)
		;
	}
	@__ > 1 ? @__ : $__[0];
}


=item $j->undefined

Returns the JavaScript undefined value.

=cut

sub undefined { # ~~~ This needs to be made for emmicient.
	JE::Undefined->new(shift);
}

sub undef { # This was what I originally named it, but it gets confused
            # with Perl's undef too easily (undef and undefined are two
            # different things). Don't use this, because I'm going to
            # delete it once I'm sure that all references to it are
            # obliterated.
	goto &undefined;
}




=item $j->null

Returns the JavaScript null value.

=cut

sub null { # ~~~ This needs to be made more efficient.
	JE::Null->new(shift);
}




#----------------PRIVATE METHODS/SUBS------------------------#

# none (yet [if ever])

1;
__END__


=head1 WHAT STILL NEEDS TO BE FIGURED OUT

=head2 How the Parser Should Work

I have not quite figured
out how the JavaScript parser should work.

I could write a parser that parses the code and 
creates a parse tree. Then the C<execute> subroutine could traverse the
tree, executing code as it goes. The parse tree could contain line number
information that would be used to generate helpful error messages.

But I think if I were to turn the parse tree into a Perl subroutine (at
least for JavaScript functions; perhaps not for code that is run only 
once--when
passed to C<eval>), it
would run a lot faster. The only problem is that I am not sure how to
retain information needed for helpful error messages. I suppose I could put
an C<< eval { ... } or die "${$@} at line <number here>" >> around each
statement. E.g., this function:

  function copy_array(ary) {
          var new_ary = [];
          for(var i = 0; i < ary.length; ++i) {
                  new_ary[i] = ary[i]
          }
          return new_ary
  }

might, without error message support, become

  sub {
          my($scope, $obj) = @_;
          $scope->new_var('new_ary', $scope->new_object('Array'));
          for($scope->new_var('i',0); $scope->var('i') <
              $scope->var('ary')->prop('length'); ++$scope->var('i')) {
                  $scope->var('new_ary')->prop(
                      $scope->var('i'), $scope->var('ary')->prop('i')
                  );
          }
          return $scope->var('new_ary');
  }

With C<eval> blocks, it would become something like:

  sub {
          my($scope, $obj) = @_;
          eval {
                  $scope->new_var('new_ary', JE::Object::Array->new());
          } or die "${$@} on line 2";
          for(eval { $scope->new_var('i',0) or die "${$@} on line 3";
              eval { $scope->var('i') < $scope->var('ary')->prop('length')
                    } or die "${$@} on line 3";
              eval {++$scope->var('i')} or die "${$@} on line 3"
          ) {
              eval {
                  $scope->var('new_ary')->prop(
                      $scope->var('i'), $scope->var('ary')->prop('i')
                  );
              } or die "${$@} on line 4";
          }
          eval { return $scope->var('new_ary'); }
              or die "${$@} on line 6";
  }


But that might slow things down considerably. (The fact that the code is
messy doesn't matter, because it's computer-generated and shouldn't need
to be read by a human.)

Or perhaps I could forget error messages altogether, since someone could
just use Firefox for that instead. :-)  Maybe I could provide the option of
optimising the code, at the expense of simpler and less helpful error
messages. "Slow mode" could be turned on for debugging.

Does anyone have any thoughts?

=head2 Tainting

I need to verify that running tainted JS code will, when
executed, be checked by Perl's taint-checking mechanism. And if
that's not the case, I need to figure out some way of making it
work.

=head2 Garbage Collection and Memory Leaks

I'm not sure how to go about removing circular references. Can anyone help?

=head2 Memoisation

Memoisation might help to speed things up a lot if applied to certain
functions. The C<value> method of JE::String, for instance, which has
to put the
string through the torturous desurrogification process, may benefit
significantly from this.

But then it uses more memory. So maybe we could allow the user to
C<use JE '-memoize'>, which could set the package var $JE::memoise to
true. Then all subsequently require'd JE modules would check that var
when they load.

=head1 PREREQUISITES

perl 5.8.0 or later

The parser uses the officially experimental C<(?{...}}> and C<(??{...})>
constructs in regexen. Considering that they are described the 3rd edition 
of
I<Mastering Regular Expressions> (and are not indicated therein as being
experimental), I don't think they will be going away.

=head1 BUGS

Apart from the fact that there aren't enough features for this module to be 
usable yet, here are some known bugs:

Identifiers in JS source code that contain pairs of Unicode escape 
sequences representing
surrogate pairs are currently not considered equivalent to the same
identifiers with the actual characters instead of escape sequences. For
example, '\ud801\udc00' is not considered the same as "\x{10400}", though
it should be.

The JE::LValue and JE::Scope classes, which have C<AUTOLOAD> subs that 
delegate methods to the objects to which they refer, do not yet implement 
the C<can> method, so if you call $thing->can('to_string') on one of these
you will get a false return value, even though these objects I<can>
C<to_string>.

The documentation is a bit incoherent. It probably needs a rewrite.

=head1 AUTHOR, COPYRIGHT & LICENSE

Copyright (C) 2007 Father Chrysostomos <sprout [at] cpan
[dot] org>

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

All the other C<JE::> modules, esp. C<JE::Object> and C<JE::Types>.

I<ECMAScript Language Specification> (ECMA-262)

=over 4

L<http://www.ecma-international.org/publications/files/ecma-st/ECMA-262.pdf>

=back

=back

C<JavaScript.pm> and C<JavaScript::SpiderMonkey>--both interfaces to
Mozilla's open-source SpiderMonkey JavaScript engine.

=cut


HTML::DOM (still to be written)

WWW::Mechanize::JavaScript (also not written yet; it might not been named
this in the end, either)


