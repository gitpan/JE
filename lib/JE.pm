package JE;

# If you are looking at the source code (which you are obviously doing
# if you are reading this),  note that  '# ~~~'  is my way of  marking
# something to be done still (except in this sentence).

# Note also that comments like "# E 7.1" refer to the indicated
# clause (7.1 in this case) in the ECMA-262 standard.

use 5.008;
use strict;
use warnings;

our $VERSION = '0.017';

use Carp 'croak';
use Encode qw< decode_utf8 encode_utf8 FB_CROAK >;
use JE::Code 'add_line_number';
use JE::_FieldHash;
use Scalar::Util qw'blessed refaddr';

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

"JE" is short for "L<JavaScript::Engine>" (q.v., for an explanation).

=head1 VERSION

Version 0.017 (alpha release)

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

  $j->prop(document => $obj); # set property
  $j->prop('document'); # get a property
  # Also:
  $j->{document} = $obj;
  $j->{document} = {}; # gets converted to a JE::Object
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

Easy to install (no C compiler necessary)

=item -

Compatible with Data::Dump::Streamer, so the runtime environment
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
L<JE::Code/FUNCTIONS|add_line_number> in the JE::Code man page.)

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

     isa => 'Object',
     # OR:
     prototype => $j->{Object}{prototype},
 );
 
 # OR:
 
 $j->bind_class(
     package => 'Net::FTP',
     wrapper => sub { new JE_Proxy_for_Net_FTP @_ }
 );


=head2 Description

(Some of this is random order, and probably needs to be rearranged.)

This method binds a Perl class to JavaScript. LIST is a hash-style list of 
key/value pairs. The keys are as follows (all optional except for 
C<package> or
C<name>--you must specify at least one of the two):

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
objects. B<This may change.> (Perhaps we should see whether the class has
overloading to determine this.)

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

=item isa => 'ClassName'

=item isa => $prototype_object

(Maybe this should be renamed 'super'.)

The name of the superclass. 'Object' is the default. To make this new
class's prototype object have no prototype, specify
C<undef>. Instead of specifying the name of the superclass, you 
can
provide the superclass's prototype object.

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
return the original object.

Note that, if you pass a Perl object to JavaScript before binding its 
class,
JavaScript's reference to it (if any) will remain as it is, and will not be
wrapped up inside a proxy object.

If C<constructor> is
not given, a constructor function will be made that throws an error when
invoked, unless C<wrapper> is given.

To use Perl's overloading within JavaScript, specify

      to_string => sub { "$_[0]" }
      to_number => sub { 0+$_[0] }

=cut

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
	$$$self{classes}{$pack} = \%class;

	my ($constructor,$proto,$coderef);
	if (exists $opts{constructor}) {
		my $c = $opts{constructor};

		$coderef = ref eq 'CODE'
			? sub { $self->upgrade(&$c()) }
			: sub { $self->upgrade($pack->$c) };
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


	if(exists $opts{isa}) {
		my $isa = $opts{isa};
		$proto->prototype(
		    !defined $isa || defined blessed $isa
		      ? $isa
		      : do {
		        defined(my $super_constr = $self->prop($isa)) ||
			  croak("JE::bind_class: The $isa" .
		                " constructor does not exist");
		        $super_constr->prop('prototype')
		      }
		);
	}

	if(exists $opts{methods}) {
		my $methods = $opts{methods};
		if (ref $methods eq 'ARRAY') { for my $m (@$methods) {
			$proto->new_method(
				$m => sub { shift->value->$m(@_) },
			);
		}} else { # it'd better be a hash!
		while( my($name, $m) = each %$methods) {
			$proto->new_method(
				$name => ref $m eq 'CODE'
					? sub {
					    &$m($_[0]->value,@_[1..$#_])
					}
					: sub { shift->value->$m(@_) },
			);
		}}
	}

	if(exists $opts{static_methods}) {
		my $methods = $opts{static_methods};
		if (ref $methods eq 'ARRAY') { for my $m (@$methods) {
			$constructor->new_function(
				$m => sub { $pack->$m(@_) },
			);
		}} else { # it'd better be a hash!
		while( my($name, $m) = each %$methods) {
			$constructor->new_function(
				$name => ref $m eq 'CODE'
					? sub {
					    unshift @_, $pack;
					    goto $m;
					}
					: sub { $pack->$m(@_) },
			);
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
	if(exists $opts{props}) {
		my $props = $opts{props};
		$class{props} = \my %props;
		if (ref $props eq 'ARRAY') {
		    for my $p (@$props) {
			$props{$p} = [
				fetch => sub {
					$self->upgrade($_[0]->value->$p)
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
				            &$fetch($_[0]->value)
				        ) }
				        : sub { $self->upgrade(
				            shift->value->$fetch
				        ) }
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
				@prop_args = ref $p eq 'CODE'
					? (
					    fetch => sub { $self->upgrade(
				                &$p($_[0]->value)
				            ) },
					    store => sub {
				                &$p($_[0]->value, $_[1])
				            },
					): (
					    fetch => sub { $self->upgrade(
				                $_[0]->value->$p
				            ) },
					    store => sub {
				                $_[0]->value->$p($_[1])
				            },
					);
			}
			$props{$name} = \@prop_args;
		}}
	}

	if(exists $opts{static_props}) {
		my $props = $opts{static_props};
		if (ref $props eq 'ARRAY') { for my $p (@$props) {
			$constructor->prop({
				name => $p,
				fetch => sub { $self->upgrade($pack->$p) },
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
				            $self->upgrade(&$fetch($pack))
				        }
				        : sub {
				            $self->upgrade($pack->$fetch)
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
				@prop_args = ref $p eq 'CODE'
					? (
					    fetch => sub {
				                $self->upgrade(&$p($pack))
				            },
					    store => sub {
				                &$p($pack, $_[1])
				            },
					): (
					    fetch => sub {
				                $self->upgrade($pack->$p)
				            },
					    store => sub {
				                $pack->$p($_[1])
				            },
					);
			}
			$constructor->prop({name => $name, @prop_args});
		}}
	}

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



#----------------PRIVATE METHODS/SUBS------------------------#

# none (yet [if ever])

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

The documentation is a bit incoherent, and needs to be restructured.

=back

=head1 PREREQUISITES

perl 5.8.0 or later

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

and to the CPAN Testers for their helpful bug reports.

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

=cut


HTML::DOM (still to be written)

WWW::Mechanize::JavaScript (also not written yet; it might not been named
this in the end, either)


