package JE::String;

our $VERSION = '0.015';


use strict;
use warnings;

use overload fallback => 1,
	'""' => 'value',
	 cmp =>  sub { "$_[0]" cmp $_[1] };

use Carp;
use Memoize;
use Scalar::Util 'blessed';
memoize 'desurrogify'; #, LIST_CACHE => 'MERGE';  # If a memoised func-
memoize 'surrogify'; #,  LIST_CACHE => 'MERGE';  # tion is  called  in
                                               # list context the first
                                             # time it is called with a
                                          # particular set of arguments,
                                       # LIST_CACHE => MERGE will  cause
                                   # an array ref to be cached instead of
                              # the actual return value, as of Memoize.pm
                        # version 1.01.

# ~~~ Perhaps memoize is a bad idea, because it would create a memory leak
#    of sorts.  Maybe we should cache the two strings in the  JE::String
#  object itself, so they will be collected as garbage when appropriate.
# And perhaps we need a 'value16' method (or 'utf16val', but that looks
# ugly and is harder to type),  for accessing the  surrogified  string.

our @ISA = 'Exporter';
our @EXPORT_OK = qw'surrogify desurrogify';

require JE::Object::String;
require JE::Boolean;
require JE::Number;
require Exporter;


sub new {
	my($class, $global, $val) = @_;
	defined blessed $global
	   or croak "First argument to JE::String->new is not an object";

	my $self;
	if(defined blessed $val and $val->can('to_string')) {
		$self = bless [$val->to_string->[0], $global], $class;
	}
	else {
		$self = bless [surrogify($val), $global], $class;
		ref $self->[0] eq "ARRAY" and print "look: " . ref $val;;
	}
	$self;
}


sub prop {
	 # ~~~ Make prop simply return the value if the prototype has that
	 #      property.
	my $self = shift;

	if ($_[0] eq 'length') {
		return length $$self[0];
	}

	JE::Object::String->new($$self[1], $self)->prop(@_);
}

sub keys {
	my $self = shift;
	$$self[1]->prop('String')->prop('prototype')->keys;
}

sub delete {
	my $self = shift;
	if ($_[0] eq 'length') { return !1 }
	JE::Object::String->new($$self[1], $self)->delete(@_);
}

sub method {
	my $self = shift;
	JE::Object::String->new($$self[1], $self)->method(@_);
}


sub value {
	desurrogify($_[0][0]);
}


sub typeof    { 'string' }
sub id        { 'str:' . $_[0][0] }
sub primitive { 1 }

sub to_primitive { $_[0] }
sub to_string    { $_[0] }
                                       # $_[0][1] is the global obj
sub to_boolean { JE::Boolean       ->new($_[0][1], length shift->[0]) }
sub to_object  { JE::Object::String->new($_[0][1], shift) }

our $s = qr.[\p{Zs}\s\ck]*.;

sub to_number  {
	my $value = (my $self = shift)->[0];
	JE::Number->new($self->[1],
		$value =~ /^$s
		  (
		    [+-]?
		    (?:
		      (?=[0-9]|\.[0-9]) [0-9]* (?:\.[0-9]*)?
		      (?:[Ee][+-]?[0-9]+)?
		        |
		      Infinity
		    )
		    $s
		  )?
		  \z
		/ox ? defined $1 ? $value : 0 :
		$value =~ /^$s   0[Xx] ([A-Fa-f0-9]+)   $s\z/ox ? hex $1 :
		'NaN'
	);
}

sub global { $_[0][1] }


sub desurrogify($) {
	my $ret = shift;
	my($ord1, $ord2);
	for(my $n = 0; $n < length $ret; ++$n) {  # really slow
		($ord1 = ord substr $ret,$n,1) >= 0xd800 and
		 $ord1                          <= 0xdbff and
		($ord2 = ord substr $ret,$n+1,1) >= 0xdc00 and
		$ord2                            <= 0xdfff and
		substr($ret,$n,2) =
		chr 0x10000 + ($ord1 - 0xD800) * 0x400 + ($ord2 - 0xDC00);
	}

	# In perl 5.8.8, if there is a sub on the call stack that was
	# triggered by the overloading mechanism when the object with the 
	# overloaded operator was passed as the only argument to 'die',
	# then the following substitution magically calls that subroutine
	# again with the same arguments, thereby causing infinite
	# recursion:
	#
	# $ret =~ s/([\x{d800}-\x{dbff}])([\x{dc00}-\x{dfff}])/
	# 	chr 0x10000 + (ord($1) - 0xD800) * 0x400 +
	#		(ord($2) - 0xDC00)
	# /ge;
	#
	# 5.9.4 still has this bug.

	$ret;
}

sub surrogify($) {
	my $ret = shift;

	no warnings 'utf8';

	$ret =~ s<([^\0-\x{ffff}])><
		  chr((ord($1) - 0x10000) / 0x400 + 0xD800)
		. chr((ord($1) - 0x10000) % 0x400 + 0xDC00)
	>eg;
	$ret;
}


1;
__END__

=head1 NAME

JE::String - JavaScript string value

=head1 SYNOPSIS

  use JE;
  use JE::String;

  $j = JE->new;

  $js_str = new JE::String $j, "etetfyoyfoht";

  $perl_str = $js_str->value;

  $js_str->to_object; # retuns a new JE::String::Object;

=head1 DESCRIPTION

This class implements JavaScript string values for JE. The difference
in use between this and JE::Object::String is that that module implements
string
I<objects,> while this module implements the I<primitive> values.

The stringification operator is overloaded.

=head1 THE FUNCTION

There is one exportable function, C<desurrogify>, which will convert
surrogate pairs in its string input argument into the characters they
represent, and return the modified string. E.g.:

  use JE::String 'desurrogify';
  
  {
          no warnings 'utf8';
          $str = "\x{d834}\x{dd2b}";
  }

  $str = desurrogify $str;  # $str now contains "\x{1d12b}" (double flat)

=head1 SEE ALSO

=over 4

=item L<JE>

=item L<JE::Types>

=item L<JE::Object::String>
