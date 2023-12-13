use strict;
use warnings;
use Dispatch::Fu; # 'dispatch', 'cases', 'xdefault', and 'on' are exported by default, just for show here
use Test::More tests => 1;
use Test::Warn;

warning_like  {on foo => sub { 1 }} qr/follows a comma/i, q{Make sure 'on' warns when used in void context};
