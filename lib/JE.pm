package JE;

# If you are looking at the source code (which you are obviously doing
# if you are reading this),  note that  '# ~~~'  is my way of  marking
# something to be done still (except in this sentence).

# Note also that comments like "# E 7.1" refer to the indicated
# clause (7.1 in this case) in the ECMA-262 standard.

use 5.008;
use strict;
use warnings;

our $VERSION = '0.007';

use Encode qw< decode_utf8 encode_utf8 FB_CROAK >;

our @ISA = 'JE::Object';

require JE::Code    ;
require JE::Null     ;
require JE::Number     ;
require JE::Object       ;
require JE::Object::Array   ;
require JE::Object::Boolean   ;
require JE::Object::Error        ;
require JE::Object::Error::RangeError;
require JE::Object::Error::ReferenceError;
require JE::Object::Error::SyntaxError      ;
require JE::Object::Error::TypeError          ;
require JE::Object::Error::URIError            ;
require JE::Object::Function                   ;
require JE::Object::Math                       ;
require JE::Object::Number                     ;
require JE::Object::RegExp                      ;
require JE::Object::String                      ;
require JE::Scope                              ;
require JE::String                           ;
require JE::Undefined                     ;

=head1 NAME

JE - Pure-Perl ECMAScript (JavaScript) Engine

"JE" is short for "JavaScript::Engine."

=head1 VERSION

Version 0.007 (alpha release)

=head1 SYNOPSIS

  use JE;

  $j = new JE; # create a new global object

  $j->eval('({"this": "that", "the": "other"}["this"])');
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
add properties and methods to it from Perl, and to access those properties, 
see 
L<< C<JE::Types> >> and L<< C<JE::Object> >>, which this
class inherits from.

If you want to create your own global object class (such as a web browser
window), inherit from JE.

=head1 METHODS

=over 4

=item $j = JE->new

This class method constructs and returns a new global scope (C<JE> object).

=cut

our $s = qr.[\p{Zs}\s\ck]*.;

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
		value => JE::Object::Array->new_constructor($self),
		dontenum => 1,
	});
	$self->prop({
		name => 'String',
		value => JE::Object::String::_new_constructor($self),
		dontenum => 1,
	});
	$self->prop({
		name => 'Boolean',
		value => JE::Object::Boolean::_new_constructor($self),
		dontenum => 1,
	});
	$self->prop({
		name => 'Number',
		value => JE::Object::Number::_new_constructor($self),
		dontenum => 1,
	});
	# ~~~ Date
	$self->prop({
		name => 'RegExp',
		value => JE::Object::RegExp->new_constructor($self),
		dontenum => 1,
	});
	$self->prop({
		name => 'Error',
		value => JE::Object::Error->new_constructor($self),
		dontenum => 1,
	});
	# ~~~ EvalError ?
	$self->prop({
		name => 'RangeError',
		value => JE::Object::Error::RangeError
			->new_constructor($self),
		dontenum => 1,
	});
	$self->prop({
		name => 'ReferenceError',
		value => JE::Object::Error::ReferenceError
			->new_constructor($self),
		dontenum => 1,
	});
	$self->prop({
		name => 'SyntaxError',
		value => JE::Object::Error::SyntaxError
			->new_constructor($self),
		dontenum => 1,
	});
	$self->prop({
		name => 'TypeError',
		value => JE::Object::Error::TypeError
			->new_constructor($self),
		dontenum => 1,
	});
	$self->prop({
		name => 'URIError',
		value => JE::Object::Error::URIError
			->new_constructor($self),
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
			function_args => [qw< scope args >],
			function => sub {
				my($scope,$code) = @_;
				return $code if class $code ne 'String'; # ~~~ I think this is wrong. (should be typeof $code eq 'string')
				$scope->eval($code);
				# ~~~ Find out what the spec means by
				#     'if the completion value is empty'
				# ~~~ Add exception handling
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
				 && die
					JE::Object::Error::URIError->new(
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
					die JE::Object::Error::URIError
					->new('Malformed UTF-8 in URI');
				}
				
				$str =~
				     /^[\0-\x{d7ff}\x{e000}-\x{10ffff}]*\z/
				or die JE::Object::Error::URIError->new(
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
				 && die
					JE::Object::Error::URIError->new(
						"Invalid escape %$1 in URI"
					);

				$str = encode_utf8 $str;

				$str =~ s/%([0-9a-f]{2})/chr hex $1/iegx;
				
				local $@;
				eval {
					$str = decode_utf8 $str, FB_CROAK;
				};
				if ($@) {
					die JE::Object::Error::URIError
					->new('Malformed UTF-8 in URI');
				}
				
				$str =~
				     /^[\0-\x{d7ff}\x{e000}-\x{10ffff}]*\z/
				or die JE::Object::Error::URIError->new(
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
die JE::Object::Error::URIError->new(
	sprintf "Unpaired surrogate 0x%x in string", ord $1
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
die JE::Object::Error::URIError->new(
	sprintf "Unpaired surrogate 0x%x in string", ord $1
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
		value => JE::Object::Math->new($self),
		dontenum  => 1,
	});

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

  $j->eval('[1,2,3]') # returns a JE::Object::Array which can be used as
                      # an array ref

If an error occurs, C<undef> will be returned and C<$@> will contain the
error message. If no error occurs, C<$@> will be a null string.

This is actually just
a wrapper around C<compile> and the C<execute> method of the
C<JE::Code> class.

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
	my $code = shift->compile(shift);
	$@ and return;

	$code->execute;
}




=item $j->new_function($name, sub { ... })

=item $j->new_function(sub { ... })

This creates and returns a new function written in Perl. If $name is given,
it will become a property of the global object.

For more ways to create functions, see L<JE::Object::Function>.

B<To do:> Make this a method of JE::Object so it is more versatile. It will
still be accessible the same way as before, since JE inherits from 
JE::Object.

=cut

sub new_function {
	my $self = shift;
	my $f = JE::Object::Function->new({
		scope   => $self,
		function   => pop,
		function_args => ['args'],
		@_ ? (name => $_[0]) : ()
	});
	@_ and $self->prop({
		name => shift,
		value=>$f,
		dontdel=>1
	});
	$f;
}




=item $j->upgrade( @values )

This method upgrades the value or values given to it. See 
L<JE::Types/UPGRADING VALUES> for more detail.


If you pass it more
than one
argument in scalar context, it returns the number of arguments--but that 
is subject to change, so don't do that.

=cut

sub upgrade { # ~~~ I need correct the use of the object constructor, once
              #     I've fixed that.
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
		?	JE::Object->new($self, { value => $_ })
		: ref($_) eq 'CODE'
		?	JE::Object::Function->new($self, $_)
		: $_ eq '0' || $_ eq '-0'
		?	JE::Number->new($self, 0)
		:	JE::String->new($self, $_)
		;
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
- ||  &&  ? :  =  return lvalues
- behaviour of 'break' and 'continue' outside of loops
- behaviour of 'return' outside of subs
- Array.prototype.toLocaleString uses ',' as the separator
- reversed words can be used as idents when there is no ambiguity

=end for me

=head1 BUGS

Apart from the fact that the core object classes are incomplete, here are 
some known bugs:

Functions objects do not always stringify properly. The body of the 
function is
missing. This produces warnings, too.

The JE::LValue and JE::Scope classes, which have C<AUTOLOAD> subs that 
delegate methods to the objects to which they refer, do not yet implement 
the C<can> method, so if you call $thing->can('to_string') on one of these
you will get a false return value, even though these objects I<can>
C<to_string>.

The documentation is a bit incoherent. It probably needs a rewrite.

=head1 PREREQUISITES

perl 5.8.0 or later

B<Note:> JE may end up with other dependencies. It is too soon to say for
sure.

=head1 AUTHOR, COPYRIGHT & LICENSE

Copyright (C) 2007 Father Chrysostomos <sprout [at] cpan
[dot] org>

This program is free software; you may redistribute it and/or modify
it under the same terms as perl.

=head1 ACKNOWLEDGEMENTS

Thanks to Max Maischein [ webmasterE<nbsp>E<nbsp>corion net ] for letting
me use
his tests.

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


