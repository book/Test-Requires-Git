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
fake_git( $version );

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
push @lesser, join '.', @version[0..2],'rc1';

# the actual tests
my %tests = (
   version    => [ @lesser, @greater ],
   version_eq => [ @lesser, @greater ],
   version_ne => [ $version ],
   version_lt => [ @lesser, $version ],
   version_gt => [ $version, @greater ],
   version_le => [ @lesser ],
   version_ge => [ @greater ],
);

plan tests => sum map scalar @$_, values %tests;

# run all failing tests in a SKIP block
for my $op ( sort keys %tests ) {

    # skip or fail
    for my $v ( @{ $tests{$op} } ) {
      SKIP: {
            test_requires_git $op => $v, skip => 1;
            fail("$version $op $v");
        }
    }
}
