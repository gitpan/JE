package JE::Number;


=begin stuff for MakeMaker

use JE; our $VERSION = $JE::VERSION;

=end

=cut


use strict;
use warnings;

our @ISA = 'JE::Object::String';
require JE::Object::String;



sub typeof    { new JE::Object::str 'string' }
sub id        { 'str:' . shift->value }
sub primitive { 1 }


=head1 NAME

JE::Object::str - JavaScript string value

=head1 SYNOPSIS

  use JE::Object::str;

  $js_str = new JE::Object::str "etetfyoyfoht";

  $perl_str = $js_str->value;

  $js_str->id; # returns "str: etetfyoyfoht";

=head1 DESCRIPTION

This class implements JavaScript string values for JE. The difference
in use between this and JE::Object::String is that that module implements
string
I<objects,> while this module implements the I<primitive> values. Both
classes inherit from JE::Object.

=head1 AUTHOR

Father Chrysostomos <sprout [at] cpan [dot] org>

=head1 SEE ALSO

=over 4

=item JE
=item JE::Object
=item JE::Object::String

=cut




