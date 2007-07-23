package JE::_FieldHash;

our $VERSION = '0.016';


use strict;
use warnings;

BEGIN {
	local $@; # ~~~ Is this necessary in a BEGIN block?
	eval { require Hash::Util::FieldHash;
	       import  Hash::Util::FieldHash 'fieldhash'; };
	if ($@) {
		require Tie::RefHash::Weak;
		eval 'sub fieldhash(\%) {
			tie %{$_[0]}, "Tie::RefHash::Weak";
			$_[0];
		}';
	}
}

use Exporter 'import';

our @EXPORT = 'fieldhash'; # this returns a veracious value

__END__

=head1 NAME

JE::_FieldHash - This module is solely for JE's private use.

=head1 SYNOPSIS

  use JE::_FieldHash;
  fieldhash my %foo;

=head1 DESCRIPTION

This is a thin wrapper around Hash::Util::FieldHash, or Tie::RefHash::Weak
if the former is not available. B<It is subject to change or vanish without
notice.>

=head1 SEE ALSO

L<JE>
