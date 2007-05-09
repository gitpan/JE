package JE::Number;

our $VERSION = '0.010';

use strict;
use warnings;


# I need constants for inf and nan, because perl 5.8.6 interprets the
# strings "inf" and "nan" as 0 in numeric context.

# This is what I get running Deparse on 5.8.6:
#    $ perl -mO=Deparse -e 'print 0+"nan"'
#    print 0;
#    $ perl -mO=Deparse -e 'print 0+"inf"'
#    print 0;
# And here is the output from 5.8.8 (PPC [big-endian]):
#    $ perl -mO=Deparse -e 'print 0+"nan"'
#    print unpack("F", pack("h*", "f78f000000000000"));
#    $ perl -mO=Deparse -e 'print 0+"inf"'
#    print 9**9**9;
# I don't know about 5.8.7.

# However, that 'unpack' does not work on little-endian Xeons running
# Linux. What I'm testing it on is running 5.8.5, so the above one-liners
# don't work. But I can use this:
#    $ perl -mO=Deparse -mPOSIX=fmod -e 'use constant nan=>fmod 0,0;print nan'
#    use POSIX (split(/,/, 'fmod', 0));
#    use constant ('nan', fmod(0, 0));
#    print sin(9**9**9);

# sin 9**9**9 also works on the PPC.



use constant nan => sin 9**9**9;
use constant inf => 9**9**9;

use overload fallback => 1,
	'""' => sub {
		my $value = $_[0][0];
		$value ==   inf  ?  'Infinity' :
		$value == -+inf  ? '-Infinity' :
		$value == $value ? $value :
		'NaN'
	 },
	'0+'  => 'value',
	 bool =>  sub {
		my $value = $_[0][0];
		$value && $value == $value;
	 },
	 cmp  =>  sub { "$_[0]" cmp $_[1] };

use Scalar::Util 'blessed';

require JE::String;
require JE::Boolean;
require JE::Object::Number;



# Each JE::Number object is an array ref like this: [value, global object]

sub new    {
	my ($class,$global,$val) = @_;
	
	if(defined blessed $val and can $val 'to_number') {
		my $new_val = $val->to_number;
		ref $new_val eq $class and return $new_val;
		eval { $new_val->isa(__PACKAGE__) } and
			$val = $new_val->[0],
			goto RETURN;
	}

	# For perls that don't interpret 0+"inf" as inf:
	if ($val =~ /^\s*([+-]?)(inf|nan)/i) {
		$val = lc $2 eq 'nan' ? nan :
			$1 eq '-' ? -(inf) : inf;
	}
	else { $val+=0 }

	RETURN:
	bless [$val, $global], $class;
}


sub prop {
	if(@_ > 2) { return $_[2] } # If there is a value, just return it

	my ($self, $name) = @_;
	
	JE::Object::Number->new($$self[1], $self)->prop($name);
}

sub keys {
	my $self = shift;
	JE::Object::Number->new($$self[1], $self)->keys;
}

sub delete {
	my $self = shift;
	JE::Object::Number->new($$self[1], $self)->delete(@_);
}

sub method {
	my $self = shift;
	JE::Object::Number->new($$self[1], $self)->method(@_);
}

sub value {
	shift->[0]
}

sub exists { !1 }

sub typeof    { 'number' }
sub class     { 'Number' }
sub id        { 
	my $value = shift->value;
	# This should (I hope) take care of systems that stringify nan and
	# inf oddly:
	'num:' . ($value eq   nan ?  'nan' : 
	          $value ==   inf ?  'inf' :
	          $value == -+inf ? '-inf' :
	          $value)
}
sub primitive { 1 }

sub to_primitive { $_[0] }
sub to_boolean   {
	my $value = (my $self = shift)->[0];
	JE::Boolean->new($$self[1],
		$value && $value == $value);
}

sub to_string { # ~~~ I  need  to  find  out  whether Perl's  number
                #     stringification is consistent with E 9.8.1 for
                #     finite numbers.
	my $value = (my $self = shift)->[0];
	JE::String->new($$self[1],
		$value ==   inf  ?  'Infinity' :
		$value == -(inf) ? '-Infinity' :
		$value == $value ? $value :
		'NaN'
	);
}

*to_number = \& to_primitive;

sub to_object {
	my $self = shift;
	JE::Object::Number->new($$self[1], $self);
}

sub global { $_[0][1] }


=head1 NAME

JE::Number - JavaScript number value

=head1 SYNOPSIS

  use JE;
  use JE::Number;

  $j = JE->new;

  $js_num = new JE::Number $j, 17;

  $perl_num = $js_num->value;

  $js_num->to_object; # returns a new JE::Object::Number

=head1 DESCRIPTION

This class implements JavaScript number values for JE. The difference
between this and JE::Object::Number is that that module implements
number
I<objects,> while this module implements the I<primitive> values.

Right now, this module simply uses Perl numbers underneath for storing
the JavaScript numbers. It seems that whether Perl numbers are in accord with the IEEE 754 standard that
ECMAScript uses is system-dependent. If anyone requires IEEE 754 
compliancy,
a patch would be welcome. :-)

The C<new> method accepts a global (JE) object and a number as its 
two arguments. If the latter is an object with a C<to_number> method whose
return value isa JE::Number, that object's internal value
will be used. Otherwise the arg itself is used. (The precise details of
the behaviour of C<new> when the second arg is a object are subject to
change.) It is numified Perl-style,
so 'nancy' becomes NaN
and 'information' becomes Infinity.

The C<value> method produces a Perl scalar. The C<0+> numeric operator is
overloaded and produces the same.

Stringification and boolification are overloaded and produce the same
results as in JavaScript

The C<typeof> and C<class> methods produce the strings 'number' and 
'Number', respectively.

=head1 SEE ALSO

=over 4

=item L<JE>

=item L<JE::Types>

=item L<JE::Object::Number>

=cut




