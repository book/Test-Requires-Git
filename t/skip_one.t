use strict;
use warnings;
use Test::More;
use List::Util qw( sum );
use Scalar::Util qw( looks_like_number );

use t::FakeGit;
use Test::Requires::Git;

# pick a random git version to work with
my @version = (
    [ 1, 2 ]->[ rand 2 ],
    [ 0 .. 12 ]->[ rand 13 ],
    [ 0 .. 12 ]->[ rand 13 ],
    [ 0 .. 12 ]->[ rand 13 ],
);
my $version = join '.', @version;
diag "fake version: $version";
fake_git($version);

# generate other versions based on the current one
my ( @lesser, @greater );
for ( 0 .. $#version ) {
    local $" = '.';
    my @v = @version;
    next if !looks_like_number( $v[$_] );
    $v[$_]++;
    push @greater, "@v";
    next if 0 > ( $v[$_] -= 2 );
    push @lesser, "@v";
}

# an rc is always lesser
push @lesser, join '.', @version[ 0 .. 2 ], 'rc1';

# build up test data
my ( @pass, @skip );
for my $t ( # [ op => [ pass ], [ skip ] ]
    [ version_eq => [$version], [ @lesser, @greater ] ],
    [ version_ne => [ @lesser, @greater ], [$version] ],
    [ version_lt => [@greater], [ @lesser,  $version ] ],
    [ version_gt => [@lesser],  [ $version, @greater ] ],
    [ version_le => [ $version, @greater ], [@lesser] ],
    [ version_ge => [ @lesser,  $version ], [@greater] ],
  )
{
    my ( $op, $pass, $skip ) = @$t;
    push @pass, map [ $version, $op, $_ ], @$pass;
    push @skip, map [ $version, $op, $_ ], @$skip;
}

# operator reversal: $a op $b <=> $b rop $a
my %reverse = (
    version_eq => 'version_eq',
    version_ne => 'version_ne',
    version_ge => 'version_le',
    version_gt => 'version_lt',
    version_le => 'version_ge',
    version_lt => 'version_gt',
);
push @pass, map [ $_->[2], $reverse{ $_->[1] }, $_->[0] ], @pass;
push @skip, map [ $_->[2], $reverse{ $_->[1] }, $_->[0] ], @skip;

# operator negation
my %negate = (
    version_ne => 'version_eq',
    version_eq => 'version_ne',
    version_ge => 'version_lt',
    version_gt => 'version_le',
    version_le => 'version_gt',
    version_lt => 'version_ge',
);
push @pass, map [ $_->[0], $negate{ $_->[1] }, $_->[2] ], @skip;
push @skip, map [ $_->[0], $negate{ $_->[1] }, $_->[2] ], @pass;

plan tests => 1 + 2 * @pass + @skip;

pass('initial pass');

# run all tests in a SKIP block

# PASS
for my $t (@pass) {
    my ( $v1, $op, $v2 ) = @$t;
    fake_git($v1);
    my $passed = 0;

  SKIP: {
        test_requires_git $op => $v2, skip => 1;
        pass("$v1 $op $v2");
        $passed = 1;
    }
    ok( $passed, "$v1 $op $v2" );
}

# SKIP
for my $t (@skip) {
    my ( $v1, $op, $v2 ) = @$t;
    fake_git($v1);

  SKIP: {
        test_requires_git $op => $v2, skip => 1;
        fail("$v1 $op $v2");
    }
}
