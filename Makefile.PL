use inc::Module::Install;

name 'MooseX-Traits-Pluggable';
all_from 'lib/MooseX/Traits/Pluggable.pm';

BEGIN {
    require Module::Install::AuthorTests
        if $Module::Install::AUTHOR;
}

requires 'Class::MOP' => '0.84';
requires 'Moose';
requires 'Moose::Role';
requires 'MooseX::Traits' => '0.06';
requires 'Scalar::Util';
requires 'namespace::autoclean';
requires 'List::MoreUtils';
requires 'Moose::Autobox';

build_requires 'Test::Exception';
build_requires 'Test::More';

author_tests 't/author';

auto_provides;
auto_install;
WriteAll();
