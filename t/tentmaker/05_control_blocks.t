use strict;

use Test::More tests => 13;
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

$ajax = $tent_maker->do_create_app_block( 'controller::Address', 'AutoCRUD' );

# this made idents 4-6

$expected_file = File::Spec->catfile( $ajax_dir, 'acontrol' );

file_ok( $expected_file, $ajax, 'create default controller (acontrol)' );

#--------------------------------------------------------------------
# Add method
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_create_subblock(
    'controller::ident_4::method::do_alt_main', 'main_listing'
);

# the new method is ident_5

$expected_file = File::Spec->catfile( $ajax_dir, 'amethod' );

file_ok( $expected_file, $ajax, 'add method to controller (amethod)' );

#--------------------------------------------------------------------
# Add statement to new controller.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_controller_statement_text(
    'ident_4::uses', 'Date::Calc][Carp'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'acontrolst' );

file_ok( $expected_file, $ajax, 'new controller statement (acontrolst)' );

#--------------------------------------------------------------------
# Change previous statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_controller_statement_text(
    'ident_4::uses', 'Carp][Date::Calc'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'ccontrolst' );

file_ok( $expected_file, $ajax, 'change controller statement (ccontrolst)' );

#--------------------------------------------------------------------
# Add method statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_7::title', 'A Label'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'amethodst' );

file_ok( $expected_file, $ajax, 'new method statement (amethodst)' );

#--------------------------------------------------------------------
# Change method statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_7::title', 'Addresses'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'cmethodst' );

file_ok( $expected_file, $ajax, 'change method statement (cmethodst)' );

#--------------------------------------------------------------------
# Change controller name.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name( 'controller::ident_4', 'AddressControl' );

$expected_file = File::Spec->catfile( $ajax_dir, 'ccontrolname' );

file_ok( $expected_file, $ajax, 'change controller name (ccontrolname)' );

#--------------------------------------------------------------------
# Change method name.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name( 'method::ident_5', 'do_main_listing' );

$expected_file = File::Spec->catfile( $ajax_dir, 'cmethodname' );

file_ok( $expected_file, $ajax, 'change method name (cmethodname)' );

#--------------------------------------------------------------------
# Remove controller statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_controller_statement_text(
    'ident_4::uses', 'undefined'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'rcontrolst' );

file_ok( $expected_file, $ajax, 'remove controller statement (rcontrolst)' );

#--------------------------------------------------------------------
# Remove method statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_7::title', 'undefined'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'rmethodst' );

file_ok( $expected_file, $ajax, 'remove method statement (rmethodst)' );

#--------------------------------------------------------------------
# Add paged_conf method statement
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_7::paged_conf', 'list_rows'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'apagedst' );

file_ok( $expected_file, $ajax, 'add paged_conf method statement (apagedst)' );

#--------------------------------------------------------------------
# Remove method.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_delete_block( 'ident_5' );

$expected_file = File::Spec->catfile( $ajax_dir, 'rmethod' );

file_ok( $expected_file, $ajax, 'remove method (rmethod)' );

#--------------------------------------------------------------------
# Removed base controller and make a new one
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

# first remove the existing one
my $discard = $tent_maker->do_delete_block( 'ident_3' );

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_create_app_block(
        'controller::base_controller', 'base_controller'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'newbase' );

file_ok( $expected_file, $ajax, 'new base controller (newbase)' );

