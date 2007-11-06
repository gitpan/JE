package JE::Object::String;

our $VERSION = '0.018';


use strict;
use warnings;

sub surrogify($);
sub desurrogify($);

our @ISA = 'JE::Object';

use Scalar::Util 'blessed';

require JE::Code;
require JE::Object                 ;
require JE::Object::Error::TypeError;
require JE::Object::Function        ;
require JE::String                 ;

JE::String->import(qw/surrogify desurrogify/);
JE::Code->import('add_line_number');
sub add_line_number;

=head1 NAME

JE::Object::String - JavaScript String object class

=head1 SYNOPSIS

  use JE;
  use JE::Object::String;

  $j = new JE;

  $js_str_obj = new JE::Object::String $j, "etetfyoyfoht";

  $perl_str = $js_str_obj->value;

=head1 DESCRIPTION

This class implements JavaScript String objects for JE. The difference
between this and JE::String is that that module implements
I<primitive> string value, while this module implements the I<objects.>

=head1 METHODS

See L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object::String is explained here.

=over 4

=cut

sub new {
	my($class, $global, $val) = @_;
	my $self = $class->SUPER::new($global, {
		prototype => $global->prop('String')->prop('prototype')
	});

	$$$self{value} = defined $val
		? defined blessed $val
		  && $val->can('to_string')
			? $val->to_string->[0]
			: surrogify $val
		: '';
	$self;
}

sub prop {
	my $self = shift;
	if($_[0] eq 'length') {
		return length $$$self{value};
	}
	SUPER::prop $self @_;
}

sub delete {
	my $self = shift;
	$_[0] eq length and return !1;
	SUPER::delete $self @_;
}

=item value

Returns a Perl scalar.

=cut

sub value { desurrogify shift->{value} }




sub is_readonly {
	my $self = shift;
	$_[0] eq length and return 1;
	SUPER::is_readonly $self @_;
}

sub class { 'String' }

no warnings 'qw';
our %_replace = qw/
	$	\$
	&	".substr($str,$-[0],$+[0]-$-[0])."
	`	".substr($str,0,$-[0])."
	'	".substr($str,$+[0])."
/;

sub _new_constructor {
	my $global = shift;
	my $f = JE::Object::Function->new({
		name            => 'String',
		scope            => $global,
		function         => sub {
			my $arg = shift;
			defined $arg ? $arg->to_string :
				JE::String->new($global, '');
		},
		function_args    => ['args'],
		constructor      => sub {
			unshift @_, __PACKAGE__;
			goto &new;
		},
		constructor_args => ['scope','args'],
	});

	$f->prop({
		name  => 'fromCharCode',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'fromCharCode',
			length => 1,
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $str = '';
				my $num;
				for (@_) {
					$num = $_->to_number->value %
						2**16 ;
					$str .= chr $num == $num && $num;
						# change nan to 0
				}
				JE::String->new($global, $str);
			},
		}),
		dontenum => 1,
	});

	my $proto = bless $f->prop({
		name    => 'prototype',
		dontenum => 1,
		readonly => 1,
	}), __PACKAGE__;
	$$$proto{value} = '';

	$proto->prop({
		name  => 'toString',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global, add_line_number
					"Argument to toString is not a " .
					"String object"
				) unless $self->class eq 'String';

				JE::String->new($global, $$$self{value});
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'valueOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'valueOf',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global, add_line_number
					"Argument to valueOf is not a " .
					"String object"
				) unless $self->class eq 'String';

				JE::String->new($global, $$$self{value});
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'charAt',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'charAt',
			argnames => ['pos'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my ($self,$pos) = @_;
				
				my $str = $self->to_string->[0];
				if (defined $pos) {
					$pos = int $pos->to_string->[0];
					$pos = 0 unless $pos == $pos;
				}

				JE::String->new($global,
					$pos < 0 || $pos >= length $str
						? ''
						: substr $str, $pos, 1);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'charCodeAt',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'charCodeAt',
			argnames => ['pos'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my ($self,$pos) = @_;
				
				my $str = $self->to_string->[0];
				if (defined $pos) {
					$pos = int $pos->to_string->[0];
					$pos = 0 unless $pos == $pos;
				}

				JE::Number->new($global,
					$pos < 0 || $pos >= length $str
					    ? 'nan'
					    : ord substr $str, $pos, 1);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'concat',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'concat',
			length => 1,
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my $str = '';
				for (@_) {
					$str .= $_->to_string->[0]
				}
				JE::String->new($global, $str);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'indexOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'indexOf',
			length => 1,
			argnames => [qw/searchString position/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				JE::Number->new($global, index
					shift->to_string->[0],
					defined $_[0]
						? $_[0]->to_string->[0]
						: 'undefined',
					defined $_[1]
						? $_[1]->to_number->value
						: 0
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'lastIndexOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'lastIndexOf',
			length => 1,
			argnames => [qw/searchString position/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				JE::Number->new($global, rindex
					shift->to_string->[0],
					defined $_[0]
						? $_[0]->to_string->[0]
						: 'undefined',
					defined $_[1]
					    && $_[1]->id ne 'undef'
						? $_[1]->to_number->value
						: ()
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({   # ~~~ I need to figure out how to deal with
	                #     locale settings
		name  => 'localeCompare',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'localeCompare',
			argnames => [qw/that/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my($this,$that) = @_;
				JE::Number->new($global,
					$this->to_string->value	
					   cmp
					defined $that
						? $that->to_string->value
						: 'undefined'
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'match',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'match',
			argnames => [qw/regexp/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my($str, $re_obj) = @_;

				$str = $str->to_string;

				!defined $re_obj || 
					$re_obj->class ne 'RegExp'
				 and $re_obj =	
					JE::Object::RegExp->new($global, 
						$re_obj);
		
				my $re = $re_obj->value;

				# For non-global patterns and string, reg-
				# exps, just return the fancy array result-
				# from a call to String.prototype.exec

				if (not $re_obj->prop('global')->value) {
					return $global->prop('RegExp')
						->prop('prototype')
						->prop('exec')
						->apply($re_obj, $str);
				}

				# For global patterns, I just do the
				# matching here, since it's faster.

				# ~~~ Problem: This is meant to call String
				#   .prototype.exec, according to the spec,
				#  which method can, of course, be replaced
				# with a user-defined function. So much for
				# this optimisation. (But, then, no one
				# else follows the spec!)
				
				$str = $str->[0];

				my @ary;
				while($str =~ /$re/g) {
					push @ary, JE::String->new($global,
						substr $str, $-[0],
						$+[0] - $-[0]);
				}
				
				JE::Object::Array->new($global, \@ary);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'replace',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'replace',
			argnames => [qw/searchValue replaceValue/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my($str, $foo, $bar) = @_;
					# as in s/foo/bar/

				my $g; # global?
				if(defined $foo && $foo->class eq 'RegExp') 
				{
					$g = $foo->prop('global')->value;
					$foo = $$$foo{value};
				}
				else {
					$g = !1;
					$foo = defined $foo
					   ? quotemeta $foo->to_string->[0]
					   : 'undefined';
				}

				if (defined $bar &&
				    $bar->class eq 'Function') {
					my $je_str = JE::String->new(
						$global, $str);

					no strict 'refs'; # for map $$_
					# The following two s///'s are
					# identical except for the /g
					$g
					? $str =~ s/$foo/$bar->call(
					    JE::String->new($global,
					        substr $str, $-[0],
					            $+[0] - $-[0]),
					    map(JE::String->new($global,
					        $$_), 1..$#+),
					    JE::Number->new($global,
					        $-[0]),
					    $je_str
					  )->to_string->[0]/ge
					: $str =~ s/$foo/$bar->call(
					    JE::String->new($global,
					        substr $str, $-[0],
					            $+[0] - $-[0]),
					    map(JE::String->new($global,
					        $$_), 1..$#+),
					    JE::Number->new($global,
					        $-[0]),
					    $je_str
					  )->to_string->[0]/e;
				}
				else {
					# replacement string instead of
					# function (a little tricky)

					# We need to use /ee and surround
					# bar with double quotes, so that
					# '$1,$2' becomes eval  '"$1,$2"'.
					# And so we also have to quotemeta
					# the whole string.

					# I know the indiscriminate
					# untainting may seem a little
					# dangerous, but quotemeta takes
					# care of it.
					$bar = defined $bar
					   ? do {
					      $bar->to_string->[0]
					          =~ /(.*)/s; # untaint
					      quotemeta $1
					   }
					   : 'undefined';

					# now $1, $&, etc have become \$1,
					# \$\& ...

					$bar =~ s/\\\$(?:
						\\([\$&`'])
						  |
						(\\[1-9][0-9]?|0[0-9])
					)/
						defined $1 ? $_replace{$1}
						: "\$$2"
					/gex;

					$g ? s/$foo/"$bar"/gee
					   : s/$foo/"$bar"/ee;
				}
					
				JE::String->new($global, $str);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'search',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'search',
			argnames => [qw/regexp/],
			no_proto => 1,
			function_args => ['this','args'],
			function =>
sub {
	my($str, $re) = @_;

	$re = defined $re ? $re->class eq 'RegExp' ? $re->value :
		JE::Object::RegExp->new($global, $re)->value : qr//;

	return JE::Number->new($global, $str->to_string->[0] =~ $re ?
		$-[0] :-1 );
}
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'slice',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'slice',
			argnames => [qw/start end/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
my($str, $start, $end) = @_;

$str = $str->to_string->[0];
my $length = length $str;

if (defined $start) {
	$start = int $start->to_number->value;
	$start = $start == $start && $start; # change nan to 0

	$start > $length and $start = $length;
}
else { $start =  0; }

if (defined $end) {
	if($end->id eq 'undef') {
		$end = undef
	}
	else {
		$end = int $start->to_number->value;
		$end = $end == $end && $end;

		$end > 0 ? ($end -= $length) : ($end ||= -$length)
	}
}

return  JE::String->new($global, substr $str, $start, $end);

			},
		}),
		dontenum => 1,
	});


=begin split notes

These are the possibitilites for the separator:

1. //
2. 'string'
3. /regexp/

Case 1: use separator as-is
Case 2: use quotemeta on the separator
Case 3: a successful zero-width match that occurs at the same position as
        the end of the previous match needs to be turned into a failure
        (no backtracking after the initial successful match), so as to
        produce the aardvark result below.

I can make / ... / fail on a successful null match by wrapping it in an
atomic group: /(?> ... )/

Perl automatically behaves as though something similar to the following is
appended to the regexp: (?(?{ $pos == pos })(?!)|(?{ $pos = pos }))

But I also need to make sure that a null match does not occur at the end of
a string. Since a successful match that begins at the end of a string can-
not but be a zero-length match, this should take care of that:

/(?!\z)(?> ... )/


join ',', split /a*?/, 'aardvark'       gives ',,r,d,v,,r,k'
'aardvark'.split(/a*?/).toString()      gives 'a,a,r,d,v,a,r,k'

/(?=\w)a*?/ has to produce the same result.

-----
JS's 'aardvark'.split('', 3) means (split //, 'aardvark', 4)[0..2]

=end split notes

=cut


	$proto->prop({
		name  => 'split',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'split',
			argnames => [qw/separator limit/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
my($str, $sep, $limit) = @_;

$str = $str->to_string->[0];

if(!defined $limit || $limit->id eq 'undef') {
	$limit = -2;
}
elsif(defined $limit) {
	$limit = int($limit->to_number->value) % 2 ** 32;
	$limit = $limit == $limit && $limit;  # Nan --> 0
}

if (defined $sep) {
	if ($sep->class eq 'RegExp') {
		$sep = $sep->value;
	}
	else {
		$sep = $sep->to_string->[0];
	}
}
else {
	$sep = '';
}

my $pos = 0;

if (!ref $sep) { $sep = quotemeta $sep }
elsif ($sep !~ /^\(\?-\w*:(?:\(\?\w*:\))?\)\z/ # empty regex
      ) {
	$sep = qr/(?!\z)(?>$sep)/;
}

my @split = split $sep, $str, $limit+1;
JE::Object::Array->new($global,
	$limit == -2 ? @split : @split[0..$limit-1]);

			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'substring',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'substring',
			argnames => [qw/start end/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
my($str, $start, $end) = @_;

$str = $str->to_string->[0];
my $length = length $str;


if (defined $start) {
	$start = int $start->to_number->value;
	$start >= 0 or $start = 0;
}
else { $start =  0; }


if (!defined $end || $end->id eq 'undef') {
	$end = $length;
}
else {
	$end = int $end->to_number->value;
	$end >= 0 or $end = 0;
}

$start > $end and ($start,$end) = ($end,$start);

no warnings 'substr'; # in case start > length
return  JE::String->new($global, substr $str, $start, $end-$start);

			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toLowerCase',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toLowerCase',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $str = shift;

				JE::String->new($global,
					lc $str->to_string->[0]);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toLocaleLowerCase',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toLocaleLowerCase',
			no_proto => 1,
			function_args => ['this'],
			function => sub { # ~~~ locale settings?
				my $str = shift;

				JE::String->new($global,
					lc $str->to_string->value);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toUpperCase',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toUpperCase',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $str = shift;

				JE::String->new($global,
					uc $str->to_string->[0]);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toLocaleUpperCase',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toLocaleUpperCase',
			no_proto => 1,
			function_args => ['this'],
			function => sub { # ~~~ locale settings?
				my $str = shift;

				JE::String->new($global,
					uc $str->to_string->value);
			},
		}),
		dontenum => 1,
	});

	$f;
}



return "a true value";

=back

=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::String

=item JE::Object

=cut




