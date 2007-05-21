package JE;

# If you are looking at the source code (which you are obviously doing
# if you are reading this),  note that  '# ~~~'  is my way of  marking
# something to be done still (except in this sentence).

# Note also that comments like "# E 7.1" refer to the indicated
# clause (7.1 in this case) in the ECMA-262 standard.

use 5.008;
use strict;
use warnings;

our $VERSION = '0.013';

use Encode qw< decode_utf8 encode_utf8 FB_CROAK >;
use Scalar::Util 'blessed';
#use SelfLoader; # ~~~ I'll get to this

our @ISA = 'JE::Object';

require JE::Code;
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

"JE" is short for "JavaScript::Engine."

=head1 VERSION

Version 0.013 (alpha release)

The API is still subject to change. If you have the time and the interest, 
please experiment with this module.
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

JE's greatest weakness is that it's slow (well, what did you expect?).

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
				defined (my $tree = $self->parse($code))
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
		autoload => 'require JE::Object::Math;
		             JE::Object::Math->new($global)',
		dontenum  => 1,
	});

	$self;
}




=item $j->parse( STRING )

C<parse> parses the code contained in STRING and returns a parse
tree (a JE::Code object).

If the syntax is not valid, C<undef> will be returned and C<$@> will 
contain an
error message. Otherwise C<$@> will be a null string.

The JE::Code class provides the method 
C<execute> for executing the 
pre-compiled syntax tree.

=item $j->compile( STRING )

Just an alias for C<parse>.

=cut

sub parse {
	my $self = shift;
	JE::Code::_new($self, JE::Parser::_parse(program =>
		shift, $self));
}
*compile = \&parse;


=item $j->eval ( STRING )

C<eval> evaluates the JavaScript code contained in STRING. E.g.:

  $j->eval('[1,2,3]') # returns a JE::Object::Array which can be used as
                      # an array ref

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
	my $code = shift->parse(shift);
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
	for (@_) {
		push @__,
		  defined blessed $_
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



=item $j->new_parser

B<Not yet implemented.>

This will return a parser object (see L<JE::Parser>) which allows you to
customise the way statements are parsed and executed.

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

The documentation is a bit incoherent. It probably needs a rewrite.

=back

=head1 PREREQUISITES

perl 5.8.0 or later

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


