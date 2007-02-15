package JE::Null;

our $VERSION = '0.003';


use strict;
use warnings;

use overload fallback => 1,
	'""' => 'id',
	 cmp =>  sub { "$_[0]" cmp $_[1] },
	bool =>  sub { undef };

require JE::String;
require JE::Boolean;


# A JE::Null object is just a reference to a global object, which itself
# is a reference to a reference to a hash, i.e.:
#   bless \(bless \\%thing, JE), JE::Null
#
# so $$$$self{keys} is a list of enumerable global property names.
# Hmm... What does ££££self{keys} mean?


=head1 NAME

JE::Null - JavaScript null value

=head1 SYNOPSIS

  use JE;

  $j = new JE;

  $js_null = $j->null;

  $js_null->value; # undef

=head1 DESCRIPTION

This class implements the JavaScript "null" type. There really
isn't much to it.

Null stringifies to 'null', and is false as a boolean.

=cut
use Carp 'longmess';
sub new    { bless \$_[1], $_[0] }
sub prop   {
	die "Null has no properties, not even one named $_[1]"
}
sub props  { die } # ~~~ implement exception-handling later 
                   #     These need to throw a ReferenceError
sub delete { JE::Boolean->new(${$_[0]}, 1) }
sub method { die }
sub value  { undef }
sub call   { die }
sub apply  { die }
sub construct { die }
sub typeof { 'object' }
sub id     { 'null' }
sub primitive { 1 }
sub to_primitive { $_[0] }
sub to_boolean { JE::String->new(${+shift}, '') };
sub to_string { JE::String->new(${+shift}, 'null') };
sub to_number { JE::Number->new(${+shift}, 0) }
sub to_object { die } # ~~~ TypeError
sub global { ${$_[0]} }


"Do you really expect a module called 'null' to return a true value?!";


=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::Undefined

=cut








