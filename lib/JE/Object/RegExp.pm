package JE::Object::RegExp;

our $VERSION = '0.022';


use strict;
use warnings; no warnings 'utf8';

use overload fallback => 1,
	'""'=> 'value';

use Scalar::Util 'blessed';

our @ISA = 'JE::Object';

require JE::Boolean;
require JE::Code;
require JE::Object;
require JE::String;

import JE::Code 'add_line_number';
sub add_line_number;

our @Match;
our @EraseCapture;

#import JE::String 'desurrogify';
#sub desurrogify($);
# Only need to turn these on when Perl starts adding regexp modifiers
# outside the BMP.

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
#    [^]	(?s:.)
# ('/[]]/' is a syntax error in ECMAScript. A positive char class cannot be
# empty,  nor can the first character within a char  class  be  a  closing
# bracket.  JE  is  more  lenient  and  allows  Perl’s  behaviour  [i.e.,
# '/[\]]/'].)

# Other differences
#
# A quantifier in a JS regexp will,  when repeated,  clear all values  cap-
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
# We can emulate  ECMAScript’s  behaviour  by  putting  a  (?{})  marker
# within each pair of capturing parentheses before the closing paren, and
# within it’s  enclosing  group  at  the  end:  (?:(a+)?b)+  will  become
# (?: ( a+ (?{...}) )? b (?{...}) )+  (spaced out for  readability). The
# last code  interpolation  sees  whether  the  re  engine  is  making
# it  past  the  (a+).  The inner  (first)  code  interpolation  will
# only be triggered if  the  a+  matches.  If the  final  code  inter-
# polation is triggered without the inner one being  triggered  first,
# then the  capture  from  the  parentheses  is  to  be  erased  after-
# wards.  It’s actually slightly more  complicated  than  that,  because
# we may have  alternatives  directly  inside  the  outer  grouping;  e.g.,
# (?:a|(b))+,  so we have to wrap the contents thereof within (?:),  making
# ‘(?:(?:a|(b(?{...})))(?{...}))+’.  Whew!  Anyway,  we store the  info  in
# $EraseCapture, using (?{$EraseCapture[n]=0}) and (?{++$EraseCapture[n]}),
# where n is the number of the capture. If $EraseCapture[n] > 1 afterwards,
# then undefined is to be returned in place of $1.
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
# This is solved with a (?{}) that comes *after* the (?!)’s final clos-
# ing paren, that marks the captures for erasure.
#
#
# In ECMAScript, as in Perl, a pair of capturing parentheses will produce
# the undefined value if the parens were not  part  of  the  final  match.
# Undefined will still be produced if there  is  a  \digit  backreference
# reference to those parens. In ECMAScript, such a back-reference is equiv-
# alent to (?:); in Perl it is equivalent to (?!). Therefore, ECMAScript’s
# \1  is equivalent to Perl’s  (?(1)\1).  (It  would  seem,  upon  testing
# /(?:|())/ vs. /(?:|())\1/ in perl, that the \1 back-reference always suc-
# ceeds, and ends up setting $1 to "" [as opposed to undef]. What is actu-
# ally happening is that the failed \1 causes backtracking, so the second
# alternative in (?:|()) matches, setting $1 to the empty string. Safari,
# incidentally, does what Perl *appears* to do at first glance, *if* the
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
and C<(?m)>, which don't do anything, and C<(?|...)>, which is 
unpredictable.

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

my $clear_captures = qr/(?{@Match=@EraseCapture=()})/;
my $save_captures = do { no strict 'refs';
  qr/(?{$Match[$_]=($EraseCapture[$_]||0)>1?undef:$$_ for 1..$#+})/; };
# These are pretty scary, aren’t they?
my $plain_regexp =
	qr/^((?:[^\\[()]|\\.|\((?:\?#|\*)[^)]*\))[^\\[()]*(?:(?:\\.|\((?:\?#|\*)[^)]*\))[^\\[()]*)*)/s;
my $plain_regexp_x_mode =
	qr/^((?:[^\\[()]|\\.|\(\s*(?:\?#|\*)[^)]*\))[^\\[()]*(?:(?:\\.|\(\s*(?:\?#|\*)[^)]*\))[^\\[()]*)*)/s;
my $plain_regexp_wo_pipe =
	qr/^((?:[^\\[()|]|\\.|\((?:\?#|\*)[^)]*\))[^\\[()|]*(?:(?:\\.|\((?:\?#|\*)[^)]*\))[^\\[()|]*)*)/s;
my $plain_regexp_x_mode_wo_pipe =
	qr/^((?:[^\\[()|]|\\.|\(\s*(?:\?#|\*)[^)]*\))[^\\[()|]*(?:(?:\\.|\(\s*(?:\?#|\*)[^)]*\))[^\\[()|]*)*)/s;

sub _capture_erasure_stuff {
	map ref() # if we have a reference, its from a (?!)
		  ? map "\$EraseCapture[$_]=2",@$_
		  : "local\$EraseCapture[$_]=(\$EraseCapture[$_]||0)+1",
		@{+shift}
}

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
					$global, add_line_number
					'Second argument to ' .
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
	no warnings 'syntax'; # so syntax errors in the eval are kept quiet
	$flags =~ /^((?:(?!s)[\$_\p{ID_Continue}])*)\z/ and eval "qr//$1"
		or die new JE::Object::Error::SyntaxError $global,
		add_line_number "Invalid regexp modifiers: '$flags'";

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

	use constant::private {
		posi => 0, type => 1, xmod => 2, parn => 3, #capn => 4,
		reg => 0, cap => 1, itrb => 2, brch => 3, cond => 4
	};

	my $new_re = '';
	my $sub_pat;
	my @stack = [0,0,$flags =~ /x/];
	my $capture_num; # number of the most recently started capture
	my @to_erase = []; # arys of numbers of captures to be marked with
	                   # (?{}) for potential erasure
	my @interrobang; # arys of nos. of captures w/in interrobang group;
                         # we keep a separate list in addition to @to_erase
	                 # because even those captures that do  participate
	                 # in the final iteration of a  quantified  subpat-
	                 # tern are to be erased.  Furthermore,  we  can’t
	                 # erase them till we reached the end of the inner-
	                 # most enclosing group,  because the interrobang
	                 # group may be quantified.
	my @capture_nums;   # numbers of the captures we’re inside
	my @add_extra_paren; # levels at which a closing paren needs to
	                     # be inserted
#my $warn;
#++$warn if $re eq '(?p{})';
	{
		if( $stack[-1][xmod]
		  ? $stack[-1][type] == cond || $stack[-1][type] == brch
		    ? $re =~ s/$plain_regexp_x_mode_wo_pipe//
		    : $re =~ s/$plain_regexp_x_mode//
		  : $stack[-1][type] == cond || $stack[-1][type] == brch
		    ? $re =~ s/$plain_regexp_wo_pipe//
		    : $re =~ s/$plain_regexp//
		) {
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
		elsif($re=~s/^\[((?:[^\\]|\\.)[^]\\]*(?:\\.[^]\\]*)*)]//s){
			if($1 eq '^') {
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
		elsif( $stack[-1][xmod]
		             ? $re =~ s/^(\(\s*\?([\w]*)(?:-([\w]*))?\))//
		             : $re =~ s/^(\(   \?([\w]*)(?:-([\w]*))?\))//x
		) {
			$new_re .= $1;
			defined $3 && index($3,'x')+1
			? $stack[-1][xmod]=0
			: $2 =~ /x/ && ++$stack[-1][xmod];
		}
		elsif( $stack[-1][xmod]
		 ? $re=~s/^(\((?:\s*\?([\w-]*:|[^:{?<p]|<.|([?p]?\{)))?)//
		 : $re=~s/^(\((?:   \?([\w-]*:|[^:{?<p]|<.|([?p]?\{)))?)//x
		) {
#			warn "$new_re-$1-$2-$3-$re" if $warn;
			$3 and  die add_line_number
				"Embedded code in regexps is not "
				    . "supported";
			$new_re .= $1;
			my $caq = $2; # char(s) after question mark
			my @current;
			if(defined $caq) {  # (?...) patterns
				if($caq eq '(') {
				  $re =~ s/^([^)]*\))//;
				  $new_re .= $1;
				  $1 =~ /^\?[?p]?\{/ && die add_line_number
				    "Embedded code in regexps is not " 
				    . "supported\n";
				  $current[type] = cond;
				}
				elsif($caq =~ /^[<'P](?![!=])/) {
				  ++$capture_num;
				  $caq eq "'" ? $re =~ s/^(.*?')//
				              : $re =~ s/^(.*?>)//;
				  $new_re .= $1;
				  $current[type] = reg;
				}
				else {
				  $current[type] = (reg,itrb)[$caq eq '!'];
				}
				$current[posi] = length $new_re;
				if($caq eq '!') {
					push @interrobang,[];
				}
			}else{ # capture
				++$capture_num;
				substr($new_re,$stack[-1][posi],0) = "(?:",
				push @add_extra_paren, $#stack
				  unless $stack[-1][type] == itrb ||
				    @add_extra_paren
				    && $add_extra_paren[-1] == $#stack;
				push @capture_nums, $capture_num;
				$current[posi] = length $new_re;
				$current[type] = cap;
				@interrobang and
				  push @{$interrobang[-1]}, $capture_num;
			}
			$current[xmod] = $stack[-1][xmod];
			push @stack, \@current;
			push @to_erase, [];
		}
		elsif($re =~ s/^\)//) {
			my @commands;
			if($stack[-1][type] != itrb) {
				push @commands,
				  _capture_erasure_stuff pop @to_erase;
				if($stack[-1][type] == cap) {
				  # we are exiting a capturing group
				  push @commands, "local" .
				    "\$EraseCapture[$capture_nums[-1]]=0";
				  push @{$to_erase[-1]}, pop @capture_nums;
				}
				$new_re .= ')', pop @add_extra_paren
				  if @add_extra_paren
				  && $add_extra_paren[-1] == $#stack;
			}
			else { # ?!
				pop @to_erase; # don't need this
				push @{$to_erase[-1]}, pop @interrobang;
				$new_re .= ')';
			}
			$new_re .= '(?{' . join(';',@commands) . '})'
				if @commands;
			$new_re .= ')' unless $stack[-1][type] == itrb;;
			pop @stack;
		}
		elsif($re =~ s/^\|//) {
			my @commands;
			push @commands, map "local\$EraseCapture[$_]=" .
				"\$EraseCapture[$_]+1",
				@{$to_erase[-1]};
			@{$to_erase[-1]} = ();
			$new_re .= ')', pop @add_extra_paren
			  if @add_extra_paren
			  && $add_extra_paren[-1] == $#stack;
			$new_re .= '(?{' . join(';',@commands) . '})'
				if @commands;
			$new_re .= '|';
			$stack[-1][posi] = length $new_re;
		}
		elsif($re) {
#warn $re;
			die JE::Object::Error::SyntaxError->new($global,
			    add_line_number
			    $re =~ /^\[/
			    ? "Unterminated character class $re in regexp"
			    : 'Trailing \ in regexp');
		}
		length $re and redo;
	}
	$new_re .= ')' if @add_extra_paren;
	$new_re .= '(?{'.join(
		';', _capture_erasure_stuff pop @to_erase
	).'})'
		if @{$to_erase[-1]};


	# This substitution is a workaround for a bug in perl.
	$new_re =~ s/([\x{d800}-\x{dfff}])/sprintf '\\x{%x}', ord $1/ge;

	$qr = eval {
		use re 'eval'; no warnings 'regexp';
		$capture_num
		  ? qr/(?$flags:$clear_captures$new_re$save_captures)/
		  : qr/(?$flags:$clear_captures$new_re)/
	} or $@ =~ s/\.?$ \n//x,
	     die JE::Object::Error::SyntaxError->new($global,
			add_line_number $@);

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
			function_args => ['this','args'],
			function => my $exec = sub {
				my ($self,$str) = @_;

				die JE::Object::Error::TypeError->new(
					$global, add_line_number
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

				my(@ary,$indx);

				my $g = $self->prop('global')->value;
				if ($g) {
					pos $str =
					   $self->prop('lastIndex')->value;
					$str =~ /$$$self{value}/g or
					  $self->prop(lastIndex =>
					    JE::Number->new($global, 0)),
					  return $global->null;

					@ary = @Match;
					$ary[0] = substr($str, $-[0],
						$+[0] - $-[0]);
					$indx = $-[0];

					$self->prop(lastIndex =>
						JE::Number->new(
							$global, pos $str
						));							}
				else {
					$str =~ /$$$self{value}/ or
					  $self->prop(lastIndex =>
					    JE::Number->new($global, 0)),
					  return $global->null;

					@ary = @Match;
					$ary[0] = substr($str, $-[0],
						$+[0] - $-[0]);
					$indx = $-[0];

				}
			
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

	$proto->prop({
		name  => 'test',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'test',
			argnames => ['string'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my ($self,$str) = @_;
				my $ret = &$exec($self,$str);
				JE::Boolean->new(
					$global, $ret->id ne 'null'
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toString',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my ($self,) = @_;
				JE::String->new(
					$global,
					"/" . $self->prop('source')->value
					. "/$$$self{regexp_flags}"
				);
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


