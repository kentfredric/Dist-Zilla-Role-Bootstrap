use strict;
use warnings;

package Dist::Zilla::Role::Bootstrap;

# ABSTRACT: Shared logic for bootstrap things.

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

sub _max_by(&@) {
  no warnings 'redefine';
  require List::UtilsBy;
  *_max_by = \&List::UtilsBy::max_by;
  goto &List::UtilsBy::max_by;
}

sub _nmax_by(&@) {
  no warnings 'redefine';
  require List::UtilsBy;
  *_nmax_by = \&List::UtilsBy::nmax_by;
  goto &List::UtilsBy::nmax_by;
}

around 'dump_config' => sub {
  my ( $orig, $self, @args ) = @_;
  my $config    = $self->$orig(@args);
  my $localconf = {};
  for my $var (qw( try_built try_built_method fallback distname )) {
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
  is      => ro =>,
  lazy    => 1,
  builder => sub { return },
);

=attr C<fallback>

=cut

has fallback => (
  isa     => 'Bool',
  is      => ro =>,
  lazy    => 1,
  builder => sub { return 1 },
);

=attr C<try_built_method>

=cut

has try_built_method => (
  isa     => 'Str',
  is      => ro =>,
  lazy    => 1,
  builder => sub { return 'mtime' }
);

=p_method C<_pick_latest_mtime>

=cut

sub _pick_latest_mtime {
  my ( $self, @candidates ) = @_;
  return _max_by { $_->stat->mtime } @candidates;
}

=p_method C<_get_candidate_version>

=cut

sub _get_candidate_version {
  my ( $self, $candidate ) = @_;
  my $distname = $self->distname;
  if ( $candidate->basename =~ /\A\Q$distname\E-(.+\z)/msx ) {
    my $version = $1;
    $version =~ s/-TRIAL\z//msx;
    require version;
    return version->parse($version);
  }
}

=p_method C<_pick_latest_parseversion>

=cut

sub _pick_latest_parseversion {
  my ( $self, @candidates ) = @_;
  return _max_by { $self->_get_candidate_version($_) } @candidates;
}

my (%methods) = (
  mtime        => _pick_latest_mtime        =>,
  parseversion => _pick_latest_parseversion =>,
);

=p_method C<_pick_candidate>

=cut

sub _pick_candidate {
  my ( $self, @candidates ) = @_;
  my $method = $self->try_built_method;
  if ( not exists $methods{$method} ) {
    require Carp;
    Carp::croak("No such candidate picking method $method");
  }
  $method = $methods{$method};
  return $self->$method(@candidates);
}

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
    if ( scalar @candidates < 1 ) {
      if ( not $self->fallback ) {
        $self->log( [ 'candidates for bootstrap (%s) == 0, and fallback disabled. not bootstrapping', 0 + @candidates ] );
        return;
      }
      else {
        $self->log( [ 'candidates for bootstrap (%s) == 0, fallback to boostrapping <distname>/', 0 + @candidates ] );
        return $self->_cwd;
      }
    }

    $self->log_debug( [ '>1 candidates, picking one by method %s', $self->try_built_method ] );
    return $self->_pick_candidate(@candidates);

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
  require Carp;
  return Carp::croak('At this time, _add_inc(arg) only supports scalar values of arg');
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
