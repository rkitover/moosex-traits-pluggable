use strict;
use warnings;
use Test::More tests => 2;

{
    package Trait;
    use Moose::Role;
    has 'foo' => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    package Parent;
    use Moose;

    sub BUILDARGS {
        pop(@_);
    }

    package Class;
    use Moose;
    use Test::More;
    extends 'Parent';
    with 'MooseX::Traits::Pluggable';
    override BUILDARGS => sub {
        my ($self, $param1) = @_;
        is $param1, 'Positional value', 'Positional value preserved';
        super();
    };
}

my $i = Class->new_with_traits('Positional value',
    { foo => 'bar', traits => 'Trait' }
);
is $i->foo, 'bar', 'Normal args work';

