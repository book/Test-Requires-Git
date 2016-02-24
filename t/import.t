use strict;
use warnings;
use Test::More;

plan tests => 2;

my $bad_use = 'use Test::Requires::Git -bonk;';
ok( !eval $bad_use, $bad_use );
like(
    $@,
    qr/^Odd number of elements in git specification /,
    '... expected error message'
);
