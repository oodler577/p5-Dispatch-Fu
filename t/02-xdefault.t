use Dispatch::Fu;    # exports 'dispatch' and 'on', which are needed

use Test::More tests => 3;

my $INPUT = q{case1};

my $results = dispatch {
    my $input_str = shift;
    xdefault $input_str, q{do_default};    # if $input_str is not in supported cases, return the string 'default'
}
$INPUT,
  on default => sub { 6 },
  on case0   => sub { 0 },
  on case1   => sub { 1 },
  on case2   => sub { 2 },
  on case3   => sub { 3 },
  on case4   => sub { 4 },
  on case5   => sub { 5 };

is $results, 1, q{POD example for xdefault works when string being tested matches a case};

$INPUT = q{not a case};

my $results = dispatch {
    my $input_str = shift;
    xdefault $input_str, q{do_default};    # if $input_str is not in supported cases, return the string 'default'
}
$INPUT,
  on do_default => sub { 6 },
  on case0      => sub { 0 },
  on case1      => sub { 1 },
  on case2      => sub { 2 },
  on case3      => sub { 3 },
  on case4      => sub { 4 },
  on case5      => sub { 5 };

is $results, 6, q{POD example for xdefault works when default case is specified};

$INPUT = q{not a case};

my $results = dispatch {
    my $input_str = shift;
    xdefault $input_str;    # if $input_str is not in supported cases, return the string 'default'
}
$INPUT,
  on default => sub { 6 },
  on case0   => sub { 0 },
  on case1   => sub { 1 },
  on case2   => sub { 2 },
  on case3   => sub { 3 },
  on case4   => sub { 4 },
  on case5   => sub { 5 };

is $results, 6, q{POD example for xdefault works when default case is not specified (uses 'default')};
