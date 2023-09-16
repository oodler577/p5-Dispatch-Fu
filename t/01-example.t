use Dispatch::Fu;    # exports 'dispatch' and 'on', which are needed

use Test::More tests => 1;

my $INPUT = [qw/1 2 3 4 5/];

my $case = dispatch {

    # here, give a reference $H of any kind,
    # you compute a static string that is added
    # via the 'on' keyword; result will be
    # 'case' + some number in in 0-5

    my $input_ref = shift;

    # what gets returned here should be a static string
    # that is used as a key in the "on" entries below.
    return ( scalar @$input_ref > 5 )
      ? q{case5}
      : sprintf qq{case%d}, scalar @$input_ref;
}
$INPUT,
  on case0 => sub { note qq{case 0}; 0; },
  on case1 => sub { note qq{case 1}; 1; },
  on case2 => sub { note qq{case 2}; 2; },
  on case3 => sub { note qq{case 3}; 3; },
  on case4 => sub { note qq{case 4}; 4; },
  on case5 => sub { note qq{case 5}; 5; };

is $case, 5, q{POD example works};
