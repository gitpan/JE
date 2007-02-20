package JE::Code;

our $VERSION = '0.004';

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
use JE::String 'desurrogify';

require JE::Object::Error::SyntaxError;
require JE::Object::Array;
require JE::Boolean;
require JE::Object;
require JE::Number;
require JE::LValue;
require JE::Scope;



our(@A,@_A);  # accumulator (named after $^A)
our($pos);

 # regexps
our($_re_h,     $_re_n,          $_re_ss,        $_re_s,     $_re_S,        
   $_re_id_cont, $_re_ident,      $_re_str,       $_re_num,
  $_re_params,    $_re_term,       $_re_subscript, $_re_args,    
 $_re_left_expr,  $_re_postfix,    $_re_unary,     $_re_multi,
$_re_add,        $_re_bitshift,   $_re_rel,       $_re_rel_noin,
 $_re_equal,    $_re_equal_noin,  $_re_bit_and,   $_re_bit_and_noin,
  $_re_bit_or,  $_re_bit_or_noin,  $_re_bit_xor,   $_re_bit_xor_noin,
   $_re_and,     $_re_and_noin,      $_re_or,        $_re_or_noin,
    $_re_cond,     $_re_cond_noin,      $_re_assign,    $_re_assign_noin,
     $_re_expr,       $_re_expr_noin,     $_re_statement, $_re_statements,
      $_re_var_decl_list, $_re_program);


# To edit these Hairy Regular Expressions, look at the file
# 'extras/regexps' included in this distribution.
{ use re qw'eval';
#--BEGIN--

$_re_h=qr((?:[ \t\x0b\f\xa0\p{Zs}]*)(?:(?:/\*[^\cm\cj\x{2028}\x{2029}]*?\*/)[ \t\x0b\f\xa0\p{Zs}]*)?)x;$_re_n=qr((?:[\cm\cj\x{2028}\x{2029}]));$_re_ss=qr([ \t\x0b\f\xa0\p{Zs}\cm\cj\x{2028}\x{2029}]);$_re_s=qr((?:(??{$_re_ss})*)(?:(?://[^\cm\cj\x{2028}\x{2029}]*(?:$_re_n|\z)|/\*.*?\*/)(?:(??{$_re_ss})*))*)sx;$_re_S=qr((?:(??{$_re_ss})|//[^\cm\cj\x{2028}\x{2029}]*|/\*.*?\*/)(??{$_re_s}))xs;$_re_id_cont=qr((?:\\u([\dA-Fa-f]{4})|[\p{ID_Continue}\$_]))x;$_re_ident=qr((?{local@_A=@_A;push@_A,[begin=>ident=>pos];pos>$pos&&($pos=pos)})(?:\\u([\dA-Fa-f]{4})|[\p{ID_Start}\$_])(?:(??{$_re_id_cont})*)(?{local@_A=@_A;push@_A,[end=>ident=>pos];pos>$pos&&($pos=pos)}))x;$_re_str=qr((?:'(?{local@_A=@_A;push@_A,[begin=>str=>pos];pos>$pos&&($pos=pos)})(?:(?s:[^'\\]|\\.)*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})'|"(?{local@_A=@_A;push@_A,[begin=>str=>pos];pos>$pos&&($pos=pos)})(?:(?s:[^"\\]|\\.)*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})"))x;$_re_num=qr((?:(?{local@_A=@_A;push@_A,[begin=>num=>pos];pos>$pos&&($pos=pos)})(?:(?=\d|\.\d)(?:0|[1-9]\d*)?(?:\.\d*)?(?:[Ee][+-]?\d+)?)(?{local@_A=@_A;push@_A,[end=>num=>pos];pos>$pos&&($pos=pos)})|0(?:[Xx])(?{local@_A=@_A;push@_A,[begin=>hex=>pos];pos>$pos&&($pos=pos)})(?:[A-Fa-f\d]+)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})))x;$_re_params=qr{(?{local@_A=@_A;push@_A,[begin=>params=>pos];pos>$pos&&($pos=pos)})\((??{$_re_s})(?:(?:(??{$_re_ident})(??{$_re_s})(?:(?:,(??{$_re_s})(??{$_re_ident})(??{$_re_s}))*))?)\)(?{local@_A=@_A;push@_A,[end=>params=>pos];pos>$pos&&($pos=pos)})}x;$_re_term=qr`(?:function(?!(??{$_re_id_cont}))(?{local@_A=@_A;push@_A,[begin=>func=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(?:(?:(??{$_re_ident})(??{$_re_s}))?)(??{$_re_params})(??{$_re_s})\{(??{$_re_s})(??{$_re_statements})\}(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|(??{$_re_ident})|(??{$_re_str})|(??{$_re_num})|/(?{local@_A=@_A;push@_A,[begin=>re=>pos];pos>$pos&&($pos=pos)})(?:[^/*\\]|\\.)(?:(?:[^/\\]|\\.)*)/(?:(??{$_re_id_cont})*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|\[ (?{local@_A=@_A;push@_A,[begin=>array=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(?:(??{$_re_assign})?)(?:(?:,(?{local@_A=@_A;push@_A,[comma=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(?:(?:(??{$_re_assign})(??{$_re_s}))?))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})\]|\{(?{local@_A=@_A;push@_A,[begin=>hash=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(?:(?:(?:(??{$_re_ident})|(??{$_re_str})|(??{$_re_num}))(??{$_re_s}):(??{$_re_s})(??{$_re_assign})(??{$_re_s})(?:(?:,(??{$_re_s})(?:(??{$_re_ident})|(??{$_re_str})|(??{$_re_num}))(??{$_re_s}):(??{$_re_s})(??{$_re_assign})(??{$_re_s}))*))?)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})\}|\((??{$_re_expr})\))`x;$_re_subscript=qr((?:\[ (?{local@_A=@_A;push@_A,[begin=>subscript=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_expr})(??{$_re_s})(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})]|\.(?{local@_A=@_A;push@_A,[begin=>prop=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_ident})(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})))x;$_re_args=qr#\((?{local@_A=@_A;push@_A,[begin=>args=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(?:(?:(??{$_re_assign})(??{$_re_s})(?:(?:,(??{$_re_s})(??{$_re_assign})(??{$_re_s}))*))?)\)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})#x;$_re_left_expr=qr((?{local@_A=@_A;push@_A,[begin=>leftexpr=>pos];pos>$pos&&($pos=pos)})(?:(?:new(?!(??{$_re_id_cont}))(?{local@_A=@_A;push@_A,[new=>pos];pos>$pos&&($pos=pos)})(??{$_re_s}))*)(??{$_re_term})(?:(?:(??{$_re_s})(?:(??{$_re_subscript})|(??{$_re_args})))*)(?{local@_A=@_A;push@_A,[end=>leftexpr=>pos];pos>$pos&&($pos=pos)}))x;$_re_postfix=qr/(?{local@_A=@_A;push@_A,[begin=>postfix=>pos];pos>$pos&&($pos=pos)})(??{$_re_left_expr})(?:(?:(??{$_re_h})(?{local@_A=@_A;push@_A,[begin=>post=>pos];pos>$pos&&($pos=pos)})(?:\+\+|\-\-)(?{local@_A=@_A;push@_A,[end=>post=>pos];pos>$pos&&($pos=pos)}))?)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})/x;$_re_unary=qr((?{local@_A=@_A;push@_A,[begin=>prefix=>pos];pos>$pos&&($pos=pos)})(?:(?:(?{local@_A=@_A;push@_A,[begin=>pre=>pos];pos>$pos&&($pos=pos)})(?:(?:delete|void|typeof)(?!(??{$_re_id_cont}))|\+\+?|--?|~|!)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})(??{$_re_s}))*)(??{$_re_postfix})(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_multi=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_unary})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})(?:[*/%])(?!=)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_unary}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_add=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_multi})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})(?:\+(?![+=])|-(?![-=]))(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_multi}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_bitshift=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_add})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})(?:>>>?|<<)(?!=)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_add}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_rel=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_bitshift})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})(?:[<>]=?|in(?:stanceof)?)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_bitshift}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_rel_noin=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_bitshift})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})(?:[<>]=?|instanceof)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_bitshift}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_equal=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_rel})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})(?:[!=]==?)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_rel}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_equal_noin=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_rel_noin})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})(?:[!=]==?)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_rel_noin}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_bit_and=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_equal})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})&(?!=)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_equal}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_bit_and_noin=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_equal_noin})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})&(?!=)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_equal_noin}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_bit_or=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_bit_and})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})\^(?!=)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_bit_and}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_bit_or_noin=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_bit_and_noin})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})\^(?!=)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_bit_and_noin}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_bit_xor=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_bit_or})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})\|(?!=)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_bit_or}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_bit_xor_noin=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_bit_or_noin})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})\|(?!=)(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_bit_or_noin}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_and=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_bit_xor})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})&&(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_bit_xor}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_and_noin=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_bit_xor_noin})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})&&(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_bit_xor_noin}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_or=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_and})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})\|\|(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_and}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_or_noin=qr((?{local@_A=@_A;push@_A,[begin=>lassoc=>pos];pos>$pos&&($pos=pos)})(??{$_re_and_noin})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})\|\|(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_and_noin}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_assign=qr((?{local@_A=@_A;push@_A,[begin=>assign=>pos];pos>$pos&&($pos=pos)})(??{$_re_or})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})(?:(?:[-*/%+&^|]|<<|>>>?)?)=(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_or}))*)(?:(?:(??{$_re_s})\?(??{$_re_s})(??{$_re_assign})(??{$_re_s}):(??{$_re_s})(??{$_re_assign}))?)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_assign_noin=qr((?{local@_A=@_A;push@_A,[begin=>assign=>pos];pos>$pos&&($pos=pos)})(??{$_re_or_noin})(?:(?:(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>in=>pos];pos>$pos&&($pos=pos)})(?:(?:[-*/%+&^|]|<<|>>>?)?)=(?{local@_A=@_A;push@_A,[end=>in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_or_noin}))*)(?:(?:(??{$_re_s})\?(??{$_re_s})(??{$_re_assign})(??{$_re_s}):(??{$_re_s})(??{$_re_assign_noin}))?)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_expr=qr((?{local@_A=@_A;push@_A,[begin=>expr=>pos];pos>$pos&&($pos=pos)})(??{$_re_assign})(?:(?:(??{$_re_s}),(??{$_re_s})(??{$_re_assign}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_expr_noin=qr((?{local@_A=@_A;push@_A,[begin=>expr=>pos];pos>$pos&&($pos=pos)})(??{$_re_assign_noin})(?:(?:(??{$_re_s}),(??{$_re_s})(??{$_re_assign_noin}))*)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))x;$_re_var_decl_list=qr((?{local@_A=@_A;push@_A,[begin=>vardecl=>pos];pos>$pos&&($pos=pos)})(??{$_re_ident})(?:(?:(??{$_re_s})=(??{$_re_s})(??{$_re_assign}))?)(?{local@_A=@_A;push@_A,[end=>vardecl=>pos];pos>$pos&&($pos=pos)})(?:(?:(??{$_re_s}),(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>vardecl=>pos];pos>$pos&&($pos=pos)})(??{$_re_ident})(?:(?:(??{$_re_s})=(??{$_re_s})(??{$_re_assign}))?)(?{local@_A=@_A;push@_A,[end=>vardecl=>pos];pos>$pos&&($pos=pos)}))?))x;$_re_statement=qr/(?:(?#Statementsthatdonothaveanoptionalsemicolon:)(?:\{(??{$_re_statements})\}|;(?{local@_A=@_A;push@_A,[emptystm=>pos];pos>$pos&&($pos=pos)})|function(??{$_re_S})(?{local@_A=@_A;push@_A,[begin=>function=>pos];pos>$pos&&($pos=pos)})(??{$_re_ident})(??{$_re_s})(??{$_re_params})(??{$_re_s})\{(??{$_re_s})(??{$_re_statements})\}(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|if(??{$_re_s})\((?{local@_A=@_A;push@_A,[begin=>if=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_expr})(??{$_re_s})\)(??{$_re_s})(??{$_re_statement})(?:(?:(??{$_re_s})else(?!(??{$_re_id_cont}))(??{$_re_s})(??{$_re_statement}))?)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|while(??{$_re_s})\((?{local@_A=@_A;push@_A,[begin=>while=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_expr})(??{$_re_s})\)(??{$_re_s})(??{$_re_statement})(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|for(??{$_re_s})\((?{local@_A=@_A;push@_A,[begin=>for=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(?:(?:var(??{$_re_S})(?{local@_A=@_A;push@_A,[begin=>var=>pos];pos>$pos&&($pos=pos)})(?{local@_A=@_A;push@_A,[begin=>vardecl=>pos];pos>$pos&&($pos=pos)})(??{$_re_ident})(?:(?:(??{$_re_s})=(??{$_re_assign_noin}))?)(?{local@_A=@_A;push@_A,[end=>vardecl=>pos];pos>$pos&&($pos=pos)})(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|(??{$_re_left_expr}))(??{$_re_s})in(?{local@_A=@_A;push@_A,[in=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_expr})|(?:;(?{local@_A=@_A;push@_A,[empty=>pos];pos>$pos&&($pos=pos)})|var(??{$_re_S})(?{local@_A=@_A;push@_A,[begin=>var=>pos];pos>$pos&&($pos=pos)})(??{$_re_var_decl_list})(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})(??{$_re_s});|(??{$_re_expr})(??{$_re_s});)(??{$_re_s})(?:;(?{local@_A=@_A;push@_A,[empty=>pos];pos>$pos&&($pos=pos)})|(??{$_re_expr})(??{$_re_s});)(?:(?=(??{$_re_s})\))(?{local@_A=@_A;push@_A,[empty=>pos];pos>$pos&&($pos=pos)})|(??{$_re_s})(??{$_re_expr})))(??{$_re_s})\)(??{$_re_s})(??{$_re_statement})(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|with(??{$_re_s})\((?{local@_A=@_A;push@_A,[begin=>with=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_expr})(??{$_re_s})\)(??{$_re_s})(??{$_re_statement})(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|switch(??{$_re_s})\((?{local@_A=@_A;push@_A,[begin=>switch=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_expr})(??{$_re_s})\)(??{$_re_s})\{(?:(?:case(?!(??{$_re_id_cont}))(??{$_re_s})(??{$_re_expr})(??{$_re_s}):(??{$_re_s})(??{$_re_statements}))*)(?:(?:default(?{local@_A=@_A;push@_A,[default=>pos];pos>$pos&&($pos=pos)})(??{$_re_s}):(??{$_re_s})(??{$_re_statements})(?:(?:case(?!(??{$_re_id_cont}))(??{$_re_s})(??{$_re_expr})(??{$_re_s}):(??{$_re_s})(??{$_re_statements}))*))?)\}(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|try(??{$_re_s})\{(?{local@_A=@_A;push@_A,[begin=>try=>pos];pos>$pos&&($pos=pos)})(??{$_re_s})(??{$_re_statements})\}(??{$_re_s})(?:catch(??{$_re_s})\((??{$_re_s})(??{$_re_ident})(??{$_re_s})\)(??{$_re_s})\{(??{$_re_s})(??{$_re_statements})\}(?:(?:(??{$_re_s})finally(??{$_re_s})\{(??{$_re_s})(??{$_re_statements})\})?)|finally(??{$_re_s})\{(??{$_re_s})(??{$_re_statements})\})|(?{local@_A=@_A;push@_A,[begin=>labelled=>pos];pos>$pos&&($pos=pos)})(?:(?:(??{$_re_ident})(??{$_re_s}):(??{$_re_s}))+)(?!(??{$_re_ident})(??{$_re_s}):)(??{$_re_statement})(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)}))(??{$_re_s})|(?#Statementsthatdohaveanoptionalsemicolon:)(?:var(??{$_re_S})(?{local@_A=@_A;push@_A,[begin=>var=>pos];pos>$pos&&($pos=pos)})(??{$_re_var_decl_list})(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|do(?!(??{$_re_id_cont}))(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>do=>pos];pos>$pos&&($pos=pos)})(??{$_re_statement})while(??{$_re_s})\((??{$_re_s})(??{$_re_expr})(??{$_re_s})\)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|continue(?!(??{$_re_id_cont}))(??{$_re_h})(?{local@_A=@_A;push@_A,[begin=>continue=>pos];pos>$pos&&($pos=pos)})(?:(??{$_re_ident})?)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|break(?!(??{$_re_id_cont}))(??{$_re_h})(?{local@_A=@_A;push@_A,[begin=>break=>pos];pos>$pos&&($pos=pos)})(?:(??{$_re_ident})?)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|return(?!(??{$_re_id_cont}))(??{$_re_h})(?{local@_A=@_A;push@_A,[begin=>return=>pos];pos>$pos&&($pos=pos)})(?:(??{$_re_expr})?)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|throw(?!(??{$_re_id_cont}))(??{$_re_h})(?{local@_A=@_A;push@_A,[begin=>throw=>pos];pos>$pos&&($pos=pos)})(?:(??{$_re_expr})?)(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})|(??{$_re_expr}))(?:(??{$_re_s})(?:\z|;(??{$_re_s})|(?=\}))|(??{$_re_h})(??{$_re_n})(??{$_re_s})))/x;$_re_statements=qr/(??{$_re_s})(?{local@_A=@_A;push@_A,[begin=>statements=>pos];pos>$pos&&($pos=pos)})$_re_statement*(?{local@_A=@_A;push@_A,[end=>'',pos];pos>$pos&&($pos=pos)})/x;$_re_program=qr/(??{$_re_statements})(?{@A=@_A})/x;

#--END--
}








sub parse {
	my($global) = shift;

	my $src = shift;

	# remove unicode format chrs
	$src =~ s/\p{Cf}//g;

	local ($pos,@A,@_A) = 0;
	# @_A is the temporary variable that is repeatedly localised
	# inside the regular expressions.
	# $pos stores the current position within the code and is not
	# subject to backtracking, so we use it when reporting syntax
	# errors.

	unless ($src =~ /^$_re_program\z/ ) {
		$@ = "Syntax error at char " . ($pos+1);
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
		local *_ = \$A[$n];
		my $type = $$_[0];
		if ( $type eq 'begin' ) {
			my $type = $$_[1]; # type of 'token'
			if ($type =~ /^(?:s(?:tatements|witch)|
				f(?:unction|or)|
				var|if|do|w(?:hile|ith)|continue|break|
				return|labelled|t(?:hrow|ry))\z/x
			) {
				push @$a, bless [[$$_[2]], $type],
					'JE::Code::Statement';
				push @_a, $a;
				$a = $$a[-1];
				next;
			}
			if ($type =~ /^(?:func|
				expr|
				a(?:ssign|rray)|
				l(?:assoc|eftexpr)|
				p(?:re|ost)fix|hash)\z/x
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
			if ($type =~ /^(?:in|p(?:re|ost))\z/) {
				push @$a, substr $src, $$_[2],
					$A[$n+1][2] - $$_[2];
				++$n; next;
			}
			if ($type eq 'ident') {
				my $ident = substr $src, $$_[2],
					$A[$n+1][2] - $$_[2];
				if (ref $a ne 'JE::Code::Subscript' and
				    $ident =~ /^(?:(?:tru|fals)e|null)\z/)
				{
					$ident = $ident eq 'null' ?
						$global->null :
					    	new JE::Boolean $global,
						 $ident eq 'true';
				}
				else {
					$ident =~
					s/\\u([\da-fA-F]{4})/chr hex $1/ge;
					$ident = desurrogify $ident;
					$ident =~ /^[\p{ID_Start}\$_]
					            [\p{ID_Continue}\$_]*
					          \z/x
					  or $@ = "Syntax error: '$ident' "
					      ."is not a valid identifier",
					     return;
				}
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
				/sgex; 
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
		elsif ($type eq 'end') {
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

				for (@$a[2..$#$a]) {
					ref eq 'new' ? ++$new_count :
						last;
				}
				NEW: for my $n (reverse 2..$new_count+1) {
					# Look ahead for the next
					# arg list
					for ($n + 1 .. $#$a) {
if(ref $$a[$_] eq 'JE::Code::Arguments') {
	# put the tokens from the current "new"
	# up to the arg list into their own array
	my $new_array = bless [[], 'leftexpr'], "JE::Code::Expression";
	push @$new_array,
		splice @$a, $n, $_ - $n + 1,
		$new_array;  
	# ~~~ This new Expr obj has no str pos's in its first elem. I
	#     will probably need to figure out a away to get them in
	#     there for error reporting.
	next NEW;
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

			if (@$a > 1 and $$a[1] =~ /^assign|
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
		elsif ($type =~ /^(?:comma|new)\z/) {
			push @$a, bless \do{my $x}, $type;
		}
		elsif ($type =~ /^(?:empty|in|default)\z/) {
			push @$a, $type;
		}
		elsif ($type eq 'emptystm') {
			push @$a, bless [[$$_[1]-1, $$_[1]], 'empty'],
					'JE::Code::Statement';
		}
	}

#	print scalar @_a;
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
	shift;

	my $scope = shift || bless [$$code{global}], 'JE::Scope';

	my $rv;
	eval {
		# passing these values around is too
		# cumbersome
		local $JE::Code::Expression::_this   = $this;
		local $JE::Code::Expression::_scope  = $scope;
		local $JE::Code::Expression::_global = $$code{global};
		local $JE::Code::Expression::_eval   = shift;
		local $JE::Code::Statement::_created_vars = 0 ;
		local $JE::Code::Statement::_label;
		local $JE::Code::Statement::_return;

		RETURN: {
		BREAK: {
		CONT: {
			$rv = $$code{tree}->eval;
			goto FINISH;
		} 

		if($JE::Code::Statement::_label) {
			 die new JE::Object::Error::SyntaxError
		  	"continue $JE::Code::Statement::_label: label " .
		  	"'$JE::Code::Statement::_label' not found";
		} else { goto FINISH; }

		} # end of BREAK

		if($JE::Code::Statement::_label) {
			 die new JE::Object::Error::SyntaxError
		  	"break $JE::Code::Statement::_label: label " .
		  	"'$JE::Code::Statement::_label' not found";
		} else { goto FINISH; }

		} # end of RETURN

		$rv = $JE::Code::Statement::_return;
	};

	FINISH:

	$@ eq '' and !defined $rv and $rv = $scope->undefined;

	$rv;
}




package JE::Code::Statement; # This does not cover expression statements.

our $VERSION = '0.004';

use subs qw'_create_vars _eval_term';
use List::Util 'first';

our($_created_vars, $_scope, $_global,$_label,$_return);

*_eval_term = *JE::Code::Expression::_eval_term;
*_global    = *JE::Code::Expression::_global;
*_scope     = *JE::Code::Expression::_scope;


# Note: each statement object is an array ref. The elems are:
# [0] - an array ref containing
#       [0] - the starting position in the source code and
#       [1] - the ending position
# [1] - the type of statement
# [2..$#] - the various expressions/statements that make up the statement

sub eval {  # evaluate statement
	my $stm = shift;

	my $type = $$stm[1];
	$type eq 'empty' || $type eq 'function' and return;

	my @labels;

	if ($type eq 'labelled') {
		@labels = $$stm[2..$#$stm-1];
		if ($$stm[1] =~ /^(?:do|while|for|switch)\z/) {
			$stm = $$stm[-1];
			$type = $$stm[1];
			goto LOOP; # skip unnecessary if statements
		}

		my $to_return;
		BREAK: {
			$to_return = $$stm[-1]->eval;
		}

		# Note that this has 'defined' in it, whereas the similar
		# 'if' statement further down where the loop constructs are
		# doesn't. This is because 'break' without a label sets
		# $_label to '' and exits loops and switches.
		if(! defined $_label || first {$_ eq $_label} @labels) {
			undef $_label;
			return $to_return;
		} else {
			last BREAK;
		}
	}

	if ($type eq 'statements') {

		# Search for function and var declarations and create vars
		# -- unless we've already done it.
		_create_vars($stm) unless ($_created_vars++);
			

		# Execute the statements, one by one, and return the return
		# value of the last statement that actually returned one.
		my $to_return;
		my $returned;
		for (@$stm[2..$#$stm]) {
			next if $_ eq 'empty';
			defined($returned = $_->eval)
				and $to_return = $returned;
		}
		return $to_return;
	}
	if ($type eq 'var') {
		for (@$stm[2..$#$stm]) {
			@$_ == 2 and
				$_scope->var($$_[0], _eval_term $$_[1]);
		}
		return;
	}
	if ($type eq 'if') {
		#            2       3          4
		# we have:  expr statement statement?
		if ($$stm[2]->eval->to_boolean->value) {
			return $$stm[3] eq 'empty'
				? ()
				: $$stm[3]->eval;
		}
		else {
			return exists $$stm[4]
				&& $$stm[4] ne 'empty'
				? $$stm[4]->eval : ();
		}
	}
	if ($type =~ /^(?:do|while|for|switch)\z/) {
		# We have one of the following:
		#
		#  1      2          3          4          5
		# 'do'    statement  expression
		# 'while' expression statement
		# 'for'   expression 'in'       expression statement
		# 'for'   var_decl   'in'       expression statement 
		# 'for'   expression expression expression statement
		# 'for'   var_decl   expression expression statement
 		#
		# In those last two cases, expression may be 'empty'.
		# (See further down for 'switch').

		no warnings 'exiting';

		LOOPS:
		my $to_return;
		my $returned;
		
		BREAK: {
		if ($type eq 'do') {
			CONT: do {
				if($_label and
				   !first {$_ eq $_label} @labels) {
					goto NEXT;
				}
				undef $_label;

				defined ($returned = ref $$stm[2]
					? $$stm[2]->eval : undef)
				and $to_return = $returned;

			} while $$stm[3]->eval->to_boolean->value;
		}
		elsif ($type eq 'while') {
			CONT: while ($$stm[2]->eval->to_boolean->value) {
				if($_label and
				   !first {$_ eq $_label} @labels) {
					goto NEXT;
				}
				undef $_label;

				defined ($returned = ref $$stm[3]
					? $$stm[3]->eval : undef)
				and $to_return = $returned;
			}
		}
		elsif ($type eq 'for' and $$stm[3] eq 'in') {
			my $left_side = $$stm[2];
			if ($left_side->[1] eq 'var') {
				$left_side->eval;
				$left_side = $left_side->[2][0];
				# now contains the identifier
			}
			my @props = (my $obj = $$stm[4]->eval)->props;
			CONT: for(@props) {
				if($_label and
				   !first {$_ eq $_label} @labels) {
					goto NEXT;
				}
				undef $_label;

				next if not defined $obj->prop($_);	
				# in which case it's been deleted
				
				(ref $left_side ? $left_side->eval :
					$_scope->var($left_side))
				  ->set(new JE::String $_global, $_);

				defined ($returned = ref $$stm[5]
					? $$stm[5]->eval : undef)
				and $to_return = $returned;
			}
		}
		elsif ($type eq 'for') { # for(;;)
			CONT: for (
				ref $$stm[2] && $$stm[2]->eval;
				ref $$stm[3]
					? $$stm[3]->eval->to_boolean->value
					: 1;
				ref $$stm[4] && $$stm[4]->eval
			) {
				if($_label and
				   !first {$_ eq $_label} @labels) {
					goto NEXT;
				}
				undef $_label;

				defined ($returned = ref $$stm[5]
					? $$stm[5]->eval : undef)
				and $to_return = $returned;
			}			
		}
		else { # switch
			# $stm->[2] is the parenthesized
			# expression.
			# Each pair of elements thereafter
			# represents one case clause, an expr
			# followed by statements, except for
			# the default clause, which has the
			# string 'default' for its first elem

			
			# Evaluate the expression in the header
			my $given = $$stm[2]->eval;
			
			# Look through the case clauses to see
			# which it matches. At the same time,
			# look for the default clause.

			no strict 'refs';

			my($n, $default) = 3;
			do {
				if($$stm[$n] eq 'default') {
					$default = $n; next;
				}

				# Execute the statements if we have a match
				if("JE::Code::Expression::in==="->(
					$given, $$stm[$n]->eval
				  )) {
					$n++;
					do {
						$$stm[$n]->eval;
					} while ($n+=2) < @$stm;
					undef $default;
					last;
				}
			} while ($n+=2) < @$stm;

			# If we can't find a case that matches, but we
			# did find a default (and it was not erased when
			# a case matched)
			$n = $default +1;
			do { $$stm[$n]->eval } while ($n+=2) < @$stm;
		}

		# In case 'continue LABEL' is called during the last
		# iteration of the loop (does not apply to switch)
		if($_label and
		   !first {$_ eq $_label} @labels) {
			next CONT;
		}
		undef $_label;

		} # end of BREAK


		if(!$_label || first {$_ eq $_label} @labels) {
			undef $_label;
			return $to_return;
		} else {
			last BREAK;
		}
		
		NEXT: next CONT;
	}
	if ($type eq 'continue') {
		no warnings 'exiting';
		$_label = exists $$stm[2] ? $$stm[2] : '';
		next CONT;
	}
	if ($type eq 'break') {
		no warnings 'exiting';
		$_label = exists $$stm[2] ? $$stm[2] : '';
		last BREAK;
	}
	if ($type eq 'return') {
		no warnings 'exiting';
		if (exists $$stm[2]) {
			ref ($_return = $$stm[2]->eval) eq 'JE::LValue'
			and $_return = get $_return;
		} else { $_return = '' }
		last RETURN;
	}
	if ($type eq 'with') {
		local $_scope = bless [
			@$_scope, $$stm[2]->eval->to_object
		], 'JE::Scope';
		return $$stm[3]->eval;
	}
	if ($type eq 'throw') {
		my $excep;
		if (exists $$stm[2]) {
			ref ($excep = $$stm[2]->eval) eq 'JE::LValue'
			and $excep = get $excep;
		}
		die $excep;
	}
	if ($type eq 'try') {
		# We have one of the following:
		#   1     2     3     4     5
		# 'try' block ident block       (catch)
		# 'try' block block             (finally)
		# 'try' block ident block block (catch & finally)

		my $result;
		my $propagate;

		eval { # try
			no warnings 'exiting';
			RETURN: {
			BREAK: {
			CONT: {
				$result = $$stm[2]->eval;
				goto END_EVAL;
			} $propagate = sub{ next CONT }; goto FINALLY;
			} $propagate = sub{ last BREAK }; goto FINALLY;
			} $propagate = sub{ last RETURN }; goto FINALLY;
		};
		if ($@ && !ref $$stm[3]) { # catch
			local $_scope = bless [
				@$_scope, new JE::Object $$stm[3] => $@
			], 'JE::Scope';
	
			eval { # in case an error is thrown in the 
			       # catch block
				$result = $$stm[4]->eval;
			}
		}
		# In case the 'finally' block resets $@:
		my $exception = $@;
		FINALLY:
		if ($#$stm == 3 or $#$stm == 5) {
			$$stm[-1]->eval;
		}
		defined $exception and die $exception;
		$propagate and &$propagate();
		return $result;
	}
}

sub _create_vars {  # Process var and function declarations
	local *_ = \shift;
	my $type = $$_[1];
	if ($type eq 'var' ) {
		for (@$_[2..$#$_]) {
			$_scope->new_var($$_[0]);
		}
	}
	elsif ($type eq 'statements') {
		for (@$_[2..$#$_]) {
			next if $_ eq 'empty';
			_create_vars $_;
		}
	}
	elsif ($type eq 'if') {
		_create_vars $$_[2];
		_create_vars $$_[3] if exists $$_[3];;
	}
	elsif ($type eq 'do') {
		_create_vars $$_[2];
	}
	elsif ($type eq 'while' || $type eq 'with') {
		_create_vars $$_[3];
	}
	elsif ($type eq 'for') {
		_create_vars $$_[2] if $$_[2][1] eq 'var';
		_create_vars $$_[-1];
	}
	elsif ($type eq 'switch') {
		_create_vars $$_[$_*2+2] for 1..($#$_-2)/2;
		# Even-numbered array indices starting with 4
	}
	elsif ($type eq 'try') {
		ref eq __PACKAGE__ and _create_vars $_ for @$_[2..$#$_];
	}
	elsif ($type eq 'function') {
		# format: [[...], function=> 'name',
		#          [ (params) ], $statements_obj] 
		$_scope->new_var($$_[2], new JE::Object::Function {
			scope    => $_scope,
			name     => $$_[2],
			argnames => $$_[3],
			function => bless {
				global => $_global,
				# ~~~ source => how do I get it? Do we need it? (for error reporting)
				tree => $$_[4],
			}, 'JE::Code'
		});
	}
}




package JE::Code::Expression;

our $VERSION = '0.004';

# See the comments in Number.pm for how I found out these constant values.
use constant nan => sin 9**9**9;
use constant inf => 9**9**9;

use subs qw'_eval_term';
use POSIX 'fmod';

our($_scope,$_this,$_global);

#----------for reference------------#
#sub _to_int {
	# call to_number first
	# then...
	# NaN becomes 0
	# 0 and Infinity remain as they are
	# other nums are rounded towards zero ($_ <=> 0) * floor(abs)
#}

# Note that abs in ECMA-262
#sub _to_uint32 {
	# call to_number, then ...

	# return 0 for Nan, -?inf and 0
	# (round toward zero) % 2 ** 32
#}

#sub _to_int32 {
	# calculate _to_uint32 but subtract 2**32 if the result >= 2**31
#}

#sub _to_uint16 { 
	# just like _to_uint32, except that 2**16 is used instead.
#}


#---------------------------------#

{ # JavaScript operators
  # Note: some operators are not dealt with here, but inside
  #       sub eval.
	no strict 'refs';
	*{'predelete'} = sub {
		ref(my $term = shift) eq 'JE::LValue' or return
			new JE::Boolean $_global, 1;
		new JE::Boolean $_global,
			$term->base->delete($term->property);
	};
	*{'prevoid'} = sub {
		my $term = shift;
		$term = get $term while ref $term eq 'JE::LValue';
		return $_global->undefined;
	};
	*{'pretypeof'} = sub {
		my $term = shift;
		ref  $term eq 'JE::LValue' and
			base $term->id eq 'null' and
			return new JE::String $_global, 'undefined';
		new JE::String $_global, typeof $term;
	};
	*{'pre++'} = sub {
		# ~~~ These is supposed to use the same rules
		#     as the + infix op for the actual
		#     addition part. Verify that it does this.
		my $term = shift;
		$term->set(new JE::Number $_global,
			get $term->to_number + 1);
	};
	*{'pre--'} = sub {
		# ~~~ These is supposed to use the same rules
		#     as the - infix op for the actual
		#     subtraction part. Verify that it does this.
		my $term = shift;
		$term->set(new JE::Number $_global,
			get $term->to_number->value - 1);
	};
	*{'pre+'} = sub {
		shift->to_number;
	};
	*{'pre-'} = sub {
		new JE::Number $_global, -shift->to_number->value;
	};
	*{'pre~'} = sub {
		my $num = shift->to_number->value;
		$num = 
			$num != $num || abs($num) == inf  # nan/+-inf
			? $num = 0
			: int($num) % 2**32;

		{ use integer; # for signed bitwise negation
		  $num = ~$num; }
		
		new JE::Number $_global, $num;	
	};
	*{'pre!'} = sub {
		new JE::Boolean $_global, !shift->to_boolean->value
	};
	*{'in*'} = sub {
		new JE::Number $_global,
			shift->to_number->value *
			shift->to_number->value;
	};
	*{'in/'} = sub {
		my($num,$denom) = map to_number $_->value, @_[0,1];
		new JE::Number $_global,
			$denom ?
				$num/$denom :
			# Divide by zero:
			$num && $num == $num # not zero or nan
				? $num * inf
				: nan;
	};
	*{'in%'} = sub {
		my($num,$denom) = map to_number $_->value,
			@_[0,1];
		new JE::Number $_global,
			$num+1 == $num ? nan :
			$num == $num && abs($denom) == inf ?
				$num :
			fmod $num, $denom;
	};
	*{'in+'} = sub {
		my($x, $y) = @_;
		$x = $x->to_primitive;
		$y = $y->to_primitive;
		if($x->typeof eq 'string' or
		   $y->typeof eq 'string') {
			return bless [
				$x->to_string->[0] .
				$y->to_string->[0],
				$_global
			], 'JE::String';
		}
		return new JE::Number $_global,
		                      $x->to_number->value +
		                      $y->to_number->value;
	};
	*{'in-'} = sub {
		new JE::Number $_global,
			shift->to_number->value -
			shift->to_number->value;
	};
	*{'in<<'} = sub {
		my $num = shift->to_number->value;
		$num = 
			$num != $num || abs($num) == inf  # nan/+-inf
			? $num = 0
			: int($num) % 2**32;
		$num -= 2**32 if $num >= 2**31;

		use integer;
		new JE::Number $_global,
			$num << (shift->to_number->value & 0x1f);
	};
	*{'in>>'} = sub {
		my $num = shift->to_number->value;
		$num = 
			$num != $num || abs($num) == inf  # nan/+-inf
			? $num = 0
			: int($num) % 2**32;
		$num -= 2**32 if $num >= 2**31;

		use integer;
		new JE::Number $_global,
			$num >> (shift->to_number->value & 0x1f);
	};
	*{'in>>>'} = sub {
		my $num = shift->to_number->value;
		$num = 
			$num != $num || abs($num) == inf  # nan/+-inf
			? $num = 0
			: int($num) % 2**32;

		new JE::Number $_global,
			$num >> (shift->to_number->value & 0x1f);
	};
	*{'in<'} = sub {
		my($x,$y) = map to_primitive $_, @_[0,1];
		new JE::Boolean $_global,
			$x->typeof eq 'string' &&
			$y->typeof eq 'string'
			? $x->to_string->[0] lt $y->to_string->[0]
			: $x->to_number->[0] <  $y->to_number->[0];
	};
	*{'in>'} = sub {
		my($x,$y) = map to_primitive $_, @_[0,1];
		new JE::Boolean $_global,
			$x->typeof eq 'string' &&
			$y->typeof eq 'string'
			? $x->to_string->[0] gt $y->to_string->[0]
			: $x->to_number->[0] >  $y->to_number->[0];
	};
	*{'in<='} = sub {
		my($x,$y) = map to_primitive $_, @_[0,1];
		new JE::Boolean $_global,
			$x->typeof eq 'string' &&
			$y->typeof eq 'string'
			? $x->to_string->[0] le $y->to_string->[0]
			: $x->to_number->[0] <= $y->to_number->[0];
	};
	*{'in>='} = sub {
		my($x,$y) = map to_primitive $_, @_[0,1];
		new JE::Boolean $_global,
			$x->typeof eq 'string' &&
			$y->typeof eq 'string'
			? $x->to_string->[0] ge $y->to_string->[0]
			: $x->to_number->[0] >= $y->to_number->[0];
	};
	*{'ininstanceof'} = sub {
		my($obj,$func) = @_;
		die "$func is not an object" # ~~~ TypeError
			if $func->primitive;
		return new JE::Boolean $_global, 0 if $obj->primitive;
		
		my $proto_id = $func->prop('prototype');
		!defined $proto_id || $proto_id->primitive and die
			"Function $$$func{func_name} has no prototype property"; # ~~~ TypeError
		$proto_id = $proto_id->id;

		0 while (defined($obj = $obj->prototype)
		         or return new JE::Boolean $_global, 0)
			->id ne $proto_id;
		# ~~~ find out about joined objects (E 13.1.2)
		
		new JE::Boolean $_global, 1;
	};
	*{'inin'} = sub {
		my($prop,$obj) = @_;
		die "$obj is not an object" # ~~~ TypeError
			if $obj->primitive;
		new JE::Boolean $_global, defined $obj->prop($prop);
	};
	*{'in=='} = sub {
		my($x,$y) = @_;
		my($xt,$yt) = (typeof $x, typeof $y);
		my($xi,$yi) = (    id $x,     id $y);
		$xt eq $yt and return new JE::Boolean $_global,
			$xi eq $yi && $xi ne 'num:nan';

		$xi eq 'null' and
			return new JE::Boolean $_global,
				$yi eq 'undef';
		$xi eq 'undef' and
			return new JE::Boolean $_global,
				$yi eq 'null';
		$yi eq 'null' and
			return new JE::Boolean $_global,
				$xi eq 'undef';
		$yi eq 'undef' and
			return new JE::Boolean $_global,
				$xi eq 'null';

		$xt eq 'number'  or $yt eq 'number'  or
		$xt eq 'boolean' or $yt eq 'boolean' and
			return new JE::Boolean $_global,
			to_number $x->[0] == to_number $y->[0];

		$xt eq 'string' or $yt eq 'string' and 
			return new JE::Boolean $_global,
			to_string $x->[0] eq to_string $y->[0];
		
		new JE::Boolean $_global, 0;
	};
	*{'in!='} = sub {
		new JE::Boolean $_global, !&{'in=='}->[0];
	};
	*{'in==='} = sub {
		my($x,$y) = @_;
		my($xi,$yi) = (    id $x,     id $y);
		return new JE::Boolean $_global,
			$xi eq $yi && $xi ne 'num:nan';
		# ~~~ find out about joined objects (E 13.1.2)
	};
	*{'in!=='} = sub {
		new JE::Boolean $_global, !&{'in==='}->[0];
	};
	*{'in&'} = sub {
		my $num = shift->to_number->[0];
		$num = 
			$num != $num || abs($num) == inf
			? $num = 0
			: int($num) % 2**32;
		$num -= 2**32 if $num >= 2**31;

		use integer;
		new JE::Number $_global,
			$num & shift->to_number->[0];
	};
	*{'in^'} = sub {
		my $num = shift->to_number->[0];
		$num = 
			$num != $num || abs($num) == inf
			? $num = 0
			: int($num) % 2**32;
		$num -= 2**32 if $num >= 2**31;

		use integer;
		new JE::Number $_global,
			$num ^ shift->to_number->[0];
	};
	*{'in|'} = sub {
		my $num = shift->to_number->[0];
		$num = 
			$num != $num || abs($num) == inf
			? $num = 0
			: int($num) % 2**32;
		$num -= 2**32 if $num >= 2**31;

		use integer;
		new JE::Number $_global,
			$num | shift->to_number->[0];
	};
}

=begin for me

Types of expressions:

'leftexpr' 'new' term subscript* args

'leftexpr' 'new'+ term subscript*

'leftexpr' term ( subscript | args) *  

'postfix' term op

'hash' term*

'array' term? (comma term?)*

'prefix' op+ term

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

sub eval {  # evalate (sub)expression
	my $expr = shift;

	my $type = $$expr[1];
	my @labels;

	if ($type eq 'expr') {
		_eval_term $_ for @$expr[2..$#$expr-1];
		return _eval_term $$expr[-1];
	}
	if ($type eq 'assign') {
		my @copy = @$expr[2..$#$expr];
		# Evaluation is done left-first in JS, unlike in
		# Perl, so a = b = c is evaluated in this order:
		#  - evaluate a
		#  - evaluate b
		#  - evaluate c
		#  - assign c to b
		#  - assign b to a

		# Check first to see whether we have the terms
		# of a ? : at the end:
		my @qc_terms = @copy >= 3 && $copy[-2] !~ /=\z/
			? (pop @copy, pop @copy) : ();
			# @qc_terms is now in reverse order

		# Make a list of operands, evalling each
		my @terms = _eval_term shift @copy;
		my @ops;
		while(@copy) {
			push @ops, shift @copy;
			push @terms, _eval_term shift @copy;
		}

		my $val = pop @terms;		

		# Now apply ? : if it's there
		@qc_terms and $val = _eval_term
			$qc_terms[$val->to_boolean->[0]];

		for (reverse @ops) {
			no strict 'refs';
			length > 1 and $val =
				&{'in'.substr $_,0,-1}(
					$terms[-1], $val
				);
			$val = $val->get if ref $val eq 'JE::LValue'; 
			$val = (pop @terms)->set($val);
		}
		return $val;
	}
	if($type eq 'lassoc') { # left-associative
		my @copy = @$expr[2..$#$expr];
		my $result = _eval_term shift @copy;
		while(@copy) {
			no strict 'refs';
			$result = $copy[0] eq '&&' ?
				$result->to_boolean->[0]
				? _eval_term($copy[1])
				: $result
			: $copy[0] eq '||' ?
				$result->to_boolean->[0]
				? $result
				: _eval_term($copy[1])
			: &{'in' . $copy[0]}(
				$result, _eval_term $copy[1]
			);
			splice @copy, 0, 2; # double shift
		}
		return $result;
	}
	if ($type eq 'prefix') {
		# $$expr[1]     -- 'prefix'
		# @$expr[2..-2] -- prefix ops
		# $$expr[-1]    -- operand
		my $term = _eval_term $$expr[-1];

		no strict 'refs';
		$term = &{"pre$_"}($term) for reverse @$expr[2..@$expr-2];
		return $term;
	}
	if ($type eq 'postfix') {
		# ~~~ These are supposed to use the same rules
		#     as the + and - infix ops for the actual
		#     addition part. Verify that they do this.

		my $ret = (my $term = _eval_term $$expr[2])
			->to_number;
		$term->set(new JE::Number $_global,
			$ret + (-1,1)[$$expr[3] eq '++']);
		return $ret;
	}
	if ($type eq 'leftexpr') {
	# 1. 'leftexpr' 'new' term subscript* args
	# 2. 'leftexpr' 'new'+ term subscript*
	# 3. 'leftexpr' term ( subscript | args) *  

		if(ref $$expr[2] eq 'new') {
			if(ref $$expr[-1] eq 'JE::Code::Arguments') {
				# Type 1:
				my $obj = _eval_term $$expr[3];
				for (@$expr[4..$#$expr-1]) {
					$obj = $obj->prop(
						$_->str_val
					);
					# ~~~ need some error-checking
				}
				return $obj->construct($$expr[-1]->list);
			}
			else { # Type 2:
				my $new_count = 1;
				for (@$expr[3..$#$expr]) {
					++$new_count, last
						if ref eq 'new';
				}
				my $obj = _eval_term $$expr[2+$new_count];
				for (@$expr[3+$new_count..$#$expr]) {
					$obj = $obj->prop(
						$_->str_val
					);
					# ~~~ need some error-checking
				}
				$obj = construct $obj for 1..$new_count;
				return $obj;
			}
		}
		# Type 3:

		my $obj = _eval_term $$expr[2];

		for (@$expr[3..$#$expr]) {
			if(ref eq 'JE::Code::Subscript') {
				$obj = new JE::LValue $obj, $_->str_val;
			}
			else {
				$obj = $obj->call($_->list);
				# If $obj is an lvalue,
				# JE::LValue::call will make
				# the lvalue's base object the 'this'
				# value. Otherwise,
				# JE::Object::Function::call 
				# will make the
				# global object the 'this' value.
			}
			# ~~~ need some error-checking
		}
		return $obj; # which may be an lvalue
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
	if ($type eq 'func') {
		# format: [[...], function=> 'name',
		#          [ params ], $statements_obj] 
		#     or: [[...], function =>
		#          [ params ], $statements_obj] 
		my($name,$params,$statements) = ref $$expr[2] ?
			(undef, @$expr[2,3]) : @$expr[2..4];
		my $func_scope = $name
			? bless([@$_scope, new JE::Object $_global], 
				'JE::Scope')
			: $_scope;
		my $f = new JE::Object::Function {
			scope    => $func_scope,
			name     => $name,
			argnames => $params,
			function => bless {
				global => $_global,
				# ~~~ source => how do I get it? Do we need it? (for error reporting)
				tree => $statements,
			}, 'JE::Code'
		};
		$name and $func_scope->new_var($name => $f);
		return $f;
	}
}
sub _eval_term {
	my $term = shift;

	while (ref $term eq 'JE::Code::Expression') {
		$term = $term->eval;
	}
	ref $term ? $term : $term eq 'this' ?
				$_this : $_scope->var($term);
}




package JE::Code::Subscript;

our $VERSION = '0.004';

sub str_val {
	my $val = (my $self = shift)->[1];
	ref $val ? ''.$val->eval : $val; 
}




package JE::Code::Arguments;

our $VERSION = '0.004';

sub list {
	my $self = shift;
	map { my $val = JE::Code::Expression::_eval_term($_);
	      ref $val eq 'JE::LValue' ? $val->get : $val }
	    @$self[1..$#$self];
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


