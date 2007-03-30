package JE::Object::String;

our $VERSION = '0.006';


use strict;
use warnings;

sub surrogify($);
sub desurrogify($);

our @ISA = 'JE::Object';

require JE::Object                 ;
require JE::Object::Error::TypeError;
require JE::Object::Function        ;
require JE::String                 ;

JE::String->import(qw/surrogify desurrogify/);


=head1 NAME

JE::Object::String - JavaScript String object class

=head1 SYNOPSIS

  use JE;

  $j = new JE;

  $js_str_obj = new JE::Object::String $j, "etetfyoyfoht";

  $perl_str = $js_str_obj->value;

=head1 DESCRIPTION

This class implements JavaScript String objects for JE. The difference
between this and JE::String is that that module implements
I<primitive> string value, while this module implements the I<objects.>

=head1 METHODS

See L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object::String is explained here.

=over 4

=cut

sub new {
	my($class, $global, $val) = @_;
	my $self = $class->SUPER::new($global, {
		prototype => $global->prop('String')->prop('prototype')
	});

	$$$self{value} = defined $val
		? UNIVERSAL::isa($val, 'UNIVERSAL')
		  && $val->can('to_string')
			? $val->to_string->[0]
			: surrogify $val
		: '';
	$self;
}

#sub prop {
	# ~~~ deal with the length property here
#}

sub value { desurrogify shift->{value} }

sub class { 'String' }
sub def_value { shift->method('toString') } # ~~~ make sure this is
                                            #     acc. to spec

sub new_constructor {
	my($class,$global) = @_;
	my $constr = $class->SUPER::new_constructor($global,
		sub {
			my $arg = shift;
			defined $arg ? $arg->to_string :
				JE::String->new($global, '');
		},
		\&_init_proto,
	);
	$constr->prop({
		name  => 'fromCharCode',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'fromCharCode',
			length => 1,
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $str = '';
				my $num;
				for (@_) {
					$num = $_->to_number->value %
						2**16 ;
					$str .= chr $num == $num && $num;
						# change nan to 0
				}
				JE::String->new($global, $str);
			},
		}),
		dontenum => 1,
	});

	$constr;
}

sub _init_proto{
	my $proto = shift;
	bless $proto, __PACKAGE__;
	$$$proto{value} = '';

	my $global = $$$proto{global};

	$proto->prop({
		name  => 'toString',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'toString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global,
					"Argument to toString is not a " .
					"String object"
				) unless $self->class eq 'String';

				JE::String->new($global, $$$self{value});
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'valueOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'valueOf',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global,
					"Argument to valueOf is not a " .
					"String object"
				) unless $self->class eq 'String';

				JE::String->new($global, $$$self{value});
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'charAt',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'charAt',
			argnames => 'pos',
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my ($self,$pos) = @_;
				
				my $str = $self->to_string->[0];
				if (defined $pos) {
					$pos = int $pos->to_string->[0];
					$pos = 0 unless $pos == $pos;
				}

				JE::String->new($global,
					$pos < 0 || $pos >= length $str
						? ''
						: substr $str, $pos, 1);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'charCodeAt',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'charCodeAt',
			argnames => 'pos',
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my ($self,$pos) = @_;
				
				my $str = $self->to_string->[0];
				if (defined $pos) {
					$pos = int $pos->to_string->[0];
					$pos = 0 unless $pos == $pos;
				}

				JE::Number->new($global,
					$pos < 0 || $pos >= length $str
					    ? 'nan'
					    : ord substr $str, $pos, 1);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'concat',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'concat',
			length => 1,
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my $str = '';
				for (@_) {
					$str .= $_->to_string->[0]
				}
				JE::String->new($global, $str);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'indexOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'indexOf',
			length => 1,
			argnames => [qw/searchString position/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				JE::Number->new($global, index
					shift->to_string->[0],
					defined $_[0]
						? $_[0]->to_string->[0]
						: 'undefined',
					defined $_[1]
						? $_[1]->to_number->value
						: 0
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'lastIndexOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'lastIndexOf',
			length => 1,
			argnames => [qw/searchString position/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				JE::Number->new($global, rindex
					shift->to_string->[0],
					defined $_[0]
						? $_[0]->to_string->[0]
						: 'undefined',
					defined $_[1]
					    && $_[1]->id ne 'undef'
						? $_[1]->to_number->value
						: ()
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({   # ~~~ I need to figure out how to deal with
	                #     locale settings
		name  => 'localeCompare',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'localeCompare',
			argnames => [qw/that/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my($this,$that) = @_;
				JE::Number->new($global,
					$this->to_string->value	
					   cmp
					defined $that
						? $that->to_string->value
						: 'undefined'
				);
			},
		}),
		dontenum => 1,
	});

=begin not ready yet

	$proto->prop({
		name  => 'match',
		value => JE::Object::Function->new({
			scope  => $global,
			name   => 'match',
			argnames => [qw/regexp/],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my($str, $re_obj) = @_;

				$str = $str->to_string->[0];

				!defined $re_obj || 
					$re_obj->class ne 'RegExp'
				 and $re_obj =	
					JE::Object::RegExp->new($global, 
						$re);
		
				my $re = $re_obj->value;

				...

				For non-global patterns and string regexps,
				I need to call the .exec method, since it
				returns the fancy array that match needs
				to return.

				For global patterns, I can just do the
				matching here, since it would be faster.
			},
		}),
		dontenum => 1,
	});

=end not ready yet

=cut

	# ~~~ match
	#    replace
	#  search
	# slice
	# split
	# substring
	# toLowerCase
	# toLocaleLowerCase
	# toUpperCase
	# toLocaleUpperCase
}


return "a true value";

=back

=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::String

=item JE::Object

=cut




