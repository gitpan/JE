package JE::Number;

our $VERSION = '0.002';

use strict;
use warnings;

use overload fallback => 1,
	'0+' => 'value',
	 cmp =>  sub { "$_[0]" cmp $_[1] };

require JE::String;
require JE::Boolean;
require JE::Object::Number;



# Each JE::Number object is an array ref like this: [value, global object]

sub new    { # If this is changed to use regexps, JE::Code::_re_num and
             # JE::Code::_re_hex need to be changed.
	my ($class,$global,$val) = @_;
	
	$val eq '+Infinity' and $val = 'Infinity';

	bless [$val, $global], $class;
}


sub prop {
	if(@_ > 2) { return $_[2] } # If there is a value, just return it

	my ($self, $name) = @_;
	
	JE::Object::Number->new($$self[1], $self)->prop($name);
}

sub props {
	my $self = shift;
	JE::Object::Number->new($$self[1], $self)->props;
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

sub call   { die }
sub apply  { die }
sub construct { die }


sub typeof    { 'number' }
sub id        { 'num:' . shift->value }
sub primitive { 1 }

sub to_primitive { $_[0] }
sub to_boolean   {
	my $value = (my $self = shift)->[0];
	JE::Object::Number->new($$self[1],
		$value == 0 && $value !~ /^-?Infinity/);
}

sub to_string { # ~~~ I  need  to  find  out  whether Perl's  number
                #     stringification is consistent with E 9.8.1 for
                #     finite numbers.
	my $value = (my $self = shift)->[0];
	JE::String->new($$self[1],
		$value == 'inf'  ?  'Infinity' :
		$value == '-inf' ? '-Infinity' :
		$value == $value ? $value :
		'NaN'
	);
}

*to_number = \& to_primitive;

sub to_object {
	my $self = shift;
	JE::Object::Number->new($$self[1], $self);
}


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
in use between this and JE::Object::Number is that that module implements
number
I<objects,> while this module implements the I<primitive> values.

Right now, this module simply uses Perl numbers underneath for storing
the JavaScript numbers (except for NaN, +Infinity and -Infinity). I do not
know whether Perl numbers are in accord with the IEEE 754 standard that
ECMAScript uses. Could someone knowledgeable please inform me?

The C<new> method accepts a global (JE) object and a Perl scalar as its 
two arguments. The latter can be a
Perl number or a string matching
S<< C</^( Nan | [+-]?infinity )\z/s> >>.

The C<value> method produces a Perl scalar. The C<0+> numeric operator is
overloaded and produces the same.

B<To do:> Make it use Perl's 'nan' and 'inf' values. When I started writing
this, I didn't know that Perl supported these.

=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::Object::Number

=cut




