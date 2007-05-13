package JE::Object::RegExp;

our $VERSION = '0.012';


use strict;
use warnings;

use overload fallback => 1,
	'""'=> 'value';

use Scalar::Util 'blessed';

our @ISA = 'JE::Object';

require JE::Object;
require JE::String;

#import JE::String 'desurrogify';
#sub desurrogify($);
# Only need to turn these on when Perl starts adding regexp modifiers
# outside the BMP.

# ~~~ Add support for JavaScript's \c, which differs from Perl's
#     \c` in JavaScript means \x00, while in Perl it means \x20

# JS regexp features that Perl doesn't have, or which differ from Perl's,
# along with their Perl equivalents
#    ^ with /m  \A|(?<=[\cm\cj\x{2028}\x{2029}])  (^ with the  /m modifier
#                                                matches whenever a Unicode
#                                              line  break  (not  just  \n)
#                                           precedes the current  position,
#                                       even at the end of the string. In
#                                  Perl, /^/m matches \A|(?<=\n)(?!\z) .)
#    $          \z
#    $ with /m  (?:\z|(?=[\cm\cj\x{2028}\x{2029}]))
#    \b         (?:(?<=$w)(?!$w)|(?<!$w)(?=$w))  (where  $w  represents
#    \B         (?:(?<=$w)(?=$w)|(?<!$w)(?!$w))  [A-Za-z0-9_], because JS
#                                               doesn't include  non-ASCII
#                                             word chars in \w)
#    .          [^\cm\cj\x{2028}\x{2029}]
#    \v         \cK
#    \n         \cj  (whether \n matches \cj in Perl is system-dependent)
#    \r         \cm
#    \cX        (Matches the character produced by chr ord('X') % 32)
#    \uHHHH     \x{HHHH}
#    \d         [0-9]
#    \D         [^0-9]
#    \s         [\p{Zs}\s\ck]
#    \S         [^\p{Zs}\s\ck]
#    \w         [A-Za-z0-9_]
#    \W         [^A-Za-z0-9_]
#    []         (?!)  (ECMAScript allows an empty character class, which
#                    always fails.)
#    [^]	(?s:.)

# Other differences
#
# A quantifier in a JE regexp will,  when repeated,  clear all values  cap-
# tured by capturing parentheses in the term that it quantifies. This means
# that /((a)?b)+/, when matched against "abb" will leave $2 undefined, even
# though the second () matched  "a"  the first time the first  ()  matched.
# (The ECMAScript spec says to do it this way,  but Safari leaves $2  with
# "a" in it and doesn't clear it on the second iteration of the '+'.) Perl
# does it both ways, and the rules aren't quite clear to me:
#
# $ perl5.8.8 -le '$, = ",";print "abb" =~ /((a)?b)+/;'
# b,
# $ perl5.8.8 -le '$, = ",";print "abb" =~ /((a+)?b)+/;'
# b,a
#
# perl5.9.4 produces the same. perl5.002_01 crashes quite nicely.
#
#
# In ECMAScript, when the pattern inside a (?! ... ) fails (in which case
# the (?!) succeeds), values captured by parentheses within the negative
# lookahead are cleared, such that subsequent backreferences *outside* the
# lookahead are equivalent to (?:) (zero-width always-match assertion). In
# Perl, the captured values are left as they are when the pattern inside
# the lookahead fails:
#
# $ perl5.8.8 -le 'print "a" =~ /(?!(a)b)a/;'
# a
# $ perl5.9.4 -le 'print "a" =~ /(?!(a)b)a/;'
# a
#
#
# In ECMAScript, as in Perl, a pair of capturing parentheses will produce
# the undefined value if the parens were not part of the final match.  In
# ECMAScript,  undefined will still be produced if there is a \digit back-
# reference to those parens. In Perl, this value changes to a null string
# instead. (After /(?:|())/, $1 contains undef; after /(?:|())\1/, $1 con-
# tains "".) Safari, incidentally, does it the same way as Perl, *if* the
# backreference itself is within capturing parentheses (as in
# /(?:|())(\1)/).





=head1 NAME

JE::Object::RegExp - JavaScript regular expression (RegExp object) class

=head1 SYNOPSIS

  use JE;
  use JE::Object::RegExp;

  $j = new JE;

  $js_regexp = new JE::Object::RegExp $j, "(.*)", 'ims';

  $perl_qr = $js_regexp->value;

  $some_string =~ $js_regexp; # You can use it as a qr//

=head1 DESCRIPTION

This class implements JavaScript regular expressions for JE.

See L<JE::Types> for a description of most of the interface. Only what
is specific to JE::Object::RegExp is explained here.

A RegExp object will stringify the same way as a C<qr//>, so that you can
use C<=~> on it. This is different from the return value of the
C<to_string> method (the way it stringifies in JS).

Since JE's regular expressions use Perl's engine underneath, the 
features that Perl provides that are not part of the ECMAScript spec are
supported, except for C<(?s)>
and C<(?m)>, which don't do anything.

=head1 METHODS

=over 4

=cut

# ~~~ How should surrogates work??? To make regexps work with JS strings
#    properly, we need to use the surrogified string so that /../  will
#  correctly match two surrogates.  In this case it won't work properly
# with Perl strings, so what is the point of Perl-style stringification?
# Perhaps we should allow this anyway, but warn about code points outside
# the BMP in the documentation.  (Should we also produce a Perl  warning?
# Though I'm not that it's possible to catch  this:  "\x{10000}" =~ $re).
#
# But it would be nice if this would work:
#	$j->eval("'\x{10000}'") =~ $j->eval('/../')

our %_patterns = qw/
\b  (?:(?<=[A-Za-z0-9_])(?![A-Za-z0-9_])|(?<![A-Za-z0-9_])(?=[A-Za-z0-9_]))
\B  (?:(?<=[A-Za-z0-9_])(?=[A-Za-z0-9_])|(?<![A-Za-z0-9_])(?![A-Za-z0-9_]))
.   [^\cm\cj\x{2028}\x{2029}]
\v  \cK
\n  \cj
\r  \cm
\d  [0-9]
\D  [^0-9]
\s  [\p{Zs}\s\ck]
\S  [^\p{Zs}\s\ck]
\w  [A-Za-z0-9_]
\W  [^A-Za-z0-9_]
/;

our %_class_patterns = qw/
\v  \cK
\n  \cj
\r  \cm
\d  0-9
\s  \p{Zs}\s\ck
\w  A-Za-z0-9_
/;

sub new {
	my ($class, $global, $re, $flags) = @_;
	my $self = $class->SUPER::new($global, {
		prototype => $global->prop('RegExp')->prop('prototype')
	});

	my $qr;

	if(defined blessed $re) {
		if ($re->isa(__PACKAGE__)) {
			defined $flags && eval{$flags->id} ne 'undef' and
				die JE::Object::Error::TypeError->new(
					$global, 'Second argument to ' .
					'RegExp() must be undefined if ' .
					'first arg is a RegExp');
			$flags = $$$re{regexp_flags};
			$qr = $$$re{value};
			$re = $re->prop('source')->[0];
		}
		elsif(can $re 'id' and $re->id eq 'undef') {
			$re = '';
		}
		elsif(can $re 'to_string') {
			$re = $re->to_string->[0];
		}
	}
	else {
		defined $re or $re = '';
	}

	if(defined blessed $flags) {
		if(can $flags 'id' and $flags->id eq 'undef') {
			$flags = '';
		}
		elsif(can $flags 'to_string') {
			$flags = $flags->to_string->value;
		}
	}
	else {
		defined $flags or $flags = '';
	}


	# Let's begin by processing the flags:

	# Save the flags before we start mangling them
	$$$self{regexp_flags} = $flags;

	$self->prop({
		name => global =>
		value  => JE::Boolean->new($global, $flags =~ y/g//d),
		dontenum => 1,
		readonly  => 1,
		dontdel   => 1,
	});

#	$flags = desurrogify $flags;
# Not necessary, until Perl adds a /𐐢 modifier (not likely)

	# I'm not supporting /s (at least not for now)
	$flags =~ /^((?:(?!s)[\$_\p{ID_Continue}])*)\z/ and eval "qr//$1"
		or die new JE::Object::Error::SyntaxError $global,
		"Invalid regexp modifiers: '$flags'";

	my $m = $flags =~ /m/;
	$self->prop({
		name => ignoreCase =>
		value  => JE::Boolean->new($global, $flags =~ /i/),
		dontenum => 1,
		readonly  => 1,
		dontdel   => 1,
	});
	$self->prop({
		name => multiline =>
		value  => JE::Boolean->new($global, $m),
		dontenum => 1,
		readonly  => 1,
		dontdel   => 1,
	});


	# Now we'll deal with the pattern itself.

	# Save it before we go and mangle it
	$self->prop({
		name => source =>
		value  => JE::String->new($global, $re),
		dontenum => 1,
		readonly  => 1,
		dontdel   => 1,
	});

	unless (defined $qr) { # processing begins here

	my $new_re = '';
	my $sub_pat;
	{
		if($re =~ s/^((?:[^\\[]|\\.)[^\\[]*(?:\\.[^\\[]*)*)//s) {
			($sub_pat = $1) =~
			s/
				([\^\$])
				  |
				(\.|\\[bBvnrdDsSwW])
				  |
				\\c(.)
				  |
				\\u([A-Fa-f0-9]{4})
				  |
				(\\.)
			/
			  defined $1
			  ? $1 eq '^'
			    ? $m
			      ? '(?:\A|(?<=[\cm\cj\x{2028}\x{2029}]))'
			      : '^'
			    : $m
			      ? '(?:\z|(?=[\cm\cj\x{2028}\x{2029}]))'
			      : '\z'
			  : defined $2 ? $_patterns{$2} :
			    defined $3 ? sprintf('\x%02x', ord($3) % 32) :
			    defined $4 ? "\\x{$4}"      :
			    $5
			/egxs;
			$new_re .= $sub_pat;
		}
		if($re =~ s/^\[([^]\\]*(?:\\.[^]\\]*)*)]//s) {
			if ($1 eq '') {
				$new_re .= '(?!)';
			}
			elsif($1 eq '^') {
				$new_re .= '(?s:.)';
			}
			else {
				my @full_classes;
				($sub_pat = $1) =~ s/
				  (\\[vnrdsw])
				    |
				  (\.|\\[DSW])
				    |
				  \\c(.)
				    |
				  \\u([A-Fa-f0-9]{4})
				    |
				  (\\.)
				/
			  	  defined $1 ? $_class_patterns{$1} :
				  defined $2 ? ((push @full_classes,
					$_patterns{$2}),'') :
				  defined $3 ?
				     sprintf('\x%02x', ord($3) % 32) :
				  defined $4 ? "\\x{$4}"  :
			    	  $5
				/egxs;

				$new_re .= length $sub_pat
				  ? @full_classes
				    ? '(?:' .
				      join('|', @full_classes,
				        "[$sub_pat]")
				      . ')'
				    : "[$sub_pat]"
				  : @full_classes == 1
				    ? $full_classes[0]
				    : '(?:' . join('|', @full_classes) .
				      ')';
			}
		}
		elsif($re) {
			die JE::Object::Error::SyntaxError->new($global,
			    $re =~ /^\[/
			    ? "Unterminated character class $re in regexp"
			    : 'Trailing \ in regexp');
		}
		length $re and redo;
	}

	$qr = eval { qr/(?$flags:$new_re)/ }
		|| die JE::Object::Error::SyntaxError->new($global, $@);

	} # end of pattern processing

	$$$self{value} = $qr;

	$self->prop({
		name => lastIndex =>
		value => JE::Number->new($global, 0),
		dontdel => 1,
		dontenum => 1,
	});

	$self;
}




=item value

Returns a Perl C<qr//> regular expression.

If the regular expression
or the string that is being matched against it contains characters outside
the Basic Multilingual Plane (whose character codes exceed 0xffff), the
behavior is undefined--for now at least. I still need to solve the problem
caused by JS's unintuitive use of raw surrogates. (In JS, C</../> will 
match a
surrogate pair, which is considered to be one character in Perl. This means
that the same regexp matched against the same string will produce different
results in Perl and JS.)

=cut

sub value {
	$${$_[0]}{value};
}




=item class

Returns the string 'RegExp'.

=cut

sub class { 'RegExp' }



sub new_constructor {
	my($package,$global) = @_;
	my $f = JE::Object::Function->new({
		name            => 'RegExp',
		scope            => $global,
		argnames         => [qw/pattern flags/],
		function         => sub {
			my ($re, $flags) = @_;
			if ($re->class eq 'RegExp' and !defined $flags
			    || $flags->id eq 'undef') {
				return $re
			}
			unshift @_, __PACKAGE__;
			goto &new;
		},
		function_args    => ['scope','args'],
		constructor      => sub {
			unshift @_, $package;
			goto &new;
		},
		constructor_args => ['scope','args'],
	});

	my $proto = $f->prop({
		name    => 'prototype',
		dontenum => 1,
		readonly => 1,
	});
	
	$proto->prop({
		name  => 'exec',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'exec',
			argnames => ['string'],
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my ($self,$str) = @_;
				die JE::Object::Error::TypeError->new(
					$global,
					"Argument to exec is not a " .
					"RegExp object"
				) unless $self->class eq 'RegExp';

				my $je_str;
				if (defined $str) {
					$str =
					($je_str = $str->to_string)->[0];
				}
				else {
					$str = 'undefined';
				}

				$str = defined $str ? $str->to_string->[0]
					: 'undefined';

				my $g = $self->prop('global')->value;
				if ($g) {
					pos $str =
					   $self->prop('lastIndex')->value;
					$str =~ /$$$self{value}/g or
					  $self->prop(lastIndex =>
					    JE::Number->new($global, 0)),
					  return $global->null;
				}
				else {
					$str =~ /$$$self{value}/ or
					  $self->prop(lastIndex =>
					    JE::Number->new($global, 0)),
					  return $global->null;
				}

				my @ary = substr($str, $-[0],
					$+[0] - $-[0]);
				no strict 'refs';
				push @ary, map $$_, 1..$#+;
				my $indx = $-[0];

				$g and $self->prop(lastIndex =>
						JE::Number->new(
							$global, pos $str
						));						
				my $ary = JE::Object::Array->new(
					$global, \@ary);
				$ary->prop(index => $indx);
				$ary->prop(input => defined $je_str
					? $je_str :
					JE::String->new(
						$global, $str
					));
				
				$ary;
			},
		}),
		dontenum => 1,
	});


	$f;
}


=back

=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::Object

=cut


