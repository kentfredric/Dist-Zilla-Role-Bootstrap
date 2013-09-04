use strict;
use warnings;

package Dist::Zilla::Role::Bootstrap;
BEGIN {
  $Dist::Zilla::Role::Bootstrap::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Role::Bootstrap::VERSION = '0.1.0';
}

# ABSTRACT: Shared logic for boostrap things.

use Moose::Role;
use MooseX::AttributeShortcuts;


with 'Dist::Zilla::Role::Plugin';

around 'dump_config' => sub {
  my ( $orig, $self, @args ) = @_;
  my $config    = $self->$orig(@args);
  my $localconf = {};
  for my $var (qw( try_built fallback distname )) {
    my $pred = 'has_' . $var;
    if ( $self->can($pred) ) {
      next unless $self->$pred();
    }
    if ( $self->can($var) ) {
      $localconf->{$var} = $self->$var();
    }
  }
  $config->{ q{} . __PACKAGE__ } = $localconf;
  return $config;
};

has distname => ( is => ro =>, lazy => 1, builder => sub { $_[0]->zilla->name; }, );

has _cwd => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require Path::Tiny;
    require Cwd;
    return Path::Tiny::path( Cwd::cwd() );
  },
);


has try_built => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return },
);


has fallback => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return 1 },
);


has _bootstrap_root => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    if ( not $self->try_built ) {
      return $self->_cwd;
    }
    my $distname = $self->distname;
    my (@candidates) = grep { $_->basename =~ /\A\Q$distname\E-/msx } grep { $_->is_dir } $self->_cwd->children;

    if ( scalar @candidates == 1 ) {
      return $candidates[0];
    }
    $self->log_debug( [ 'candidate: %s', $_->basename ] ) for @candidates;

    if ( not $self->fallback ) {
      $self->log( [ 'candidates for bootstrap (%s) != 1, and fallback disabled. not bootstrapping', 0 + @candidates ] );
      return;
    }

    $self->log( [ 'candidates for bootstrap (%s) != 1, fallback to boostrapping <distname>/', 0 + @candidates ] );
    return $self->_cwd;
  },
);

sub _add_inc {
  my ( $self, $import ) = @_;
  if ( not ref $import ) {
    require lib;
    return lib->import($import);
  }
  die "At this time, _add_inc(arg) only supports scalar values of arg";
}

requires 'bootstrap';

around plugin_from_config => sub {
  my ( $orig, $plugin_class, $name, $payload, $section ) = @_;

  my $instance = $plugin_class->$orig( $name, $payload, $section );

  $instance->bootstrap;

  return $instance;
};

no Moose::Role;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Role::Bootstrap - Shared logic for boostrap things.

=head1 VERSION

version 0.1.0

=head1 ATTRIBUTES

=head2 C<try_built>

=head2 C<fallback>

=head1 PRIVATE ATTRIBUTES

=head2 C<_bootstrap_root>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Role::Bootstrap",
    "interface":"role",
    "does":"Dist::Zilla::Role::Plugin"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
