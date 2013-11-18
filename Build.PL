
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4200"
  },
  "configure_requires" => {
    "Module::Build" => "0.4200"
  },
  "dist_abstract" => "Shared logic for bootstrap things.",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Dist-Zilla-Role-Bootstrap",
  "dist_version" => "0.2.2",
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
    "perl" => "5.006",
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
    "Moose" => 0,
    "Path::FindDev" => 0,
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "Dist::Zilla::Chrome::Test" => 0,
  "Dist::Zilla::Dist::Builder" => 0,
  "Dist::Zilla::MVP::Assembler::Zilla" => 0,
  "Dist::Zilla::MVP::Section" => 0,
  "File::Copy::Recursive" => 0,
  "Module::Build" => "0.4200",
  "Moose" => 0,
  "Path::FindDev" => 0,
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
