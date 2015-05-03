package t::FakeGit;

use strict;
use warnings;

use Config;
use File::Spec;
use File::Temp qw( tempdir );

# push this to the PATH
my $dir = tempdir( CLEANUP => 1 );
$ENV{PATH} = join $Config::Config{path_sep}, $dir,
  split /\Q$Config::Config{path_sep}\E/, $ENV{PATH} || '';

# compute the 'git' filename
my $file = File::Spec->catfile( $dir, $^O eq 'MSWin32' ? 'git.bat' : 'git' );

# import to build one fake git at compile time
sub import {
    my $package = shift;
    no strict 'refs';
    *{"$package\::fake_git"} = \&fake_git;
    fake_git(shift) if @_;
}

# helper routine to build a fake fit binary
sub fake_git {
    my ($version) = @_;
    unlink $file if -e $file;

    open my $fh, '>', $file or die "Can't open $file for writing: $!";
    print {$fh} $^O eq 'MSWin32' ? << "WIN32" : << "UNIX";
\@echo git version $version
WIN32
#!$^X
print "git version $version\\n"
UNIX
    close $fh;
    chmod 0755, $file;
    return $version;
}

1;
