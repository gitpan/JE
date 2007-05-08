package JE::Object::Error;

our $VERSION = '0.009';


use strict;
use warnings;

our @ISA = 'JE::Object';

require JE::Object;
require JE::String;


# ~~~ Need to add support for line number, script name, etc., or perhaps
#     just a reference to the corresponding JE::Code object.

=head1 NAME

JE::Object::Error - JavaScript Error object class

=head1 SYNOPSIS

  use JE::Object::Error;

  # Somewhere in code called by an eval{}
  die new JE::Object::Error $global, "(Error message here)";

  # Later:
  $@->prop('message');  # error message
  $@->prop('name');     # 'Error'
  "$@";                 # 'Error: ' plus the error message

=head1 DESCRIPTION

This class implements JavaScript Error objects for JE. This is the base
class for all JavaScript's native error objects. (See L<SEE ALSO>, below.)

=head1 METHODS

See L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object::Error is explained here.

The C<value> method returns the string S<'Error: '> followed by the error
message. 'Error' will be replaced with the class name (the result of 
calling
C<< ->class >>) for subclasses. 

The C<new_constructor> method (see JE::Object for details) does not work
in subclasses. If you create a C<new_constructor> method in your own
subclass of JE::Object::Error, call
C<< $class->JE::Object::new_constructor >> instead of using C<SUPER>.

=cut

sub new {
	my($class, $global, $val) = @_;
	my $self = $class->SUPER::new($global, { 
		prototype => $global->prop(class $class)->prop('prototype')
	});

	$self->prop({
		dontenum => 1,
		name => 'message',
		value => JE::String->new($global, $val),
	});
	$self;
}

sub value { $_[0]->method('toString')->value }

sub class { 'Error' }

sub new_constructor {
	shift->SUPER::new_constructor(shift,
		sub {
			__PACKAGE__->new(@_);
		},
		sub {
			my $proto = shift;
			my $global = $$proto->{global};
			bless $proto, __PACKAGE__;
			$proto->prop({
				name  => 'toString',
				value => JE::Object::Function->new({
					scope  => $global,
					name   => 'toString',
					length => 0,
					function_args => ['this'],
					function => sub {
						my $self = shift;
						JE::String->new(
							$$$self{global},
							$self->class .
							': ' .
							$self->prop(
								'message'							)
						);
					}
				}),
				dontenum => 1,
			});
			$proto->prop({
				name  => 'name',
				value => JE::String->new($global, 'Error'),
				dontenum => 1,
			});
			$proto->prop({
				name  => 'message',
				value => JE::String->new($global,
					'Unknown Error'),
				dontenum => 1,
			});
		},
	);
}


return "a true value";

=head1 SEE ALSO

=over 4

=item L<JE>

=item L<JE::Object>

=item L<JE::Object::Error::RangeError>

=item L<JE::Object::Error::SyntaxError>

=item L<JE::Object::Error::TypeError>

=item L<JE::Object::Error::URIError>

=item Other classes to be added...

=cut




