use inc::Module::Install;

name 'MooseX-Traits-Pluggable';
all_from 'lib/MooseX/Traits/Pluggable.pm';

requires 'Class::MOP' => '0.84';
requires 'Moose';
requires 'Moose::Role';
requires 'MooseX::Traits';
requires 'Scalar::Util';

build_requires 'Test::Exception';
build_requires 'Test::More';
build_requires 'ok';

auto_provides;
auto_install;
WriteAll();
