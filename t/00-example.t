use strict;
use warnings;
use Dispatch::Fu;    # exports 'fu' and 'on'

my $bar = [qw/1 2 3 4 5/];

fu {
    # here, give a reference $H of any kind,
    # you compute a static string that is added
    # via the 'on' keyword; result will be
    # 'bucket' + some number in in 0-5

    my $baz = shift;
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
