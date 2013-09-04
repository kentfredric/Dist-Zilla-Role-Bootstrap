
use strict;
use warnings;

use Test::More;

{
    package Example;
    use Moose;
    with 'Dist::Zilla::Role::Bootstrap';

    sub bootstrap {
        1;
    }

    __PACKAGE__->meta->make_immutable;
    1;
}

pass("Role Composition Check Ok");
ok( Example->bootstrap , 'invoke basic method on composed class');

done_testing;
