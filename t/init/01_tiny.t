use strict;

use Test::More tests => 2;
use Test::Files;

use lib 't';
use Purge;

#---------------------------------------------------------------
# Full build
#---------------------------------------------------------------

use Bigtop::Parser qw/Init=Std/;

my $dir = File::Spec->catdir( qw( t ) );

my $simple = File::Spec->catfile( $dir, 'init', 'simple.bigtop' );

Bigtop::Parser->add_valid_keywords(
    'field',
    { keyword => 'is' },
    { keyword => 'update_with' },
);

my $tree = Bigtop::Parser->parse_file($simple);

my $built_dir = Bigtop::Parser::_form_build_dir(
    $dir, $tree, $tree->get_config(), 'create'
);

mkdir $built_dir;

Bigtop::Backend::Init::Std->gen_Init( $built_dir, $tree, $simple );

dir_contains_ok(
    $built_dir,
    [ qw(
        lib
        t
        docs
        Changes
        MANIFEST.SKIP
        README
        Build.PL
        MANIFEST
        docs/simple.bigtop
    ) ],
    'directory structure'
);

Purge::real_purge_dir( $built_dir );

#---------------------------------------------------------------
# Limited build
#---------------------------------------------------------------

my $simple_w_no_gen = File::Spec->catfile( $dir, 'init', 'nogen.bigtop' );

$tree = Bigtop::Parser->parse_file( $simple_w_no_gen );

#my $built_dir = Bigtop::Parser::_form_build_dir(
#    $dir, $tree, $tree->get_config()
#);

mkdir $built_dir;

Bigtop::Backend::Init::Std->gen_Init( $built_dir, $tree, $simple );

dir_only_contains_ok(
    $built_dir,
    [ qw(
        lib
        t
        docs
        MANIFEST.SKIP
        Build.PL
        docs/simple.bigtop
    ) ],
    'limited directory structure'
);

Purge::real_purge_dir( $built_dir );
