package JE;

# If you are looking at the source code (which you are obviously doing
# if you are reading this),  note that  '# ~~~'  is my way of  marking
# something to be done still (except in this sentence).

# Note also that comments like "# E 7.1" refer to the indicated
# clause (7.1 in this case) in the ECMA-262 standard.

use 5.008;
use strict;
use warnings;

our $VERSION = '0.019';

use Carp 'croak';
use Encode qw< decode_utf8 encode_utf8 FB_CROAK >;
use JE::Code 'add_line_number';
use JE::_FieldHash;
use Scalar::Util 1.08 qw'blessed refaddr weaken';

our @ISA = 'JE::Object';

require JE::Null     ;
require JE::Number     ;
require JE::Object      ;
require JE::Object::Function;
require JE::Parser                             ;
require JE::Scope                             ;
require JE::String                          ;
require JE::Undefined                     ;

=head1 NAME

JE - Pure-Perl ECMAScript (JavaScript) Engine

=head1 VERSION

Version 0.019 (alpha release)

The API is still subject to change. If you have the time and the interest, 
please experiment with this module (or even lend a hand :-).
If you have any ideas for the API, or would like to help with development,
please e-mail the author.

=head1 SYNOPSIS

  use JE;

  $j = new JE; # create a new global object

  $j->eval('({"this": "that", "the": "other"}["this"])');
  # returns "that"

  $parsed = $j->parse('new Array(1,2,3)');
 
  $rv = $parsed->execute; # returns a JE::Object::Array
  $rv->value;             # returns a Perl array ref

  $obj = $j->eval('new Object');
  # create a new object

  $foo = $j->{document}; # get property
  $j->{document} = $obj; # set property
  $j->{document} = {};   # gets converted to a JE::Object
  $j->{document}{location}{href}; # autovivification

  $j->method(alert => "text"); # invoke a method


  # create global function from a Perl subroutine:
  $j->new_function(print => sub { print @_, "\n" } );

  $j->eval(<<'--end--');
          function correct(s) {
                  s = s.replace(/[EA]/g, function(s){
                          return ['E','A'][+(s=='E')]
                  })
                  return s.charAt(0) +
                         s.substring(1,4).toLowerCase() +
                         s.substring(4)
          }
          print(correct("ECMAScript")) // :-)
  --end--

=head1 DESCRIPTION

JE is a pure-Perl JavaScript engine. Here are some of its
strengths:

=over 4

=item -

Easy to install (no C compiler necessary*)

=item -

Compatible with L<Data::Dump::Streamer>, so the runtime environment
can be serialised

=item -

The parser can be extended/customised to support extra (or
fewer) language features (not yet complete)

=item -

All JavaScript datatypes can be manipulated directly from Perl (they all
have overloaded operators)

=back

JE's greatest weakness is that it's slow (well, what did you expect?). It
also uses and leaks lots of memory, but that will be fixed.

* If you are using perl 5.9.3 or lower, then L<Tie::RefHash::Weak> is
required. Recent versions of it require L<Variable::Magic>, an XS module
(which requires a compiler of course), but version 0.02 of the former is
just pure Perl with no XS dependencies.

=head1 USAGE

=head2 Simple Use

If you simply need to run a few JS functions from Perl, create a new JS
environment like this:

  my $je = new JE;

If necessary, make Perl subroutines available to JavaScript:

  $je->new_function(warn => sub { warn @_ });
  $je->new_function(ok => \&Test::More::ok);

Then pass the JavaScript functions to C<eval>:

  $je->eval(<<'___');

  function foo() {
      return 42
  }
  // etc.
  ___

  # or perhaps:
  use File::Slurp;
  $je->eval(scalar read_file 'functions.js');

Then you can access those function from Perl like this:

  $return_val = $je->{foo}->();
  $return_val = $je->eval('foo()');

The return value will be a special object that, when converted to a string,
boolean or number, will behave exactly as in JavaScript. You can also use
it as a hash, to access or modify its properties. (Array objects can be
used as arrays, too.) To call one of its
JS methods, you should use the C<method> method:
C<$return_val->method('foo')>. See L<JE::Types> for more information.

=head2 Custom Global Objects

To create a custom global object, you have to subclass JE. For instance,
if all you need to do is add a C<self> property that refers to the global
object, then override the C<new> method like this:

  package JEx::WithSelf;
  @ISA = 'JE';
  sub new {
      my $self = shift->SUPER::new(@_);
      $self->{self} = $self;
      return $self;
  }

=head2 Using Perl Objects from JS

See C<bind_class>, below.

=head2 Writing Custom Data Types

See L<JE::Types>.

=head1 METHODS

See also L<< C<JE::Object> >>, which this
class inherits from, and L<< C<JE::Types> >>.

=over 4

=item $j = JE->new

This class method constructs and returns a new JavaScript environment, the
JE object itself being the global object.

=cut

our $s = qr.[\p{Zs}\s\ck]*.;

sub new {
	my $class = shift;

	# I can't use the usual object and function constructors, since
	# they both rely on the existence of  the global object and its
	# 'Object' and 'Function' properties.

	if(ref $class) {
		croak "JE->new is a class method and cannot be called " .
			"on a" . ('n' x ref($class) =~ /^[aoeui]/i) . ' ' .
			 ref($class). " object."
	}

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
					return JE::Object->new( @_ );
				},
				constructor_args => ['scope','args'],
				constructor => sub {
					return JE::Object->new( @_ );
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
				func_argnames => [],
				func_args => ['scope','args'],
				function => sub { # E 15.3.1
					JE::Object::Function->new(
						$${$_[0][0]}{global},
						@_[1..$#_]
					);
				},
				constructor_args => ['scope','args'],
				constructor => sub {
					JE::Object::Function->new(
						$${$_[0][0]}{global},
						@_[1..$#_]
					);
				},
				keys => [],
				props => {
					#length => JE::Number->new(1),
					prototype => bless(\{
						#prototype=>(Object.proto)
						#global => ...
						func_argnames => [],
						func_args => [],
						function => '',
						keys => [],
						props => {},
					}, 'JE::Object::Function')
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

	$obj_constr ->prop({name=>'length', value=>1});
	$func_constr->prop({name=>'length', value=>1});
	$func_proto->prop({name=>'length', value=>0});

	JE::Object::_init_proto($obj_proto);
	JE::Object::Function::_init_proto($func_proto);


	# The rest of the constructors
	# E 15.1.4
	$self->prop({
		name => 'Array',
		autoload =>
			'require JE::Object::Array;
			 JE::Object::Array->new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'String',
		autoload =>
			'require JE::Object::String;
			JE::Object::String::_new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'Boolean',
		autoload =>
		    'require JE::Object::Boolean;
		    JE::Object::Boolean::_new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'Number',
		autoload =>
			'require JE::Object::Number;
			JE::Object::Number::_new_constructor($global)',
		dontenum => 1,
	});
	# ~~~ Date
	$self->prop({
		name => 'RegExp',
		autoload => 
			'require JE::Object::RegExp;
			 JE::Object::RegExp->new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'Error',
		autoload =>
			'require JE::Object::Error;
			 JE::Object::Error->new_constructor($global)',
		dontenum => 1,
	});
	# No EvalError
	$self->prop({
		name => 'RangeError',
		autoload => 'require JE::Object::Error::RangeError;
		             JE::Object::Error::RangeError
		              ->new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'ReferenceError',
		autoload => 'require JE::Object::Error::ReferenceError;
		             JE::Object::Error::ReferenceError
		              ->new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'SyntaxError',
		autoload => 'require JE::Object::Error::SyntaxError;
		             JE::Object::Error::SyntaxError
		              ->new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'TypeError',
		autoload => 'require JE::Object::Error::TypeError;
		             JE::Object::Error::TypeError
		              ->new_constructor($global)',
		dontenum => 1,
	});
	$self->prop({
		name => 'URIError',
		autoload => 'require JE::Object::Error::URIError;
		             JE::Object::Error::URIError
		              ->new_constructor($global)',
		dontenum => 1,
	});

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
			argnames => ['x'],
			function_args => [qw< args >],
			function => sub {
				my($code) = @_;
				return $self->undefined unless defined
					$code;
				return $code if typeof $code ne 'string';
				my $old_at = $@; # hope it's not tied
				defined (my $tree = 
					($JE::Code::parser||$self)
					->parse($code))
					or die;
				my $ret = execute $tree
					$JE::Code::this,
					$JE::Code::scope, 1;

				ref $@ ne '' and die;
				
				$@ = $old_at;
				$ret;
			},
			no_proto => 1,
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'parseInt',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'parseInt', # E 15.1.2.2
			argnames => [qw/string radix/],
			no_proto => 1,
			function_args => [qw< scope args >],
			function => sub {
				# ~~~ implement ToInt32 and
				#     StrWhiteSpaceChar acc. to
				#     spec
				my($scope,$str,$radix) = @_;
				
				($str = $str->to_string) =~ s/^$s//;
				my $sign = $str =~ s/^([+-])//
					? (-1,1)[$1 eq '+']
					:  1;
				$radix = (int $radix) % 2 ** 32;
				$radix -= 2**32 if $radix >= 2**31;
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
					$num += ($_ =~ /[0-9]/ ? $_
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
			argnames => [qw/string/],
			no_proto => 1,
			function_args => [qw< scope args >],
			function => sub {
				# ~~~ implement StrWhiteSpaceChar and
				#     StrDecimalLiteral acc. to
				#     spec
				my($scope,$str,$radix) = @_;
				
				return JE::Number->new($self, $str =~
					/^$s
					  (?:
					    [+-]?
					    (?:
					      (?=[0-9]|\.[0-9]) [0-9]*
					      (?:\.[0-9]*)?
					      (?:[Ee][+-]?[0-9]+)?
					        |
					      Infinity
					    )
					  )
					/ox
					?  $str : 'nan');
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'isNaN',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'isNaN',
			argnames => [qw/number/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				shift->to_number->id eq 'num:nan';
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'isFinite',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'isFinite',
			argnames => [qw/number/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				shift->to_number->value !~ /n/;
				# NaN, Infinity, and -Infinity are the only
				# values with the letter 'n' in them.
				# ~~~ Does this work with Windoze and
				#     ClosedBSD?
			},
		}),
		dontenum  => 1,
	});

	# E 15.1.3
	$self->prop({
		name  => 'decodeURI',
		value => JE::Object::Function->new({
		    scope  => $self,
		    name   => 'decodeURI',
		    argnames => [qw/encodedURI/],
		    no_proto => 1,
		    function_args => ['args'],
		    function => sub {
		        my $str = shift->to_string->value;
		        $str =~ /%(?![a-fA-F0-9]{2})(.{0,2})/
		         and require JE::Object::Error::URIError,
		             die
		        	JE::Object::Error::URIError->new(
		        		$self,
		        		add_line_number
						"Invalid escape %$1 in URI"
		        	);

		        $str = encode_utf8 $str;

		        # [;/?:@&=+$,#] do not get unescaped
		        $str =~ s/%(?!2[346bcf]|3[abdf]|40)
		        	([0-9a-f]{2})/chr hex $1/iegx;
		        
		        local $@;
		        eval {
		        	$str = decode_utf8 $str, FB_CROAK;
		        };
		        if ($@) {
		        	require JE'Object'Error'URIError;
		        	die JE::Object::Error::URIError
		        	->new(
		        		$self,
		        		add_line_number
						'Malformed UTF-8 in URI'
		        	);
		        }
		        
		        $str =~
		             /^[\0-\x{d7ff}\x{e000}-\x{10ffff}]*\z/
		        or require JE::Object::Error::URIError,
		           die JE::Object::Error::URIError->new(
		        	$self, add_line_number
					'Malformed UTF-8 in URI');

		        JE::String->new($self, $str);
		    },
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'decodeURIComponent',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'decodeURIComponent',
			argnames => [qw/encodedURIComponent/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $str = shift->to_string->value;
				$str =~ /%(?![a-fA-F0-9]{2})(.{0,2})/
				 and require JE::Object::Error::URIError,
				     die
					JE::Object::Error::URIError->new(
						$self,
						add_line_number
						"Invalid escape %$1 in URI"
					);

				$str = encode_utf8 $str;

				$str =~ s/%([0-9a-f]{2})/chr hex $1/iegx;
				
				local $@;
				eval {
					$str = decode_utf8 $str, FB_CROAK;
				};
				if ($@) {
					require JE::Object::Error'URIError;
					die JE::Object::Error::URIError
					->new(
						$self, add_line_number
						'Malformed UTF-8 in URI'
					);
				}
				
				$str =~
				     /^[\0-\x{d7ff}\x{e000}-\x{10ffff}]*\z/
				or require JE::Object::Error::URIError,
				   die JE::Object::Error::URIError->new(
					$self, add_line_number
					'Malformed UTF-8 in URI');

				JE::String->new($self, $str);
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'encodeURI',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'encodeURI',
			argnames => [qw/uri/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $str = shift->to_string->value;
				$str =~ /(\p{Cs})/ and
require JE::Object::Error::URIError,
die JE::Object::Error::URIError->new($self, 
	add_line_number sprintf "Unpaired surrogate 0x%x in string", ord $1
);

				$str = encode_utf8 $str;

				$str =~
				s< ([^;/?:@&=+$,A-Za-z0-9\-_.!~*'()#]) >
				 < sprintf '%%%02x', ord $1           >egx;
				
				JE::String->new($self, $str);
			},
		}),
		dontenum  => 1,
	});
	$self->prop({
		name  => 'encodeURIComponent',
		value => JE::Object::Function->new({
			scope  => $self,
			name   => 'encodeURIComponent',
			argnames => [qw/uriComponent/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $str = shift->to_string->value;
				$str =~ /(\p{Cs})/ and
require JE::Object::Error::URIError,
die JE::Object::Error::URIError->new(
 $self, add_line_number sprintf "Unpaired surrogate 0x%x in string", ord $1
);

				$str = encode_utf8 $str;

				$str =~ s< ([^A-Za-z0-9\-_.!~*'()])  >
				         < sprintf '%%%02x', ord $1 >egx;
				
				JE::String->new($self, $str);
			},
		}),
		dontenum  => 1,
	});

	# E 15.1.5 / 15.8
	$self->prop({
		name  => 'Math',
		autoload => 'require JE::Object::Math;
		             JE::Object::Math->new($global)',
		dontenum  => 1,
	});

	$self;
}




=item $j->parse( $code, $filename, $first_line_no )

C<parse> parses the code contained in C<$code> and returns a parse
tree (a JE::Code object).

If the syntax is not valid, C<undef> will be returned and C<$@> will 
contain an
error message. Otherwise C<$@> will be a null string.

The JE::Code class provides the method 
C<execute> for executing the 
pre-compiled syntax tree.

C<$filename> and C<$first_line_no>, which are both optional, will be stored
inside the JE::Code object and used for JS error messages. (See also
L<add_line_number|JE::Code/FUNCTIONS> in the JE::Code man page.)

=item $j->compile( STRING )

Just an alias for C<parse>.

=cut

sub parse {
	goto &JE::Code::parse;
}
*compile = \&parse;


=item $j->eval( $code, $filename, $lineno )

C<eval> evaluates the JavaScript code contained in C<$code>. E.g.:

  $j->eval('[1,2,3]') # returns a JE::Object::Array which can be used as
                      # an array ref

If C<$filename> and C<$lineno> are specified, they will be used in error
messages. C<$lineno> is the number of the first line; it defaults to 1.

If an error occurs, C<undef> will be returned and C<$@> will contain the
error message. If no error occurs, C<$@> will be a null string.

This is actually just
a wrapper around C<parse> and the C<execute> method of the
JE::Code class.

If the JavaScript code evaluates to an lvalue, a JE::LValue object will be
returned. You can use this like any other return value (e.g., as an array
ref if it points to a JS array). In addition, you can use the C<set> and
C<get> methods to set/get the value of the property to which the lvalue
refers. (See also L<JE::LValue>.) E.g., this will create a new object
named C<document>:

  $j->eval('this.document')->set({});

Note that I used C<this.document> rather than just C<document>, since the
latter would throw an error if the variable did not exist.

=cut

sub eval {
	my $code = shift->parse(@_);
	$@ and return;

	$code->execute;
}




=item $j->new_function($name, sub { ... })

=item $j->new_function(sub { ... })

This creates and returns a new function object. If $name is given,
it will become a property of the global object.

Use this to make a Perl subroutine accessible from JavaScript.

For more ways to create functions, see L<JE::Object::Function>.

This is actually a method of JE::Object, so you can use it on any object:

  $j->prop('Math')->new_function(double => sub { 2 * shift });


=item $j->new_method($name, sub { ... })

This is just like C<new_function>, except that, when the function is
called, the subroutine's first argument (number 0) will be the object
with which the function is called. E.g.:

  $j->eval('String.prototype')->new_method(
          reverse => sub { scalar reverse shift }
  );
  # ... then later ...
  $j->eval(q[ 'a string'.reverse() ]); # returns 'gnirts a'


=item $j->upgrade( @values )

This method upgrades the value or values given to it. See 
L<JE::Types/UPGRADING VALUES> for more detail.


If you pass it more
than one
argument in scalar context, it returns the number of arguments--but that 
is subject to change, so don't do that.

=cut

sub upgrade {
	my @__;
	my $self = shift;
	my($classes,$proxy_cache);
	for (@_) {
		if (defined blessed $_) {
			$classes or ($classes,$proxy_cache) =
				@$$self{'classes','proxy_cache'};
			my $ident = refaddr $_;
			my $class = ref;
			push @__, exists $$classes{$class}
			    ? exists $$proxy_cache{$ident}
			        ? $$proxy_cache{$ident}
			        : ($$proxy_cache{$ident} =
			            exists $$classes{$class}{wrapper}
			                ? $$classes{$class}{wrapper}->(
			                    $self,$_)
			                : JE::Object::Proxy->new($self,$_)
			           )
			    : $_;
		} else {
			push @__,
			  !defined()
			?	$self->undefined
			: ref($_) eq 'ARRAY'
			?	JE::Object::Array->new($self, $_)
			: ref($_) eq 'HASH'
			?	JE::Object->new($self, { value => $_ })
			: ref($_) eq 'CODE'
			?	JE::Object::Function->new($self, $_)
			: $_ eq '0' || $_ eq '-0'
			?	JE::Number->new($self, 0)
			:	JE::String->new($self, $_)
			;
		}
	}
	@__ > 1 ? @__ : @__ == 1 ? $__[0] : ();
}

sub _upgr_def {
# ~~~ maybe I should make this a public method named upgrade_defined
	return defined $_[1] ? shift->upgrade(shift) : undef
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
            # delete it.
	goto &undefined;
}




=item $j->null

Returns the JavaScript null value.

=cut

sub null { # ~~~ This needs to be made more efficient.
	JE::Null->new(shift);
}



=item $j->bind_class( LIST )

=head2 Synopsis

 $j->bind_class(
     package => 'Net::FTP',
     name    => 'FTP', # if different from package
     constructor => 'new', # or sub { Net::FTP->new(@_) }

     methods => [ 'login','get','put' ],
     # OR:
     methods => {
         log_me_in => 'login', # or sub { shift->login(@_) }
         chicken_out => 'quit',
     }
     static_methods => {
         # etc. etc. etc.
     }
     to_primitive => \&to_primitive # or a method name
     to_number    => \&to_number
     to_string    => \&to_string

     props => [ 'status' ],
     # OR:
     props => {
         status => {
             fetch => sub { 'this var never changes' }
             store => sub { system 'say -vHysterical hah hah' }
         },
         # OR:
         status => \&fetch_store # or method name
     },
     static_props => { ... }

     hash  => 1, # Perl obj can be used as a hash
     array => 1, # or as an array
     # OR (not yet implemented):
     hash  => 'namedItem', # method name or code ref
     array => 'item',       # likewise
     # OR (not yet implemented):
     hash => {
         fetch => 'namedItem',
         store => sub { shift->{+shift} = shift },
     },
     array => {
         fetch => 'item',
         store => sub { shift->[shift] = shift },
     },

     isa => 'Object',
     # OR:
     isa => $j->{Object}{prototype},
 );
 
 # OR:
 
 $j->bind_class(
     package => 'Net::FTP',
     wrapper => sub { new JE_Proxy_for_Net_FTP @_ }
 );


=head2 Description

(Some of this is random order, and probably needs to be rearranged.)

This method binds a Perl class to JavaScript. LIST is a hash-style list of 
key/value pairs. The keys, listed below, are all optional except for 
C<package> or
C<name>--you must specify at least one of the two.

Whenever it says you can pass a method name to a particular option, and
that method is expected to return a value (i.e., this does not apply to
C<< props => { property_name => { store => 'method' } } >>), you may append
a colon and a data type (such as ':String') to the method name, to indicate
to what JavaScript type to convert the return value. Actually, this is the
name of a JS function to which the return value will be passed, so 'String'
has to be capitalised. This also means than you can use 'method:eval' to
evaluate the return value of 'method' as JavaScript code. One exception to
this is that the special string ':null' indicates that Perl's C<undef>
should become JS's C<null>, but other values will be converted the default
way. This is useful, for instance, if a method should return an object or
C<null>, from JavaScript's point of view. This ':' feature does not stop
you from using double colons in method names, so you can write
C<'Package::method:null'> if you like, and rest assured that it will split
on the last colon. Furthermore, just C<'Package::method'> will also work.
It won't split it at all.

=over 4

=item package

The name of the Perl class. If this is omitted, C<name> will be used
instead.

=item name

The name the class will have in JavaScript. This is used by
C<Object.prototype.toString> and as the name of the constructor. If 
omitted, C<package> will be used.

=item constructor => 'method_name'

=item constructor => sub { ... }

If C<constructor> is given a string, the constructor will treat it as the
name of a class method of C<package>.

If it is a coderef, it will be used as the constructor.

If this is omitted, no constructor will be made.

=item methods => [ ... ]

=item methods => { ... }

If an array ref is supplied, the named methods will be bound to JavaScript
functions of the same names.

If a hash ref is used, the keys will be the
names of the methods from JavaScript's point of view. The values can be
either the names of the Perl methods, or code references.

=item static_methods

Like C<methods> but they will become methods of the constructor itself, not
of its C<prototype> property.

=item to_primitive => sub { ... }

=item to_primitive => 'method_name'

When the object is converted to a primitive value in JavaScript, this
coderef or method will be called. The first argument passed will, of
course, be the object. The second argument will be the hint ('number' or
'string') or will be omitted.

If to_primitive is omitted, the usual valueOf and
toString methods will be tried as with built-in JS
objects, if the object does not have overloaded string/boolean/number
conversions. If the object has even one of those three, then conversion to
a primitive will be the same as in Perl.

If C<< to_primitive => undef >> is specified, primitivisation
without a hint (which happens with C<< < >> and C<==>) will throw a 
TypeError.

=item to_number

If this is omitted, C<to_primitive($obj, 'number')> will be
used.
If set to undef, a TypeError will be thrown whenever the
object is numified.

=item to_string

If this is omitted, C<to_primitive($obj, 'string')> will be
used.
If set to undef, a TypeError will be thrown whenever the
object is strung.

=item props => [ ... ]

=item props => { ... }

Use this to add properties that will trigger the provided methods or
subroutines when accessed. These property definitions can also be inherited
by subclasses, as long as, when the subclass is registered with 
C<bind_class>, the superclass is specified as a string (via C<isa>, below).

If this is an array ref, its elements will be the names of the properties.
When a property is retrieved, a method of the same name is called. When a
property is set, the same method is called, with the new value as the
argument.

If a hash ref is given, for each element, if the value is a simple scalar,
the property named by the key will trigger the method named by the value.
If the value is a coderef, it will be called with the object as its
argument when the variable is read, and with the object and
the new
value as its two arguments when the variable is set.
If the value is a hash ref, the C<fetch> and C<store> keys will be
expected to be either coderefs or method names. If only C<fetch> is given,
the property will be read-only. If only C<store> is given, the property 
will
be write-only and will appear undefined when accessed. (If neither is 
given,
it will be a read-only undefined property--really useful.)

=item static_props

Like C<props> but they will become properties of the constructor itself, 
not
of its C<prototype> property.

=item hash

If this option is present, then this indicates that the Perl object 
can be used
as a hash. An attempt to access a property not defined by C<props> or
C<methods> will result in the retrieval of a hash element instead (unless
the property name is a number and C<array> is specified as well).

=begin comment

There are several values this option can take:

 =over 4

 =item *

One of the strings '1-way' and '2-way' (also 1 and 2 for short). This will
indicate that the object being wrapped can itself be used as a hash.

=end comment

The value you give this option should be one of the strings '1-way' and
'2-way' (also 1 and 2 for short).

If
you specify '1-way', only properties corresponding to existing hash 
elements will be linked to those elements;
properties added to the object from JavaScript will
be JavaScript's own, and will not affect the wrapped object. (Consider how
node lists and collections work in web browsers.)

If you specify '2-way', an attempt to create a property in JavaScript will
be reflected in the underlying object.

=begin comment

=item *

A method name (that does not begin with a number). This method will be
called on the object with the object as the first arg (C<$_[0]>), the
property name as the second, and, if an assignment is being made, the new
value as the third. This will be a one-way hash.

=item *

A reference to a subroutine. This sub will be called with the same
arguments as a method. Again, this will be a one-way hash.

=item *

A hash with C<store> and C<fetch> keys, which should be set to method names
or coderefs. Actually, you may omit C<store> to create a one-way binding,
as per '1-way', above, except that the properties that correspond to hash
keys will be read-only as well.

 =back

=end comment

B<To do:> Make this accept '1-way:String', etc.

=item array

This is just like C<hash>, but for arrays. This will also create a property
named 'length'.

=for comment
if passed '1-way' or '2-way'.

B<To do:> Make this accept '1-way:String', etc.

=begin comment

=item keys

This should be a method name or coderef that takes the object as its first 
argument and
returns a list of hash keys. This only applies if C<hash> is specified
and passed a method name, coderef, or hash.

=end comment

=item isa => 'ClassName'

=item isa => $prototype_object

(Maybe this should be renamed 'super'.)

The name of the superclass. 'Object' is the default. To make this new
class's prototype object have no prototype, specify
C<undef>. Instead of specifying the name of the superclass, you 
can
provide the superclass's prototype object.

If you specify a name, a constructor function by that name must already
exist, or an exception will be thrown. (I supposed I could make JE smart
enough to defer retrieving the prototype object until the superclass is
registered. Well, maybe later.)

=item wrapper => sub { ... }

If C<wrapper> is specified, all other arguments will be ignored except for
C<package> (or C<name> if C<package> is not present).

When an object of the Perl class in question is 'upgraded,' this subroutine
will be called with the global object as its first argument and the object
to be 'wrapped' as the second. The subroutine is expected to return
an object compatible with the interface described in L<JE::Types>.

If C<wrapper> is supplied, no constructor will be created.

=back

After binding a class, objects of the Perl class will, when passed
to JavaScript (or the C<upgrade> method), appear as instances of the
corresponding JS class. Actually, they are 'wrapped up' in a proxy object 
(a JE::Object::Proxy 
object), such that operators like C<typeof> and C<===> will work. If the 
object is passed back to Perl, it is the I<proxy,>
not the original object that is returned. The proxy's C<value> method will
return the original object. B<Note:> I might change this slightly so that
objects passed to JS functions created by C<bind_class> will be unwrapped.
I still trying to figure out what the exact behaviour should be.

Note that, if you pass a Perl object to JavaScript before binding its 
class,
JavaScript's reference to it (if any) will remain as it is, and will not be
wrapped up inside a proxy object.

If C<constructor> is
not given, a constructor function will be made that throws an error when
invoked, unless C<wrapper> is given.

To use Perl's overloading within JavaScript, well...er, you don't have to
do
anything. If the object has C<"">, C<0+> or C<bool> overloading, that will
automatically be detected and used.

=cut

sub _split_meth { $_[0] =~ /(.*[^:]):([^:].*)/s ? ($1, $2) : $_[0] }
# This function splits a method specification  of  the  form  'method:Func'
# into its two constituent parts, returning ($_[0],undef) if it is a simple
# method name.  The  [^:]  parts of the regexp are  to  allow  things  like
# "HTML::Element::new:null"  and to prevent  "Foo::bar"  from being turned
# into qw(Foo: bar).

sub _cast {
	my ($self,$val,$type) = @_;
	return $self->upgrade($val) unless defined $type;
	if($type eq 'null') {
		defined $val ? $self->upgrade($val) : $self->null
	}
	else {
		$self->prop($type)->call($self->upgrade($val));
	}
}

sub bind_class {
	require JE::Object::Proxy;

	my $self = shift;
	my %opts = @_;

	# &upgrade relies on this, because it
	# takes the value of  ->{proxy_cache},
	# sticks it in a scalar, then modifies
	# it through that scalar.
	$$$self{proxy_cache} ||= &fieldhash({}); # & to bypass prototyping

	if(exists $opts{wrapper}) { # special case
		my $pack = $opts{qw/name package/[exists $opts{package}]};
		$$$self{classes}{$pack} = {wrapper => $opts{wrapper}};
		return;
	}

	my($pack, $class);
	if(exists $opts{package}) {
		$pack = "$opts{package}";
		$class = exists $opts{name} ? $opts{name} : $pack;
	}
	else {
		$class = $opts{name};
		$pack = "$class";
	}
		
	my %class = ( name => $class );
	$$$self{classes}{$pack} = $$$self{classes_by_name}{$class} =
		\%class;

	my ($constructor,$proto,$coderef);
	if (exists $opts{constructor}) {
		my $c = $opts{constructor};

		$coderef = ref eq 'CODE'
			? sub { $self->upgrade(scalar &$c()) }
			: sub { $self->upgrade(scalar $pack->$c) };
	}
	else {
		$coderef = sub {
			die JE::Code::add_line_number(
				"$class cannot be instantiated");
		 };
	}
	$class{prototype} = $proto = $self->prop({
		name => $class,
		value => $constructor = JE::Object::Function->new({
			name => $class,
			scope => $self,
			function => $coderef,
			function_args => [],
			constructor => $coderef,
			constructor_args => [],
		}),
	})->prop('prototype');

	my $super;
	if(exists $opts{isa}) {
		my $isa = $opts{isa};
		$proto->prototype(
		    !defined $isa || defined blessed $isa
		      ? $isa
		      : do {
		        $super = $isa;
		        defined(my $super_constr = $self->prop($isa)) ||
			  croak("JE::bind_class: The $isa" .
		                " constructor does not exist");
		        $super_constr->prop('prototype')
		      }
		);
	}

	if(exists $opts{methods}) {
		my $methods = $opts{methods};
		if (ref $methods eq 'ARRAY') { for (@$methods) {
			my($m, $type) = _split_meth $_;
			if (defined $type) {
				$proto->new_method(
					$m => sub {
					  $self->_cast(
					    scalar shift->value->$m(@_),
					    $type
					  );
					}
				);
			}else {
				$proto->new_method(
					$m => sub { shift->value->$m(@_) },
				);
			}
		}} else { # it'd better be a hash!
		while( my($name, $m) = each %$methods) {
			if(ref $m eq 'CODE') {
				$proto->new_method(
					$name => sub {
					    &$m($_[0]->value,@_[1..$#_])
					  }
				);
			} else {
				my ($method, $type) = _split_meth $m;
				$proto->new_method(
				  $name => defined $type
				    ? sub {
				      $self->_cast(
				        scalar shift->value->$method(@_),
				        $type
				      );
				    }
				    : sub { shift->value->$m(@_) },
				);
			}
		}}
	}

	if(exists $opts{static_methods}) {
		my $methods = $opts{static_methods};
		if (ref $methods eq 'ARRAY') { for (@$methods) {
			my($m, $type) = _split_meth $_;
			$constructor->new_function(
				$m => defined $type
					? sub { $self->_cast(
						scalar $pack->$m(@_), $type
					) }
					: sub { $pack->$m(@_) }
			);
			 # new_function makes the functions  enumerable,
			 # unlike new_method. This code is here to make
			 # things consistent. I'll delete it if someone
			 # convinces me otherwise. (I can't make
			 # up my mind.)
			$constructor->prop({
				name => $m, dontenum => 1
			});
		}} else { # it'd better be a hash!
		while( my($name, $m) = each %$methods) {
			if(ref $m eq 'CODE') {
				$constructor->new_function(
					$name => sub {
					    unshift @_, $pack;
					    goto $m;
					}
				);
			} else {
				($m, my $type) = _split_meth $m;
				$constructor->new_function(
					$name => defined $type
						? sub { $self->_cast(
							scalar $pack->$m,
							$type
						) }
						: sub { $pack->$m(@_) },
				);
			}
			 # new_function makes the functions  enumerable,
			 # unlike new_method. This code is here to make
			 # things consistent. I'll delete it if someone
			 # convinces me otherwise. (I can't make
			 # up my mind.)
			$constructor->prop({
				name => $name, dontenum => 1
			});
		}}
	}

	for(qw/to_primitive to_string to_number/) {
		exists $opts{$_} and $class{$_} = $opts{$_}
	}

	# The properties enumerated by the 'props' option need to be made
	# instance properties, since assignment never falls through to the
	# prototype,  and a fetch routine is passed the property's  actual
	# owner;  i.e., the prototype, if it is an inherited property.  So
	# we'll make a list of argument lists which &JE::Object::Proxy::new
	# will take care of passing to each object's prop method.
	{ my %props;
	if(exists $opts{props}) {
		my $props = $opts{props};
		$class{props} = \%props;
		if (ref $props eq 'ARRAY') {
		    for(@$props) {
			my ($p,$type) = _split_meth $_;
			$props{$p} = [
				fetch => defined $type
				  ? sub {
				    $self->_cast(
				      scalar $_[0]->value->$p, $type
				    )
				  }
				  : sub {
				    $self->upgrade(scalar $_[0]->value->$p)
				  },
				store => sub { $_[0]->value->$p($_[1]) },
			];
		    }
		} else { # it'd better be a hash!
		while( my($name, $p) = each %$props) {
			my @prop_args;
			if (ref $p eq 'HASH') {
				if(exists $$p{fetch}) {
				    my $fetch = $$p{fetch};
				    @prop_args = ( fetch =>
				        ref $fetch eq 'CODE'
				        ? sub { $self->upgrade(
				            scalar &$fetch($_[0]->value)
				        ) }
				        : do {
					  my($f,$t) = _split_meth $fetch;
					  defined $t ? sub { $self->_cast(
				            scalar shift->value->$f, $t
				          ) }
				          : sub { $self->upgrade(
				              scalar shift->value->$fetch
				          ) }
				        }
				    );
				}
				else { @prop_args =
					(value => $self->undefined);
				}
				if(exists $$p{store}) {
				    my $store = $$p{store};
				    push @prop_args, ( store =>
				        ref $store eq 'CODE'
				        ? sub {
				            &$store($_[0]->value, $_[1])
				        }
				        : sub {
				            $_[0]->value->$store($_[1])
				        }
				    );
				}
				else {
					push @prop_args, readonly => 1;
				}
			}
			else {
				if(ref $p eq 'CODE') {
					@prop_args = (
					    fetch => sub { $self->upgrade(
				                scalar &$p($_[0]->value)
				            ) },
					    store => sub {
				              &$p(
					        scalar $_[0]->value, $_[1]
					      )
				            },
					);
				}else{
					($p, my $t) = _split_meth($p);
					@prop_args = (
					    fetch => defined $t
					    ? sub { $self->_cast(
				                scalar $_[0]->value->$p, $t
				              ) }
					    : sub { $self->upgrade(
				                scalar $_[0]->value->$p
				              ) },
					    store => sub {
				                $_[0]->value->$p($_[1])
				            },
					);
				}
			}
			$props{$name} = \@prop_args;
		}}
	}
	if(defined $super){
		$class{props} ||= \%props;
		{
			my $super_props =
				$$$self{classes_by_name}{$super}{props}
				|| last;
			for (keys %$super_props) {
				exists $props{$_} or
					$props{$_} = $$super_props{$_}
			}
		}
	}}

	if(exists $opts{static_props}) {
		my $props = $opts{static_props};
		if (ref $props eq 'ARRAY') { for (@$props) {
			my($p,$t) = _split_meth $_;
			$constructor->prop({
				name => $p,
				fetch => defined $t
				  ? sub { $self->_cast(
				      scalar $pack->$p, $t
				    ) }
				  : sub { $self->upgrade(
				      scalar $pack->$p
				    ) },
				store => sub { $pack->$p($_[1]) },
			});
		}} else { # it'd better be a hash!
		while( my($name, $p) = each %$props) {
			my @prop_args;
			if (ref $p eq 'HASH') {
				if(exists $$p{fetch}) {
				    my $fetch = $$p{fetch};
				    @prop_args = ( fetch =>
				        ref $fetch eq 'CODE'
				        ? sub {
				            $self->upgrade(
					        scalar &$fetch($pack))
				        }
				        : do {
				            my($f,$t) = _split_meth $fetch;
				            defined $t ? sub {
				              $self->_cast(
				                scalar $pack->$f,$t)
				            }
				            : sub {
				              $self->upgrade(
				                scalar $pack->$f)
				            }
				        }
				    );
				}
				else { @prop_args =
					(value => $self->undefined);
				}
				if(exists $$p{store}) {
				    my $store = $$p{store};
				    push @prop_args, ( store =>
				        ref $store eq 'CODE'
				        ? sub {
				            &$store($pack, $_[1])
				        }
				        : sub {
				            $pack->$store($_[1])
				        }
				    );
				}
				else {
					push @prop_args, readonly => 1;
				}
			}
			else {
				if(ref $p eq 'CODE') {
					@prop_args = (
					    fetch => sub {
				                $self->upgrade(
					          scalar &$p($pack))
				            },
					    store => sub {
				                &$p($pack, $_[1])
				            },
					);
				} else {
					($p, my $t) = _split_meth $p;
					@prop_args = (
					    fetch => defined $t
					    ? sub {
				                $self->_cast(
					          scalar $pack->$p,$t)
				              }
					    : sub {
				                $self->upgrade(
					          scalar $pack->$p)
				              },
					    store => sub {
				                $pack->$p($_[1])
				            },
					);
				}
			}
			$constructor->prop({name => $name, @prop_args});
		}}
	}

	# ~~~ needs to be made more elaborate
# ~~~ for later:	exists $opts{keys} and $class{keys} = $$opts{keys};



	# $class{hash}{store} will be a coderef that returns true or false,
	# depending on whether it was able to write the property. With two-
	# way hash bindings, it will always return true

	if($opts{hash}) {
		if(!ref $opts{hash} # ) {
			#if(
			&& $opts{hash} =~ /^(?:1|(2))/) {
				$class{hash} = {
					fetch => sub { exists $_[0]{$_[1]}
						? $self->upgrade(
						    $_[0]{$_[1]})
						: undef
					},
					store => $1 # two-way?
					  ? sub { $_[0]{$_[1]}=$_[2]; 1 }
					  : sub {
						exists $_[0]{$_[1]} and
						   ($_[0]{$_[1]}=$_[2], 1)
					  },
				};
				$class{keys} ||= sub { keys %{$_[0]} };
			}
		else { croak
			"Invalid value for the 'hash' option: $opts{hash}";
		}

=begin comment

# I haven't yet figured out a logical way for this to work:

			else { # method name
				my $m = $opts{hash};
				$class{hash} = {
					fetch => sub {
						$self->_upgr_def(
						  $_[0]->value->$m($_[1])
						)
					},
					store => sub {
					  my $wrappee = shift->value;
					  defined $wrappee->$m($_[0]) &&
					    ($wrappee->$m(@_), 1)
					},
				};
			}
		} elsif (ref $opts{hash} eq 'CODE') {
			my $cref = $opts{hash};
			$class{hash} = {
				fetch => sub {
					$self->_upgr_def(
				            &$cref($_[0]->value, $_[1])
					)
				},
				store => sub {
				  my $wrappee = shift->value;
				  defined &$cref($wrappee, $_[0]) &&
				    (&$cref($wrappee, @_), 1)
				},
			};
		} else { # it'd better be a hash!
			my $opt = $opts{hash_elem};
			if(exists $$opt{fetch}) {
				my $fetch = $$opt{fetch};
				$class{hash}{fetch} =
				        ref $fetch eq 'CODE'
				        ? sub { $self-> _upgr_def(
				            &$fetch($_[0]->value, $_[1])
				        ) }
				        : sub { $self-> _upgr_def(
				            shift->value->$fetch(shift)
				        ) }
				;
			}
			if(exists $$opt{store}) {
				my $store = $$opt{store};
				$class{hash}{store} =
				        ref $store eq 'CODE'
				        ? sub {
				  	  my $wrappee = shift->value;
				  	  defined &$store($wrappee, $_[0])
					  and &$store($wrappee, @_), 1
				        }
				        : sub {
				  	  my $wrappee = shift->value;
				  	  defined $wrappee->$store($_[0])
					  and &$store($wrappee, @_), 1
				            $_[0]->value->$store(@_[1,2])
				        }
				;
			}
		}

=end comment

=cut

	}

	if($opts{array}) {
			if($opts{array} =~ /^(?:1|(2))/) {
				$class{array} = {
					fetch => sub { $_[1] < @{$_[0]}
						? $self->upgrade(
						    $_[0][$_[1]])
						: undef
					},
					store => $1 # two-way?
					  ? sub { $_[0][$_[1]]=$_[2]; 1 }
					  : sub {
						$_[1] < @{$_[0]} and
						   ($_[0]{$_[1]}=$_[2], 1)
					  },
				};
			}
		else { croak
		    "Invalid value for the 'array' option: $opts{array}";
		}

=begin comment

	} elsif (exists $opts{array_elem}) {
		if (!ref $opts{array_elem}) {
			my $m = $opts{array_elem};
			$class{array} = {
				fetch => sub {
					$self->upgrade(
						$_[0]->value->$m($_[1])
					)
				},
				store => sub { $_[0]->value->$m(@_[1,2]) },
			};
		} else { # it'd better be a hash!
			my $opt = $opts{array_elem};
			if(exists $$opt{fetch}) {
				my $fetch = $$opt{fetch};
				$class{array}{fetch} =
				        ref $fetch eq 'CODE'
				        ? sub { $self->upgrade(
				            &$fetch($_[0]->value, $_[1])
				        ) }
				        : sub { $self->upgrade(
				            shift->value->$fetch(shift)
				        ) }
				;
			}
			if(exists $$opt{store}) {
				my $store = $$opt{store};
				$class{array}{store} =
				        ref $store eq 'CODE'
				        ? sub {
				            &$store($_[0]->value, @_[1,2])
				        }
				        : sub {
				            $_[0]->value->$store(@_[1,2])
				        }
				;
			}
		}

=end comment

=cut

	}

	weaken $self; # we've got closures

	return # nothing
}



=item $j->new_parser

This returns a parser object (see L<JE::Parser>) which allows you to
customise the way statements are parsed and executed (only partially
implemented).

=cut

sub new_parser {
	JE::Parser->new(shift);
}




=back

=cut



1;
__END__

=begin for me

=head1 IMPLEMENTATION NOTES

(to be written)

- decimal interpretation of parseInt's argument
- numbers not necessarily acc. to spec
- typo in 'for' and 'try' algorithms in spec
- behaviour of 'break' and 'continue' outside of loops
- behaviour of 'return' outside of subs
- Array.prototype.toLocaleString uses ',' as the separator
- reversed words can be used as idents when there is no ambiguity

=end for me

=head1 BUGS

=over 4

=item *

JE is not necessarily IEEE 754-compliant. It depends on the OS. For this
reason the Number.MIN_VALUE and Number.MAX_VALUE properties do not exist.

=item *

The RegExp class is incomplete. The Date class is still nonexistent.

=item *

Functions objects do not always stringify properly. The body of the 
function is
missing. This produces warnings, too.

=item *

The JE::Scope class, which has an C<AUTOLOAD> sub that 
delegates methods to the global object, does not yet implement 
the C<can> method, so if you call $scope->can('to_string')
you will get a false return value, even though scope objects I<can>
C<to_string>.

=item *

JE::LValue's C<can> method returns the method that JE::LValue::AUTOLOAD 
calls when methods are delegated. But that means that if you call C<can>'s
return value, it's not the same as invoking a method, because a
different object is passed:

 $lv = $je->eval('this.document');
 $lv->set({});

 $lv->to_string; # passes a JE::Object to JE::Object's to_string method
 $lv->can('to_string')->($lv);
	# passes the JE::LValue to JE::Object's to_string method

If this is a problem for anyone, I have a fix for it (returning a closure),
but I think it would have a 
performance
penalty, so I don't want to fix it. :-(

=item *

C<hasOwnProperty> does not work properly with arrays and arguments objects.

=item *

Currently some tests for bitshift operators fail on Windows. Patches are
welcome.

=back

=head1 PREREQUISITES

perl 5.8.3 or later (to be precise: Exporter 5.57 or later)

Tie::RefHash::Weak, for perl versions earlier than 5.9.4

B<Note:> JE will probably end up with Date::Parse and Unicode::Collate in
the list of dependencies.

=head1 AUTHOR, COPYRIGHT & LICENSE

Copyright (C) 2007 Father Chrysostomos <sprout [at] cpan
[dot] org>

This program is free software; you may redistribute it and/or modify
it under the same terms as perl.

=head1 ACKNOWLEDGEMENTS

Thanks to Max Maischein S<< [ webmasterE<nbsp>E<nbsp>corion net ] >> for 
letting
me use
his tests,

to Andy Armstrong S<< [ andyE<nbsp>E<nbsp>hexten net ] >> and Yair Lenga
S<< [ yair lengaE<nbsp>E<nbsp>gmail com ] >> for their suggestions,

and to the CPAN Testers for their helpful failure reports.

=head1 SEE ALSO

The other JE man pages, especially the following (the rest are listed on
the L<JE::Types> page):

=over 4

=item L<JE::Types>

=item L<JE::Object>

=item L<JE::Object::Function>

=item L<JE::LValue>

=item L<JE::Scope>

=item L<JE::Code>

=item L<JE::Parser>

=back

I<ECMAScript Language Specification> (ECMA-262)

=over 4

L<http://www.ecma-international.org/publications/files/ecma-st/ECMA-262.pdf>

=back

L<JavaScript.pm|JavaScript> and L<JavaScript::SpiderMonkey>--both 
interfaces to
Mozilla's open-source SpiderMonkey JavaScript engine.

L<WWW::Mechanize::Plugin::JavaScript>
