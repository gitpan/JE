package JE::Code;


=begin stuff for MakeMaker

use JE; our $VERSION = $JE::VERSION;

=end

=cut


use strict;
use warnings;
use re 'eval'; # Why on earth do I need this? Oh, I see why.

use Data::Dumper;

require JE::String;
require JE::Number;
require JE::LValue;
require JE::Scope;

our(@A,@_A,$A);  # accumulators
our($s, $term, $prefix, $postfix, $infix, $term_with_op, $expression,
    $statement); # regexps


#  Oh boy, Hairy Regular Expressions!

#--BEGIN--

$s = qr((?>\s*));

$term = qr[ (?>
	([A-Za-z\$_](?>[\w\$]+))  (?{push@$A,[ident=>$^N,pos]})
	  |
	('(?>(?:[^'\\] | \\.)*)') (?{push@$A,[str=>$^N,pos]})
	  |
	("(?>(?:[^"\\] | \\.)*)") (?{push@$A,[str=>$^N,pos]})
	  |
	(/(?>(?:[^/\\] | \\.)*/(?:ig?|gi?|))) (?{push@$A,[re=>$^N,pos]})
) ]x;
$prefix = qr((-) (?{push@$A,[pre=>$^N,pos]}) )x;

$postfix = qr/
	(\()      (?{push@$A,[post=>$^N,pos,[]];push@_A,$A;$A=$$A[-1][-1]})
	  $s
	(??{ $expression })
	  $s
	(\))      (?{$A=pop@_A;push@{$$A[-1]},$^N,pos})
/x;

$infix        = qr/([-+.*\/]) (?{push@$A,[in=>$^N,pos]}) /x;
$term_with_op = qr/ (?>(?:$prefix $s)?)
	(?> $term | 
		(\() (?{push@$A,[paren=>$^N,pos,[]];push@_A,$A;$A=$$A[-1][-1]})
		(??{ $expression })
		(\)) (?{$A=pop@_A;push@{$$A[-1]},$^N,pos})
	) (?>(?:$s $postfix)?)
/x;
$expression   = qr/ $term_with_op
			(?>(?: $s $infix $s $term_with_op)*)/x;
$statement    = qr/$s$expression$s(\z|;)/;

#--END--


sub parse {
	my($scope) = shift;

	my $src = shift; $src =~ s/\p{Cf}//g;
	my @statements;
	while(do { @A = (); $A = \@A; $src =~ /\G$statement/gc }) {
		push @statements, [@A];
	}

	if (pos($src) < length $src) { # Uh-oh, we have a syntax error
		$@ = "Syntax error at char ". pos($src);
		# ~~~ I'll improve the diagnostics later.
		return;
	}

	# now we deal with op precedence
	for(@statements){
		_parenthesise(bless $_, 'JE::Code::Expression');
	}




	$@ = '';
	return bless { scope      => $scope,
	               source     => $src,
	               statements => \@statements };
	# ~~~ I need to add support for a name for the code--to be
	#     used in error messages.
}


our %prec = # op precedence
qw`	post.	15
	post[	15
	post(	15
	prenew	15
	pre++	14
	pre--	14
	post++	14
	post--	14
	pre-	14
	pre+	14
	pre~	14
	pre!	14
	in*	13
	in/	13
	in+	12
	in-	12
`; #that'll do for now :-)

our %assoc = # op associativity
qw`	post.	l
	post[	l
	post(	l
	prenew	r
	pre++	r
	pre--	r
	post++	r
	post--	r
	pre-	r
	pre+	r
	pre~	r
	pre!	r
	in*	l
	in/	l
	in+	l
	in-	l
`;

sub _parenthesise { # replace literals  with  the  equivalent objects,
                    # and  resolve precedence by  creating dozens  of
                    # little JE::Code::Expression objects (a bit like
                    # parenthesised groups)
	my($tokens,$start,$end) = @_;
	my($token, $next_op, $op_key, $next_op_key);

	$end = defined $end ? $#$tokens - $end : 0;
	for(my $i = $start||0; $i <= $#$tokens - $end; ++$i) {
	$token = $$tokens[$i];
	for ($$token[0]) {
		next if !ref $token or ref $token ne 'ARRAY';
		if($_ eq 'str') {
			$$tokens[$i] = new JE::String
				substr $$token[1], 1, -1;
			# ~~~ still need to deal with escapes
		}
		if($_ eq 'ident') {
			$$tokens[$i] = $$token[1];
		}
		elsif($_ eq 'in') { # infix
			# if the next op has a higher precedence than
			# this one,  call _parenthesise,  indicating  a
			# starting position based  on  what  type  of
			# op it is

			# if it has the same precedence as this op and
			# and it is right-associative, do the same

			# otherwise wrap this op up in parentheses
			# together with its operands.
			
			$op_key = join '', @{$$tokens[$i]}[0,1];
			FIND_NEXT_OP: {
			for ($i..$#$tokens) {
				next unless $$tokens[$_][0] =~
					/^(?:p(?:ost|re)|in)\z/;
				$next_op_key = join '',
					@{$$tokens[$_]}[0,1];

				if($$tokens[$_][0] eq 'in'
				and $prec{$next_op_key} > $prec{$op_key}
				||  $prec{$next_op_key} == $prec{$op_key}
				&&  $assoc{$op_key} eq 'r'
				) {
					_parenthesise($tokens,
						$$tokens[$_][0] eq 'in'
						? $_ - 1 :
						$$tokens[$_][0] eq 'pre'
						? $_ :
						  $_ - 1 
					);
					redo FIND_NEXT_OP;
				}
				
				splice @$tokens, $i - 1, 3, bless
					[ @$tokens[$i-1..$i+1] ],
					 'JE::Code::Expression';
				
				# deal with the second operand
				_parenthesise($$tokens[$i-1], 2);

				$i--; last;
			}}
		}
		elsif($_ eq 'pre') { # prefix
			# We need to group this with the token that
			# follows

			splice @$tokens, $i, 2, bless
				[ @$tokens[$i,$i+1] ],
				'JE::Code::Expression';

			_parenthesise($$tokens[$i], 1);

			$i--; last;
		}
		elsif($_ eq 'post') { # postfix
			# We need to group this with the token that
			# precedes it

			splice @$tokens, $i-1, 2, bless
				[ @$tokens[$i - 1, $i] ],
				 'JE::Code::Expression';

			$i--; last;
		}
	}}
}





sub execute {
	my $code = shift;
	my $scope = $$code{scope};
	my $rv = eval {
		for(@{$$code{statements}}) {
			if(ref eq 'JE::Code::Expression') {
				return $_->eval($scope);
			}
			# ~~~ put elsif's here to deal with other
			#     kinds of statements
			else {
				die "Oh no! Something is terrible wrong. ",
				 "I have no idea what kind of statement"
				." this is: ", Dumper $_;
			}
		}
	};
# ~~~ This needs to provide the 'return_obj' option. Right now it's
#     always on.
	$rv;
}




package JE::Code::Expression;

use subs '_eval_token';

sub eval {  # evalate expression
	my ($tokens, $scope) = @_;

	if (! $#$tokens) {
		return _eval_token $$tokens[0]; # only one token here
	}
	my $first = $$tokens[0];

	#-------------PREFIX OPS----------------#
	if(ref $first eq 'ARRAY' && $$first[0] eq 'pre') {for($$first[1]) {
		if($_ eq '+') { # no-op
			return $$tokens[1];
		};
		if($_ eq '-') {
			return; # ~~~ unary negation
		};
		# ~~~ add the rest of the prefix ops
	}}

	my $second = $$tokens[1];

	#-------------INFIX OPS----------------#
	if($$second[0] eq 'in') { for($$second[1]) {
		$first = _eval_token $first;
		my $third = _eval_token $$tokens[2];
		if($_ eq '+') {
			# Boy, look at all those arrows!
			# This is really OOey.
			$first = $first->to_primitive;
			$third = $third->to_primitive;
			if($first->typeof eq 'string' or
			   $third->typeof eq 'string') {
				return $first->to_string->method(concat =>
					$third);
			}
			return new JE::Number $first->to_number->value +
			                      $third->to_number->value;
		};
		if($_ eq '-') {
			return; # ~~~ unary negation
		};
		# ~~~ add the rest of the prefix ops
	}}

	#-------------POSTFIX OPS----------------#

	for($$second[1]) {
		if ($_ eq '++') {
			# ~~~ etc
		}
		# ~~~ if ($_ .....
	}
}

sub _eval_token {
	my($token, $context, $scope,) = @_;

	# context can be one of:
	#    undef  no context (or a context that just wants the obj)
	#    lvalue 
	#    str    string context
	#    num    number context
	#    bool   boolean
	#    primitive  ???
	# ~~~ I need to complete this list

	while (ref $token eq 'JE::Code::Expression') {
		$token = $token->eval;
	}

# in no context
#	return an object
# in lvalue context
# 	we return an lvalue if we have an identifier or an lvalue
#	we die othrewise
# in other context
#	get an object and cast it accordingly

	for ($context) {
		if (!defined) {
			return ref $token ? $token : $scope->var($token);
		}
		if ($_ eq 'lvalue') {
			!ref $token  # identifier
				and $token = $scope->lvalue($token);

			ref $token ne 'JE::Code::LValue'
				and die "not an lvalue";
			# ~~~ improve the error message

			return $token;
		}

		ref $token or $token = $scope->var($token);
		ref $token eq 'lvalue' and $token = $token->get;
#		if ($_ eq 'primitive') {
#			Er ,. b..e ydco?
#		}
		if ($_ eq 'string') {
			return $token->to_string;
		}
		if ($_ eq 'num') {
			return $token->to_num;
		}

		# ~~~ etc

		die "How did we get here??? context: $context; token $token";
	}
}




1;
__END__


=head1 NAME

JE::Code - ECMAScript parser and code executor for JE

=head1 SYNOPSIS

  use JE;

  $j = new JE;

  $code = $j->compile('1+1'); # returns a JE::Code object

  $code->execute;

=head1 DESCRIPTION

This parser is a bit of a joke, since it supports so few features of JS
syntax. For now I'm only implementing enough to test the object classes
(and I'm not doing it precisely).

It will need a complete rewrite when the time cometh.

=head1 THE FUNCTION

C<JE::Code::parse($scope)> parses JS code and returns a parse tree.

=head1 THE METHOD

The C<execute> method of a parse tree executes it.

=head1 SEE ALSO

=over 4

L<JE>

=cut


To modify the parser's regexps, change what's below, then run this
file through perl -x.

#!perl

$data = <<'--END--';


$s = qr((?>\s*));

$term = qr[ (?>
	([A-Za-z\$_](?>[\w\$]+))   # ident
	  |
	('(?>(?:[^'\\] | \\.)*)')  # str
	  |
	("(?>(?:[^"\\] | \\.)*)")  # str
	  |
	(/(?>(?:[^/\\] | \\.)*/(?:ig?|gi?|)))  # re
) ]x;
$prefix = qr((-)  # pre )x;

$postfix = qr/
	(\()       # begin-post
	  $s
	(??{ $expression })
	  $s
	(\))       # end
/x;

$infix        = qr/([-+.*\/])  # in /x;
$term_with_op = qr/ (?>(?:$prefix $s)?)
	(?> $term | 
		(\()  # begin-paren
		(??{ $expression })
		(\))  # end
	) (?>(?:$s $postfix)?)
/x;
$expression   = qr/ $term_with_op
			(?>(?: $s $infix $s $term_with_op)*)/x;
$statement    = qr/$s$expression$s(\z|;)/;

--END--

sub build_regex {
	local $_ = shift;
	s/ # (?:(begin)-)?([a-z]+)(\s)/   '(?{' . (
		$1 ?
			"push\@\$A,[$2=>\$^N,pos,[]];push\@_A,\$A;\$A=\$\$A[-1][-1]"
		: $2 eq 'end' ?
			'$A=pop@_A;push@{$$A[-1]},$^N,pos'
		:	"push\@\$A,[$2=>\$^N,pos]"		
	) . "})$3"
	/ge;
	s/\s//g; # :-)
	"\n\n$_\n\n";
}


$data = build_regex $data;
($file = `cat \Q$0`) =~ s<#--BEGIN--(.*?)#--END-->
                         <#--BEGIN--$data#--END-->s;
system cp => $0, "$0~";
open F, ">$0" or die $!;
print F $file;

__END__


This   becomes	this
-------		-----
 # str		(?{ push @$A, [ str => $^N, pos ] })
 # begin-meth	(?{ push @$A, [ meth=> $^N, pos, [] ];
                    push @_A, $A;
                    $A = $$A[-1][-1]; })
 # end          (?{ $A = pop @_A;
                    push @{$$A[-1]}, $^N, pos })

