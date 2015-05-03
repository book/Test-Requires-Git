use strict;
use warnings;
use Test::More;
use t::FakeGit '1.2.3';

use Test::Requires::Git version_gt => '1.0.0';

plan tests => 8;

pass( "passed the compile-time check version_gt => '1.0.0'");

test_requires_git version => '1.2.3';

pass( "passed the run-time check version => '1.2.3'");

test_requires_git
  version_eq => '1.2.3',
  version_ne => '1.2.4';

pass( "passed the run-time check version_eq => '1.2.3', version_ne => '1.2.4'");

test_requires_git version_lt => '1.3.3';

pass( "passed the run-time check version_lt => '1.3.3'");

test_requires_git version_gt => '1.0.0a';

pass( "passed the run-time check version_gt => '1.0.0a'");

test_requires_git version_le => '1.2.3';

pass( "passed the run-time check version_le => '1.2.3'");

test_requires_git version_ge => '1.2.3';

pass( "passed the run-time check version_ge => '1.2.3'");

pass('all passed');
