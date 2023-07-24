use strict;
use warnings;

package Dispatch::Fu;

our $VERSION = q{0.8};

use Exporter qw/import/;
our @EXPORT    = qw(fu on);
our @EXPORT_OK = qw(fu on);

sub fu (&@) {
    my $code_ref  = shift;
    my $match_ref = shift;
    my %dispatch  = @_;
    my $key       = $code_ref->($match_ref);
    $dispatch{$key}->();
}

sub on (@) {
    return @_;
}

1;
