use strict;
use warnings;

package Dist::Zilla::Role::Bootstrap;
BEGIN {
  $Dist::Zilla::Role::Bootstrap::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Role::Bootstrap::VERSION = '0.1.2';
}

# ABSTRACT: Shared logic for bootstrap things.

use Moose::Role;
use MooseX::AttributeShortcuts;



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


has distname => ( isa => 'Str', is => ro =>, lazy => 1, builder => sub { $_[0]->zilla->name; }, );


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
  isa     => 'Bool',
  is      => ro =>,
  lazy    => 1,
  builder => sub { return },
);


has fallback => (
  isa     => 'Bool',
  is      => ro =>,
  lazy    => 1,
  builder => sub { return 1 },
);

has try_built_method => (
  isa     => 'Str',
  is      => ro =>,
  lazy    => 1,
  builder => sub { return 'mtime' }
);

sub _pick_latest_mtime {
  my ( $self, @candidates ) = @_;
  return _max_by { $_->stat->mtime } @candidates;
}

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

sub _pick_latest_parseversion {
  my ( $self, @candidates ) = @_;
  return _max_by { $self->_get_candidate_version($_) } @candidates;
}

my (%methods) = (
  mtime        => _pick_latest_mtime        =>,
  parseversion => _pick_latest_parseversion =>,
);

sub _pick_candidate {
  my ( $self, @candidates ) = @_;
  my $method = $self->try_built_method;
  if ( not exists $methods{$method} ) {
    require Carp;
    Carp::croak("No such candidate picking method $method");
  }
  return $self->$method(@candidates);
}


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


sub _add_inc {
  my ( $self, $import ) = @_;
  if ( not ref $import ) {
    require lib;
    return lib->import($import);
  }
  require Carp;
  return Carp::croak('At this time, _add_inc(arg) only supports scalar values of arg');
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

Dist::Zilla::Role::Bootstrap - Shared logic for bootstrap things.

=head1 VERSION

version 0.1.2

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

=head1 REQUIRED METHODS

=head2 C<bootstrap>

=head1 ATTRIBUTES

=head2 C<distname>

=head2 C<try_built>

=head2 C<fallback>

=head1 PRIVATE ATTRIBUTES

=head2 C<_cwd>

=head2 C<_bootstrap_root>

=head1 PRIVATE METHODS

=head2 C<_add_inc>

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
