use strict;
use warnings;
use Test::More;
use t::FakeGit '1.2.3';

use Test::Requires::Git;

plan 'no_plan';

# ok
test_requires_git version_gt => '1.2.0';

# skip
test_requires_git version_lt => '1.2.1';

fail('cannot happen');
