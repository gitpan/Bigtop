use strict;

use Test::More tests => 8;
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

use File::Spec;

my $tent_maker;
my @maker_input;
my @maker_deparse;
my @correct_input;
my $ajax;
my $ajax_dir = File::Spec->catdir( qw( t tentmaker ajax_02 ) );
my $expected_file;

#--------------------------------------------------------------------
# Reading sample file from TentMaker __DATA__ block.
#--------------------------------------------------------------------

@correct_input = split /\n/, <<'EO_sample_input';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    SQL SQLite {  }
    SQL Postgres {  }
    SQL MySQL {  }
    CGI Gantry { gen_root 1; with_server 1; flex_db 1; }
    Control Gantry { dbix 1; }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
}
EO_sample_input

Bigtop::TentMaker->take_performance_hit();

$tent_maker  = Bigtop::TentMaker->new();

$tent_maker->uri( '/' );
$tent_maker->root( 'tenttemplates' );

@maker_input = split /\n/, $tent_maker->input();

is_deeply( \@maker_input, \@correct_input, 'simple sample input' );

#--------------------------------------------------------------------
# Deparsing __DATA__ input
#--------------------------------------------------------------------

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'simple sample deparse' );

#--------------------------------------------------------------------
# Change App Name
#--------------------------------------------------------------------

$ajax = $tent_maker->do_update_std( 'appname', 'MySample' );

$expected_file = File::Spec->catfile( $ajax_dir, 'cappname' );

file_ok( $expected_file, $ajax, 'change app name' );

#--------------------------------------------------------------------
# Add backend keyword
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_conf_text(
    'SiteLook::GantryDefault::gantry_wrapper', '/path/to/gantry/root'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'abackword' );

file_ok( $expected_file, $ajax, 'add backend keyword' );

#--------------------------------------------------------------------
# Change backend keyword
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_conf_text(
    'SiteLook::GantryDefault::gantry_wrapper', 'meaning_less_value'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'cbackword' );

file_ok( $expected_file, $ajax, 'change backend keyword' );

#--------------------------------------------------------------------
# Add backend bool
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_conf_bool(
            'SiteLook::GantryDefault::no_gen',
            'true'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'abackbool' );

file_ok( $expected_file, $ajax, 'add backend boolean' );

#--------------------------------------------------------------------
# Turn off backend bool
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_conf_bool(
            'SiteLook::GantryDefault::no_gen',
            'false'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'cbackbool' );

file_ok( $expected_file, $ajax, 'change backend boolean' );

#--------------------------------------------------------------------
# Add base location statement
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_app_statement_text( 'location', '/site' );

$expected_file = File::Spec->catfile( $ajax_dir, 'aappst' );

file_ok( $expected_file, $ajax, 'add app statement' );

