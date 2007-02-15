package JE::Object;

our $VERSION = '0.003';


use strict;
use warnings;

use overload fallback => 1,
	'%{}'=>  \&value, # a method call won't work here
	'""' => 'to_string',
	 cmp =>  sub { "$_[0]" cmp $_[1] },
	bool =>  sub { 1 };

use Scalar::Util 'refaddr';
use List::Util 'first';
use Data::Dumper;


require JE::Object::Function;
require JE::Boolean;
require JE::String;



=head1 NAME

JE::Object - Base class for all JavaScript objects

=head1 SYNOPSIS

  use JE;
  use JE::Object;

  $j = new JE;

  $obj = new JE::Object $j,
          property1 => $obj1,
          property2 => $obj2;

  $obj->prop('property1');              # returns $obj1;
  $obj->prop('property1', $new_value);  # sets the property

  $obj->props; # returns a list of the names of enumerable property

  $obj->delete('property_name');

  $obj->method('method_name', 'arg1', 'arg2');
    # calls a method with the given arguments

  $obj->value ;    # returns a value useful in Perl (a hashref)

  "$obj"; # "[object Object]"
          # same as $obj->to_string->value

=head1 DESCRIPTION

This module implements JavaScript objects for JE. It serves as a base class
for all other JavaScript objects.

A JavaScript object is an associative array, the elements of which are
its properties. A method is a property that happens to be an instance
of the
C<Function> class (C<JE::Object::Function>).

This class overrides the stringification operator by calling
C<< $obj->method('toString') >>. The C<%{}> (hashref) operator is also
overloaded and returns a hash of enumerable properties.

See also L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object is explained here.

=head1 METHODS

=over 4

=item $obj = JE::Object->new( $global_obj, LIST )

This class method constructs and returns a new object. LIST is a hash-style
list of keys and values. If the values are not blessed references, they
will be upgraded. (See L<JE::Types/'UPGRADING VALUES'>.)

=cut

sub new {
	my($class, $global, %hash, @keys) = (shift, shift);
	my $key;
	while (@_) { # I have to loop through them to keep the order.
		$key = shift;
		push @keys, $key
			unless exists $hash{$key};
		$hash{$key} = $global->upgrade(shift);
	}

	my $p = $global->prop("Object")->prop("prototype");

	bless \{ prototype => $p,
	         global    => $global,
	         props     => \%hash,
	         keys      => \@keys  }, $class;
}




sub prop {
	my ($self, $opts) = (shift, shift);
	my $guts = $$self;

	if(ref $opts eq 'HASH') { # special use
		my $name = $$opts{name};
		for (qw< dontdel readonly >) {
			exists $$opts{$_}
				and $$guts{"prop_$_"}{$name} = $$opts{$_};
		}
		my $dontenum;
		if(exists $$opts{dontenum}) {
			if($$opts{dontenum}) {
				$$guts{keys} = [
					grep $_ ne $name, @{$$guts{keys}}
				];
			}
			else {
				push @{ $$guts{keys} }, $name
			    	unless first {$_ eq $name} @{$$guts{keys}};
			}
		}
		if(exists $$opts{value}) {
			return $$guts{props}{$name} =
				$$guts{global}->upgrade($$opts{value});
		}
		return exists $$guts{value} ? $$guts{value} : undef;
	}

	else { # normal use
		my $name = $opts;
		if (@_) { # we is doing a assignment
			my($new_val) =
				$$guts{global}->upgrade(shift);

			return $new_val if $self->is_readonly($name);

			$$guts{props}{$name} = $new_val;
			push @{ $$guts{keys} }, $name
			    unless first {$_ eq $name} @{ $$guts{keys} }; 
			return $new_val;
		}
		else {
			my $props = $$guts{props};
			my $proto;
			return exists $$props{$name} ? $$props{$name} :
				($proto = $self->prototype) ?
				$proto->prop($name) :
				undef;
		}	
	}

}




sub is_readonly { # See JE::Types for a description of this.
	my ($self,$name) = (shift,@_);  # leave $name in @_

	my $guts = $$self;

	my $props = $$guts{props};
	if( exists $$props{$name}) {
		my $read_only_list = $$guts{prop_readonly};
		return exists $$read_only_list{$name} ?
			$$read_only_list{$name} : 0;
	}

	if(my $proto = $self->prototype) {
		return $proto->is_readonly(@_);
	}

	return 0;
}




sub props {# ~~~ This needs to list enumerable properties of
            #     the object's prototypes
	@{ ${+shift}->{keys} };
}




sub delete {
	my ($self, $name) = @_;
	my $guts = $$self;

	my $dontdel_list = $$guts{prop_dontdel};
	exists $$dontdel_list{$name} and $$dontdel_list{$name}
		and return !1;

	delete $$guts{prop_dontenum}{$name};
	delete $$guts{prop_readonly}{$name};
	delete $$guts{props}{$name};
	$$guts{keys} = [ grep $_ ne $name, @{$$guts{keys}} ];
	return 1;
}




sub method {
	my($self,$method) = (shift,shift);

	$self->prop($method)->apply($self, @_);
}

=item $obj->typeof

This returns the string 'object'.

=cut

sub typeof { 'object' }




=item $obj->class

Returns the string 'Object'.

=cut

sub class { 'Object' }




=item $obj->value

This returns a hash ref of the object's enumerable properties.

=cut

sub value {
	my $self = shift;
	+{ map +($_ => $self->prop($_)), $self->props };
}




sub id {
	refaddr shift;
}

sub primitive { 0 };

sub prototype {
	@_ > 1 ? (${+shift}->{prototype} = $_[1]) : ${+shift}->{prototype};
}




sub to_primitive {
	my($self, $hint) = @_;

	my @methods = ('valueOf','toString');
	$hint eq 'string' and @methods = reverse @methods;

	for (@methods) {
		return +($self->prop($_) || next)->apply($self)
	}

	die; # ~~~ throw a TypeError exception later
}




sub to_boolean { 
	JE::Boolean->new( $${+shift}{global}, 1 );
}

sub to_string {
	shift->to_primitive('string')->to_string;
}


sub to_number {
	shift->to_primitive('number')->to_number;
}

sub to_object { $_[0] }

sub global { ${+shift}->{global} }


=item I<Class>->new_constructor( $global, \&function, \&prototype_init );

You should not call this method--or read its description--unless you are 
subclassing JE::Object. 

This class method creates and returns a constructor function 
(JE::Object::Function object), which when its C<construct> method is
invoked, call C<new> in the 
package through which
C<new_constructor> is invoked, using the same arguments, but with the 
package name prepended to the argument list (as though
C<<< I<< <package name> >>->new >>> had been called.

C<\&function>, if present, will be the subroutine called when the
constructor function is called as a regular function (i.e., without
C<new> in JavaScript; using the C<call> method from Perl). If this is
omitted, the function will simply return undefined.

C<\&prototype_init> (prototype initialiser), if present, will be called by
the C<new_constructor> with a prototype object as its only argument. It is
expected to add the default properties to the prototype (except for the
C<constructor> property, which will be there already).

For both coderefs, the scope will be passed as the first argument.

Here is an example of how you might set up the
constructor function and add methods to the prototype:

  package MyObject;

  require JE::Object;
  our @ISA = 'JE::Object';

  sub new_constructor {
      shift->SUPER::new_constructor(shift,
          sub {
              __PACKAGE__->new(@_);
          },
          sub {
              my $proto = shift;
              my $global = $$proto->{global};
              $proto->prop({
                  name  => 'toString',
                  value => JE::Object::Function->new({
                      scope  => $global,
                      name   => 'toString',
                      length => 1,
                      function_args => ['this'],
                      function => sub {
                          # ...
                      }
                  }),
                  dontenum => 1,
              });
              # ...
              # put other properties here
          },
      );
  }

And then you can add it to a global object like this:

  $j->prop({
          name => 'MyObject',
          value => MyObject->new_constructor,
          readonly => 1,
          dontenum => 1,
          dontdel  => 1,
  });


You can, of course, 
create your
own constructor function with C<new JE::Object::Function> if 
C<new_constructor> does not 
do what you want.

B<To do:> Make this exportable, for classes that don't feel like inheriting
from JE::Object (maybe this is not necessary, since one can say
S<< C<<< __PACKAGE__->JE::Object::new_constructor >>> >>).

=cut

sub new_constructor {
	my($package,$global,$function,$init_proto) = @_;
	
	my $f = JE::Object::Function->new({
		scope            => $global,
		function         => $function,
		function_args    => ['scope','args'],
		constructor      => sub {
			no strict 'refs';
			&{"$package\::new"}($package, @_);
		},
		constructor_args => ['scope','args'],
	});

	$init_proto and &$init_proto($f->prop('prototype'));

	$f;
}





=back

=cut




#----------- PRIIVATE ROUTIES ---------------#

# _init_proto takes the Object prototype (Object.prototype) as its sole
# arg and adds all the default properties thereto.

sub _init_proto {
	my $proto = shift;
	my $scope = $$proto->{global};

	# E 15.2.4
	# ~~~ $proto->prop({ ... })

	$proto->prop({
		name      => 'toString',
		value     => JE::Object::Function->new({
			scope    => $scope,
			name     => 'toString',
			length   => 0, # ~~~ check this
			function_args => ['this'],
			function => sub {
				my $self = shift;
				JE::String->new($$$self{global},
					'[object ' . $self->class . ']');
			},
		}),
		dontenum  => 1, # ~~~ any other attrs?
	});

}



#----------- THE REST OF THE DOCUMENTATION ---------------#

=pod

=head1 INNARDS

Each C<JE::Object> instance is a blessed reference to a hash ref. The 
contents of the hash
are as follows:

  $$self->{global}         a reference to the global object
  $$self->{props}          a hash ref of properties, the values being
                           JavaScript objects
  $$self->{prop_readonly}  a hash ref with property names for the keys
                           and booleans  (that indicate  whether  prop-
                           erties are read-only) for the values
  $$self->{prop_dontdel}   a hash ref in the same format as
                           prop_readonly that indicates whether proper-
                           ties are undeletable
  $$self->{keys}           an array of the names of enumerable
                           properties
  $$self->{prototype}      a reference to this object's prototype

In derived classes, if you need to store extra information, begin the hash 
keys with an underscore or use at least one capital letter in each key. 
Such keys 
will never be used by the
classes that come with the JE distribution.

=head1 SEE ALSO

L<JE>

L<JE::Types>

=cut


1;

