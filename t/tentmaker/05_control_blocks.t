use strict;

use Test::More tests => 11;
use Test::Files;
use File::Spec;

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 11 if $skip_all;
    }
    exit 0 if $skip_all;
}

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=TT /;

Bigtop::TentMaker->take_performance_hit();

my $ajax_dir = File::Spec->catdir( qw( t tentmaker ajax_05 ) );
my $expected_file;
my $ajax;
my $tent_maker = Bigtop::TentMaker->new();
$tent_maker->uri( '/' );
$tent_maker->root( 'tenttemplates' );

#--------------------------------------------------------------------
# Add controller
#--------------------------------------------------------------------

$ajax = $tent_maker->do_create_app_block( 'controller::Address', 'AutoCRUD' )
      . "\n";

# this made idents 1-3

$expected_file = File::Spec->catfile( $ajax_dir, 'acontrol' );

file_ok( $expected_file, $ajax, 'create default controller (acontrol)' );

#--------------------------------------------------------------------
# Add method
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_create_subblock(
    'controller::ident_1::method::do_alt_main', 'main_listing'
) . "\n";

# the new method is ident_4

$expected_file = File::Spec->catfile( $ajax_dir, 'amethod' );

file_ok( $expected_file, $ajax, 'add method to controller (amethod)' );

#--------------------------------------------------------------------
# Add statement to new controller.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_controller_statement_text(
    'ident_1::uses', 'Date::Calc][Carp'
) . "\n";

$expected_file = File::Spec->catfile( $ajax_dir, 'acontrolst' );

file_ok( $expected_file, $ajax, 'new controller statement (acontrolst)' );

#--------------------------------------------------------------------
# Change previous statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_controller_statement_text(
    'ident_1::uses', 'Carp][Date::Calc'
) . "\n";

$expected_file = File::Spec->catfile( $ajax_dir, 'ccontrolst' );

file_ok( $expected_file, $ajax, 'change controller statement (ccontrolst)' );

#--------------------------------------------------------------------
# Add method statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_4::title', 'A Label'
) . "\n";

$expected_file = File::Spec->catfile( $ajax_dir, 'amethodst' );

file_ok( $expected_file, $ajax, 'new method statement (amethodst)' );

#--------------------------------------------------------------------
# Change method statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_4::title', 'Addresses'
) . "\n";

$expected_file = File::Spec->catfile( $ajax_dir, 'cmethodst' );

file_ok( $expected_file, $ajax, 'change method statement (cmethodst)' );

#--------------------------------------------------------------------
# Change controller name.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name(
    'controller::ident_1', 'AddressControl'
) . "\n";

$expected_file = File::Spec->catfile( $ajax_dir, 'ccontrolname' );

file_ok( $expected_file, $ajax, 'change controller name (ccontrolname)' );

#--------------------------------------------------------------------
# Change method name.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name(
    'method::ident_2', 'do_main_listing'
) . "\n";

$expected_file = File::Spec->catfile( $ajax_dir, 'cmethodname' );

file_ok( $expected_file, $ajax, 'change method name (cmethodname)' );

#--------------------------------------------------------------------
# Remove controller statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_controller_statement_text(
    'ident_1::uses', 'undefined'
) . "\n";

$expected_file = File::Spec->catfile( $ajax_dir, 'rcontrolst' );

file_ok( $expected_file, $ajax, 'remove controller statement (rcontrolst)' );

#--------------------------------------------------------------------
# Remove method statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_4::title', 'undefined'
) . "\n";

$expected_file = File::Spec->catfile( $ajax_dir, 'rmethodst' );

file_ok( $expected_file, $ajax, 'remove method statement (rmethodst)' );

#--------------------------------------------------------------------
# Remove method.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_delete_block( 'ident_2' ) . "\n";

$expected_file = File::Spec->catfile( $ajax_dir, 'rmethod' );

file_ok( $expected_file, $ajax, 'remove method (rmethod)' );

