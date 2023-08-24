package Dispatch::Fu;

use strict;
use warnings;
use Exporter qw/import/;

our $VERSION   = q{0.94};
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

=head1 NAME

Dispatch::Fu - Provides a reduction based approach to given/when or variable dispatch 

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Dispatch::Fu;    # exports 'dispatch' and 'on', which are needed
  
  my $INPUT_REF = [qw/1 2 3 4 5/];
  
  my $results = dispatch {
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

C<Dispatch::Fu> provides an idiomatic and succinct way to organize a C<HASH>-based
dispatch table by first computing a static key using a developer defined process.

=head2 The Problem 

C<HASH> based dispatching in Perl is a very fast and well established way
to organize your code.  A dispatch table can be fashioned easily when the
dispatch may occur on a single variable that may be one or more static
strings suitable to serve also as C<HASH> a key.

For example, the following is more or less a classical example of this approach
that is fundamentally based on a 1:1 mapping of a value of C<$action> to a C<HASH>
key defined in C<$dispatch>:

  my $action = get_action(); # presumed to return one of the hash keys used below
   
  my $dispatch = {
    do_dis     => sub { ... },
    do_dat     => sub { ... },
    do_deez    => sub { ... },
    do_doze    => sub { ... },
  }; 
   
  if (not $action or not exists $dispatch->{$action}) {
    die qq{action not supported\n};
  }
  
  my $results = $dispatch->{$action}->();

But this nice situation breaks down if C<$action> is a value that is
not suitable for us as a C<HASH> key, is a range of values, or a single
variable (e.g., C<$action>) is not sufficient to determine what action
to dispatch. C<Dispatch::Fu> solves this problem by providing a stage
where a static key might be computed or classied.

=head2 The Solution 

C<Dispatch::Fu> solves the problem by providing a I<Perlish> and I<idiomatic>
hook for computing a static key from an arbitrarily defined algorithm
written by the developer using this module.

The `dispatch` keyword and associated lexical block (I<that should be treated
as the body of a subroutine that receives exactly one parameter>), determines
what I<case> defined by the C<on> keyword is immediately executed.

The simple case above can be trivially replicated below:

  my $results = dispatch {
    my $_action = shift;
    return $_action;
  },
  $action,
   on do_dis     => sub { ... },
   on do_dat     => sub { ... },
   on do_deez    => sub { ... },
   on do_doze    => sub { ... }; # semi-colon
  
The one difference here is, if C<$action> is defined but not accounted
for using the C<on> keyword, then C<dispatch> will throw an exception via
C<die>. Certainly any logic meant to deal with the value (or lack thereof)
of C<$action> should be handled in the C<dispatch> BLOCK.

Similarly, a more complicate case might be defined:

  my $results = dispatch {
    my $array_ref = shift;
    my $rand      = $array_ref->[0];
    if ( $rand < 2.5 ) {
        return q{do_dis};
    }
    elsif ( $rand >= 2.5 and $rand < 5.0 ) {
        return q{do_dat};
    }
    elsif ( $rand >= 5.0 and $rand < 7.5 ) {
        return q{do_deez};
    }
    elsif ( $rand >= 7.5 ) {
        return q{do_doze};
    }
  },
  [ rand 10 ],
   on do_dis    => sub { ... },
   on do_dat    => sub { ... },
   on do_deez   => sub { ... },
   on do_doze   => sub { ... }; # semi-colon

The approach facilited by C<Dispatch::Fu> is one that requires the programmer
to define each case by a static key via C<on>, and define a custom algorithm
for picking which case (by way of returning the correct static key as a string)
to execute via C<dispatch>.

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

  my $results = dispatch {
  
    my $_input_ref = shift;  # there is only one parameter, but can a reference to anything
    my $key    = q{default}; # initiate the default key to use, 'default' by convention not required
    ...                      # compute $key
    return $key;             # key must be limited to the set of keys added with C<on>
  
  },
  ...

It must return a static string, and that string should be one of the keys
added using the C<on> keyword.

=item C<REF>

This is the singular scalar reference that contains all the stuff to be used
in the C<dispatch> BLOCK. In the example above it is, C<[rand 10]>. It is
the way to pass arbitrary data into C<dispatch>. E.g.,

  my $INPUT_REF  = [qw/foo bar baz 1 3 4 5/];
  
  my $result = dispatch {

    my $_input_ref = shift;  # there is only one parameter, but can a reference to anything
    my $key    = q{default}; # initiate the default key to use, 'default' by convention not required
    ...                      # compute $key
    return $key;             # key must be limited to the set of keys added with C<on>
  
  },
  $INPUT_REF,                # <~ the single scalar reference to be passed to the C<dispatch> BLOCK
  ...

=item C<on>

This keyword builds up the dispatch table. It consists of a static string and
a subroutine reference. In order for this to work for you, the C<dispatch>
BLOCK must return strictly only the keys that are defined via C<on>.

  my $INPUT_REF = [qw/foo bar baz 1 3 4 5/];
    
  my $results = dispatch {
  
    my $_input_ref = shift;      # there is only one parameter, but can a reference to anything
    my $key        = q{default}; # initiate the default key to use, 'default' by convention not required
    ...                          # compute $key
    return $key;                 # key must be limited to the set of keys added with C<on>
  
  },
  $INPUT_REF,                    # <~ the single scalar reference to be passed to the C<dispatch> BLOCK
   on q{key1}    => sub {...},
   on q{key2}    => sub {...},
   on q{key3}    => sub {...},
   on q{key4}    => sub {...},
   on q{key5}    => sub {...},
   on q{default} => sub {...};   # 'default' (by convention, not enforced); not semi-colon needed to end structure 

Note: It was made as a design decision that there be no way to specify the
input parameters into the subroutine reference that is added by each C<on>
statement. This means that the subroutine refs are to be treated as wrappers
that access the current scope. This provides maximum flexibility and allows
one to manage what happens in each C<on> case more explicitly. Perl's scoping
rules lets one use variables in a higher scope, so that would be the way to
deal with it. E.g.,

  my $INPUT_REF = [qw/foo bar baz 1 3 4 5/];
   
  my $results = dispatch {
  
    my $_input_ref = shift;      # there is only one parameter, but can a reference to anything
    my $key        = q{default}; # initiate the default key to use, 'default' by convention not required
    ...                          # compute $key
    return $key;                 # key must be limited to the set of keys added with C<on>
  
  },
  $INPUT_REF,                    # <~ the single scalar reference to be passed to the C<dispatch> BLOCK
   on q{default}  => sub { do_default($input_ref) },
   on q{key1}     => sub { do_key1(input => $input_ref) },
   on q{key2}     => sub { do_key2(qw/some other inputs entirely/) };

=back

=head1 BUGS

Please report any bugs or ideas about making this module an even better
basis for doing dynamic dispatching.

=head1 AUTHOR

O. ODLER 558 L<< <oodler@cpan.org> >>.

=head1 LICENSE AND COPYRIGHT

Same as Perl.
