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

    # perform the check
    my ( $ok, $skip, $why ) = ( 1, 0, '' );
    if ($version) {
        $version =~ s/(?<=^1\.0\.)0([ab])$/$1^"P"/e;    # aliases
        while ( my ( $spec, $arg ) = splice @spec, 0, 2 ) {
            if ( $spec eq 'skip' ) {
                $skip = $arg;
                next;
            }
            croak "Unknown git specification '$spec'" if !exists $check{$spec};
            $arg =~ s/(?<=^1\.0\.)0([ab])$/$1^"P"/e;    # aliases
            if ( !$why && !$check{$spec}->( $version, $arg ) ) {
                $ok  = 0;
                $why = "$version $spec $arg";
            }
        }
    }
    else {
        $ok   = 0;
        $why  = '`git` binary not available or broken';
        $skip = {@spec}->{skip};
    }

    # skip if needed
    if ( !$ok ) {
        my $builder = __PACKAGE__->builder;

        # skip a specified number of tests
        if ( $skip ) {
            $builder->skip($why) for 1 .. $skip;
            no warnings 'exiting';
            last SKIP;
        }

        # no plan declared yet
        elsif ( !defined $builder->has_plan ) {
            $builder->skip_all($why);
        }

        # the plan is no_plan
        elsif ( $builder->has_plan eq 'no_plan' ) {
            $builder->skip($why);
            exit 0;
        }

        # some plan was declared, skip all tests one by one
        else {
            $builder->skip($why) for 1 + $builder->summary .. $builder->has_plan;
            exit 0;
        }
    }
}

'git';

__END__

=encoding utf-8

=head1 NAME

Test::Requires::Git - Check your test requirements against the available version of Git

=head1 SYNOPSIS

    use Test::Requires::Git;

    # needs some git that supports `git init $dir`
    test_requires_git version_ge => '1.6.5';

=head1 DESCRIPTION

Test::Requires::Git checks if the version of Git available for testing
meets the given requirements.

The "current git" is obtained by running C<git --version> (so the first
C<git> binary found in the C<PATH> will be tested).

If the checks fail, then all tests will be I<skipped>.

=head1 EXPORTED FUNCTIONS

=head2 test_requires_git

    # skip all
    test_requires_git version_ge => '1.6.5';

    # skip 2
  SKIP: {
        test_requires_git
          skip       => 2,
          version_ge => '1.7.12';
        ...;
    }

    # skip all if git is not available
    test_requires_git;

    # skip 2 if git is not available
  SKIP: {
        test_requires_git skip => 2;
        ...;
    }

Takes a list of version requirements (see L</GIT VERSION CHECKING> below),
and I<skip> all tests if one of them does not pass.

If the C<skip> parameter is given, only the specified number of tests will
be skipped.

All conditions must be satisfied for the check to pass.

If no condition is given, C<test_requires_git> will only check if C<git>
is available.

=head1 GIT VERSION CHECKING

The following version checks are currently supported.

Note that versions C<1.0.0a> and C<1.0.0b> are respectively turned into
C<1.0.1> and C<1.0.2> internally.

=head2 version

=head2 version_eq

    test_requires_git version    => $version;
    test_requires_git version_eq => $version;

Passes if the current B<git> version is I<equal> to C<$version>.

=head2 version_ne

    test_requires_git version_eq => $version;

Passes if the current B<git> version is I<not equal> to C<$version>.

=head2 version_lt

    test_requires_git version_lt => $version;

Passes if the current B<git> version is I<less than> C<$version>.

=head2 version_gt

    test_requires_git version_gt => $version;

Passes if the current B<git> version is I<greater than> C<$version>.

=head2 version_le

    test_requires_git version_le => $version;

Passes if the current B<git> version is I<less than or equal> C<$version>.

=head2 version_ge

    test_requires_git version_ge => $version;

Passes if the current B<git> version is I<greater than or equal > C<$version>.

=head1 SEE ALSO

L<Test::Requires>

=head1 ACKNOWLEDGEMENTS

Thanks to Oliver Mengué (DOLMEN), who gave me the idea for this module
at the Perl QA Hackathon 2015 in Berlin, and suggested to give a look
at L<Test::Requires> for inspiration.

=head1 AUTHOR

Philippe Bruhat (BooK), <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2015 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
