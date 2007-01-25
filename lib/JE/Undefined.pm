package JE::Undefined;


=begin stuff for MakeMaker

use JE; our $VERSION = $JE::VERSION;

=end

=cut


use strict;
use warnings;

require JE::String;

our $_string = new JE::String 'undefined';


=head1 NAME

JE::Undefined - JavaScript undefined value

=head1 SYNOPSIS

  use JE;

  $js_undefined = $JE::undef;

  # You could use JE::Undefined->new, but, really, why would you
  # want to create another instance of undefined?

  $js_undefined->value; # undef

=head1 DESCRIPTION

This class implements the JavaScript "undefined" type. There really
isn't much to it.

=cut

sub new    { bless \do{my $doodaa}, $_[0] }
sub prop   { die }
sub method { die }
sub value  { undef }
sub typeof { $_string }
sub id     { 'undef' }
sub primitive { 1 }
sub to_primitive { $_[0] }
sub to_string { $_string }
#sub to_number # ~~~ what do this meant to?


return "undef";
__END__

=head1 AUTHOR

Father Chrysostomos <sprout [at] cpan [dot] org>

=head1 SEE ALSO

=over 4

=item JE

=item JE::Null

