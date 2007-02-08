package JE::Object::Function::Call;

=head1 NAME

JE::Object::Function::Call - Call object (aka activation object) class for JavaScript functions

=cut

sub new { # takes a list of hash-style pairs which become
          # its properties

	my($class,$opts) = @_;
	my @args = @{$$opts{args}};
	my %self = map {
		defined($arg_val = shift @args)
			or $arg_val = $scope->undef;
		$_ => $arg_val;
	} @$argnames;

	$$self{'-global'}  = $$opts{global};
	# A call object's properties can never be accessed via bracket
	# syntax, so '-global' cannot conflict with properties, since the
	# latter have to be valid identifiers.

	unless (exists $self{arguments}) {
		$self{arguments} = 
			JE::Object::Function::Arguments->new(
				$$opts{global},
				$$opts{function},
				\%self,
				$$opts{argnames},
				@{$$opts{args}},
			);
	};

	return bless \%self, $class;
}

sub prop {
	my ($self, $name)  =(shift,shift);

	# This very naught line assumes it's being called by
	# JE::Scope::new_var:
	return if ref $name eq 'HASH';

	if (@_ ) {
		return $$self{$name} = $$self{'-global'}->upgrade(shift);
	}

	if (exists $$self{$name}) {
		return $$self{$name};
	}

	return
}

sub delete { # ~~~ Can delete be called on a property of a call object?
             #     If so, does the arguments object still retain that prop?
	# 'arguments' has an attribute of 'dontdel'

}



#----------- OH LOOK, WE HAVE ANOTHER PACKAGE HERE! ---------------#

package JE::Object::Function::Arguments;

our $VERSION = '0.002';

our @ISA = 'JE::Object';

require JE::Object;

sub new {
	my($class,$global,$function,$call,$argnames,@args) = @_;
	
	my $self = JE::Object->new($global);
	my $guts = $$self;

	$$guts{args_call} = $call;
	$self->prop({
		name => 'callee',
		value => $function,
		dontenum => 1,
	});
	$self->prop({
		name => 'length',
		value => scalar @args,
		dontenum => 1,
	});
	$$guts{args_length} = @args; # in case the length prop
	                              # gets changed

=begin pseudocode

Go through the named args one by one in reverse order.

If an arg with the same name as the current one has been seen
	Create a regular numbered property for that arg.
Else
	Create a magical property.

=end pseudocode

=cut

	my (@seen,$name,$val);
	for (reverse 0..$#$argnames) {
		($name,$val) = ($$argnames[$_], $args[$_]);
		if($seen{$name}++) {
			$self->prop({
				name => $_,
				value => $val,
				dontenum => 1,
			});
		}
		else {
			$$guts{args_magic}{$_} = $name;
		}
	}

	# deal with any extra properties
	for (@$argnames..$#args) {
		$self->prop({
			name => $_,
			value => $args[$_],
			dontenum => 1,
		});
	}

	return bless $self, $class;
}

sub prop {
	# Some properties are magically linked to properties of
	# the call object.

	my($self,$name) = @_;
	my $guts = $$self;
	if (exists $$guts{args_magic} and exists $$guts{args_magic}{$name})
	{
		return $$guts{args_call}->prop(
			$$guts{args_magic}{$name}, @_[2..$#_]
		);
	}
	SUPER::prop $self @_[1..$#_];
}

sub delete { 
	# Magical properties are still deleteable.
	my($self,$name) = @_;
	my $guts = $$self;
	if (exists $$guts{args_magic} and exists $$guts{args_magic}{$name})
	{
		delete $$guts{args_magic}{$name}
	}
	SUPER::delete $self @_[1..$#_];
}



1;