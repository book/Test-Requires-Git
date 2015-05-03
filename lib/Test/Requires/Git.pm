package Test::Requires::Git;

use strict;
use warnings;

use Carp;
use Scalar::Util qw( looks_like_number );

use base 'Test::Builder::Module';

# comparison logic stolen from Git::Repository
sub _version_gt {
    my ( $v1, $v2 ) = @_;

    my @v1 = split /\./, $v1;
    my @v2 = split /\./, $v2;

    # pick up any dev parts
    my @dev1 = splice @v1, -2 if substr( $v1[-1], 0, 1 ) eq 'g';
    my @dev2 = splice @v2, -2 if substr( $v2[-1], 0, 1 ) eq 'g';

    # skip to the first difference
    shift @v1, shift @v2 while @v1 && @v2 && $v1[0] eq $v2[0];

    # we're comparing dev versions with the same ancestor
    if ( !@v1 && !@v2 ) {
        @v1 = @dev1;
        @v2 = @dev2;
    }

    # prepare the bits to compare
    ( $v1, $v2 ) = ( $v1[0] || 0, $v2[0] || 0 );

    # rcX is less than any number
    return looks_like_number($v1)
      ? looks_like_number($v2) ? $v1 > $v2 : 1
      : looks_like_number($v2) ? ''        : $v1 gt $v2;
}

my %check = (
    version    => sub { $_[0] eq $_[1] },
    version_eq => sub { $_[0] eq $_[1] },
    version_ne => sub { $_[0] ne $_[1] },
    version_gt => sub { _version_gt(@_) },
    version_le => sub { !_version_gt(@_) },
    version_lt => sub { $_[0] ne $_[1] && !_version_gt(@_) },
    version_ge => sub { $_[0] eq $_[1] || _version_gt(@_) },
);

sub import {
    my $class = shift;
    my $caller = caller(0);

    # export methods
    {
        no strict 'refs';
        *{"$caller\::test_requires_git"} = \&test_requires_git;
    }

    # test arguments
    test_requires_git(@_) if @_;
}

sub test_requires_git {
    my @spec = @_;
    croak 'Odd number of elements in git specification' if @spec % 2;

    # get the git version
    my ($version) = qx{git --version} =~ /^git version (.*)/g;
    $version =~ s/^(?<=^1\.0\.)0([ab])$/$1^"P"/e;    # aliases

    # perform the check
    my $ok = 1;
    while ( my ( $spec, $arg ) = splice @spec, 0, 2 ) {
        croak "Unknown git specification '$spec'" if !exists $check{$spec};
        $arg =~ s/^(?<=^1\.0\.)0([ab])$/$1^"P"/e;    # aliases
        $ok = $check{$spec}->( $version, $arg );
        last if !$ok;
    }

    # skip if needed
    if ( !$ok ) {
        my $builder = __PACKAGE__->builder;

        # no plan declared yet
        if ( !defined $builder->has_plan ) {
            $builder->skip_all();
        }

        # the plan is no_plan
        elsif ( $builder->has_plan eq 'no_plan' ) {
            $builder->skip();
            exit 0;
        }

        # some plan was declared, skip all tests one by one
        else {
            for ( 1 .. $builder->has_plan ) {
                $builder->skip();
            }
            exit 0;
        }
    }
}

'git';
