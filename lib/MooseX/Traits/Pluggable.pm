package MooseX::Traits::Pluggable;

use namespace::autoclean;
use Moose::Role;
use Scalar::Util qw/blessed reftype/;
use List::MoreUtils 'uniq';
use Carp;
use Moose::Autobox;
use Moose::Util qw/find_meta/;

our $VERSION   = '0.07';
our $AUTHORITY = 'id:RKITOVER';

# stolen from MX::Object::Pluggable
has _original_class_name => (
  is => 'ro',
  required => 1,
  isa => 'Str',
  default => sub { blessed $_[0] },
);

has '_trait_namespace' => (
  # no accessors or init_arg
  init_arg => undef,
  (Moose->VERSION >= 0.84 ) ? (is => 'bare') : (),
);

has _traits => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { [] },
);

has _resolved_traits => (
  is => 'ro',
  isa => 'ArrayRef[ClassName]',
  default => sub { [] },
);

sub _find_trait {
    my ($class, $base, $name) = @_;

    my @search_ns = $class->meta->class_precedence_list;

    for my $ns (@search_ns) {
        my $full = "${ns}::${base}::${name}";
        return $full if eval { Class::MOP::load_class($full) };
    }

    croak "Could not find a class for trait: $name";
}

sub _transform_trait {
    my ($class, $name) = @_;
    my $namespace = $class->meta->find_attribute_by_name('_trait_namespace');
    my $base;
    if($namespace->has_default) {
        $base = $namespace->default;
        if (ref($base) && reftype($base) eq 'CODE') {
            $base = $base->();
        }
    }

    return $name unless $base;
    return $1 if $name =~ /^[+](.+)$/;

    $base = [ $base ] if !ref($base) || reftype($base) ne 'ARRAY';

    for my $ns (@$base) {
        if ($ns =~ /^\+(.*)/) {
            my $trait = eval { $class->_find_trait($1, $name) };
            return $trait if defined $trait;
        }

        my $trait = join '::', $ns, $name;
        return $trait if eval { Class::MOP::load_class($trait) };
    }

    croak "Could not find a class for trait: $name";
}

sub _resolve_traits {
    my ($class, @traits) = @_;

    return map {
        my $transformed = $class->_transform_trait($_);
        Class::MOP::load_class($transformed);
        $transformed;
    } @traits;
}

sub new_with_traits {
    my $class = shift;

    my ($hashref, %args, @others) = 0;
    if (ref($_[-1]) eq 'HASH') {
        %args    = %{ +pop };
        @others  = @_;
        $hashref = 1;
    } else {
        %args    = @_;
    }

    $args{_original_class_name} = $class;

    if (my $traits = delete $args{traits}) {
        my @traits = $traits->flatten;
        if(@traits){
            $args{_traits} = \@traits;
            my @resolved_traits = $class->_resolve_traits(@traits);
            $args{_resolved_traits} = \@resolved_traits;

            my $meta = $class->meta->create_anon_class(
                superclasses => [ $class->meta->name ],
                roles        => \@resolved_traits,
                cache        => 1,
            );
            # Method attributes in inherited roles may have turned metaclass
            # to lies. CatalystX::Component::Traits related special move
            # to deal with this here.
            $meta = find_meta($meta->name);

            $meta->add_method('meta' => sub { $meta });
            $class = $meta->name;
        }
    }

    my $constructor = $class->meta->constructor_name;
    confess "$class does not have a constructor defined via the MOP?"
      if !$constructor;

    return $class->$constructor($hashref ? (@others, \%args) : %args);
}

sub apply_traits {
    my ($self, $traits, $rebless_params) = @_;

    my @traits = $traits->flatten;

    if (@traits) {
        my @resolved_traits = $self->_resolve_traits(@traits);

        $rebless_params ||= {};

        $rebless_params->{_traits} = [ uniq @{ $self->_traits }, @traits ];
        $rebless_params->{_resolved_traits} = [
            uniq @{ $self->_resolved_traits }, @resolved_traits
        ];

        for my $trait (@resolved_traits){
            $trait->meta->apply($self, rebless_params => $rebless_params);
        }
    }
}

no Moose::Role;

1;

__END__

=head1 NAME

MooseX::Traits::Pluggable - an extension to MooseX::Traits

=head1 DESCRIPTION

See L<MooseX::Traits> for usage information.

Adds support for class precedence search for traits and some extra attributes,
described below.

=head1 TRAIT SEARCH

If the value of L<MooseX::Traits/_trait_namespace> starts with a C<+> the
namespace will be considered relative to the C<class_precedence_list> (ie.
C<@ISA>) of the original class.

Example:

  package Class1
  use Moose;

  package Class1::Trait::Foo;
  use Moose::Role;
  has 'bar' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );

  package Class2;
  use parent 'Class1';
  with 'MooseX::Traits';
  has '+_trait_namespace' => (default => '+Trait');

  package Class2::Trait::Bar;
  use Moose::Role;
  has 'baz' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );

  package main;
  my $instance = Class2->new_with_traits(
      traits => ['Foo', 'Bar'],
      bar => 'baz',
      baz => 'quux',
  );

  $instance->does('Class1::Trait::Foo'); # true
  $instance->does('Class2::Trait::Bar'); # true

=head1 NAMESPACE ARRAYS

You can search multiple namespaces for traits, for example:

  has '+_trait_namespace' => (
      default => sub { [qw/+Trait +Role ExtraNS::Trait/] }
  );

Will search in the C<class_precedence_list> for C<::Trait::TheTrait>
and C<::Role::TheTrait> and then for C<ExtraNS::Trait::TheTrait>.

=head1 EXTRA ATTRIBUTES

=head2 _original_class_name

When traits are applied to your class or instance, you get an anonymous class
back whose name will be not the same as your original class. So C<ref $self>
will not be C<Class>, but C<< $self->_original_class_name >> will be.

=head2 _traits

List of the (unresolved) traits applied to the instance.

=head2 _resolved_traits

List of traits applied to the instance resolved to full package names.

=head1 AUTHOR

Rafael Kitover C<< <rkitover@cpan.org> >>

Don't email these guys, they had nothing to do with this fork:

Jonathan Rockway C<< <jrockway@cpan.org> >>

Stevan Little C<< <stevan.little@iinteractive.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
