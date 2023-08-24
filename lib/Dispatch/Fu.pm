use strict;
use warnings;

package Dispatch::Fu;

our $VERSION = q{0.9};
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

# ABSTRACT: Provides a reduction based approach to given/when or variable dispatch

=head1 NAME
  Dispatch::Fu - Provides a reduction based approach to given/when or variable dispatch 

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Dispatch::Fu;    # exports 'dispatch' and 'on', which are needed
  
  my $input_ref = [qw/1 2 3 4 5/];
  
  my $bucket = dispatch {
      my $_input_ref = shift;                        # <~ input reference

      return ( scalar @$_input_ref > 5 )             # <~ return a string that must be
        ? q{bucket5}                                 #    defined below using the 'on'
        : sprintf qq{bucket%d}, scalar @$_input_ref; #    keyword, this i
  }
  $input_ref,                                        # <~ input reference, SCALAR passed to dispatch BLOCK 
    on bucket0 => sub { print qq{bucket 0\n}; 0 },   # <~ if dispatch returns 'bucket0', run this CODE
    on bucket1 => sub { print qq{bucket 1\n}; 1 },   # <~ if dispatch returns 'bucket1', run this CODE
    on bucket2 => sub { print qq{bucket 2\n}; 2 },   # ...
    on bucket3 => sub { print qq{bucket 3\n}; 3 },   # ...   ...   ...   ... 
    on bucket4 => sub { print qq{bucket 4\n}; 4 },   # ...
    on bucket5 => sub { print qq{bucket 5\n}; 5 };   # <~ if dispatch returns 'bucket5', run this CODE

=head1 DESCRIPTION

C<Dispatch::Fu> provide an idomatic and succinct way to organize a C<HASH>-based
dispatch table.

=head2 The Problem 

This can be done easily when dispatch may occur on a single variable that
may be one or more static strings that are suitable to serve also as C<HASH>
keys. For example,

  my $action = get_action();
  
  my $dispatch = {
    do_dis     => sub { ... },
    do_dat     => sub { ... }.
    do_dese    => sub { ... },
    do_dose    => sub { ... },
    do_default => sub { ... },
  }; 
   
  if ($action or not exists $dispatch->{$action}) {
    $action = q{do_default};
  }

  my $results = $dispatch->{$action}->();

But this nice situation breaks down if C<$action> is a value that is
not suitable as as a C<HASH> key, is a range of values, or a single
variable C<$action> is not sufficient to determine what action to
dispatch. C<Dispatch::Fu> solves this problem.

=head2 The Solution 

C<Dispatch::Fu> solves this problem buy providing a I<Perlish> and I<idiomatic>
structure for computing a static key from an arbitrarily defined algorithm
written by the developer using this module. This static key that is computed
is then used to do to dispatch the anonyous subroutine explicitly defined
but that key.

The simple ideal case can be mostly replicated below:

  my $results = dispatch {
    my $_action = shift;
    return $_action;
  },
  $action,
   on do_dis     => sub { ... },
   on do_dat     => sub { ... },
   on do_dese    => sub { ... }.
   on do_dose    => sub { ... };
  
The one difference here is, if C<$action> is defined but not accounted
for using the C<on> keyword, then C<dispatch> will throw an exception via
C<die>. Certainly any logic meant to deal with the value (or lack thereof)
of C<$action> should be handled in the C<dispatch> BLOCK.

=head1 USAGE

The developer using this module defines how to boil down the provided
C<REF> into a single, static string. It can be described as a I<reduction>
operation or, maybe even a I<classification>. The author tends to use the
term I<buckets>, because the C<dispatch> function decides what I<bucket>
(or case) the provided set of input falls into. It's best to play with the
module rather than try to really understand it from this description.

For more working examples, look at the tests in the C<./t> directory. It
should quickly become apparent how to use this method and what it's for by
trying it out.

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

It must return a static string, and that string should be one of the keys
added using the C<on> keyword.

=item C<REF>

This is the scalar reference that contains all the stuff to be used in the
C<dispatch> BLOCK. In the example above it is, C<$bar>.

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
a subroutine reference. In order for this to work for you, the C<dispatch>
BLOCK must return strictly only the keys that are defined via C<on>.

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

Note: Currently, there is no way to specific the input parameters into the
subroutine reference that is added by each C<on> statement. This means that
the subroutine refs are to be treated as wrappers that access the current
scope. This provides maximum flexibility and allows one to manage what
happens in each C<on> case more explicitly.

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
