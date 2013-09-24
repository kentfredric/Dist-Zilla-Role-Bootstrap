
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4007"
  },
  "configure_requires" => {
    "Module::Build" => "0.4007"
  },
  "dist_abstract" => "Shared logic for bootstrap things.",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Dist-Zilla-Role-Bootstrap",
  "dist_version" => "0.2.1",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Role::Bootstrap",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Dist::Zilla::Role::Plugin" => 0,
    "List::UtilsBy" => 0,
    "Moose::Role" => 0,
    "MooseX::AttributeShortcuts" => 0,
    "Path::Tiny" => 0,
    "lib" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "version" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Dist::Zilla::Chrome::Test" => 0,
    "Dist::Zilla::Dist::Builder" => 0,
    "Dist::Zilla::MVP::Assembler::Zilla" => 0,
    "Dist::Zilla::MVP::Section" => 0,
    "File::Copy::Recursive" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Moose" => 0,
    "Path::FindDev" => 0,
    "Test::More" => "0.98"
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
