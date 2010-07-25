use inc::Module::Install;

name 'MooseX-Traits-Pluggable';
all_from 'lib/MooseX/Traits/Pluggable.pm';

require Module::Install::ReadmeFromPod;
BEGIN {
    require Module::Install::AuthorTests
        if $Module::Install::AUTHOR;
}

requires 'Class::MOP' => '0.84';
requires 'Moose';
requires 'Moose::Role';
requires 'Scalar::Util';
requires 'namespace::autoclean';
requires 'List::MoreUtils';

build_requires 'Test::Exception';
build_requires 'Test::More';

author_tests 't/author';

auto_provides;
auto_install;

resources repository =>
    'git://github.com/rkitover/moosex-traits-pluggable.git';

readme_from 'lib/MooseX/Traits/Pluggable.pm';

realclean_files qw[MANIFEST README];

WriteAll();
