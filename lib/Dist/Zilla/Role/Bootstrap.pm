use strict;
use warnings;

package Dist::Zilla::Role::Bootstrap;

# ABSTRACT: Shared logic for boostrap things.

use Moose::Role;
use MooseX::AttributeShortcuts;

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Role::Bootstrap",
    "interface":"role",
    "does":"Dist::Zilla::Role::Plugin"
}

=end MetaPOD::JSON

=cut

=head1 SYNOPSIS

For consuming plugins:

    use Moose;
    with 'Dist::Zilla::Role::Bootstrap';

    sub bootstrap {
        my $bootstrap_root = $_[0]->_bootstrap_root;
        # Do the actual bootstrap work here
        $_[0]->_add_inc('./some/path/here');
    }

For users of plugins:

    [Some::Plugin::Name]
    try_built = 0 ; # use / as the root to bootstrap
    try_built = 1 ; # try to use /Dist-Name-.*/ instead of /

    fallback  = 0 ; # don't bootstrap at all if /Dist-Name-.*/ matches != 1 things
    fallback  = 1 ; # fallback to / if /Dist-Name-.*/ matches != 1 things
   

=cut

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

=attr C<distname>

=cut

has distname => ( isa => 'Str', is => ro =>, lazy => 1, builder => sub { $_[0]->zilla->name; }, );

=p_attr C<_cwd>

=cut

has _cwd => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require Path::Tiny;
    require Cwd;
    return Path::Tiny::path( Cwd::cwd() );
  },
);

=attr C<try_built>

=cut

has try_built => (
  isa     => 'Bool',
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return },
);

=attr C<fallback>

=cut

has fallback => (
  isa     => 'Bool',
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return 1 },
);

=p_attr C<_bootstrap_root>

=cut

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

=p_method C<_add_inc>

=cut

sub _add_inc {
  my ( $self, $import ) = @_;
  if ( not ref $import ) {
    require lib;
    return lib->import($import);
  }
  die "At this time, _add_inc(arg) only supports scalar values of arg";
}

=requires C<bootstrap>

=cut

requires 'bootstrap';

around plugin_from_config => sub {
  my ( $orig, $plugin_class, $name, $payload, $section ) = @_;

  my $instance = $plugin_class->$orig( $name, $payload, $section );

  $instance->bootstrap;

  return $instance;
};

no Moose::Role;

1;
