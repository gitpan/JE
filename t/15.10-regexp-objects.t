#!perl -T
do './t/jstest.pl' or die __DATA__

function joyne (sep,ary) { // Unlike the built-in, this does not convert
	var ret = '';      // undefined to an empty string.
	if(!(ary instanceof Array))return ary;
	for(var i = 0; i<ary.length;++i)ret +=(i?sep:'')+ary[i]
	return ret
}

// ===================================================
// 15.10.1 Pattern compilation
// 15 tests
// ===================================================

(function(){
function tcp /*try compiling pattern*/(re,tn/*test name*/) {
	try{ RegExp(re); pass('compilation of ' + tn)}
	catch(foo){fail('compilation of ' + tn), diag(foo)}
}

tcp('foo','alternative')
tcp('foo|foo','two-part disjunction')
tcp('foo|foo|foo','three-part disjunction')
tcp('','empty pattern')
tcp('^$\\b\\B','assertions')
tcp('f*o*?o+b+?a?r??b{0}a{33}?z{32,}a{98,}?o{6,7}e{32,54}?','quantifiers')
tcp('\nf\u0100\ud801.(foo)(?:foo)(?=foo)(?!foo)', 'atoms')
tcp("\\0\\98732", 'decimal escapes')
tcp("\\f\\n\\r\\t\\v", 'control escapes')
tcp('\\ca\\cb\\cc\\cd\\ce\\cf\\cg\\ch\\ci\\cj\\ck\\cl\\cm\\cn\\co\\cp\\cq'
   +'\\cr\\cs\\ct\\cu\\cv\\cw\\cx\\cy\\cz', 'lc control letter escapes')
tcp('\\cA\\cB\\cC\\cD\\cE\\cF\\cG\\cH\\cI\\cJ\\cK\\cL\\cM\\cN\\cO\\cP\\cQ'
   +'\\cR\\cS\\cT\\cU\\cV\\cW\\cX\\cY\\cZ', 'uc control letter escapes')
tcp('\\x00\\u1234','hex & unicode escapes')
tcp('\\ \\\n\\.\\\ud801','identity escapes')
tcp('\\d\\D\\s\\S\\W\\W','character class escapes')
tcp('[foo][^bar][^][-][\nb][\u0100-\ud801][\1\b\f][\da-z]','char classes')

}())

// ===================================================
// 15.10.2.3 Disjunction
// 4 tests
// ===================================================

is(/foo|bar/.exec("foo")[0], 'foo',
	'disjunction w/left-hand side matching')
is(/foo|bar/.exec("bar")[0], 'bar',
	'disjunciton w/right-hand side matching')
is(/a|ab/.exec('abc'), 'a', 'disjunction (example in the spec.)')
is(joyne(',',/((a)|(ab))((c)|(bc))/.exec('abc')),
	'abc,a,a,undefined,bc,undefined,bc',
	'disjunction (another example in the spec.)')


// ===================================================
// 15.10.2.4 Alternative
// 2 tests
// ===================================================

is(new RegExp('').exec('abcdefg'), '', 'empty pattern')
is(/[xy]?(y|x)/.exec('yx')[1], 'x', 'backtracking within an alternative')


// ===================================================
// 15.10.2.5 Term
// ===================================================

// 2 tests: Term :: Assertion
ok(/x\b/.exec('x '),'term with matching assertion')
ok(!/x\b/.exec('xy'),'term with failing assertion')

// 2 tests: Term :: Atom Quantifier
try{new RegExp('a{3,2}'); fail('{n,m} where n > m')}
catch(cold){ok(cold instanceof SyntaxError, '{n,m} where n > m')}
is(/f{0}/.exec('abcdefg'), '', 'quantifier with 0 max')

// 4 tests: RepeatMatcher
is(/f{0,3}/.exec('ffff'), 'fff',
	'greedy quantifier that reaches its maximum')
is(/o{0,3}/.exec('oo'), 'oo',
	'greedy quantifier that falls short of its maximum')
is(/f{1,3}?/.exec('ffff'), 'f',
	'stingy quantifier that meets its minimum')
is(/o{1,3}?$/.exec('oo'), 'oo',
	'stingy quantifier that exceeds its minimum')

// 7 tests: Examples from the spec.
is(/a[a-z]{2,4}/.exec('abcdefghi'), 'abcde', 'term (example in the spec.)')
is(/a[a-z]{2,4}?/.exec('abcdefghi'), 'abc',
	'term (stingy example in the spec.)')
is(/(aa|aabaac|ba|b|c)*/.exec('aabaac'), 'aaba,ba',
	'term (choice point ordering example)')
is('aaaaaaaaaa,aaaaaaaaaaaaaaa'.replace(/^(a+)\1*,\1+$/,"$1"), 'aaaaa',
	'term (gcm example)')
is(joyne(',',/(z)((a+)?(b+)?(c))*/.exec("zaacbbbcac")), 
	'zaacbbbcac,z,ac,a,undefined,c', 'capture erasure')
is(/(a*)*/.exec('b'), ',', 'term (infinite loop example)')
is(/(a*)b\1+/.exec('baaaac'), 'b,', 'term (second infinite loop example)')

// 9 tests: Some more capture erasure tests
is(joyne(',',/((a)?b)+/.exec('abb')),'abb,b,undefined',
	'capture erasure ((a)?b)+')
is(joyne(',',/((a+)?b)+/.exec('abb')),'abb,b,undefined',
	'capture erasure ((a+)b)+')
is(joyne(',',/((?:|(a))b)+/.exec('abb')), 'abb,b,undefined',
	'capture erasure ((?:|(a))b)+')
is(joyne(',','ba'.match(/(a|(b))+/)),'ba,a,undefined',
	'capture erasure (a|(b))+')
is('cbazyx'.replace(/(a|(b))+/, "$1$2"), 'cazyx',
	'capture erasure with String.prototype.replace')
is('cbazyx'.replace(/(a|(b))+/,
    function($and,$1,$2){return $1+$2}), 'cazyx',
   'capture erasure w/String.prototype.replace w/ a function replacement')
is(joyne(',','cbazyx'.split(/(a|(b))+/)), 'c,a,undefined,zyx',
	'capture erasure String.prototype.split')
is(joyne(',',/(?:a(b)?bc)+/.exec('abbcabc')), 'abbcabc,undefined',
	'capture erasure with backtracking')
is(joyne(',',/(?:a(b)?bc)+..c/.exec('abbcabc')), 'abbcabc,b',
	'make sure backtracking does not cause undue capture erasure')


// ===================================================
// 15.10.2.6 Assertion
// ===================================================

// ~~~ ...

// ===================================================
// 15.10.2.8 Atom
// ===================================================

// ...

// 6 tests: interrobang groups

is (joyne(',',/(?!(foo)(?!))/.exec('foo')), ',undefined',
	'interrobang with captures');
is (joyne(',',/(?!(a)b)/.exec('ab')), ',undefined',
	'interrobang with captures (another)');
is (joyne(',',/(?!(a)|b)c/.exec('ac')), 'c,undefined',
	'interrobang with captures (yet another)');
is (joyne(',',/(?!(a)(?!)){0}/.exec('a')), ',undefined',
	'quantified interrobang')
is (joyne(',',/(?:(?!(a)(?!)){0})/.exec('a')), ',undefined',
	'quantified interrobang inside another group')
is(peval('my $warnings=0; local $SIG{__WARN__}=sub{++$warnings};'
     + '$je->{RegExp}("(?!(a)(?!))+"); $warnings;'
   ),0, 'quantified interrobangs don\'t warn')

// ...


// ===================================================
// 15.10.6.3 test
// 2 tests
// ===================================================

ok(/(.)(.)(.)+/.test("abcd") === true, 'test returning true')
ok(/./.test("\n") === false, 'test returning false');

// ===================================================
// 15.10.6.4 toString
// 31 tests
// ===================================================

(function(){
	var re_strs =("/a/i /a/g /a/m /a/mg /a/gi /a/mi /a/mgi /a/ "
	            + "/^[^a]/ /^[^a]/m /$[$]/ /$[$]/m /\\b[\\b]/ /\\B/ "
	            + "/.[.]/ /\\v[\\v]/ /\\n[\\n]/ /\\r[\\r]/ "
	            + "/\\c`[\\c`]/ /\\u1234[\\uabcD]/ /\\d[\\d]/ "
	            + "/\\D[\\D]/ /\\s[\\s]/ /\\S[\\S]/ /\\w[\\w]/ "
	            + "/\\W[\\W]/ /[^]/ /[.a]/ /[a]/ /[.]/ /[\\D\\W]/"
	             )
	.split(' ');
	for (var i = 0;i<re_strs.length;++i)
		is(eval(re_strs[i]).toString(),re_strs[i],
			re_strs[i]+'.toString()');
}())

// ---------------------------------------------------
// 1 test: Make sure exec can be called */

try{is(/a/.exec('a'), 'a', 'exec doesn\'t simply die')}
catch(e){fail('exec doesn\'t simply die')}


// ===================================================
// Perl features that begin with (
// (The regexp-munging has special cases for most of these, so we have
// to test them individually.)  
// 48 tests
// ===================================================

is(new RegExp("fo(?#(li)o").exec('foo'), 'foo', '(?#...)');
is(new RegExp("(?x)fo( ?#(li)o").exec('foo'), 'foo', '( ?#...)');
is(/f(?im-sx)Oo/.exec('foo'), 'foo', '(?mod)')
is(/(?x)f( ?im-sx)Oo/.exec('foo'), 'foo', '( ?mod)')
is(RegExp("f(?i:(O))o").exec('foo'), 'foo,o','(?mod:)');
is(RegExp("(?x)f( ?i:(O))o").exec('foo'), 'foo,o','( ?mod:)');
is(/.(?<=(f)oo)/.exec('foo'), 'o,f', '(?<=)')
is(/.( ?<=(f)oo)/x.exec('foo'), 'o,f', '( ?<=)')
is( /(?<!f(o)o)bar./ .exec('foobarrbard')[0], 'bard', '(?<!)')
is(/( ?<!f(o)o)bar./x.exec('foobarrbard')[0], 'bard', '( ?<!)')
is(/(foo)(?(1)bar)(baz)?(?(2)(bonk))ers/.exec('phfoobarers'),
	'foobarers,foo,,', '(?())')
is(/(foo)( ?(1)bar)(baz)?( ?(2)(bonk))ers/x.exec('phfoobarers'),
	'foobarers,foo,,', '( ?())')
is(/(foo)(?(1)bar|(ba))(?(2)(x)|y)/.exec('foobarx foobary'),
	'foobary,foo,,', '(?()|)')
is(/(foo)( ?(1)bar|(ba))( ?(2)(x)|y)/x.exec('foobarx foobary'),
	'foobary,foo,,', '( ?()|)')
is(/(?>()a+)(?<!aaa)../.exec('aaaaa aabc'), 'aabc,', '(?>)')
is(/( ?>()a+)(?<!aaa)../x.exec('aaaaa aabc'), 'aabc,', '( ?>)')

function dies(what,name,like) {
	try{ eval(what); fail(name); diag(name + ' doesn\'t die') }
	catch($at){ 
		if(like) ok(($at+'').match(like),name) || diag($at)
	}
}
dies('/(?{})/', '(?{})', 'mbedded')
dies('/(??{})/', '(??{})', 'mbedded')
dies('/(?p{})/', '(?p{})', 'mbedded')
dies('/( ?{})/x', '( ?{})', 'mbedded')
dies('/( ??{})/x', '( ??{})', 'mbedded')
dies('/( ?p{})/x', '( ?p{})', 'mbedded')
dies('/(?(?{}))/', '(?({}))', 'mbedded')

// These five don’t actually work in Perl, but if they ever do work we need
// to block them:
0,function(){
	var a  = ['/(?(??{}))/','/(?(?p{}))/','/(?( ?{}))/x',
	          '/(?( ??{}))/x','/(?( ?p{}))/x']
	for(var i = 0; i < a.length; ++ i)
		try{
			if(peval('use re "eval";' + a[i] + ";1"))
				dies(a[i],a[i],'mbedded')
			else skip ('unnecessary',1)
		}catch(e){}
}()

try{peval('$]')<5.01&&skip('Perl version < 5.10',20)
	// You can’t put regexp literals here because they will cause com-
	// pilation to fail in 5.8.x.
	try{skip('not yet supported', 2);
		is(joyne(',',
		     RegExp('(?|(f)(o)(o)|(b)a(r))+').exec('foobar')
		   ), 'foobar,b,undefined', '(?|)')
		is(joyne(',',
		     RegExp('(?x)( ?|(f)(o)(o)|(b)a(r))+').exec('foobar')
 		   ), 'foobar,b,undefined', '( ?|)')
	}catch(eoneou){}
	is(RegExp('foo(?0)?bar').exec('phoofoofoobarbarbarr'),
		'foofoobarbar', '(?0)')
	is(RegExp('foo( ?0)?bar','x').exec('phoofoofoobarbarbarr'),
		'foofoobarbar', '( ?0)')
	is(RegExp('foo(?R)?bar').exec('phoofoofoobarbarbarr'),
		'foofoobarbar', '(?R)')
	is(RegExp('foo( ?R)?bar','x').exec('phoofoofoobarbarbarr'),
		'foofoobarbar', '( ?R)')
	is(RegExp('foo(?1)bar|(baz)(?!)').exec('phoofoobazbarbump'),
		'foobazbar,', '(?1)')
	is(RegExp('foo( ?1)bar|(baz)(?!)','x').exec('phoofoobazbarbump'),
		'foobazbar,', '( ?1)')
	is(RegExp('()foo(?+1)bar|(baz)(?!)').exec('hoofoobazbarbump'),
		'foobazbar,,', '(?+1)')
	is(RegExp('()foo( ?+1)bar|(baz)(?!)','x').exec('hoofoobazbarbump'),
		'foobazbar,,', '( ?+1)')
	is(RegExp('()(baz)(?!)()|foo(?-2)bar').exec('ofoobazbarbump'),
		'foobazbar,,,', '(?-2)')
	is(RegExp('()(baz)(?!)()|foo( ?-2)bar','x').exec('ofoobazbarbump'),
		'foobazbar,,,', '( ?-2)')
	is(RegExp('a+(*PRUNE)(?<!aaa)..').exec('aaaaa aabc'), 'aabc',
		'(*PRUNE)')
	is(RegExp('a+( *PRUNE)(?<!aaa)..','x').exec('aaaaa aabc'), 'aabc',
		'( *PRUNE)')
	is(RegExp('(.)\\1*(*:foo)(?:b(*SKIP:foo)(*FAIL)|c)')
		.exec('aaabbbccc')[0],
	  'bbbc', '(*:foo) (*bar:baz) (*bonk) syntax')
	is(RegExp('(.)\\1*( *:foo)(?:b( *SKIP:foo)( *FAIL)|c)','x')
		.exec('aaabbbccc')[0],
	  'bbbc', '( *:foo) ( *bar:baz) ( *bonk) syntax')
	is(RegExp(
	     "(?'foo'f..)(?<bar>b..)(?P<baz>p..)(?&foo)(?&bar)(?&baz)"
	   ).exec('   fgcbmwpyffgcbmwpyf.fedei'),
	   'fgcbmwpyffgcbmwpyf,fgc,bmw,pyf', 'named captures'
	)
	is(RegExp(
	    "( ?'foo'f..)( ?<bar>b..)( ?P<baz>p..)( ?&foo)( ?&bar)( ?&baz)"
	    ,'x'
	   ).exec('   fgcbmwpyffgcbmwpyf.fedei'),
	   'fgcbmwpyffgcbmwpyf,fgc,bmw,pyf', '( ?...)-style named captures'
	)
	is(RegExp(
	    "(?'foo'f..())(?<bar>b..())(?P<baz>p..())(?&foo)(?&bar)(?&baz)"
	   ).exec('   fgcbmwpyffgcbmwpyf.fedei'),
	   'fgcbmwpyffgcbmwpyf,fgc,,bmw,,pyf,',
	   'named captures with nested regular captures'
	)
	is(RegExp(
	    "( ?'foo'f..())( ?<bar>b..())( ?P<baz>p..())" +
	    "( ?&foo)( ?&bar)( ?&baz)"
	    ,'x'
	   ).exec('   fgcbmwpyffgcbmwpyf.fedei'),
	   'fgcbmwpyffgcbmwpyf,fgc,,bmw,,pyf,',
	   '( ?...) named captures with nested regular captures'
	)
}catch($){}


// ===================================================
// Miscellaneous tests  
// ===================================================

// 5 tests: Regexps with surrogates

testname = 'surrogates in regexps don\'t cause fatal errors';
try{ new RegExp('\ud800'); pass(testname) }
catch(e){fail(testname)}

testname = 'surrogates in regexp char classes don\'t cause fatal errors';
try{ new RegExp('[\ud800]'); pass(testname) }
catch(e){fail(testname)}

ok('\ud800'.match(new RegExp('\ud800')),
	'regexps with surrogates in them work')
is(joyne(',',/(?:(a)?(b)?(c))+/.exec('abcc')),'abcc,undefined,undefined,c',
	'(?: ( )? ( )? )')
is(joyne(',',/a|(b)/.exec('a')),'a,undefined', 'a|(b)')


/// 4 tests: Make sure that our special capture-handling doesn’t break reg-
//          exps that originate from Perl
/*
function PerlRegExp(re) {
	return peval('new JE::Object::RegExp $je, qr/${\\shift}/',re)
	// ~~~ (This constructor doesn’t currently support qr//'s. It
	//      stringifies them.)
}

is(PerlRegExp('(a).').exec('abb'), 'ab,a',
	'exec with qr/()/')
is('ba'.match(PerlRegExp('(.).')),'ba,b',
	'String.prototype.match with qr/()/')
is('cbazyx'.replace(PerlRegExp('b(.)'), "$1"), 'cazyx',
	'String.prototype.replace with qr/()/')
is('cbazyx'.replace(PerlRegExp('b(.)'),
    function($and,$1){return $1}), 'cazyx',
	'String.prototype.replace with qr/()/ and a function')
*/

diag('TO DO: Finish writing this test script');
