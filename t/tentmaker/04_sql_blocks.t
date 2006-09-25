use strict;

use Test::More tests => 29;
use Test::Files;
use Test::Warn;

# This script uses Test::Files in an unconventional way.  Normally one
# generates a file, then checks to see if that file was correctly built.
# Here ajax returns from tentmaker arrives as strings which are compared
# to expected files.
# The main effect is upon test failure, the senses of Expected and Got
# are REVERSED.  Expected is the ajax output which arrived from tentmaker,
# while Got is the file on the disk of what it should have been.

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 22 if $skip_all;
    }
    exit 0 if $skip_all;
}

use File::Spec;

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=TT /;

Bigtop::TentMaker->take_performance_hit();

my $ajax_dir   = File::Spec->catdir( qw( t tentmaker ajax_04 ) );
my $expected_file;
my $ajax;
my $tent_maker = Bigtop::TentMaker->new();
$tent_maker->uri( '/' );
$tent_maker->root( 'tenttemplates' );

#--------------------------------------------------------------------
# Add table
#--------------------------------------------------------------------

$ajax = $tent_maker->do_create_app_block( 'table::street_address' );

# ident counting:
#   1   table address
#   2-6 its fields
#   7   controller Address
#   8-9 its methods

$expected_file = File::Spec->catfile( $ajax_dir, 'atable' );

file_ok( $expected_file, $ajax, 'add table' );

#--------------------------------------------------------------------
# Add sequence
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_create_app_block( 'sequence::addresses_seq' );

# ident numbering continues:
#  10 addresses_seq
#  11 addresses table
#  12-16 its fields
#  17 controller Addresses
#  18-19 its methods

$expected_file = File::Spec->catfile( $ajax_dir, 'cseq' );

file_ok( $expected_file, $ajax, 'create sequence' );

#--------------------------------------------------------------------
# Reorder blocks
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_move_block_after( 'ident_1', 'ident_7' );

$expected_file = File::Spec->catfile( $ajax_dir, 'reorder' );

file_ok( $expected_file, $ajax, 'reorder blocks' );

#--------------------------------------------------------------------
# Create first field
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_create_subblock( 'table::ident_1::field::name' );

# this field becomes ident_20

$expected_file = File::Spec->catfile( $ajax_dir, 'cfield' );

file_ok( $expected_file, $ajax, 'create field' );

#--------------------------------------------------------------------
# Create field in missing table
#--------------------------------------------------------------------

warning_like { $tent_maker->do_create_subblock( 'table::missing::field::id' ); }
        qr/Couldn't add subblock/,
        'attempt to create field in missing table';

#--------------------------------------------------------------------
# Change table name
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name( 'table::ident_1', 'address_tbl' );

$expected_file = File::Spec->catfile( $ajax_dir, 'ctablename' );

file_ok( $expected_file, $ajax, 'create table name' );

#--------------------------------------------------------------------
# Add statement to table.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_table_statement_text(
    'ident_1::foreign_display', '%name'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'atablest' );

file_ok( $expected_file, $ajax, 'new table statement' );

#--------------------------------------------------------------------
# Remove statement from table.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_table_statement_text(
    'ident_1::foreign_display', 'undefined'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'remtablest' );

file_ok( $expected_file, $ajax, 'remove table statement' );

#--------------------------------------------------------------------
# Add statement to new field.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_bool(
    'ident_20::html_form_optional', 'true'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'afieldbool' );

file_ok( $expected_file, $ajax, 'new boolean statement' );

#--------------------------------------------------------------------
# Change field statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_text(
    'ident_2::is', 'int8][primary_key][assign_by_sequence'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'cis' );

file_ok( $expected_file, $ajax, 'change is field statement' );

#--------------------------------------------------------------------
# Third field.
#--------------------------------------------------------------------

$tent_maker->do_create_subblock( 'table::ident_1::field::street' );

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_table_statement_text(
    'ident_1::foreign_display', '%street'
);

# this field is ident_21

$expected_file = File::Spec->catfile( $ajax_dir, 'afieldcst' );

file_ok( $expected_file, $ajax, 'add second field and change statement' );

#--------------------------------------------------------------------
# Change field name
#--------------------------------------------------------------------

# pretend street was popular in the controller
$tent_maker->do_update_method_statement_text(
    'ident_8::cols', 'ident][street][description'
);
# pretend street was unpopular in the form
$tent_maker->do_update_method_statement_text(
    'ident_9::all_fields_but', 'id][created][street][modified'
);
# ... or not  (This combination is no illegal.)
$tent_maker->do_update_method_statement_text(
    'ident_9::fields', 'street'
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name( 'field::ident_21', 'street_address' );

$expected_file = File::Spec->catfile( $ajax_dir, 'cfieldname' );

file_ok( $expected_file, $ajax, 'change field name' );

# put things back the way they were
$tent_maker->do_update_method_statement_text(
    'ident_8::cols', 'ident][description'
);
$tent_maker->do_update_method_statement_text(
    'ident_9::all_fields_but', 'id][created][modified'
);
$tent_maker->do_update_method_statement_text(
    'ident_9::fields', 'undef'
);

#--------------------------------------------------------------------
# Set a multi-word label.
#--------------------------------------------------------------------
# first, get rid of foreign display
$tent_maker->do_update_table_statement_text(
    'ident_1::foreign_display', 'undef'
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_text(
    'ident_21::label', 'Their Street Address'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'clabel' );

file_ok( $expected_file, $ajax, 'set multi-word label' );

#--------------------------------------------------------------------
# Remove field statement
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_text(
    'ident_21::label', 'undefined'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'rlabel' );

file_ok( $expected_file, $ajax, 'removed field statement' );

#--------------------------------------------------------------------
# Add field statement with pair values
#--------------------------------------------------------------------
# params is a routine in the Gantry engine which sets query strings.
$tent_maker->params(
    {
        values => '1][0',
        keys   => 'Happy][Unhappy',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_pair(
    'ident_21::html_form_options'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'apair' );

file_ok( $expected_file, $ajax, 'new pair statement' );

#--------------------------------------------------------------------
# Change field statement with pair values
#--------------------------------------------------------------------
# params is an engine method which sets query string params
$tent_maker->params(
    {
        values => '1][2][0',
        keys   => 'Happy][Neutral][Unhappy',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_pair(
    'ident_21::html_form_options'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'cpair' );

file_ok( $expected_file, $ajax, 'update pair statement' );

#--------------------------------------------------------------------
# Remove field statement with pair values
#--------------------------------------------------------------------
$tent_maker->params(
    {
        values => '1][2][0',
        keys   => '',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_pair(
    'ident_21::html_form_options'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'rpair' );

file_ok( $expected_file, $ajax, 'remove pair statement' );

#--------------------------------------------------------------------
# Add a foreign key to table, change other table name
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_text(
    'ident_21::refers_to', 'addresses'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'afieldtext' );

file_ok( $expected_file, $ajax, 'add refers_to statement' );

#--------------------------------------------------------------------
# Change table name, check foreign key updates
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name( 'table::ident_11', 'new_table_name' );

$expected_file = File::Spec->catfile( $ajax_dir, 'ctablename2' );

file_ok( $expected_file, $ajax, 'refers_to updates on table name change' );

#--------------------------------------------------------------------
# Delete field.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_delete_block( 'ident_21' );

$expected_file = File::Spec->catfile( $ajax_dir, 'rfield' );

file_ok( $expected_file, $ajax, 'remove field' );

#--------------------------------------------------------------------
# Delete table.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_delete_block( 'ident_1' );

$expected_file = File::Spec->catfile( $ajax_dir, 'rtable' );

file_ok( $expected_file, $ajax, 'remove table' );

#--------------------------------------------------------------------
#--------------------------------------------------------------------
# Switch to reading files and modifying them.
#--------------------------------------------------------------------
#--------------------------------------------------------------------

#--------------------------------------------------------------------
# Change table statement value on missing table.
#--------------------------------------------------------------------

my $sql_config = File::Spec->catfile( 't', 'tentmaker', 'sql.bigtop' );

Bigtop::TentMaker->take_performance_hit( $sql_config );

warning_like {
    $tent_maker->do_update_table_statement_text(
        'ident_25::sequence', 'new_seq'
    )
} qr/Couldn't change table statement/,
  'attempt to change statement in missing table';

#--------------------------------------------------------------------
# Change table statement value.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_table_statement_text(
    'ident_23::sequence', 'new_seq'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchctst' );

file_ok( $expected_file, $ajax, 'update table statement' );

#--------------------------------------------------------------------
# Add table statment by changing its value.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_table_statement_text(
    'ident_23::foreign_display', '%name'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchctst2' );

file_ok( $expected_file, $ajax, 'new table statement' );

#--------------------------------------------------------------------
# Add join_table
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_create_app_block( 'join_table::fox_sock' );

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchaj' );

file_ok( $expected_file, $ajax, 'new join table' );

#--------------------------------------------------------------------
# Add join_table statment by changing its value.
#--------------------------------------------------------------------
# params is a routine in the Gantry engine which sets query strings.
$tent_maker->params(
    {
        values => 'sock',
        keys   => 'fox',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_join_table_statement_pair(
    'ident_24::joins'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchajst' );

file_ok( $expected_file, $ajax, 'new join table statement' );

#--------------------------------------------------------------------
# Change join_table statment value
#--------------------------------------------------------------------
# params is a routine in the Gantry engine which sets query strings.
$tent_maker->params(
    {
        values => 'stocking',
        keys   => 'fox',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_join_table_statement_pair(
    'ident_24::joins'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchcjst' );

file_ok( $expected_file, $ajax, 'change join table statement' );

#--------------------------------------------------------------------
# Check app_block_hash
#--------------------------------------------------------------------

my $expected_blocks  = [
    {
        body => undef,
        name => 'address_seq',
        type => 'sequence',
        ident => 'ident_22',
    },
    {
        body => {
            statements => {
                sequence => bless ( [ 'new_seq' ], 'arg_list' ),
                foreign_display => bless ( [ '%name' ], 'arg_list' ),
            },
            fields => [],
        },
        name => 'address',
        type => 'table',
        ident => 'ident_23',
    },
    {
        body => {
            statements => {
                joins => bless ( [ { 'fox' => 'stocking' } ], 'arg_list' ),
            },
        },
        name => 'fox_sock',
        type => 'join_table',
        ident => 'ident_24',
    },
];

my $app_blocks = $tent_maker->get_tree()->get_app_blocks();

is_deeply( $app_blocks, $expected_blocks, 'app blocks join_table' );

#--------------------------------------------------------------------
# Remove join_table statment by giving it blank keys.
#--------------------------------------------------------------------
# params is a routine in the Gantry engine which sets query strings.
$tent_maker->params(
    {
        values => '',
        keys   => '',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_join_table_statement_pair(
    'ident_24::joins'
);

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchrjst' );

file_ok( $expected_file, $ajax, 'remove join table statement' );

#use Data::Dumper; warn Dumper( $tent_maker->get_tree() );
#exit;

