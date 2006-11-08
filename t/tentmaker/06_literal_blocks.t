use strict;

use Test::More tests => 4;
use Test::Files;
use File::Spec;

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 4 if $skip_all;
    }
    exit 0 if $skip_all;
}

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=TT /;

Bigtop::TentMaker->take_performance_hit();

my $ajax_dir = File::Spec->catdir( qw( t tentmaker ajax_06 ) );
my $expected_file;
my $ajax;
my $tent_maker = Bigtop::TentMaker->new();
$tent_maker->uri( '/' );
$tent_maker->root( 'tenttemplates' );

#--------------------------------------------------------------------
# Add literal
#--------------------------------------------------------------------

$ajax = $tent_maker->do_create_app_block( 'literal::' );

$expected_file = File::Spec->catfile( $ajax_dir, 'alit' );

file_ok( $expected_file, $ajax, 'create empty literal (alit)' );

#--------------------------------------------------------------------
# Change literal type
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_type_change( 'ident_4', 'Location' );

$expected_file = File::Spec->catfile( $ajax_dir, 'clittype' );

file_ok( $expected_file, $ajax, 'change literal type (clittype)' );

#--------------------------------------------------------------------
# Change literal value
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_literal( 'ident_4', '    require valid-user' );

$expected_file = File::Spec->catfile( $ajax_dir, 'clittext' );

file_ok( $expected_file, $ajax, 'change literal text (clittext)' );

#--------------------------------------------------------------------
# Delete literal
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_delete_block( 'ident_4' );

$expected_file = File::Spec->catfile( $ajax_dir, 'rlit' );

file_ok( $expected_file, $ajax, 'remove literal (rlit)' );

