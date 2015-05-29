use strict;
use warnings;
use Test::More;
use t::FakeGit 'broken';

use Test::Requires::Git -nocheck;

plan tests => 1;

test_requires_git;

fail('cannot happen');
