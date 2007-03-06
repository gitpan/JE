package JE::Object::Boolean;

our $VERSION = '0.005';


use strict;
use warnings;

our @ISA = 'JE::Object';
require JE::Object;

require JE::Object::Function;
require JE::String;


# ~~~ write 'new_constructor' if necessary
#our $constructor = __PACKAGE__->make_constructor;
#our $prototype   = prop $constructor 'prototype';
#for($prototype) {
#	# ~~~ I need to finish adding all the usual string methods
#	prop $_ toString => new_method JE::Object::Function sub {
#		bless {%{+shift}}, 'JE::String';
#	};
#}


# ~~~ make certain methods/props get delegated to JE::String via
#     $$$self{value}->prop


=head1 NAME

JE::Object::Boolean - JavaScript Boolean object class

Not yet implemented.

=begin todo

=head1 SYNOPSIS

  use JE::Object::String;

  $js_str_obj = new JE::Object::String $scope, "etetfyoyfoht";

  $perl_str = $js_str_obj->value;

  $js_str->id; # returns a number uniquely identifying the object

=head1 DESCRIPTION

This class implements JavaScript String objects for JE. The difference
between this and JE::String is that that module implements
I<primitive> string value, while this module implements the I<objects.>

=cut

sub new {
	my($class, $scope, $val) = @_;
	my $self = bless JE::Object->new($scope), $class;
	$$$self{value} = new JE::String $val;
	$self;
}

sub prop {
	# ~~~ deal with the length property here
}

sub value { shift->{value}->value }

sub class { 'String' } # I don't think this is even used.
sub def_value { shift->method('toString') } # ~~~ make sure this is
                                            #     acc. to spec

return "a true value";

=head1 SEE ALSO

=over 4

=item JE
=item JE::Object
=item JE::String

=cut




