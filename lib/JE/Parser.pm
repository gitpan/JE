package JE::Parser;

our $VERSION = '0.017';

use strict;  # :-(
use warnings;# :-(

use Scalar::Util 'blessed';

require JE::Code  ;
require JE::Number; # ~~~ Don't want to do this

import JE::Code 'add_line_number';
sub add_line_number;

our ($_parser, $global, @_decls, @_stms);

#----------METHODS---------#

sub new {
	my %self = (
		stm_names => [qw[
			-function block empty if while with for switch try
			 labelled var do continue break return throw expr
		]],
		stm => {
			-function => \&function,  block    => \&block,
			 empty    => \&empty,     if       => \&if,
			 while    => \&while,     with     => \&with,
			 for      => \&for,       switch   => \&switch,
			 try      => \&try,       labelled => \&labelled,
			 var      => \&var,       do       => \&do,
			 continue => \&continue,  break    => \&break,
			 return   => \&return,    throw    => \&throw,
			 expr     => \&expr_statement,
		},
		global => pop,
	);
	return bless \%self, shift;
}

sub add_statement {
	my($self,$name,$parser) = shift;
	my $in_list;
#	no warnings 'exiting';
	grep $_ eq $name && ++$in_list && goto END_GREP,
		@{$$self{stm_names}};
	END_GREP: 
	$in_list or unshift @{$$self{stm_names}} ,$name;
	$$self{stm}{$name} = $parser;
	return; # Don't return anything for now, because if we return some-
	        # thing, even if it's not documented, someone might start
		# relying on it.
}

sub delete_statement {
	my $self = shift;
	for my $name (@_) {
		delete $$self{stm}{$name};
		@{$$self{stm_names}} =
			grep $_ ne $name, @{$$self{stm_names}};
	}
	return $self;
}

sub statement_list {
	$_[0]{stm_names};
}

sub parse {
	local $_parser = shift;
	local(@_decls, @_stms); # Doing this here and localising it saves
	for(@{$_parser->{stm_names}}) { # us from having to do it multiple
		push @{/^-/ ? \@_decls : \@_stms}, # times.
			$_parser->{stm}{$_};
	}

	JE::Code::parse($_parser->{global}, @_);
}

sub eval {
	shift->parse(@_)->execute
}

#----------PARSER---------#

use Exporter 'import';

our @EXPORT_OK = qw/ $h $n $optional_sc $ss $s $S $id_cont
                     str num skip ident expr expr_noin statement
                     statements expected optional_sc/;
our @EXPORT_TAGS = (
	vars => [qw/ $h $n $optional_sc $ss $s $S $id_cont/],
	functions => [qw/ str num skip ident expr expr_noin statement
                          statements expected optional_sc /],
);

use re 'taint';
#use subs qw'statement statements assign assign_noin expr new';
use constant JECE => 'JE::Code::Expression';
use constant JECS => 'JE::Code::Statement';

require JE::String;
import JE::String 'desurrogify';
sub desurrogify($);


# die is called with a simple scalar when the string contains what  is
# expected. This will be converted to a longer message afterwards, which
# will read something like "Expected %s but found %s"  (probably the most
# common error message, which is why there is a shorthand).  The 'expected'
# function  takes  care  of  dying  without  the  'at ..., line ...'  being
# appended, even if there is no line break at the end. die is called with a 
# reference to a string if  the  string  is  the  complete  error  message.

# @ret != push @ret, ...  is a funny way of pushing and then checking to
# see whether anything was pushed.


sub expected($) { # public
	$@ = shift; local $@ = ''; die  # No, you can't really do this!
}


# public vars:

# optional horizontal comments and whitespace
our $h = qr(
	(?> [ \t\x0b\f\xa0\p{Zs}]* ) 
	(?> (?>/\*[^\cm\cj\x{2028}\x{2029}]*?\*/) [ \t\x0b\f\xa0\p{Zs}]* )?
)x;

# line terminators
our $n = qr((?>[\cm\cj\x{2028}\x{2029}]));

# single space char
our $ss = qr((?>[\p{Zs}\s\ck]));

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
	  \\u([0-9A-Fa-f]{4})
	    |
	  [\p{ID_Continue}\$_]
	)
)x;

# end public vars


sub str() { # public
	/\G (?: '((?>(?:[^'\\] | \\.)*))'
	          |
	        "((?>(?:[^"\\] | \\.)*))"  )/xcgs or return;

	no re 'taint'; # I need eval "qq-..." to work
	no warnings 'utf8'; # for surrogates
	(my $yarn = $+) =~ s/\\(?:
		u([0-9a-fA-F]{4})
		 |
		x([0-9a-fA-F]{2})
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
	JE::String->new($global, $yarn);
}

sub  num() { # public
	/\G (?:
	  0[Xx] ([A-Fa-f0-9]+)
	    |
	  (?=[0-9]|\.[0-9])
	  (
	    (?:0|[1-9][0-9]*)?
	    (?:\.[0-9]*)?
	    (?:[Ee][+-]?[0-9]+)?
	  )
	) /xcg
	or return;
	return JE::Number->new($global, defined $1 ? hex $1 : $2);
}

our $ident = qr(
          (?! (?: case | default )  (?!$id_cont) )
	  (?:
	    \\u[0-9A-Fa-f]{4}
	      |
	    [\p{ID_Start}\$_]
	  )
	  (?> $id_cont* )
)x;

sub unescape_ident($) {
	my $ident = shift;
	no warnings 'utf8';
	$ident =~ s/\\u([0-9a-fA-F]{4})/chr hex $1/ge;
	$ident = desurrogify $ident;
	$ident =~ /^[\p{ID_Start}\$_]
	            [\p{ID_Continue}\$_]*
	          \z/x
	  or die \"'$ident' is not a valid identifier";
	$ident;
}

 # public
sub skip() { /\G$s/go } # skip whitespace

sub ident() { # public
	return unless my($ident) = /\G($ident)/cgox;
	unescape_ident $ident;
}

sub params() { # Only called when we know we need it, which is why it dies
                # on the second line
	my @ret;
	/\G\(/gc or expected "'('";
	&skip;
	if (@ret != push @ret, &ident) { # first identifier (not prec.
	                               # by comma)
		while (/\G$s,$s/ogc) {
			# if there's a comma we need another ident
			@ret != push @ret, &ident or expected 'identifier';
		}
		&skip;
	}
	/\G\)/gc or expected "')'";
	\@ret;
}

sub term() {
	my $pos = pos;
	my $tmp;
	if(/\Gfunction(?!$id_cont)$s/cog) {
		my @ret = (func => ident);
		@ret == 2 and &skip;
		push @ret, &params;
		&skip;
		/\G \{ /gcx or expected "'{'";
		push @ret, &statements;
		/\G \} /gocx or expected "'}'";

		return bless [[$pos, pos], @ret], JECE;
	}
	elsif($tmp = &ident or defined($tmp = &str) or
	      defined($tmp = &num)) {
		if (!ref $tmp and $tmp =~ /^(?:(?:tru|fals)e|null)\z/) {
			$tmp = $tmp eq 'null' ?
				$global->null :
				JE::Boolean->new( $global, $tmp eq 'true');
		}
		return $tmp;
	}
	elsif(m-\G
		/
		( (?:[^/*\\] | \\.) (?>(?:[^/\\] | \\.)*) )
		/
	  	($id_cont*)
	      -cogx ) {

		#  I have to use local *_ because
		# 'require JE::Object::RegExp' causes
		#  Scalar::Util->import() to be called (import is inherited
		#  from Exporter), and  &Exporter::import does  'local $_',
		#  which,  in p5.8.8  (though not  5.9.5)  causes  pos()
		#  to be reset.
		{ local *_; require JE::Object::RegExp; }
		return JE::Object::RegExp->new( $global, $1, $2);
	}
	elsif(/\G\[$s/cog) {
		my $anon;
		my @ret;
		my $length;

		while () {
			@ret != ($length = push @ret, &assign) and &skip;
			push @ret, bless \$anon, 'comma' while /\G,$s/cog;
			$length == @ret and last;
		}

		/\G]/cg or expected "']'";
		return bless [[$pos, pos], array => @ret], JECE;
	}
	elsif(/\G\{$s/cog) {
		my @ret;

		# ~~~ This could be much more efficient if 'str' and 'num'
		#     did not have to create objects when called from here,
		#     since the objects are just stringified  in  the  end
		#     anyway (in &JE::Code::Expression::eval).

		if($tmp = &ident or defined($tmp = &str) or
				defined($tmp = &num)) {
			# first elem, not preceded by comma
			push @ret, $tmp;
			&skip;
			/\G:$s/coggg or expected 'colon';
			@ret != push @ret, &assign
				or expected \'expression';
			&skip;

			while (/\G,$s/cog) {
				$tmp = ident or defined($tmp = &str) or
					defined($tmp = &num)
				or expected
				 'identifier, or string or number literal';

				push @ret, $tmp;
				&skip;
				/\G:$s/coggg or expected 'colon';
				@ret != push @ret, &assign
					or expected 'expression';
				&skip;
			}
		}
		/\G}/cg or expected "'}'";
		return bless [[$pos, pos], hash => @ret], JECE;
	}
	elsif (/\G\($s/cog) {
		my $ret = &expr or expected 'expression';
		&skip;
		/\G\)/cg or expected "')'";
		return $ret;
	}
	return
}

sub subscript() { # skips leading whitespace
	my $pos = pos;
	my $subscript;
	if (/\G$s\[$s/cog) {
		$subscript = &expr or expected 'expression';
		&skip;
		/\G]/cog or expected "']'";
	}
	elsif (/\G$s\.$s/cog) {
		$subscript = &ident or expected 'identifier';
	} 
	else { return }

	return bless [[$pos, pos], $subscript], 'JE::Code::Subscript';
}

sub args() { # skips leading whitespace
	my $pos = pos;
	my @ret;
	/\G$s\($s/ogc or return;
	if (@ret != push @ret, &assign) { # first expression (not prec.
	                               # by comma)
		while (/\G$s,$s/ogc) {
			# if there's a comma we need another expression
			@ret != push @ret, &assign
				or expected 'expression';
		}
		&skip;
	}
	/\G\)/gc or expected "')'";
	return bless [[$pos, pos], @ret], 'JE::Code::Arguments';
}

sub new_expr() {
	/\G new(?!$id_cont) $s /cogx or return;
	my $ret = bless [[pos], 'new'], JECE;
	
	my $pos = pos;
	my @member_expr = &new_expr || &term
		|| expected "identifier, literal, 'new' or '('";

	0 while @member_expr != push @member_expr, &subscript;

	push @$ret, @member_expr == 1 ? @member_expr :
		bless [[$pos, pos], 'member/call', @member_expr],
		      JECE;
	push @$ret, args;
	$ret;
}

sub left_expr() {
	my($pos,@ret) = pos;
	@ret != push @ret, &new_expr || &term or return;

	0 while @ret != push @ret, &subscript, &args;
	@ret ? @ret == 1 ? @ret : 
		bless([[$pos, pos], 'member/call', @ret],
			JECE)
		: return;
}

sub postfix() {
	my($pos,@ret) = pos;
	@ret != push @ret, &left_expr or return;
	push @ret, $1 while /\G $h ( \+\+ | -- ) /cogx;
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
	@ret != push @ret, &postfix or (
		@ret
		? expected "expression"
		: return
	);
	@ret == 1 ? @ret : bless [[$pos, pos], 'prefix', @ret],
		JECE;
}

sub multi() {
	my($pos,@ret) = pos;
	@ret != push @ret, &unary or return;
	while(m-\G $s ( [*%](?!=) | / (?![*/=]) ) $s -cogx) {
		push @ret, $1;
		@ret == push @ret, &unary and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub add() {
	my($pos,@ret) = pos;
	@ret != push @ret, &multi or return;
	while(/\G $s ( \+(?![+=]) | -(?![-=]) ) $s /cogx) {
		push @ret, $1;
		@ret == push @ret, &multi and expected 'expression'
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bitshift() {
	my($pos,@ret) = pos;
	@ret == push @ret, &add and return;
	while(/\G $s (>>> | >>(?!>) | <<)(?!=) $s /cogx) {
		push @ret, $1;
		@ret == push @ret, &add and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub rel() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bitshift and return;
	while(/\G $s ( ([<>])(?!\2|=) | [<>]= |
	               in(?:stanceof)?(?!$id_cont) ) $s /cogx) {
		push @ret, $1;
		@ret== push @ret, &bitshift and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub rel_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bitshift and return;
	while(/\G $s ( ([<>])(?!\2|=) | [<>]= | instanceof(?!$id_cont) )
	          $s /cogx) {
		push @ret, $1;
		@ret == push @ret, &bitshift and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub equal() {
	my($pos,@ret) = pos;
	@ret == push @ret, &rel and return;
	while(/\G $s ([!=]==?) $s /cogx) {
		push @ret, $1;
		@ret == push @ret, &rel and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub equal_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &rel_noin and return;
	while(/\G $s ([!=]==?) $s /cogx) {
		push @ret, $1;
		@ret == push @ret, &rel_noin and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_and() {
	my($pos,@ret) = pos;
	@ret == push @ret, &equal and return;
	while(/\G $s &(?![&=]) $s /cogx) {
		@ret == push @ret, '&', &equal and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_and_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &equal_noin and return;
	while(/\G $s &(?![&=]) $s /cogx) {
		@ret == push @ret, '&', &equal_noin
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_or() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_and and return;
	while(/\G $s \|(?![|=]) $s /cogx) {
		@ret == push @ret, '|', &bit_and and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_or_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_and_noin and return;
	while(/\G $s \|(?![|=]) $s /cogx) {
		@ret == push @ret, '|', &bit_and_noin
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_xor() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_or and return;
	while(/\G $s \^(?!=) $s /cogx) {
		@ret == push @ret, '^', &bit_or and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_xor_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_or_noin and return;
	while(/\G $s \^(?!=) $s /cogx) {
		@ret == push @ret, '^', &bit_or_noin
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub and_expr() { # If I just call it 'and', then I have to write
                 # CORE::and for the operator! (Far too cumbersome.)
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_xor and return;
	while(/\G $s && $s /cogx) {
		@ret == push @ret, '&&', &bit_xor
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub and_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_xor_noin and return;
	while(/\G $s && $s /cogx) {
		@ret == push @ret, '&&', &bit_xor_noin
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub or_expr() {
	my($pos,@ret) = pos;
	@ret == push @ret, &and_expr and return;
	while(/\G $s \|\| $s /cogx) {
		@ret == push @ret, '||', &and_expr
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub or_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &and_noin and return;
	while(/\G $s \|\| $s /cogx) {
		@ret == push @ret, '||', &and_noin
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub assign() {
	my($pos,@ret) = pos;
	@ret == push @ret, &or_expr and return;
	while(m@\G $s ((?>(?: [-*/%+&^|] | << | >>>? )?)=) $s @cogx) {
		push @ret, $1;
		@ret == push @ret, &or_expr and expected 'expression';
	}
	if(/\G$s\?$s/cog) {
		@ret == push @ret, &assign and expected 'expression';
		&skip;
		/\G:$s/cog or expected "colon";
		@ret == push @ret, &assign and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'assign', @ret],
		JECE;
}

sub assign_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &or_noin and return;
	while(m~\G $s ((?>(?: [-*/%+&^|] | << | >>>? )?)=) $s ~cogx) {
		push @ret, $1;
		@ret == push @ret, &or_noin and expected 'expression';
	}
	if(/\G$s\?$s/cog) {
		@ret == push @ret, &assign and expected 'expression';
		&skip;
		/\G:$s/cog or expected "colon";
		@ret == push @ret, &assign_noin and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'assign', @ret],
		JECE;
}

sub expr() { # public
	my $ret = bless [[pos], 'expr'], JECE;
	@$ret == push @$ret, &assign and return;
	while(/\G$s,$s/cog) {
		@$ret == push @$ret,& assign and expected 'expression';
	}
	push @{$$ret[0]},pos;
	$ret;
}

sub expr_noin() { # public
	my $ret = bless [[pos], 'expr'], JECE;
	@$ret == push @$ret, &assign_noin and return;
	while(/\G$s,$s/cog) {
		@$ret == push @$ret, &assign_noin
			and expected 'expression';
	}
	push @{$$ret[0]},pos;
	$ret;
}

sub vardecl() { # vardecl is only called when we *know* we need it, so it
                # will die when it can't get the first identifier, instead
                # of returning undef
	my @ret;
	@ret == push @ret, &ident and expected 'identifier';
	/\G$s=$s/cog and
		(@ret != push @ret, &assign or expected 'expression');
	\@ret;
}

sub vardecl_noin() {
	my @ret;
	@ret == push @ret, &ident and expected 'identifier';
	/\G$s=$s/cog and
		(@ret != push @ret, &assign_noin or expected 'expression');
	\@ret;
}

sub finish_for_sc_sc() {  # returns the last two expressions of a for (;;)
                          # loop header
	my @ret;
	my $msg;
	if(@ret != push @ret, expr) {
		$msg = '';
		&skip
	} else {
		push @ret, 'empty';
		$msg = 'expression or '
	}
	/\G;$s/cog or expected "${msg}semicolon";
	if(@ret != push @ret, expr) {
		$msg = '';
		&skip
	} else {
		push @ret, 'empty';
		$msg = 'expression or '
	}
	/\G\)$s/cog or expected "${msg}')'";

	@ret;
}

# ----------- Statement types ------------ #
#        (used by custom parsers)

our $optional_sc = # public
		qr-\G (?:
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
		)-x;

sub optional_sc() {
	/$optional_sc/gc or expected "semicolon, '}' or end of line";
}

sub block() {
	/\G\{/gc or return;
	my $ret = [[pos()-1], 'statements'];
	&skip;
	while() { # 'last' does not work when 'while' is a
	         # statement modifier
		@$ret == push @$ret, &statement and last;
	}
	expected "'}'" unless /\G\}$s/goc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub empty() {
	my $pos = pos;
	/\G;$s/cog or return;
	bless [[$pos,pos], 'empty'], JECS;
}

sub function() {
	my $pos = pos;
	/\Gfunction$S/cog or return;
	my $ret = [[$pos], 'function'];
	@$ret == push @$ret, &ident
		and expected "identifier";
	&skip;
	push @$ret, &params;
	&skip;
	/\G \{ /gcx or expected "'{'";
	push @$ret, &statements;
	/\G \}$s /gocx or expected "'}'";

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub if() {
	my $pos = pos;
	/\Gif$s\($s/cog or return;
	my $ret = [[$pos], 'if'];

	@$ret == push @$ret, &expr
		and expected 'expression';
	&skip;
	/\G\)$s/goc or expected "')'";
	@$ret != push @$ret, &statement
		or expected 'statement';
	if (/\Gelse(?!$id_cont)$s/cog) {
		@$ret == push @$ret, &statement
			and expected 'statement';
	}

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub while() {
	my $pos = pos;
	/\Gwhile$s\($s/cog or return;
	my $ret = [[$pos], 'while'];

	@$ret == push @$ret, &expr
		and expected 'expression';
	&skip;
	/\G\)$s/goc or expected "')'";
	@$ret != push @$ret, &statement
		or expected 'statement';

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub for() {
	my $pos = pos;
	/\Gfor$s\($s/cog or return;
	my $ret = [[$pos], 'for'];

	if (/\G var$S/cogx) {
		push @$ret, my $var = bless
			[[pos() - length $1], 'var'],
			'JE::Code::Statement';

		push @$var, &vardecl_noin;
		&skip;
		if (/\G([;,])$s/ogc) {
			# if there's a comma or sc then
			# this is a for(;;) loop
			if ($1 eq ',') {
				# finish getting the var
				# decl list
				do{
				    @$var ==
				    push @$var, &vardecl 
				    and expected
				      'identifier'
				} while (/\G$s,$s/ogc);
				&skip;
				/\G;$s/cog
				   or expected 'semicolon';
			}
			push @$ret, &finish_for_sc_sc;
		}
		else {
			/\Gin$s/cog or expected
			    "'in', comma or semicolon";
			push @$ret, 'in';
			@$ret == push @$ret, &expr
				and expected 'expresssion';
			&skip;
			/\G\)$s/cog or expected "')'";
		}
	}
	elsif(@$ret != push @$ret, &expr_noin) {
		&skip;
		if (/\G;$s/ogc) {
			# if there's a semicolon then
			# this is a for(;;) loop
			push @$ret, &finish_for_sc_sc;
		}
		else {
			/\Gin$s/cog or expected
				"'in' or semicolon";
			push @$ret, 'in';
			@$ret == push @$ret, &expr
				and expected 'expresssion';
			&skip;
			/\G\)$s/cog or expected "')'";
		}
	}
	else {
		push @$ret, 'empty';
		/\G;$s/cog
		    or expected 'expression or semicolon';
		push @$ret, &finish_for_sc_sc;
	}

	# body of the for loop
	@$ret != push @$ret, &statement
		or expected 'statement';

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub with() { # almost identical to while
	my $pos = pos;
	/\Gwith$s\($s/cog or return;
	my $ret = [[$pos], 'with'];

	@$ret == push @$ret, &expr
		and expected 'expression';
	&skip;
	/\G\)$s/goc or expected "')'";
	@$ret != push @$ret, &statement
		or expected 'statement';

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub switch() {
	my $pos = pos;
	/\Gswitch$s\($s/cog or return;
	my $ret = [[$pos], 'switch'];

	@$ret == push @$ret, &expr
		 and expected 'expression';
	&skip;
	/\G\)$s/goc or expected "')'";
	/\G\{$s/goc or expected "'{'";

	while (/\G case(?!$id_cont) $s/cogx) {
		@$ret == push @$ret, &expr
			and expected 'expression';
		&skip;
		/\G:$s/cog or expected 'colon';
		push @$ret, &statements;
	}
	my $default=0;
	if (/\G default(?!$id_cont) $s/cogx) {
		/\G : $s /cgox or expected 'colon';
		push @$ret, default => &statements;
		++$default;
	}
	while (/\G case(?!$id_cont) $s/cogx) {
		@$ret == push @$ret, &expr
			and expected 'expression';
		&skip;
		/\G:$s/cog or expected 'colon';
		push @$ret, &statements;
	}
	/\G \} $s /cgox or expected (
		$default
		? "'}' or 'case'"
		: "'}', 'case' or 'default'"
	); 

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub try() {
	my $pos = pos;
	/\Gtry$s\{$s/cog or return;
	my $ret = [[$pos], 'try', &statements];

	/\G \} $s /cgox or expected "'}'";

	$pos = pos;

	if(/\Gcatch$s/cgo) {
		/\G \( $s /cgox or expected "'('";
		@$ret == push @$ret, &ident
			and expected 'identifier';
		&skip;
		/\G \) $s /cgox or expected "')'";

		/\G \{ $s /cgox or expected "'{'";
		push @$ret, &statements;
		/\G \} $s /cgox or expected "'}'";
	}
	if(/\Gfinally$s/cgo) {
		/\G \{ $s /cgox or expected "'{'";
		push @$ret, &statements;
		/\G \} $s /cgox or expected "'}'";
	}

	pos eq $pos and expected "'catch' or 'finally'";

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub labelled() {
	my $pos = pos;
	/\G ($ident) $s : $s/cogx or return;
	my $ret = [[$pos], 'labelled', unescape_ident $1];

	while (/\G($ident)$s:$s/cog) {
		push @$ret, unescape_ident $1;
	}
	@$ret != push @$ret, &statement
		or expected 'statement';

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub var() {
	my $pos = pos;
	/\G var $S/cogx or return;
	my $ret = [[$pos], 'var'];

	do{
		push @$ret, &vardecl;
	} while(/\G$s,$s/ogc);

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub do() {
	my $pos = pos;
	/\G do(?!$id_cont)$s/cogx or return;
	my $ret = [[$pos], 'do'];

	@$ret != push @$ret, &statement
		or expected 'statement';
	/\Gwhile$s/cog               or expected "'while'";
	/\G\($s/cog                or expected "'('";
	@$ret != push @$ret, &expr
		or expected 'expression';
	&skip;
	/\G\)/cog or expected "')'";

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub continue() {
	my $pos = pos;
	/\G continue(?!$id_cont)/cogx or return;
	my $ret = [[$pos], 'continue'];

	/\G$h($ident)/cog
		and push @$ret, unescape_ident $1;

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub break() { # almost identical to continue
	my $pos = pos;
	/\G break(?!$id_cont)/cogx or return;
	my $ret = [[$pos], 'break'];

	/\G$h($ident)/cog
		and push @$ret, unescape_ident $1;

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub return() {
	my $pos = pos;
	/\G return(?!$id_cont)/cogx or return;
	my $ret = [[$pos], 'return'];

	$pos = pos;
	/\G$h/g; # skip horz ws
	@$ret == push @$ret, &expr and pos = $pos;
		# reverse to before the white space if
		# there is no expr

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub throw() {
	my $pos = pos;
	/\G throw(?!$id_cont)/cogx
	        or return; 
	my $ret = [[$pos], 'throw'];

	/\G$h/g; # skip horz ws
	@$ret == push @$ret, &expr and expected 'expression';

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub expr_statement() {
	my $ret = &expr or return;
	optional_sc; # the only difference in behaviour between
	             # this and &expr
	$ret;
}



# -------- end of statement types----------#

# This takes care of trailing white space.
sub statement_default() {
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
			&skip;
			while() { # 'last' does not work when 'while' is a
			         # statement modifier
				@$ret == push @$ret, 
					&statement_default and last;
			}
			
			expected "'}'" unless /\G\}$s/goc;
		}
		elsif($1 eq ';') {
			push @$ret, 'empty';
			&skip;
		}
		elsif($2) {
			push @$ret, 'function';
			@$ret == push @$ret, &ident
				and expected "identifier";
			&skip;
			push @$ret, &params;
			&skip;
			/\G \{ /gcx or expected "'{'";
			push @$ret, &statements;
			/\G \}$s /gocx or expected "'}'";
		}
		elsif($3 eq 'if') {
			push @$ret, 'if';
			@$ret == push @$ret, &expr
				and expected 'expression';
			&skip;
			/\G\)$s/goc or expected "')'";
			@$ret != push @$ret, &statement_default
				or expected 'statement';
			if (/\Gelse(?!$id_cont)$s/cog) {
				@$ret == push @$ret, 
					&statement_default
					and expected 'statement';
			}
		}
		elsif($3 eq 'while') {
			push @$ret, 'while';
			@$ret == push @$ret, &expr
				and expected 'expression';
			&skip;
			/\G\)$s/goc or expected "')'";
			@$ret != push @$ret, &statement_default
				or expected 'statement';
		}
		elsif($3 eq 'for') {
			push @$ret, 'for';
			if (/\G var$S/cogx) {
				push @$ret, my $var = bless
					[[pos() - length $1], 'var'],
					'JE::Code::Statement';

				push @$var, &vardecl_noin;
				&skip;
				if (/\G([;,])$s/ogc) {
					# if there's a comma or sc then
					# this is a for(;;) loop
					if ($1 eq ',') {
						# finish getting the var
						# decl list
						do{
						    @$var ==
						    push @$var, &vardecl 
						    and expected
						      'identifier'
						} while (/\G$s,$s/ogc);
						&skip;
						/\G;$s/cog
						   or expected 'semicolon';
					}
					push @$ret, &finish_for_sc_sc;
				}
				else {
					/\Gin$s/cog or expected
					    "'in', comma or semicolon";
					push @$ret, 'in';
					@$ret == push @$ret, &expr
						and expected 'expresssion';
					&skip;
					/\G\)$s/cog or expected "')'";
				}
			}
			elsif(@$ret != push @$ret, &expr_noin) {
				&skip;
				if (/\G;$s/ogc) {
					# if there's a semicolon then
					# this is a for(;;) loop
					push @$ret, &finish_for_sc_sc;
				}
				else {
					/\Gin$s/cog or expected
						"'in' or semicolon";
					push @$ret, 'in';
					@$ret == push @$ret, &expr
						and expected 'expresssion';
					&skip;
					/\G\)$s/cog or expected "')'";
				}
			}
			else {
				push @$ret, 'empty';
				/\G;$s/cog
				    or expected 'expression or semicolon';
				push @$ret, &finish_for_sc_sc;
			}

			# body of the for loop
			@$ret != push @$ret, &statement_default
				or expected 'statement';
		}
		elsif($3 eq 'with') {
			push @$ret, 'with';
			@$ret == push @$ret, &expr
				and expected 'expression';
			&skip;
			/\G\)$s/goc or expected "')'";
			@$ret != push @$ret, &statement_default
				or expected 'statement';
		}
		elsif($3 eq 'switch') {
			push @$ret, 'switch';
			@$ret == push @$ret, &expr
				 and expected 'expression';
			&skip;
			/\G\)$s/goc or expected "')'";
			/\G\{$s/goc or expected "'{'";

			while (/\G case(?!$id_cont) $s/cogx) {
				@$ret == push @$ret, &expr
					and expected 'expression';
				&skip;
				/\G:$s/cog or expected 'colon';
				push @$ret, &statements;
			}
			my $default=0;
			if (/\G default(?!$id_cont) $s/cogx) {
				/\G : $s /cgox or expected 'colon';
				push @$ret, default => &statements;
				++$default;
			}
			while (/\G case(?!$id_cont) $s/cogx) {
				@$ret == push @$ret, &expr
					and expected 'expression';
				&skip;
				/\G:$s/cog or expected 'colon';
				push @$ret, &statements;
			}
			/\G \} $s /cgox or expected (
				$default
				? "'}' or 'case'"
				: "'}', 'case' or 'default'"
			); 
		}
		elsif($4) { # try
			push @$ret, 'try', &statements;
			/\G \} $s /cgox or expected "'}'";

			my $pos = pos;

			if(/\Gcatch$s/cgo) {
				/\G \( $s /cgox or expected "'('";
				@$ret == push @$ret, &ident
					and expected 'identifier';
				&skip;
				/\G \) $s /cgox or expected "')'";

				/\G \{ $s /cgox or expected "'{'";
				push @$ret, &statements;
				/\G \} $s /cgox or expected "'}'";
			}
			if(/\Gfinally$s/cgo) {
				/\G \{ $s /cgox or expected "'{'";
				push @$ret, &statements;
				/\G \} $s /cgox or expected "'}'";
			}

			pos eq $pos and expected "'catch' or 'finally'";
		}
		else { # labelled statement
			push @$ret, 'labelled', unescape_ident $5;
			while (/\G($ident)$s:$s/cog) {
				push @$ret, unescape_ident $1;
			}
			@$ret != push @$ret, &statement_default
				or expected 'statement';
		}
	}
	# Statements that do have an optional semicolon
	else {
		if (/\G var$S/xcog) {
			push @$ret, 'var';

			do{
				push @$ret, &vardecl;
			} while(/\G$s,$s/ogc);
		}
		elsif(/\Gdo(?!$id_cont)$s/cog) {
			push @$ret, 'do';
			@$ret != push @$ret, &statement_default
				or expected 'statement';
			/\Gwhile$s/cog               or expected "'while'";
			/\G\($s/cog                or expected "'('";
			@$ret != push @$ret, &expr
				or expected 'expression';
			&skip;
			/\G\)/cog or expected "')'";
		}
		elsif(/\G(continue|break)(?!$id_cont)/cog) {
			push @$ret, $1;
			/\G$h($ident)/cog
				and push @$ret, unescape_ident $1;
		}
		elsif(/\Greturn(?!$id_cont)/cog) {
			push @$ret, 'return';
			my $pos = pos;
			/\G$h/g; # skip horz ws
			@$ret == push @$ret, &expr and pos = $pos;
				# reverse to before the white space if
				# there is no expr
		}
		elsif(/\Gthrow(?!$id_cont)/cog) {
			push @$ret, 'throw';
			/\G$h/g; # skip horz ws
			@$ret == push @$ret, &expr
				and expected 'expression';
		}
		else { # expression statement
			$ret = &expr or return;
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
		)-cogx or expected "semicolon, '}' or end of line";
	}
	push @{$$ret[0]},pos unless @{$$ret[0]} == 2; # an expr will 
	                                             # already have this

	ref $ret eq 'ARRAY' and bless $ret, 'JE::Code::Statement';

	return $ret;
}

sub statement() { # public
	my $ret;
	for my $sub(@_stms) {
		defined($ret = &$sub)
			and last;
	}
	defined $ret ? $ret : ()
}

# This takes care of leading white space.
sub statements() {
	my $ret = bless [[pos], 'statements'], 'JE::Code::Statement';
	/\G$s/go; # skip initial whitespace
	while () { # 'last' does not work when 'while' is a
	           # statement modifier
		@$ret != push @$ret,
			$_parser ? &statement : &statement_default
			or last;
	}
	push @{$$ret[0]},pos;
	return $ret;
}

sub program() { # like statements(), but it allows function declarations
                # as well
	my $ret = bless [[pos], 'statements'], 'JE::Code::Statement';
	/\G$s/go; # skip initial whitespace
	if($_parser) {
		while () {	
			DECL: {
				for my $sub(@_decls) {
					@$ret != push @$ret, &$sub
						and redo DECL;
				}
			}
			@$ret != push @$ret, &statement or last;
		}
	}
	else {
		while () {	
			while() {
				@$ret == push @$ret, &function and last;
			}
			@$ret != push @$ret, &statement_default or last;
		}
	}
	push @{$$ret[0]},pos;
	return $ret;
}


# ~~~ The second arg to add_line_number is a bit ridiculous. I may change
#     add_line_number's parameter list, perhaps so it accepts either a
#     code object, or (src,file,line) if $_[1] isn'ta JE::Code. I don't
#     know....
sub _parse($$$;$$) { # Returns just the parse tree, not a JE::Code object.
                     # Actually,  it returns the source followed  by  the
                     # parse tree in list context, or just the parse tree
                     # in scalar context.
	my ($rule, $src, $my_global, $file, $line) = @_;

	$src = "$src"; # We *hafta* stringify it, because it could be an
	               # object with overloading  (e.g., JE::String)  and
	               # we need to rely on its pos(), which simply cannot
	               # be done with an  object.  Furthermore,  perl5.8.5
	               # is a bit buggy and sometimes mangles the contents
	               # of $1 when one does $obj =~ /(...)/.

	# remove unicode format chrs
	$src =~ s/\p{Cf}//g;

	my $tree;
	for($src) {
		pos = 0;
		eval {
			local $global = $my_global;
			$tree = (\&$rule)->();
			!defined pos or pos == length 
			   or expected 'statement or function declaration';
		};
		if(ref $@ ne '') {
			ref $@ eq 'SCALAR' or die;
			defined blessed $@ and die;
			$@ = JE::Object::Error::SyntaxError->new(
				$my_global,
				add_line_number(
				    ${$@},	
				   {file=>$file,line=>$line,source=>\$src},
				     pos)
			);
		}
		elsif($@ =~ /\n\z/) { die }
		elsif($@) {
			$@ = JE::Object::Error::SyntaxError->new(
				$my_global,
			# ~~~ This should perhaps show more context
				add_line_number
				    "Expected $@ but found '".
				    substr($_, pos, 10) . "'",
				   {file=>$file,line=>$line,source=>\$src},
				     pos
			);
			return;
		}
	}
#use Data::Dumper;
#print Dumper $tree;
	$src, $tree;
}



#----------DOCS---------#

!!!0;

=head1 NAME

JE::Parser - Framework for customising JE's parser

=cut

# Actually, this *is* JE's parser. But since JE::Parser's methods are never
# used directly with the default parser, I think it's actually less confus-
# ing to call it this.

=head1 SYNOPSIS

  use JE;
  use JE::Parser;

  $je = new JE;
  $p = new JE::Parser $je; # or: $p = $je->new_parser

  $p->delete_statement('for', 'while', 'do'); # disable loops
  $p->add_statement(try => \&parser); # replace existing 'try' statement

=head1 DESCRIPTION

This allows one to change the list of statement types that the parser
looks for. For instance, one could disable loops for a mini-JavaScript, or
add extensions to the language, such as the 'catch-if' clause of a C<try> 
statement.

As yet, C<delete_statement> works, but I've not finished
designing the API for C<add_statement>. Currently, JavaScript's C<eval>
function always uses the default parser, which will be fixed.

I might provide an API for extending expressions, if I can resolve the
complications caused by the 'new' operator. If anyone else wants to have a
go at it, be my guest. :-)

=head1 METHODS

=over 4

=item $p = new JE::Parser

Creates a new parser object.

=item $p->add_statement($name, \&parser);

This adds a new statement (source element, to be precise) type 
to the
list of statements types the parser supports. If a statement type called 
C<$name> already exists, it will be replaced.
Otherwise, the new statement type will be added to the top of the list.

(C<$name> ought to be optional; it should only be necessary if one wants to 
delete 
it
afterwards or rearrange the list.)

If the name of a statement type begins with a hyphen, it is only allowed at
the 'program' level, not within compound statements. Function declarations
use this. Maybe this
convention is too unintuitive.... (Does anyone think I should change it?
What should I change it too?)

C<&parser> will need to parse code contained in C<$_> starting at C<pos()>, then either
return an object, list or coderef (see below)
and set C<pos()> to the position of the next token[1], or, if it 
could not
parse anything, return undef and reset C<pos()> to its initial value if it
changed.

[1] I.e., it is expected to move C<pos> past any trailing whitespace.

The return value of C<&parser> can be one of the following:

=over 4

=item 1)

An object with an C<eval> method, that will execute the statement, and/or 
an C<init> method, which will be called
before the code runs.

=item 2)

B<(Not yet 
supported!)> A coderef, which will be called when the code is executed.

=item 3)

B<(Not yet 
supported.)> A hash-style list, the two keys being C<eval> and C<init> 
(corresponding to
the methods under item 1) and the values being coderefs; i.e.:

  ( init => \&init_sub, eval => \&eval_sub )

=back

Maybe we need support for a JavaScript function to be called to handnle the
statement.

=item $p->delete_statement(@names);

Deletes the given statement types and returns C<$p>.

=item $p->statement_list

B<(Not yet implemented.)>

Returns an array ref of the names of the various statement types. You can 
rearrange this
list, but it is up to you to make sure you do not add to it any statement
types that have not been added via C<add_statement> (or were not there by
default). The statement types in the list will be tried in order, except
that items beginning with a hyphen always come before other items.

The default list is C<qw/-function block empty if while with for switch try
labelled var do continue break return throw expr/>

=item $p->parse($code)

Parses the C<$code> and returns a parse tree (JE::Code object).

=item $p->eval($code)

Shorthand for $p->parse($code)->execute;

=back

=head1 EXPORTS

None by default. You may choose to export the following:

=head2 Exported Variables

... blah blah blah ...

=head2 Exported Functions

These all have C<()> for their prototype, except for C<expected> which has
C<($)>.

... blah blah blah ...

=head1 SYNTAX ERRORS

(To be written)

  expected 'aaaa'; # will be changed to 'Expected aaaa but found....'
  die \"You can't put a doodad after a frombiggle!"; # complete message
  die 'aoenstuhoeanthu'; # big no-no (the error is propagated)

=head1 EXAMPLES

=head2 Mini JavaScript

This is an example of a mini JavaScript that does not allow loops or the
creation of functions.

  use JE;
  $j = new JE;
  $p = $j->new_parser;
  $p->delete_statement('for','while','do','-function');

Since function expressions could still create functions, we need to remove
the Function prototype object. Someone might then try to put it back with
C<Function = parseInt.constructor>, so we'll overwrite Function with an
undeletable read-only undefined property.

  $j->prop({ name     => 'Function',
             value    => undef,
             readonly => 1,
             dontdel  => 1 });

Then, after this, we call C<< $p->eval('...') >> to run JS code.

=head2 Perl-style for(LIST) loop

Well, after writing this example, it seems to me this API is not 
sufficient....

This example doesn't actually work yet.

  use JE;
  use JE::Parser qw'$s ident expr statement expected';
  
  $j = new JE;
  $p = $j->new_parser;
  $p->add_statement('for-list',
      sub {
          /\Gfor$s/cog or return;
          my $loopvar = ident or return;
          /\G$s\($s/cog or return;
          my @expressions;
          do {
              # This line doesn't actually work properly because
              # 'expr' will gobble up all the commas
              @expressions == push @expressions, expr
                  and return; # If nothing gets pushed on  to  the
                              # list,  we need to give the default
                              # 'for' handler a chance, instead of
                              # throwing an error.
          } while /\G$s,$s/cog;
          my $statement = statement or expected 'statement';
          return bless {
              var => $loopvar,
              expressions => \@expressions,
              statement => $statement
          }, 'Local::JEx::ForList';
      }
  );
  
  package Local::JEx::ForList;
  
  sub eval {
      my $self = shift;
      local $JE::Code::scope =
          bless [@$JE::Code::scope], 'JE::Scope';
          # I've got to come up with a better interface than this.
      my $obj = $JE::Code::global->eval('new Object');
      push @$JE::Code::scope, $obj;

      for (@{$self->{expressions}}) {
          $obj->{ $self->{loopvar} } = $_->eval;
          $self->{statement}->execute;
      }
  }

=head1 SEE ALSO

L<JE> and L<JE::Code>.

=cut




