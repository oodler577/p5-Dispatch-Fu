use strict;
use warnings;

package Dispatch::Fu;

our $VERSION = q{0.8};
use Exporter qw/import/;
our @EXPORT    = qw(dispatch on);
our @EXPORT_OK = qw(dispatch on);

sub dispatch (&@) {
    my $code_ref  = shift;
    my $match_ref = shift;
    my %dispatch  = @_;
    my $key       = $code_ref->($match_ref);
    return $dispatch{$key}->();
}

sub on (@) {
    return @_;
}

1;

=head1 NAME
  Dispatch::Fu - hash based dispatch with dynamic key computations

=head1 SYNOPSIS

  use Dispatch::Fu;    # exports 'dispatch' and 'on'
  
  my $bar = [qw/1 2 3 4 5/];
  
  dispatch {
      # here, give a reference $H of any kind,
      # you compute a static string that is added
      # via the 'on' keyword; result will be
      # 'bucket' + some number in in 0-5
  
      my $baz = shift;

      # what gets returned here should be a static string
      # that is used as a key in the "on" entries below.
      return ( scalar @$baz > 5 )
        ? q{bucket5}
        : sprintf qq{bucket%d}, scalar @$baz;
  }
  $bar,
    on bucket0 => sub { print qq{bucket 0\n} },
    on bucket1 => sub { print qq{bucket 1\n} },
    on bucket2 => sub { print qq{bucket 2\n} },
    on bucket3 => sub { print qq{bucket 3\n} },
    on bucket4 => sub { print qq{bucket 4\n} },
    on bucket5 => sub { print qq{bucket 5\n} };

=head1 DESCRIPTION

C<Dispatch::Fu> attempts to provide a more idomatic and succinct way to offer
hash-based dispatching, especially when there is no natural opportunity to
use static keys. Via the C<dispatch> section (implemented as a Perl prototype), a
static key is computed using an algorithm implemented by the developer. Once
a static key is determined and returned from C<dispatch>, C<Dispatch::Fu> will use
the created index to immediately call the subroutine stored in that slot.

It might not be wrong to consider this a generic case of I<given>/I<when> or
I<match>/I<case> that is bantied about from time to time. It might even
suffice as a form of I<smart match>, but the author of this module doesn't
understand the issue well enough to say.

=head1 USAGE

Perl's prototype data coersions are used to facilitate this I<construct>,
which is more accurate than claiming this module has I<methods>. The construct
consists of two keywords, C<dispatch> (required exactly once), a scalar reference,
C<$baz> in the L<SYNOPSIS> above; and one or more applications of the C<on>
keyword. 

The general form is:

dispatch BLOCK,
REF,
on STRING => sub BLOCK,
on STRING => sub BLOCK,
on STRING => sub BLOCK,
on STRING => sub BLOCK,
on STRING => sub BLOCK,
...
on STRING => sub BLOCK; # last 'on' must be terminated by a semicolon

=over 4

=item C<dispatch> BLOCK

BLOCK is required, and is coerced to be an anonymous subroutine that is passed
a single scalar reference; this reference can be a single value or point to
anything a Perl scalar reference can point to. It's the single point of entry
for input.

  dispatch {
    my ($ref) = @_;          # there is only one parameter, but can a reference to anything
    my $key   = q{default};  # initiate the default key to use, 'default' by convention not required
    ...                      # compute $key
    return $key;             # key must be limited to the set of keys added with C<on>
  },
  ...

It must return a static string, and that string should be one of the keys added
using the C<on> keyword.

=item C<REF>

This is the scalar reference that contains all the stuff to be used in the C<dispatch>
BLOCK. In the example above it is, C<$bar>.

  my $_ref = [qw/foo bar baz 1 3 4 5/];
  dispatch {
    my ($ref) = @_;          # there is only one parameter, but can a reference to anything
    my $key   = q{default};  # initiate the default key to use, 'default' by convention not required
    ...                      # compute $key
    return $key;             # key must be limited to the set of keys added with C<on>
  },
  $_ref,                     # <~ the single scalar reference to be passed to the C<dispatch> BLOCK
  ...

=item C<on>

This keyword builds up the dispatch table. It consists of a static string and
a subroutine reference. In order for this to work for you, the C<dispatch> BLOCK must
return strictly only the keys that are defined via C<on>.

  my $_ref = [qw/foo bar baz 1 3 4 5/];
  dispatch {
    my ($ref) = @_;          # there is only one parameter, but can a reference to anything
    my $key   = q{default};  # initiate the default key to use, 'default' by convention not required
    ...                      # compute $key
    return $key;             # key must be limited to the set of keys added with C<on>
  },
  $_ref,                     # <~ the single scalar reference to be passed to the C<dispatch> BLOCK
  on q{default} => sub {...},
  on q{key}     => sub {...},
  on q{key}     => sub {...},
  on q{key}     => sub {...},
  on q{key}     => sub {...},
  on q{key}     => sub {...};# <~ last line of the construct must end with a semicolon, like all Perl statements

=back

=head1 SEE ALSO

=head1 AUTHOR

O. ODLER 558 L<< <oodler@cpan.org> >>.

=head1 LICENSE AND COPYRIGHT

Same as Perl.
