use strict;
use warnings;
use Test::More;
use t::FakeGit '1.2.3';

use Test::Requires::Git version_gt => '1.0.0';

plan tests => 1;

test_requires_git version => '1.2.3';

test_requires_git version_ge => '1.2.3';

test_requires_git version_lt => '1.3.3';

pass('all passed');
