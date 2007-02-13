use strict;

use Test::More tests => 2;
use Test::Files;

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 8 if $skip_all;
    }
    exit 0 if $skip_all;
}

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=TT /;
use Bigtop::ScriptHelp::Style;

use File::Spec;

my $tent_maker;
my @maker_input;
my @maker_deparse;
my @correct_input;
my $ajax;
my $ajax_dir   = File::Spec->catdir( qw( t tentmaker ajax_09 ) );
my $input_file = File::Spec->catdir( qw( t tentmaker billing.bigtop ) );
my $expected_file;
my $style      = Bigtop::ScriptHelp::Style->get_style( 'Original' );

#--------------------------------------------------------------------
# sanity check
#--------------------------------------------------------------------

Bigtop::TentMaker->take_performance_hit( $style, $input_file );

$tent_maker  = Bigtop::TentMaker->new();

$tent_maker->uri( '/' );
$tent_maker->root( 'tenttemplates' );

my $maker_input  = $tent_maker->input();

file_ok( $input_file, $maker_input, 'read and deparse input' );

#--------------------------------------------------------------------
# Change App Name
#--------------------------------------------------------------------

$tent_maker->do_main();

$ajax = $tent_maker->do_process();

$expected_file = File::Spec->catfile( $ajax_dir, 'billing_initial' );

file_ok( $expected_file, $ajax, 'initial do_main hit (billing_initial)' );

open AJAX, ">dump.txt" or warn "$!\n";
print AJAX $ajax;
close $ajax;

