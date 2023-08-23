use strict;
use warnings;

package Dispatch::Fu;

our $VERSION = q{0.8};
use Exporter qw/import/;
our @EXPORT    = qw(dispatch on);
our @EXPORT_OK = qw(dispatch on);

sub dispatch (&@) {
    my $code_ref  = shift;    # catch sub ref that was coerced from the 'dispatch' BLOCK
    my $match_ref = shift;    # catch the input reference passed after the 'dispatch' BLOCK

    # build up dispatch table for each k/v pair preceded by 'on'
    my $dispatch = {};
    while ( my $key = shift @_ ) {
        my $HV = shift @_;
        $dispatch->{$key} = _to_sub($HV);
    }

    # call $code_ref that needs to return a valid bucket name
    my $key = $code_ref->($match_ref);

    die qq{Computed static bucket not found\n} if not $dispatch->{$key} or 'CODE' ne ref $dispatch->{$key};

    # call subroutine ref defined as the v in the k/v $dispatch->{$key} slot
    return $dispatch->{$key}->();
}

# on accumulater, wants h => v pair, where h is a static bucket string and v is a sub ref
sub on (@) {
    return @_;
}

# utility sub to force a BLOCK into a sub reference
sub _to_sub (&) {
    shift;
}

1;

__END__

# ABSTRACT: provides a reduction based approach to given/when or variable dispatch

=head1 NAME
  Dispatch::Fu - hash based dispatch with dynamic key computations

=head1 SYNOPSIS

  use Dispatch::Fu;    # exports 'dispatch' and 'on', which are needed
  
  my $input_ref = [qw/1 2 3 4 5/];
  
  my $bucket = dispatch {
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
  $input_ref,
    on bucket0 => sub { print qq{bucket 0\n}; 0 },
    on bucket1 => sub { print qq{bucket 1\n}; 1 },
    on bucket2 => sub { print qq{bucket 2\n}; 2 },
    on bucket3 => sub { print qq{bucket 3\n}; 3 },
    on bucket4 => sub { print qq{bucket 4\n}; 4 },
    on bucket5 => sub { print qq{bucket 5\n}; 5 };

=head1 DESCRIPTION

C<Dispatch::Fu>  provide an idomatic and succinct way to offer hash-based
dispatching, especially when there is no natural opportunity to use static
keys. In the right hands, it is hoped this construct will do good things for
good people. It'll also do bad things for bad people. C<Dispatch::Fu> is
just a created thing.

Via the C<dispatch> section (implemented as a Perl prototype), a static key
is computed using an algorithm implemented by the developer. Once a static
key is determined and returned from C<dispatch>, C<Dispatch::Fu> will use
the created index to immediately call the subroutine stored in that slot.

It might not be wrong to consider this a generic case of I<given>/I<when>
or I<match>/I<case> that is bantied about from time to time. It might even
suffice as a form of I<smart match>, but the author of this module doesn't
understand the issue well enough to say.

=head1 USAGE

Perl's prototype data coersions are used to facilitate this I<construct>,
which is more accurate than claiming this module has I<methods>. The construct
consists of two keywords, C<dispatch> (required exactly once), a scalar
reference, C<$baz> in the L<SYNOPSIS> above; and one or more applications
of the C<on> keyword.

The C<dispatch> keyword will return the results of the block that is executed
based on the computed STRING.

The general form is:

SCALAR = dispatch BLOCK,
REF,
 on STRING1 => sub BLOCK1,
 on STRING2 => sub BLOCK2,
 on STRING3 => sub BLOCK3,
 on STRING4 => sub BLOCK4,
 on STRING5 => sub BLOCK5,
...
 on STRINGn => sub BLOCKn; # last 'on' must be terminated by a semicolon

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

  my $input_ref = [qw/foo bar baz 1 3 4 5/];
  
  dispatch {
    my ($ref)    = @_;          # there is only one parameter, but can a reference to anything
    my $key      = q{default};  # initiate the default key to use, 'default' by convention not required
    ...                         # compute $key
    return $key;                # key must be limited to the set of keys added with C<on>
  },
  $_input_ref,                  # <~ the single scalar reference to be passed to the C<dispatch> BLOCK
   on q{default} => sub {...},
   on q{key1}    => sub {...},
   on q{key2}    => sub {...},
   on q{key3}    => sub {...},
   on q{key4}    => sub {...},
   on q{key5}    => sub {...};  # <~ last line of the construct must end with a semicolon, like all Perl statements

Note: Currently, there is no way to specific the input parameters into the subroutine
reference that is added by each C<on> statement. This means that the subroutine refs
are to be treated as wrappers that access the current scope. This provides maximum
flexibility and allows one to manage what happens in each C<on> case more explicitly.

For example,

  my $input_ref  = [qw/foo bar baz 1 3 4 5/];
  
  dispatch {
    my ($ref)    = @_;
    my $key      = q{default};
    ...
    return $key;
  },
  $_input_ref,
   on q{default}  => sub { do_default($input_ref) },
   on q{key1}     => sub { do_key1(input => $input_ref) },
   on q{key2}     => sub { do_key2(qw/some other inputs entirely/) };

=back

=head1 AUTHOR

O. ODLER 558 L<< <oodler@cpan.org> >>.

=head1 LICENSE AND COPYRIGHT

Same as Perl.
