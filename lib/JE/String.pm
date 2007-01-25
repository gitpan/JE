package JE::String;


=begin stuff for MakeMaker

use JE; our $VERSION = $JE::VERSION;

=end

=cut


use strict;
use warnings;

use overload fallback => 1,
	'""' => 'value',
	 cmp =>  sub { $_[0]->value cmp $_[1] };

require JE::Object::String;


# ~~~ But I need to figure out a way to prevent a never-ending loop,
#     since  JE::Object::String will  itself  use  the  methods  of 
#     this class.

sub new {
	my($class, $val, $self) = (shift,shift);
	if(UNIVERSAL::isa($val,'UNIVERSAL') and $val->can('to_string')) {
		$self = bless \${'' . $val->to_string}, $class;
		# ~~~ I should be able simply to say  '$self = $val',
		#     but that would prevent subclassing.  But would
		#     anyone have any reason to subclass a primitive?
		#     Someone please help me make up my mind.
	}
	else {
		# surrogify:
		# ~~~ do char class ranges work this way?
		$val =~ s<([^\0-\x{ffff}])><    no warnings 'utf8';
			  chr((ord($1) - 0x10000) / 0x400 + 0xD800)
			. chr((ord($1) - 0x10000) % 0x400 + 0xDC00)
		>eg;
					
		# objectify:

		$self = bless \$val, $class;
	}
	$self;
}



# This module implements basic string methods and properties.  If a
# requested (as opposed to set)  prop/method is not dealt with here,
# the String prototype is checked, and if the property exists there,
# a new JE::Object::String is then created, to provide the
# method/property.

# The check is necessary to avoid an infinite loop, as
# JE::Object::String itself uses the methods here.

# ~~~ sub prop

sub method {
	my $self = shift;
	for (shift) {
		if($_ eq 'concat') { # ~~~ See  whether this  is  pre-
		                     #     cisely  according to  spec.
		                     #     Specifically, does it take
		                     #     just one arg?
			return bless \($$self . ${shift->to_string});
		}
		# ~~~ add the rest of the basic string methods

		# ~~~ deal with the stuff pertaining to String
		#     objects here.
	}
}


sub value {  # unsurrogify:
	my $ret = ${+shift};
	$ret =~ s/([\x{d800}-\x{dbff}])([\x{dc00}-\x{dfff}])/
		chr 0x10000 + ($1 - 0xD800) * 0x400 + ($2 - 0xDC00)
	/ge;
	$ret;
 }

sub typeof    { new JE::String 'string' }
sub id        { 'str:' . shift->value }
sub primitive { 1 }

sub to_primitive { $_[0] }
sub to_string    { $_[0] }



1;
__END__

=head1 NAME

JE::String - JavaScript string value

=head1 SYNOPSIS

  use JE::String;

  $js_str = new JE::String "etetfyoyfoht";

  $perl_str = $js_str->value;

  $js_str->id; # returns "str: etetfyoyfoht";

=head1 DESCRIPTION

This class implements JavaScript string values for JE. The difference
in use between this and JE::Object::String is that that module implements
string
I<objects,> while this module implements the I<primitive> values.

=head1 AUTHOR

Father Chrysostomos <sprout [at] cpan [dot] org>

=head1 SEE ALSO

=over 4

=item JE

=item JE::Object::String
