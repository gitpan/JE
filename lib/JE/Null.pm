package JE::Null;


=begin stuff for MakeMaker

use JE; our $VERSION = $JE::VERSION;

=end

=cut


use strict;
use warnings;

require JE::String;


our $_string = new JE::String 'null';


=head1 NAME

JE::Null - JavaScript null value

=head1 SYNOPSIS

  use JE::Object;

  $js_undefined = $JE::null;

  # You could use JE::Null->new, but that would be pointless.

  $js->value; # undef

=head1 DESCRIPTION

This class implements the JavaScript "undefined" type. There really
isn't much to it.

=cut

sub new    { bless \\undef, $_[0] }
sub prop   { die }
sub method { die }
sub value  { undef }
sub typeof { $_string }
sub id     { 'null' }
sub primitive { 1 }
sub to_primitive { $_[0] }
sub to_string { $_string }
#sub to_number # ~~~ what do this meant to?


"Do you really expect a module called 'null' to return a true value?!";


=head1 AUTHOR

Father Chrysostomos <sprout [at] cpan [dot] org>

=head1 SEE ALSO

=over 4

=item JE

=item JE::Object

=item JE::Object::undef

=cut








