package JE;

# If you are looking at the source code (which you are obviously doing
# if you are reading this),  note that  '# ~~~'  is my way of  marking
# something to be done still (except in this sentence).

# Note also that comments like "# E 7.1" refer to the indicated
# clause (7.1 in this case) in the ECMA-262 standard.

require 5.008;
use strict;
use warnings;

our $VERSION =  0.001;

our @ISA = 'JE::Object';

require JE::Undefined;
require JE::Object;
require JE::Scope;
require JE::Code;
require JE::Null;


=head1 NAME

JE - Pure-Perl ECMAScript (JavaScript) Engine

"JE" is short for "JavaScript::Engine."

=head1 VERSION

Version .001

B<WARNING:> This module is still at an experimental stage. Only a few
features have been implemented so far. The API is subject to change without
notice.

Wait a minute! I shouldn't say that. I'll end up scaring people away. :-)
If
you have the time and the interest, please go ahead and experiment with
this module and let me know if you have any ideas as to how the API might
be
improved (or redesigned if need be).

Right now about the only thing it can to is string concatenation (despite
the fact that many more features are documented):

  $ perl -MJE -le 'print JE->new->compile(q("aa" + "bb"))->execute->value'
  aabb

Nice, isn't it?

=head1 SYNOPSIS

  use JE;

  $j = new JE;

  $j->prop(document => new JE::Object); # set property
  $j->prop('document'); # get a property

  $j->method(alert => "text"); # invoke a method

  $j->eval('{"this": "that", "the": "other"}["this"]');
  # returns "that"

  $compiled = $j->compile('new Array(1,2,3)');
 
  $compiled->execute;
  # returns [1,2,3]

  # create global functions:
  $j->new_function(correct => sub {
          my $x = shift;
          $x =~ y/AEae/EAea/;
          substr($x,1,3) =~ y/A-Z/a-z/;
          return $x;
  } );
  $j->new_function(print => sub { print @_, "\n" } );

  $j->eval('print(correct("ECMAScript"))'); # :-)
  
=head1 DESCRIPTION

This is a pure-Perl JavaScript engine. All JavaScript values (except
undefined) are actually Perl objects underneath, that inherit from
C<JE::Object>. When you create a new C<JE> object, you are basically 
creating
a new JavaScript "world," the C<JE> object itself being the global object. 
To
add properties and methods to it, and to access those properties, see 
L<< C<JE::Object> >>, which this
class inherits from.

If you want to create your own global object class (such as a web browser
window), inherit from this class.

=head1 METHODS

=over 4

=item new

This class method constructs and returns a new global scope (C<JE> object).


=item compile( STRING )

C<compile> parses the code contained in C<STRING> and returns a parse
tree (a JE::Code object [but I might rename JE::Code]).

The JE::Code class provides the method 
C<execute> for executing the 
pre-compiled syntax tree.

=cut

sub compile {
	JE::Code::parse(bless([shift], 'JE::Scope'), @_);
}


=item eval ( STRING, return_obj => 1 )

=item eval ( STRING )

B<Note:> C<return_obj> has not been implemented. For now it is alwoys
turned on and you can't turn it off.

C<eval> evaluates the JavaScript code contained in string. This is just
a wrapper around C<compile> and the C<execute> method of the
C<JE::Code> class. If C<return_obj>
is specified and is true, the return value will be the JavaScript object.
Otherwise, C<eval> will call the C<value> method of the object, which
produces a value that is more useful in Perl (see C<JE::Types>). The 
following
line:

  $j->eval('[1,2,3]') # returns an array ref

is equivalent to

  $j->eval('[1,2,3]', return_obj => 1)->value;

If an error occurs, C<undef> will be returned and C<$@> will contain the
error message. If no error occurs, C<$@> will be a null string.

=cut

sub eval {
	my $rv = shift->compile(shift)->execute;
	my %opts = @_;
	$opts{return_obj} ? $rv : $rv->value;
}




=back

=head1 VARIABLES

=over 4

=item $JE::undef

The JavaScript undefined value.

=item $JE::null

The JavaScript null value.

=cut

our($undef,$null) = (
	JE::Undefined->new,
	JE::Null     ->new,
);




1;
__END__


=head1 WHAT STILL NEEDS TO BE FIGURED OUT

=head2 Constructor Functions

I've just noticed a problem. Right now, each object class has its own
constructor function, and there is only one instance of it in Perl. That
means that, when the parser supports enough syntax, JavaScript code can
modify a constructor and the changes will be reflected in the constructor
functions of C<other> global scopes. I need to rethink part of my
design....

=head2 How the Parser Should Work

I have not quite figured
out how the JavaScript parser should work.

I could write a parser that parses the code and 
creates a parse tree. Then the C<execute> subroutine could traverse the
tree, executing code as it goes. The parse tree could contain line number
information that would be used to generate helpful error messages.

But I think if I were to turn the parse tree into a Perl subroutine (at
least for JavaScript functions; perhaps not for code that is run only 
once--when
passed to C<eval>), it
would run a lot faster. The only problem is that I am not sure how to
retain information needed for helpful error messages. I suppose I could put
an C<< eval { ... } or die "${$@} at line <number here>" >> around each
statement. E.g., this function:

  function copy_array(ary) {
          var new_ary = [];
          for(var i = 0; i < ary.length; ++i) {
                  new_ary[i] = ary[i]
          }
          return new_ary
  }

might, without error message support, become

  sub {
          my($scope, $obj) = @_;
          $scope->var('new_ary', JE::Object::Array->new());
          for($scope->var('i',0); $scope->var('i') <
              $scope->var('ary')->prop('length'); ++$scope->var('i')) {
                  $scope->var('new_ary')->prop(
                      $scope->var('i'), $scope->var('ary')->prop('i')
                  );
          }
          return $scope->var('new_ary');
  }

With C<eval> blocks, it would become something like:

  sub {
          my($scope, $obj) = @_;
          eval {
                  $scope->var('new_ary', JE::Object::Array->new());
          } or die "${$@} on line 2";
          for(eval { $scope->var('i',0) or die "${$@} on line 3";
              eval { $scope->var('i') < $scope->var('ary')->prop('length')
                    } or die "${$@} on line 3";
              eval {++$scope->var('i')} or die "${$@} on line 3"
          ) {
              eval {
                  $scope->var('new_ary')->prop(
                      $scope->var('i'), $scope->var('ary')->prop('i')
                  );
              } or die "${$@} on line 4";
          }
          eval { return $scope->var('new_ary'); }
              or die "${$@} on line 6";
  }


But that might slow things down considerably. (The fact that the code is
messy doesn't matter, because it's computer-generated and shouldn't need
to be read by a human.)

Or perhaps I could forget error messages altogether, since someone could
just use Firefox for that instead. :-)  Maybe I could provide the option of
optimising the code, at the expense of simpler and less helpful error
messages. "Slow mode" could be turned on for debugging.

Does anyone have any thoughts?

=head2 Tainting

Since the JavaScript code could come from a web page we need some way to
make sure that it cannot access Perl functions directly. Of course, if my
code were perfect, that would not be a problem. But is there any way to use
perl's tainting features to prevent a leakage, in case of buggy code in
this module?

=head2 Garbage Collection and Memory Leaks

I'm not sure how to go about removing circular references. Can anyone help?

=head2 Memoisation

Memoisation might help to speed things up a lot if applied to certain
functions. The C<value> method of JE::String, for instance, which has
to put the
string through the torturous desurrogification process, may benefit
significantly from this.

But then it uses more memory. So maybe we could allow the user to
C<use JE '-memoize'>>, which could set the package var $JE::memoise to
true. Then all subsequently require'd JE modules would check that var
when they load.

=head1 PREREQUISITES

perl 5.8.0 or later 

The parser uses the officially experimental C<(?{...}}> and C<(??{...})>
constructs in regexen. Considering that they are described the 3rd edition 
of
I<Mastering Regular Expressions> (and are not indicated therein as being
experimental), I don't think they will be going away.

=head1 BUGS

Lots and lots.

There aren't enough features for this module to be usable yet.

The documentation is a bit incoherent. It probably needs a rewrite.

The author is not an expert on JavaScript, so there are probably some big
conceptual errors here and there.

=head1 AUTHOR, COPYRIGHT & LICENSE

Copyright (C) 2007 Father Chrysostomos <sprout [at] cpan
[dot] org>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

All the other C<JE::> modules, esp. C<JE::Object> and C<JE::Types>.

I<ECMAScript Language Specification> (ECMA-262)

=over 4

L<http://www.ecma-international.org/publications/files/ecma-st/ECMA-262.pdf>

=cut


HTML::DOM (still to be written)

WWW::Mechanize::JavaScript (also not written yet; it might not been named
this in the end, either)


