package JE::Code;

our $VERSION = '0.002';

use strict;
use warnings;

no warnings 'regexp';

# There is a bug in perl 5.8.8 that causes erroneous regexp warnings to
# appear. When I run
#         perl -lwe '$_ = "aoeu"; /(??{"."})+/ and print "$&"'
# it produces
#         (??{"."})+ matches null string many times in regex; marked by <-- HERE in m/(??{"."})+ <-- HERE / at -e line 1.
#         aoeu


use Data::Dumper;

require JE::Object::Array;
require JE::Boolean;
require JE::Object;
require JE::String;
require JE::Number;
require JE::LValue;
require JE::Scope;



our @A;  # accumulator (named after $^A)

 # regexps
our($_re_h,     $_re_n,          $_re_ss,        $_re_s,     $_re_S,        
   $_re_id_cont, $_re_ident,      $_re_str,       $_re_num,
  $_re_params,    $_re_term,       $_re_subscript, $_re_args,    
 $_re_left_expr,   $_re_postfix,    $_re_unary,     $_re_multi,
$_re_add,           $_re_bitshift,   $_re_rel,       $_re_rel_noin,
 $_re_equal,         $_re_equal_noin, $_re_bit_and,   $_re_bit_and_noin,
  $_re_bit_or,      $_re_bit_or_noin,  $_re_bit_xor,   $_re_bit_xor_noin,
   $_re_and,       $_re_and_noin,       $_re_or,        $_re_or_noin,
    $_re_cond,    $_re_cond_noin,        $_re_assign,    $_re_assign_noin,
     $_re_expr,  $_re_expr_noin,          $_re_statement, $_re_statements,
      $_re_var_decl_list);


# To edit these Hairy Regular Expressions, look at the file called 
# 'regexps' included in this distribution.
{ use re qw'eval taint';
#--BEGIN--

$_re_h=qr((?>[ \t\x0b\f\xa0\p{Zs}]*)(?>(?>/\*[^\cm\cj\x{2028}\x{2029}]*?\*/)[ \t\x0b\f\xa0\p{Zs}]*)?)x;$_re_n=qr((?>[\cm\cj\x{2028}\x{2029}]));$_re_ss=qr([ \t\x0b\f\xa0\p{Zs}\cm\cj\x{2028}\x{2029}]);$_re_s=qr((?>(??{$_re_ss})*)(?>(?>//[^\cm\cj\x{2028}\x{2029}]*|/\*.*?\*/)(?>(??{$_re_ss})*))?)sx;$_re_S=qr((?>(??{$_re_ss})|//[^\cm\cj\x{2028}\x{2029}]*|/\*.*?\*/)(??{$_re_s}))xs;$_re_id_cont=qr((?>\\u([\dA-Fa-f]{4})|[\p{ID_Continue}\$_]))x;$_re_ident=qr((?{push@A,[begin=>ident=>pos]})(?:\\u([\dA-Fa-f]{4})|[\p{ID_Start}\$_])(?>(??{$_re_id_cont})*)(?{push@A,[end=>ident=>pos]}))x;$_re_str=qr((?>'(?{push@A,[begin=>str=>pos]})(?>(?s:[^'\\]|\\.)*)(?{push@A,[end=>'',pos]})'|"(?{push@A,[begin=>str=>pos]})(?>(?s:[^"\\]|\\.)*)(?{push@A,[end=>'',pos]})"))x;$_re_num=qr((?>(?{push@A,[begin=>num=>pos]})(?>(?=\d|\.\d)(?:0|[1-9]\d*)?(?:\.\d*)?(?:[Ee][+-]?\d+)?)(?{push@A,[end=>num=>pos]})|0(?>[Xx])(?{push@A,[begin=>hex=>pos]})(?>[A-Fa-f\d]+)(?{push@A,[end=>'',pos]})))x;$_re_params=qr{(?{push@A,[begin=>params=>pos]})\((??{$_re_s})(?>(?:(??{$_re_ident})(??{$_re_s})(?>(?:,(??{$_re_s})(??{$_re_ident})(??{$_re_s}))*))?)\)(?{push@A,[end=>params=>pos]})}x;$_re_term=qr`(?>function(?!(??{$_re_id_cont}))(?{push@A,[begin=>func=>pos]})(??{$_re_s})(?>(?:(??{$_re_ident})(??{$_re_s}))?)(??{$_re_params})(??{$_re_s})\{(??{$_re_statements})\}(?{push@A,[end=>'',pos]})|(??{$_re_ident})|(??{$_re_str})|(??{$_re_num})|/(?{push@A,[begin=>re=>pos]})(?:[^/*\\]|\\.)(?>(?:[^/\\]|\\.)*)/(?>(??{$_re_id_cont})*)(?{push@A,[end=>'',pos]})|\[ (?{push@A,[begin=>array=>pos]})(??{$_re_s})(?>(??{$_re_assign})?)(?>(?:,(?{push@A,[comma=>pos]})(??{$_re_s})(?>(?:(??{$_re_assign})(??{$_re_s}))?))*)(?{push@A,[end=>'',pos]})\]|\{(?{push@A,[begin=>hash=>pos]})(??{$_re_s})(?>(?:(?>(??{$_re_ident})|(??{$_re_str})|(??{$_re_num}))(??{$_re_s}):(??{$_re_assign})(??{$_re_s})(?>(?:,(??{$_re_s})(?>(??{$_re_ident})|(??{$_re_str})|(??{$_re_num}))(??{$_re_s}):(??{$_re_assign})(??{$_re_s}))*))?)(?{push@A,[end=>'',pos]})\}|\((??{$_re_expr})\))`x;$_re_subscript=qr((?>\[ (?{push@A,[begin=>subscript=>pos]})(??{$_re_s})(??{$_re_expr})(??{$_re_s})(?{push@A,[end=>'',pos]})]|\.(?{push@A,[begin=>prop=>pos]})(??{$_re_s})(??{$_re_ident})(?{push@A,[end=>'',pos]})))x;$_re_args=qr#\((?{push@A,[begin=>args=>pos]})(??{$_re_s})(?>(?:(??{$_re_assign})(??{$_re_s})(?>(?:,(??{$_re_s})(??{$_re_assign})(??{$_re_s}))*))?)\)(?{push@A,[end=>'',pos]})#x;$_re_left_expr=qr((?{push@A,[begin=>leftexpr=>pos]})(?>(?:new(?!(??{$_re_id_cont}))(?{push@A,[new=>pos]})(??{$_re_s}))*)(??{$_re_term})(?>(?:(??{$_re_s})(?>(??{$_re_subscript})|(??{$_re_args})))*)(?{push@A,[end=>leftexpr=>pos]}))x;$_re_postfix=qr/(?{push@A,[begin=>postfix=>pos]})(??{$_re_left_expr})(?>(?:(??{$_re_h})(?{push@A,[begin=>post=>pos]})(?>\+\+|\-\-)(?{push@A,[end=>post=>pos]}))?)(?{push@A,[end=>'',pos]})/x;$_re_unary=qr((?{push@A,[begin=>prefix=>pos]})(?>(?:(?{push@A,[begin=>pre=>pos]})(?>(?:delete|void|typeof)(?!(??{$_re_id_cont}))|\+\+?|--?|~|!)(?{push@A,[end=>'',pos]})(??{$_re_s}))*)(??{$_re_postfix})(?{push@A,[end=>'',pos]}))x;$_re_multi=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_unary})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})(?>[*/%])(?!=)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_unary}))*)(?{push@A,[end=>'',pos]}))x;$_re_add=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_multi})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})(?>[+-])(?!=)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_multi}))*)(?{push@A,[end=>'',pos]}))x;$_re_bitshift=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_add})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})(?>>>>?|<<)(?!=)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_add}))*)(?{push@A,[end=>'',pos]}))x;$_re_rel=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_bitshift})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})(?>[<>]=?|in(?:stanceof)?)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_bitshift}))*)(?{push@A,[end=>'',pos]}))x;$_re_rel_noin=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_bitshift})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})(?>[<>]=?|instanceof)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_bitshift}))*)(?{push@A,[end=>'',pos]}))x;$_re_equal=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_rel})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})(?>[!=]==?)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_rel}))*)(?{push@A,[end=>'',pos]}))x;$_re_equal_noin=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_rel_noin})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})(?>[!=]==?)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_rel_noin}))*)(?{push@A,[end=>'',pos]}))x;$_re_bit_and=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_equal})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})&(?!=)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_equal}))*)(?{push@A,[end=>'',pos]}))x;$_re_bit_and_noin=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_equal_noin})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})&(?!=)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_equal_noin}))*)(?{push@A,[end=>'',pos]}))x;$_re_bit_or=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_bit_and})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})\^(?!=)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_bit_and}))*)(?{push@A,[end=>'',pos]}))x;$_re_bit_or_noin=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_bit_and_noin})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})\^(?!=)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_bit_and_noin}))*)(?{push@A,[end=>'',pos]}))x;$_re_bit_xor=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_bit_or})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})\|(?!=)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_bit_or}))*)(?{push@A,[end=>'',pos]}))x;$_re_bit_xor_noin=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_bit_or_noin})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})\|(?!=)(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_bit_or_noin}))*)(?{push@A,[end=>'',pos]}))x;$_re_and=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_bit_xor})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})&&(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_bit_xor}))*)(?{push@A,[end=>'',pos]}))x;$_re_and_noin=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_bit_xor_noin})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})&&(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_bit_xor_noin}))*)(?{push@A,[end=>'',pos]}))x;$_re_or=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_and})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})\|\|(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_and}))*)(?{push@A,[end=>'',pos]}))x;$_re_or_noin=qr((?{push@A,[begin=>lassoc=>pos]})(??{$_re_and_noin})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})\|\|(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_and_noin}))*)(?{push@A,[end=>'',pos]}))x;$_re_assign=qr((?{push@A,[begin=>assign=>pos]})(??{$_re_or})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})(?>(?:[-*/%+&^|]|<<|>>>?)?)=(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_or}))*)(?>(?:(??{$_re_s})\?(??{$_re_s})(??{$_re_assign})(??{$_re_s}):(??{$_re_s})(??{$_re_assign}))?)(?{push@A,[end=>'',pos]}))x;$_re_assign_noin=qr((?{push@A,[begin=>assign=>pos]})(??{$_re_or_noin})(?>(?:(??{$_re_s})(?{push@A,[begin=>in=>pos]})(?>(?:[-*/%+&^|]|<<|>>>?)?)=(?{push@A,[end=>in=>pos]})(??{$_re_s})(??{$_re_or_noin}))*)(?>(?:(??{$_re_s})\?(??{$_re_s})(??{$_re_assign})(??{$_re_s}):(??{$_re_s})(??{$_re_assign_noin}))?)(?{push@A,[end=>'',pos]}))x;$_re_expr=qr((?{push@A,[begin=>expr=>pos]})(??{$_re_assign})(?>(?:(??{$_re_s}),(??{$_re_s})(??{$_re_assign}))*)(?{push@A,[end=>'',pos]}))x;$_re_expr_noin=qr((?{push@A,[begin=>expr=>pos]})(??{$_re_assign_noin})(?>(?:(??{$_re_s}),(??{$_re_s})(??{$_re_assign_noin}))*)(?{push@A,[end=>'',pos]}))x;$_re_var_decl_list=qr((?{push@A,[begin=>vardecl=>pos]})(??{$_re_ident})(?>(?:(??{$_re_s})=(??{$_re_assign}))?)(?{push@A,[end=>vardecl=>pos]})(?>(?:(??{$_re_s}),(??{$_re_s})(?{push@A,[begin=>vardecl=>pos]})(??{$_re_ident})(?>(?:(??{$_re_s})=(??{$_re_assign}))?)(?{push@A,[end=>vardecl=>pos]}))?))x;$_re_statement=qr/(??{$_re_s})(?>(?#Statementsthatdonothaveanoptionalsemicolon:)(?:;(?{push@A,[empty=>pos]})|function<S>(?{push@A,[begin=>function=>pos]})(??{$_re_ident})(??{$_re_s})(??{$_re_params})(??{$_re_s})\{(??{$_re_statements})\}(?{push@A,[end=>'',pos]})|for(??{$_re_s})\((?{push@A,[begin=>for=>pos]})(??{$_re_s})(?>(?>var<S>(?{push@A,[begin=>var=>pos]})(?{push@A,[begin=>vardecl=>pos]})(??{$_re_ident})(?>(?:(??{$_re_s})=(??{$_re_assign_noin}))?)(?{push@A,[end=>vardecl=>pos]})(?{push@A,[end=>'',pos]})|(??{$_re_left_expr}))(??{$_re_s})in(?{push@A,[in=>pos]})(??{$_re_s})(??{$_re_expr})|(?>;(?{push@A,[empty=>pos]})|var<S>(?{push@A,[begin=>var=>pos]})(??{$_re_var_decl_list})(?{push@A,[end=>'',pos]})(??{$_re_s});|(??{$_re_expr})(??{$_re_s});)(?>;(?{push@A,[empty=>pos]})|(??{$_re_expr})(??{$_re_s});)(?>(?=(??{$_re_s})\))(?{push@A,[empty=>pos]})|(??{$_re_expr})))(??{$_re_s})\)(??{$_re_s})(??{$_re_statement})(?{push@A,[end=>'',pos]}))|(?#Statementsthatdohaveanoptionalsemicolon:)(?:(??{$_re_expr})|var<S>(?{push@A,[begin=>var=>pos]})(??{$_re_var_decl_list})(?{push@A,[end=>'',pos]}))(?:(??{$_re_s})(?:\z|;|(?=\}))|(??{$_re_h})(??{$_re_n})))/x;$_re_statements=qr/(?{push@A,[begin=>statements=>pos]})$_re_statement*(?{push@A,[end=>'',pos]})/x;

#--END--
}






#sub _to_int {  # ~~~ when is this used?
	# call to_number first
	# then...
	# NaN becomes 0
	# 0 and Infinity remain as they are
	# other nums are rounded towards zero ($_ <=> 0) * floor(abs)
#}

# Note that abs in ECMA-262
#sub _to_uint32 {  # ~~~ when is this used?
	# call to_number, then ...

	# return 0 for Nan, -?inf and 0
	# (round toward zero) % 2 ** 32
#}

#sub _to_int32 {
	# calculate _to_uint32 but subtract 2**31 if the result >= 2**31
#}

#sub _to_uint16 {  # ~~~ when is this used?
	# just like _to_uint32, except that 2**16 is used instead.
#}




sub parse {
	my($global) = shift;

	my $src = shift; $src =~ s/\p{Cf}//g;

	local @A; # so I don't have to erase it afterwards

	unless ($src =~ /^$_re_statements\z/ ) {
		$@ = "Syntax error at char ".
			(@A ? $A[-1][2] : 0);
		# ~~~ I'll improve the diagnostics later.
		#     and use the line number and perhaps some surrounding
		#     code or the offending token.
		return;
	}

	# Now that the fancy regular expressions have marked all the posi-
	# tions of the tokens in the source code, we need to build a tree.

# print Dumper \@A;  # uncomment this line to see the structure

	my @tree;
	my $a = \@tree;
	my @_a;
	# $a holds a reference to the current (possibly nested) array.
	# @_a holds references to arrays previously referenced by $a.

	for (my $n = 0; $n<$#A;++$n) {
		local $_ = $A[$n];
		if ( $$_[0] eq 'begin' ) {
			next if $$_[2] == length $src;
				# We've reached the end of the
				# source code.

			my $type = $$_[1]; # type of 'token'

			if ($type =~ /^(?:statements|f(?:unc(?:tion)?|or)|
				expr|
				var|a(?:ssign|rray)|
				l(?:assoc|eftexpr)|
				p(?:re|ost)fix)|hash\z/x
			) {
				push @$a, bless [[$$_[2]], $type],
					'JE::Code::Expression';
				push @_a, $a;
				$a = $$a[-1];
				next;
			}
			if ($type eq 'params' || $type eq 'vardecl') {
				push @$a, [];
				push @_a, $a;
				$a = $$a[-1];
				next;
			}
			if ($type eq 'subscript'
			 or $type eq 'prop') {
				push @$a, bless [[$$_[2]]],
					'JE::Code::Subscript';
				push @_a, $a;
				$a = $$a[-1];
				next;
			}
			if ($type eq 'args') {
				push @$a, bless [[$$_[2]]],
					'JE::Code::Arguments';
				push @_a, $a;
				$a = $$a[-1];
				next;
			}
			if ( $type =~ /^(?:i(?:dent|n)|num|p(?:ost|re))\z/
			    and $n == $#A || do { my $next = $A[$n+1];
			                          $$next[0] ne 'end' ||
			                          $$next[1] ne $type }
			) {
				# this was a failed attempt to match a 
				# particular type of token that wasn't 
				# there
				next;
			}
			if ($type =~ /^(?:in|p(?:re|ost))\z/) {
				push @$a, substr $src, $$_[2],
					$A[$n+1][2] - $$_[2];
				++$n; next;
			}
			if ($type eq 'ident') {
				my $ident = substr $src, $$_[2],
					$A[$n+1][2] - $$_[2];
				$ident =~ s/u([\da-fA-F]{4})/chr hex $1/ge;
				push @$a, $ident;
				++$n; next;
			}
			if ($type eq 'str') {
				my $yarn = substr $src, $$_[2],
					$A[$n+1][2] - $$_[2];
				$yarn =~ s/\\(?:
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
				/sge; 
				push @$a, new JE::String $global, $yarn;
				++$n; next;
			}
			if ($type eq 'num') {
				push @$a, new JE::Number $global,
					substr $src, $$_[2],
					$A[$n+1][2] - $$_[2];;
				++$n; next;
			}
			if ($type eq 'hex') {
				push @$a, new JE::Number $global, hex
					substr $src, $$_[2],
					$A[$n+1][2] - $$_[2];;
				++$n; next;
			}
			if ($type eq 're') {
				my $re = substr $src, $$_[2],
					$A[$n+1][2] - $$_[2];
				$re =~ s-([^/]*)\z--;
				push @$a, new JE::Object::RegExp $global,
					substr($re, 0, -1), $1;
					# the original slash has already
					# been removed, or rather, it
					# wasn't captured by the first
					# substr in this block to begin
					# with
				++$n; next;
			}
		}
		elsif ($$_[0] eq 'end') {
			my $type = $$_[1]; # type of 'token'

			push @{$$a[0]}, $$_[2]
				unless ref $$a[0] ne 'ARRAY'
				    or $type eq 'params'
				    or $type eq 'vardecl';

			if ($type eq 'leftexpr') {
# A left-hand expr is like this:
#         'new'*  term  ( subscript | args )*
# If there are more arg lists than "new"s, then count(new) arg
# lists belong to those "new" operators, and the rest are function
# calls. Otherwise those arg lists belong to the same number of
# 'new' ops, the leftmost 'new' ops possibly not getting any arg
# lists.

				my $new_count = 0;

				for (@$a[1..$#$a]) {
					$_ eq 'new' ? ++$new_count :
						last;
				}
				for my $n (reverse 1..$new_count) {
					# Look ahead for the next
					# arg list
					for ($n + 1 .. $#$a) {
if(ref $$a[$_] eq 'JE::Code::Arguments') {
	# put the tokens from the current "new"
	# up to the arg list into their own array
	my $new_array = bless [[]], "JE::Code::Expression";
	push @$new_array,
		splice @$a, $n, $_ - $n + 1,
		$new_array;  
	# ~~~ This new Expr obj has no str pos's in its first elem. I
	#     will probably need to figure out a away to get them in
	#     there for error reporting.
	last;
}
					}
					last; # if we get here,
					      # there are no more 
					      # arg lists left
				}
			
				# now we either have
				#    new* term subscript*
				# or
				#    term ( subscript | args )*
			}

			if ($$a[1] =~ /^assign|
				l(?:assoc|eftexpr)|
				p(?:re|ost)fix\z/x) {

				# If we find ourselves with an
				# expression that has only one term in
				#  it, let's eliminate it.

		 		@$a == 3 and

				# remove the reference to the
				# current array ($a) from the
				# parent array (the last elem
				# of @_a) and replace it with
				# the third elem of $a.
				$_a[-1][-1] = $$a[2];
			}

			$a = pop @_a;
		}
		elsif ($$_[0] eq 'comma') {
			push @$a, bless \do{my $x}, 'comma';
		}
	}

#	print Dumper $tree[0];

	$@ = '';
	return bless { global     => $global,
	               source     => $src,
	               tree       => $tree[0] };
	# ~~~ I need to add support for a name for the code--to be
	#     used in error messages.
	#     -- and a starting line number
}




sub execute {
	my $code = shift;

	my $this = defined $_[0] ? $_[0] : $$code{global};
	shift; # Oh for the // op!
	#my $this = shift // $$code{global};

	my $scope = shift || bless [$$code{global}], 'JE::Scope';

	my $rv = eval {
		# passing these values around is too
		# cumbersome
		local $JE::Code::Expression::_this  = $this;
		local $JE::Code::Expression::_scope = $scope;
		local $JE::Code::Expression::_eval  = shift;
		local $JE::Code::Expression::_created_vars = 0 ;
		$$code{tree}->eval;
	};
# ~~~ We need to make it so that lvalues can be returned if asked for
#      Or perhaps this should be an option of JE::eval called
#     'lvalue' or 'return_lvalue' or 'allow_lvalue'.
#    .

	if(ref $rv eq 'JE::LValue') {
		$rv = get $rv;
	}
	$rv;
}




package JE::Code::Expression; # Perhaps not aptly named. It was orig-
                              # inally just for (sub)expressions, but
                              # ended up being for statements as well.

our $VERSION = '0.002';

use subs '_eval_term';

our($_scope,$_this,$_created_vars);

{ # JavaScript operators
	no strict 'refs';
	*{'in+'} = sub {
		my($x, $y) = @_;
		$x = $x->to_primitive;
		$y = $y->to_primitive;
		if($x->typeof eq 'string' or
		   $y->typeof eq 'string') {
			return bless [
				$x->to_string->[0] .
				$y->to_string->[0],
				$_scope
			], 'JE::String';
		}
		return new JE::Number $_scope,
		                      $x->to_number->value +
		                      $y->to_number->value;
	};
	# ~~~ add subs for all the other ops
}

=begin for me

Types of expressions:

'leftexpr' 'new' term subscript* args

'leftexpr' 'new'* term subscript*

'leftexpr' term ( subscript | args) *  

'postfix' term op

'hash' term*

'array' term? (comma term?)*

'prefix' op term

'lassoc' term (op term)*

'assign' term (op term)* (term term)?
	(the last two terms are the 2nd and 3rd terms of ? :

'expr' term*
	(commas are omitted from the array)

'function' ident? params statements

=end for me

=cut


# Note: each expression object is an array ref. The elems are:
# [0] - an array ref containing
#       [0] - the starting position in the source code and
#       [1] - the ending position
# [1] - the type of expression
# [2..$#] - the various terms/tokens that make up the expr

sub eval {  # evalate (sub)expression/statement
	my $expr = shift;

	my $type = $$expr[1];

	if ($type eq 'statements') {

		# Search for function and var declarations and create vars
		# -- unless we've already done it.
		unless ($_created_vars++) {
		for (@$expr[2..$#$expr]) {
			if ($$_[1] eq 'var' ) {
				for (@$_[2..$#$_]) {
					$_scope->new_var($$_[0]);
				}
			} # ~~~ add extra elsif's that look for 'var'
			  #     declarations in for loops
			  #     and in blocks and all other compound
			  #     statements
			elsif ($$_[1] eq 'function') {
				# format: [[...], function=> 'name',
				#          [ (params) ], $statements_obj] 
				$_scope->new_var($$_[2], new JE::Function {
					scope    => $_scope,
					name     => $$_[2],
					argnames => $$_[3],
					function => bless {
						scope => $_scope,
						# ~~~ source => how do I get it? Do we need it? (for error reporting)
						tree => $$_[4],
					}, 'JE::Code'
				});
			}
		}}

		# ~~~ This dies on empty statements right now.
		$_->eval for @$expr[2..$#$expr-1];
		return $$expr[-1]->eval;
	}

	if ($type eq 'expr') {
		_eval_term $_ for @$expr[2..$#$expr-1];
		return _eval_term $$expr[-1];
	}
	if ($type eq 'assign') {
		# ~~~
	}
	if($type eq 'lassoc') { # left-associative
		my @copy = @$expr[2..$#$expr];
		my $result = _eval_term shift @copy;
		while(@copy) {
			no strict 'refs';
			$result = &{'in' . $copy[0]}(
				$result, _eval_term $copy[1]
			);
			splice @copy, 0, 2; # double shift
			# ~~~ These 'eval_term's should probobly be moved
			#     to sub in+
		}
		return $result;
	}
	if($type eq 'array') {
		my @ary;
		my $undef = $_scope->undefined;
		for (2..$#$expr) {
			if(ref $$expr[$_] eq 'comma') {
				ref $$expr[$_-1] eq 'comma' || $_ == 2
				and push @ary, $undef
			}
			else {
				push @ary, _eval_term $$expr[$_];
			}
		}

		return new JE::Object::Array $_scope, @ary;
	}
	if($type eq 'hash') {
		return new JE::Object $_scope,
			@$expr[2..$#$expr];
	}
	# ~~~ other types of ebxpressionssonoaau

}

sub _eval_term { # ~~~ This needs to take care of 'this'
	my($term, $context, ) = @_;

	# context can be one of:
	#    undef  no context (or a context that just wants the obj)
	#    lvalue 
	#    str    string context
	#    num    number context
	#    bool   boolean
	#    primitive  ???
	# ~~~ I need to complete this list

	while (ref $term eq 'JE::Code::Expression') {
		$term = $term->eval;
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
			return ref $term ? $term : $term eq 'this' ?
				$_this : $_scope->var($term);
		}
		if ($_ eq 'lvalue') {
			die "'this' is not an lvalue"
			if !ref $term  # evade overloading
			    and $term eq 'this';

			!ref $term  # identifier
				and $term = $_scope->var($term);

			ref $term ne 'JE::Code::LValue'
				and die "not an lvalue";
			# ~~~ improve the error message

			return $term;
		}

		ref $term or $term eq 'this' ? return($_this) :
			($term = $_scope->var($term));
		ref $term eq 'JE::LValue' and $term = $term->get;
#		if ($_ eq 'primitive') {
#			Er ,. b..e ydco?
#		}
		if ($_ eq 'string') {
			return $term->to_string;
		}
		if ($_ eq 'num') {
			return $term->to_number;
		}

		# ~~~ etc

		die "How did we get here??? context: $context; term $term";
	}
}




package JE::Code::Subscript;

our $VERSION = '0.002';




package JE::Code::Arguments;

our $VERSION = '0.002';




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

This parser is still in the process of being written. Right now it only
supports a few features of the syntax.

=head1 THE FUNCTION

C<JE::Code::parse($global, $src)> parses JS code and returns a parse tree.

C<$global> is a global object. C<$src> is the source code.

=head1 THE METHOD

=over 4

=item $code->execute($this, $scope, $eval);

The C<execute> method of a parse tree executes it. All the arguments are
optional.

The first argument
will be the 'this' value of the execution context. The global object will
be used if it is omitted or undef.

The second argument is a scope chain.
A scope chain containing just the global object will be used if it is
omitted or undef.

The third arg is a boolean indicating whether this is
eval code (code called by I<JavaScript's> C<eval> function, which has
nothing to do with JE's C<eval> method, which runs global code). The 
difference is that variables created with C<var> and function declarations 
inside
eval code can be deleted, whereas such variables in global or function
code cannot.

=back

=head1 SEE ALSO

=over 4

L<JE>

=cut


