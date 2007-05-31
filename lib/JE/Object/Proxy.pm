package JE::Object::Proxy;

our $VERSION = '0.014';

use strict;
use warnings;

# ~~~ delegate overloaded methods?

use Scalar::Util qw'refaddr';

require JE::Object;

our @ISA = 'JE::Object';


=head1 NAME

JE::Object::Proxy - JS wrapper for Perl objects

=head1 SYNOPSIS

  $proxy = new JE::Object::Proxy $JE_object, $some_Perl_object;

=cut




sub new {
	my($class, $global, $obj) = @_;

	my $class_info = $$$global{classes}{ref $obj};

	my $self = $class->JE::Object::new($global,
		{ prototype => $$class_info{prototype} });

	@$$self{qw/proxy_class value/} = ($$class_info{name}, $obj);

	$self;
}




sub class { $${$_[0]}{proxy_class} }




sub value { $${$_[0]}{value} }




sub id {
	refaddr $${$_[0]}{value};
}




sub to_primitive { # ~~~ I think maybe the info should be stored in the
                   #     proxy object itself to make this more efficient.
	my($self, $hint) = (shift, @_);

	my $guts = $$self;
	my $value = $$guts{value};
	my $class_info = $${$$guts{global}}{classes}{
		ref $value
	};

	if(exists $$class_info{to_primitive}) {
		my $tp = $$class_info{to_primitive};
		return defined $tp
			? $$guts{global}->upgrade(ref $tp eq 'CODE'
				? &$tp($value, @_)
				: $value->$tp(@_))
			: die "The object ($$guts{proxy_class} cannot "
				. "be converted to a primitive";
	} else {
		return SUPER::to_primitive $self @_;
	}
}




sub to_string {
	my($self, $hint) = (shift, @_);

	my $guts = $$self;
	my $value = $$guts{value};
	my $class_info = $${$$guts{global}}{classes}{
		ref $value
	};

	if(exists $$class_info{to_string}) {
		my $tp = $$class_info{to_string};
		return defined $tp
			? $$guts{global}->upgrade(ref $tp eq 'CODE'
				? &$tp($value, @_)
				: $value->$tp(@_))->to_string
			: die "The object ($$guts{proxy_class} cannot "
				. "be converted to a string";
	} else {
		return SUPER::to_string $self @_;
	}
}




sub to_number {
	my($self, $hint) = (shift, @_);

	my $guts = $$self;
	my $value = $$guts{value};
	my $class_info = $${$$guts{global}}{classes}{
		ref $value
	};

	if(exists $$class_info{to_number}) {
		my $tp = $$class_info{to_number};
		return defined $tp
			? $$guts{global}->upgrade(ref $tp eq 'CODE'
				? &$tp($value, @_)
				: $value->$tp(@_))->to_number
			: die "The object ($$guts{proxy_class} cannot "
				. "be converted to a number";
	} else {
		return SUPER::to_number $self @_;
	}
}




1;

