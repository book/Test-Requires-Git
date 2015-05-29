use strict;
use warnings;
use Test::More;

use Test::Requires::Git -nocheck;

plan tests => 5;

ok( !eval { test_requires_git 'zlonk' }, 'odd specification' );
like(
    $@,
    qr/^Odd number of elements in git specification /,
    '... expected error message'
);

ok( !eval { test_requires_git 'zlonk' => 'bam' }, 'bad specification' );
like(
    $@,
    qr/^Unknown git specification 'zlonk' /,
    '... expected error message'
);

$ENV{PATH} = '';
test_requires_git;
fail( 'cannot happen');
