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
    my $caller  = caller(0);
    no strict 'refs';
    *{"$caller\::fake_git"} = \&fake_git;
    fake_git(shift) if @_;
}

# helper routine to build a fake fit binary
sub fake_git {
    my ($version) = @_;
    unlink $file if -e $file;

    my $message = $version =~ /^[1-9]/ ? "git version $version" : 'not git';

    open my $fh, '>', $file or die "Can't open $file for writing: $!";
    print {$fh} $^O eq 'MSWin32' ? << "WIN32" : << "UNIX";
\@echo $message
WIN32
#!$^X
print "$message\\n"
UNIX
    close $fh;
    chmod 0755, $file;
    return $version;
}

1;
