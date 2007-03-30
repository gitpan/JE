package JE::Object::RegExp;

our $VERSION = '0.006';


use strict;
use warnings;

use overload fallback => 1,
	'""'=> 'value';


our @ISA = 'JE::Object';

require JE::Object;


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

sub new {
	my ($class, $global, $re, $flags) = @_;
	my $self = $class->SUPER::new($global, {
		prototype => $global->prop('RegExp')->prop('prototype')
	});

	# ~~~ Verify subroutine this with the spec.

	# ~~~ and do some syntax-checking of $re and $flags

	# ~~~ desurrogify the input string

	$flags =~ y/g//d and $self->prop(global => new JE::Boolean
		$global, 1); # ~~~ set attrs later

	$flags =~ /^([\$_\p{ID_Continue}]*)\z/ and eval "qr//$1"
		or die new JE::Object::Error::SyntaxError $global,
		"Invalid regexp modifiers: '$flags'";

	$$$self{value} = qr/(?$flags:$re)/;

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

=cut

sub value {
	$${$_[0]}{value};
}




sub new_constructor {
	my($class,$global) = @_;
	my $constr = $class->SUPER::new_constructor($global,
		sub {
		# what happens when RegExp is called as a function?
#			my $arg = shift;
#			defined $arg ? $arg->to_string :
#				JE::String->new($global, '');
		},
		\&_init_proto,
	);

#	$constr->prop({
#		dontenum => 1,
#	});
#	...

	$constr;
}

sub _init_proto{
}

=back

=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::Object

=cut


