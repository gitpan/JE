package JE::Code::Grammar;

our $VERSION = '0.005';
our $x;
use strict;
use warnings;
use re 'taint'; # highly important
use subs qw'statement statements assign assign_noin expr new';

use constant JECE => 'JE::Code::Expression';

require JE::Object::RegExp;
require JE::Number;
require JE::String;

import JE::String 'desurrogify';
sub desurrogify($);

our $global;


# die is called with a scalar ref when the string contains what is
# expected. This will be converted to a longer message afterwards, which
# will read something like "Expected %s but found %s" (probably the most
# common error message, which is why there is a shorthand).
# die is called with an array ref containing a single element if the string
# is the complete error message.

# @ret != push @ret, ...  is a funny way of pushing and then checking to
# see whether anything was pushed.


# optional horizontal comments and whitespace
our $h = qr(
	(?> [ \t\x0b\f\xa0\p{Zs}]* ) 
	(?> (?>/\*[^\cm\cj\x{2028}\x{2029}]*?\*/) [ \t\x0b\f\xa0\p{Zs}]* )?
)x;

# line terminators
our $n = qr((?>[\cm\cj\x{2028}\x{2029}]));

# single space char
our $ss = qr((?>[ \t\x0b\f\xa0\p{Zs}\cm\cj\x{2028}\x{2029}]));

# optional comments and whitespace
our $s = qr(
	(?> $ss* )
	(?> (?> //[^\cm\cj\x{2028}\x{2029}]* (?>$n|\z) | /\*.*?\*/ )
	    (?> $ss* )
	) *
)sx;

# mandatory comments/whitespace
our $S = qr(
	(?>
	  $ss
	    |
	  //[^\cm\cj\x{2028}\x{2029}]*
	    |
	  /\*.*?\*/
	)
	$s
)xs;

our $id_cont = qr(
	(?>
	  \\u([\dA-Fa-f]{4})
	    |
	  [\p{ID_Continue}\$_]
	)
)x;

sub  str() {
	/\G (?: '((?>(?:[^'\\] | \\.)*))'
	          |
	        "((?>(?:[^"\\] | \\.)*))"  )/xcgs or return;
	(my $yarn = $+) =~ s/\\(?:
		u([\da-fA-F]{4})
		 |
		x([\da-fA-F]{2})
		 |
		([bfnrt])
		 |
		(v)
		 |
		(.)
	)/
		$1 ? chr(hex $1) :
		$2 ? chr(hex $2) :
		$3 ? eval "qq-\\$3-" :
		$4 ? "\cK" :
		$5
	/sgex;
	new JE::String $global, $yarn;
}

sub  num() {
	/\G (?:
	  (?=\d|\.\d)
	  (
	    (?:0|[1-9]\d*)?
	    (?:\.\d*)?
	    (?:[Ee][+-]?\d+)?
	  )
	    |
	  0[Xx] ([A-Fa-f\d]+)
	) /xcg
	or return;
	return new JE::Number $global, defined $1 ? $1 : hex $2;
}

our $ident = qr(
	  (?:
	    \\u[\dA-Fa-f]{4}
	      |
	    [\p{ID_Start}\$_]
	  )
	  (?> $id_cont* )
)x;

sub unescape_ident($) {
	my $ident = shift;
	$ident =~ s/\\u([\da-fA-F]{4})/chr hex $1/ge;
	$ident = desurrogify $ident;
	$ident =~ /^[\p{ID_Start}\$_]
	            [\p{ID_Continue}\$_]*
	          \z/x
	  or die ["'$ident' is not a valid identifier."];
	$ident;
}

sub skip() { /\G$s/go } # skip whitespace

sub ident() {
	return unless my($ident) = /\G($ident)/cgox;
	unescape_ident $ident;
}

sub params() { # Only called when we know we need it, which is why it dies
                # on the second line
	my @ret;
	/\G\(/gc or die \"'('";
	skip;
	if (@ret != push @ret, ident) { # first identifier (not prec.
	                               # by comma)
		while (/\G$s,$s/ogc) {
			# if there's a comma we need another ident
			@ret != push @ret, ident or die \'identifier';
		}
		skip;
	}
	/\G\)/gc or die \"')'";
	\@ret;
}

sub term() {
	my $pos = pos;
	my $tmp;
	if(/\Gfunction(?!$id_cont)$s/cog) {
		my @ret = (func => ident);
		@ret == 2 and skip;
		push @ret, params;
		skip;
		/\G \{ /gcx or die \"'{'";
		push @ret, statements;
		/\G \} /gocx or die \"'}'";

		return bless [[$pos, pos], @ret], JECE;
	}
	elsif($tmp = ident or defined($tmp = str) or defined($tmp = num)) {
		if (!ref $tmp and $tmp =~ /^(?:(?:tru|fals)e|null)\z/) {
			$tmp = $tmp eq 'null' ?
				$global->null :
				new JE::Boolean $global, $tmp eq 'true';
		}
		return $tmp;
	}
	elsif(m-\G
		/
		( (?:[^/*\\] | \\.) (?>(?:[^/\\] | \\.)*) )
		/
	  	($id_cont*)
	      -cogx ) {
		return new JE::Object::RegExp $global, $1, $2;
	}
	elsif(/\G\[$s/cog) {
		my $anon;
		my @ret;
		my $length;

		while () {
			@ret != ($length = push  @ret, assign) and skip;
			push @ret, bless \$anon, 'comma' while /\G,$s/cog;
			$length == @ret and last;
		}

		/\G]/cg or die \"']'";
		return bless [[$pos, pos], array => @ret], JECE;
	}
	elsif(/\G\{$s/cog) {
		my @ret;

		# ~~~ This could be much more efficient if 'str' and 'num'
		#     did not have to create objects when called from here,
		#     since the objects are just stringified in the end
		#     anyway (in JE::Code::eval).

		if($tmp = ident or defined($tmp = str) or
				defined($tmp = num)) {
			# first elem, not preceded by comma
			push @ret, $tmp;
			skip;
			/\G:$s/coggg or die \'colon';
			@ret != push @ret, assign or die \'expression';
			skip;

			while (/\G,$s/cog) {
				$tmp = ident or defined($tmp = str) or
					defined($tmp = num)
				or die
				\'identifier, or string or number literal';

				push @ret, $tmp;
				skip;
				/\G:$s/coggg or die \'colon';
				@ret != push @ret, assign
					or die \'expression';
				skip;
			}
		}
		/\G}/cg or die \"'}'";
		return bless [[$pos, pos], hash => @ret], JECE;
	}
	elsif (/\G\($s/cog) {
		my $ret = expr or die \'expression';
		skip;
		/\G\)/cg or die \"')'";
		return $ret;
	}
	return
}

sub subscript() { # skips leading whitespace
	my $pos = pos;
	my $subscript;
	if (/\G$s\[$s/cog) {
		$subscript = expr or die \'expression';
		/\G]/cog or die \"']'";
	}
	elsif (/\G$s\.$s/cog) {
		$subscript = ident or die \'identifier';
	} 
	else { return }

	return bless [[$pos, pos], $subscript], 'JE::Code::Subscript';
}

sub args() { # skips leading whitespace
	my $pos = pos;
	my @ret;
	/\G$s\($s/ogc or return;
	if (@ret != push @ret, assign) { # first expression (not prec.
	                               # by comma)
		while (/\G$s,$s/ogc) {
			# if there's a comma we need another expression
			@ret != push @ret, assign or die \'expression';
		}
		skip;
	}
	/\G\)/gc or die \"')'";
	return bless [[$pos, pos], @ret], 'JE::Code::Arguments';
}

sub new() {
	/\G new(?!$id_cont) $s /cogx or return;
	my $ret = bless [[pos], 'new'], JECE;
	
	my $pos = pos;
	my @member_expr = new || term
		|| die \"identifier, literal, 'new' or '('";

	0 while @member_expr != push @member_expr, subscript;

	push @$ret, @member_expr == 1 ? @member_expr :
		bless [[$pos, pos], 'member/call', @member_expr],
		      JECE;
	push @$ret, args;
	$ret;
}

sub left_expr() {
	my($pos,@ret) = pos;
	@ret != push @ret, new || term or return;

	0 while @ret != push @ret, subscript, args;
	@ret ? @ret == 1 ? @ret : 
		bless([[$pos, pos], 'member/call', @ret],
			JECE)
		: return;
}

sub postfix() {
	my($pos,@ret) = pos;
	@ret != push @ret, left_expr or return;
	push @ret, $1 while /\G $h ( \+\+ | -- ) $s /cogx;
	@ret == 1 ? @ret : bless [[$pos, pos], 'postfix', @ret],
		JECE;
}

sub unary() {
	my($pos,@ret) = pos;
	push @ret, $1 while /\G $s (
	    (?: delete | void | typeof )(?!$id_cont)
	      |
	    \+\+? | --? | ~ | !
	) $s /cogx;
	@ret != push @ret, postfix or (
		@ret
		? die(\"expression")
		: return
	);
	@ret == 1 ? @ret : bless [[$pos, pos], 'prefix', @ret],
		JECE;
}

sub multi() {
	my($pos,@ret) = pos;
	@ret != push @ret, unary or return;
	while(m-\G $s ( [*%](?!=) | / (?![*/=]) ) $s -cogx) {
		@ret+1 == push @ret, $1, unary and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub add() {
	my($pos,@ret) = pos;
	@ret != push @ret, multi or return;
	while(/\G $s ( \+(?![+=]) | -(?![-=]) ) $s /cogx) {
		@ret+1 == push @ret, $1, multi and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bitshift() {
	my($pos,@ret) = pos;
	@ret == push @ret, add and return;
	while(/\G $s (>>>? | <<)(?!=) $s /cogx) {
		@ret+1 == push @ret, $1, add and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub rel() {
	my($pos,@ret) = pos;
	@ret == push @ret, bitshift and return;
	while(/\G $s ( [<>]=? | in(?:stanceof)?(?!$id_cont) ) $s /cogx) {
		@ret+1 == push @ret, $1, bitshift and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub rel_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, bitshift and return;
	while(/\G $s ( [<>]=? | instanceof(?!$id_cont) ) $s /cogx) {
		@ret+1 == push @ret, $1, bitshift and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub equal() {
	my($pos,@ret) = pos;
	@ret == push @ret, rel and return;
	while(/\G $s ([!=]==?) $s /cogx) {
		@ret+1 == push @ret, $1, rel and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub equal_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, rel_noin and return;
	while(/\G $s ([!=]==?) $s /cogx) {
		@ret+1 == push @ret, $1, rel_noin and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_and() {
	my($pos,@ret) = pos;
	@ret == push @ret, equal and return;
	while(/\G $s &(?!=) $s /cogx) {
		@ret == push @ret, '&', equal and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_and_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, equal_noin and return;
	while(/\G $s &(?!=) $s /cogx) {
		@ret == push @ret, '&', equal_noin and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_or() {
	my($pos,@ret) = pos;
	@ret == push @ret, bit_and and return;
	while(/\G $s \|(?!=) $s /cogx) {
		@ret == push @ret, '|', bit_and and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_or_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, bit_and_noin and return;
	while(/\G $s \|(?!=) $s /cogx) {
		@ret == push @ret, '|', bit_and_noin and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_xor() {
	my($pos,@ret) = pos;
	@ret == push @ret, bit_or and return;
	while(/\G $s \^(?!=) $s /cogx) {
		@ret == push @ret, '^', bit_or and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_xor_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, bit_or_noin and return;
	while(/\G $s \^(?!=) $s /cogx) {
		@ret == push @ret, '^', bit_or_noin and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub and_expr() { # If I just call it 'and', then I have to write
                 # CORE::and for the operator! (Far too cumbersome.)
	my($pos,@ret) = pos;
	@ret == push @ret, bit_xor and return;
	while(/\G $s && $s /cogx) {
		@ret == push @ret, '&&', bit_xor and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub and_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, bit_xor_noin and return;
	while(/\G $s && $s /cogx) {
		@ret == push @ret, '&&', bit_xor_noin and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub or_expr() {
	my($pos,@ret) = pos;
	@ret == push @ret, and_expr and return;
	while(/\G $s \|\| $s /cogx) {
		@ret == push @ret, '||', and_expr and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub or_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, and_noin and return;
	while(/\G $s \|\| $s /cogx) {
		@ret == push @ret, '||', and_noin and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub assign() {
	my($pos,@ret) = pos;
	@ret == push @ret, or_expr and return;
	while(m@\G $s ((?>(?: [-*/%+&^|] | << | >>>? )?)=) $s @cogx) {
		@ret+1 == push @ret, $1, or_expr and die
		    \'expression';
	}
	if(/\G$s\?$s/cog) {
		@ret == push @ret, assign and die
		    \'expression';
		skip;
		/\G:$s/cog or die \"colon";
		@ret == push @ret, assign and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'assign', @ret],
		JECE;
}

sub assign_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, or_noin and return;
	while(m~\G $s ((?>(?: [-*/%+&^|] | << | >>>? )?)=) $s ~cogx) {
		@ret+1 == push @ret, $1, or_noin and die
		    \'expression';
	}
	if(/\G$s\?$s/cog) {
		@ret == push @ret, assign and die
		    \'expression';
		skip;
		/\G:$s/cog or die \"colon";
		@ret == push @ret, assign_noin and die
		    \'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'assign', @ret],
		JECE;
}

sub expr() {
	my $ret = bless [[pos], 'expr'], JECE;
	@$ret == push @$ret, assign and return;
	while(/\G$s,$s/cog) {
		@$ret == push @$ret, assign and die
		    \'expression';
	}
	push @{$$ret[0]},pos;
	$ret;
}

sub expr_noin() {
	my $ret = bless [[pos], 'expr'], JECE;
	@$ret == push @$ret, assign_noin and return;
	while(/\G$s,$s/cog) {
		@$ret == push @$ret, assign_noin and die
		    \'expression';
	}
	push @{$$ret[0]},pos;
	$ret;
}

sub vardecl() { # vardecl is only called when we *know* we need it, so it
                # will die when it can't get the first identifier, instead
                # of returning undef
	my @ret;
	@ret == push @ret, ident and die \'identifier';
	/\G$s=$s/cog and (@ret != push @ret, assign or die \'expression');
	\@ret;
}

sub vardecl_noin() {
	my @ret;
	@ret == push @ret, ident and die \'identifier';
	/\G$s=$s/cog and
		(@ret != push @ret, assign_noin or die \'expression');
	\@ret;
}

sub finish_for_sc_sc() {  # returns the last two expressions of a for (;;)
                          # loop header
	my @ret;
	my $msg;
	if(@ret != push @ret, expr) {
		$msg = '';
		skip
	} else {
		push @ret, 'empty';
		$msg = 'expression or '
	}
	/\G;$s/cog or die \"${msg}semicolon";
	if(@ret != push @ret, expr) {
		$msg = '';
		skip
	} else {
		push @ret, 'empty';
		$msg = 'expression or '
	}
	/\G\)$s/cog or die \"${msg}')'";

	@ret;
}

# This takes care of trailing white space.
sub statement() {
	my $ret = [[pos]];

	# Statements that do not have an optional semicolon
	if (/\G (?:
		( \{ | ; )
		  |
		(function)$S
		  |
		( if | w(?:hile|ith) | for | switch ) $s \( $s
		  |
		( try $s \{ $s )
		  |
		($ident) $s : $s
	   ) /xogc) {
		no warnings 'uninitialized';
		if($1 eq '{') {
			push @$ret, 'statements';
			while() { # 'last' does not work when 'while' is a
			         # statement modifier
				@$ret == push @$ret, statement and last;
			}
			
			die \"'}'" unless /\G\}$s/goc;
		}
		elsif($1 eq ';') {
			push @$ret, 'empty';
			skip;
		}
		elsif($2) {
			push @$ret, 'function';
			@$ret == push @$ret, ident and die \"identifier";
			skip;
			push @$ret, params;
			skip;
			/\G \{ /gcx or die \"'{'";
			push @$ret, statements;
			/\G \}$s /gocx or die \"'}'";
		}
		elsif($3 eq 'if') {
			push @$ret, 'if';
			@$ret == push @$ret, expr and die \'expression';
			skip;
			/\G\)$s/goc or die \"')'";
			@$ret != push @$ret, statement or die \'statement';
			if (/\Gelse(?!$id_cont)$s/cog) {
				@$ret == push @$ret, statement
					and die \'statement';
			}
		}
		elsif($3 eq 'while') {
			push @$ret, 'while';
			@$ret == push @$ret, expr and die \'expression';
			skip;
			/\G\)$s/goc or die \"')'";
			@$ret != push @$ret, statement or die \'statement';
		}
		elsif($3 eq 'for') {
			push @$ret, 'for';
			if (/\G var$S/cogx) {
				push @$ret, my $var = bless
					[[pos() - length $1], 'var'],
					JECE;

				push @$var, vardecl_noin;
				skip;
				if (/\G([;,])$s/ogc) {
					# if there's a comma or sc then
					# this is a for(;;) loop
					if ($1 eq ',') {
						# finish getting the var
						# decl list
						do{
							@$ret ==
							push @$ret, vardecl 
							and die
							      \'identifier'
						} while (/\G$s,$s/ogc);
						skip;
						/\G;$s/cog
						    or die \'semicolon';
					}
					push @$ret, finish_for_sc_sc;
				}
				else {
					/\Gin$s/cog or die
					    \"'in', comma or semicolon";
					push @$ret, 'in';
					@$ret == push @$ret, expr
						and die \'expresssion';
					skip;
					/\G\)$s/cog or die \"')'";
				}
			}
			if(@$ret != push @$ret, expr_noin) {
				skip;
				if (/\G;$s/ogc) {
					# if there's a semicolon then
					# this is a for(;;) loop
					push @$ret, finish_for_sc_sc;
				}
				else {
					/\Gin$s/cog or die
						\"'in' or semicolon";
					push @$ret, 'in';
					@$ret == push @$ret, expr
						and die \'expresssion';
					skip;
					/\G\)$s/cog or die \"')'";
				}
			}
			else {
				/\G;$s/cog
					or die \'expression or semicolon';
				push @$ret, finish_for_sc_sc;
			}

			# body of the for loop
			@$ret != push @$ret, statement or die \'statement';
		}
		elsif($3 eq 'with') {
			push @$ret, 'while';
			@$ret == push @$ret, expr and die \'expression';
			skip;
			/\G\)$s/goc or die \"')'";
			@$ret != push @$ret, statement or die \'statement';
		}
		elsif($3 eq 'switch') {
			push @$ret, 'while';
			@$ret == push @$ret, expr and die \'expression';
			skip;
			/\G\)$s/goc or die \"')'";

			while (/\G case(?!$id_cont) $s/cogx) {
				@$ret == push @$ret, expr
					and die \'expression';
				skip;
				/\G:$s/cog or die \'colon';
				push @$ret, statements;
			}
			my $default=0;
			if (/\G default(?!$id_cont) $s/cogx) {
				/\G : $s /cgox or die \'colon';
				push @$ret, statements;
				++$default;
			}
			while (/\G case(?!$id_cont) $s/cogx) {
				@$ret == push @$ret, expr
					and die \'expression';
				skip;
				/\G:$s/cog or die \'colon';
				push @$ret, statements;
			}
			/\G \} $s /cgox or die \(
				$default
				? "'}' or 'case'"
				: "'}', 'case' or 'default'"
			); 
		}
		elsif($4) { # try
			push @$ret, statements;
			/\G \} $s /cgox or die \"'}'";

			if(/\Gcatch$s/cgo) {
				/\G \( $s /cgox or die \"'('";
				@$ret == push @$ret, ident
					and die \'identifier';
				skip;
				/\G \) $s /cgox or die \"')'";

				/\G \{ $s /cgox or die \"'{'";
				push @$ret, statements;
				/\G \} $s /cgox or die \"'}'";
			}
			if(/\Gfinally$s/cgo) {
				/\G \{ $s /cgox or die \"'{'";
				push @$ret, statements;
				/\G \} $s /cgox or die \"'}'";
			}
		}
		else { # labelled statement
			push @$ret, 'labelled', unescape_ident $5;
			while (/\G($ident)$s:$s/cg) {
				push @$ret, unescape_ident $1;
			}
			@$ret != push @$ret, statement or die \'statement';
		}
	}
	# Statements that do have an optional semicolon
	else {
		if (/\G var$S/xcog) {
			push @$ret, 'var';

			do{
				push @$ret, vardecl;
			} while(/\G$s,$s/ogc);
		}
		elsif(/\Gdo(?!$id_cont)$s/cog) {
			push @$ret, 'do';
			@$ret != push @$ret, statement or die \'statement';
			/\Gwhile$s/cog               or die \"'while'";
			/\G\($s/cog                or die \"'('";
			@$ret != push @$ret, expr or die \'expression';
			skip;
			/\G\)/cog or die \"')'";
		}
		elsif(/\G(continue|break)(?!$id_cont)$s/cog) {
			push @$ret, $1;
			/\G$h($ident)/cog
				and push @$ret, unescape_ident $1;
		}
		elsif(/\G(return|throw)(?!$id_cont)$s/cog) {
			push @$ret, $1;
			/\G$h/g; # skip horz ws
			push @$ret, expr;
		}
		else { # expression statement
			$ret = expr or return;
		}

		# Check for optional semicolon
		m-\G (?:
		    $s (?: \z | ; $s | (?=\}) )
		      |

		    # optional horizontal whitespace
		    # then a line terminator or a comment containing one
		    # then optional trailing whitespace
		    $h
		    (?: $n | //[^\cm\cj\x{2028}\x{2029}]* $n |
		        /\* [^*\cm\cj\x{2028}\x{2029}]* 
			    (?: \*(?!/) [^*\cm\cj\x{2028}\x{2029}] )*
			  $n
		          (?s:.)*?
		        \*/
		    )
		    $s
		)-cogx or die \"semicolon, '}' or end of line";
	}
	push @{$$ret[0]},pos unless @{$$ret[0]} == 2; # an expr will 
	                                             # already have this

	ref $ret eq 'ARRAY' and bless $ret, 'JE::Code::Statement';

	return $ret;
}

# This takes care of leading white space.
sub statements() {
	my $ret = bless [[pos], 'statements'], 'JE::Code::Statement';
	/\G$s/go; # skip initial whitespace
	while () { # 'last' does not work when 'while' is a
	           # statement modifier
		@$ret != push @$ret, statement or last;
	}
	push @{$$ret[0]},pos;
	return $ret;
}

sub program() {
	my $ret = statements;
	return $ret;
}

