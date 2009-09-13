package JE::Object::Error::RangeError;

our $VERSION = '0.036';


use strict;
use warnings;

our @ISA = 'JE::Object::Error';

require JE::Object::Error;
require JE::String;


=head1 NAME

JE::Object::Error::RangeError - JavaScript RangeError object class

=head1 SYNOPSIS

  use JE::Object::Error::RangeError;

  # Somewhere in code called by an eval{}
  die new JE::Object::Error::RangeError $global, "(Error message here)";

  # Later:
  $@->prop('message');  # error message
  $@->prop('name');     # 'RangeError'
  "$@";                 # 'RangeError: ' plus the error message

=head1 DESCRIPTION

This class implements JavaScript RangeError objects for JE.

=head1 METHODS

See L<JE::Types> and L<JE::Object::Error>.

=cut

sub class { 'RangeError' }

sub new_constructor {
	shift->JE::Object::new_constructor(shift,
		sub {
			__PACKAGE__->new(@_);
		},
		sub {
			my $proto = shift;
			my $global = $$proto->{global};
			$global->prototype_for(RangeError=>$proto);
			bless $proto, __PACKAGE__;
			$proto->prototype(
			   $global->prototype_for('Error')
			|| $global->prop('Error')->prop('prototype')
			);
			$proto->prop({
				name  => 'name',
				value => JE::String->_new($global,
					'RangeError'),
				dontenum => 1,
			});
			$proto->prop({
				name  => 'message',
				value => JE::String->_new($global,
					'Range error'),
				dontenum => 1,
			});
		},
	);
}


return "a true value";

=head1 SEE ALSO

=over 4

=item L<JE>

=item L<JE::Types>

=item L<JE::Object>

=item L<JE::Object::Error>

=cut




