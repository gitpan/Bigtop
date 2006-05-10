use strict;

use Test::More tests => 22;
use Test::Warn;

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

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=Default /;

Bigtop::TentMaker->take_performance_hit();

my $tent_maker = Bigtop::TentMaker->new();

#--------------------------------------------------------------------
# Add table
#--------------------------------------------------------------------

$tent_maker->do_create_app_block( 'table::address' );

my @correct_input = split /\n/, <<'EO_first_table';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    table address {
        field id {
            is int4, primary_key, auto;
        }
    }
}
EO_first_table

my @maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'create empty table' );

#--------------------------------------------------------------------
# Add sequence
#--------------------------------------------------------------------

$tent_maker->do_create_app_block( 'sequence::addresses_seq' );

@correct_input = split /\n/, <<'EO_addresses';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    table address {
        field id {
            is int4, primary_key, auto;
        }
    }
    sequence addresses_seq {}
}
EO_addresses

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'create sequence in empty app' );

#--------------------------------------------------------------------
# Reorder blocks
#--------------------------------------------------------------------

#use Data::Dumper; warn Dumper( $tent_maker->get_tree );

$tent_maker->do_move_block_after( 'ident_1', 'ident_3' );

@correct_input = split /\n/, <<'EO_reorder';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address {
        field id {
            is int4, primary_key, auto;
        }
    }
}
EO_reorder

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'reorder blocks' );

#--------------------------------------------------------------------
# Create first field
#--------------------------------------------------------------------

$tent_maker->do_create_subblock( 'table::ident_1::field::name' );

@correct_input = split /\n/, <<'EO_new_field';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address {
        field id {
            is int4, primary_key, auto;
        }
        field name {

        }
    }
}
EO_new_field

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'create first field' );

#--------------------------------------------------------------------
# Create field in missing table
#--------------------------------------------------------------------

warning_like { $tent_maker->do_create_subblock( 'table::missing::field::id' ); }
        qr/Couldn't add subblock/,
        'attempt to create field in missing table';

#--------------------------------------------------------------------
# Change table name
#--------------------------------------------------------------------

$tent_maker->do_update_name( 'table::ident_1', 'address_tbl' );

@correct_input = split /\n/, <<'EO_change_table_name';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int4, primary_key, auto;
        }
        field name {

        }
    }
}
EO_change_table_name

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change table name' );

#--------------------------------------------------------------------
# Add statement to table.
#--------------------------------------------------------------------

$tent_maker->do_update_table_statement_text(
    'ident_1::foreign_display', '%name'
);

@correct_input = split /\n/, <<'EO_add_table_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int4, primary_key, auto;
        }
        field name {

        }
        foreign_display `%name`;
    }
}
EO_add_table_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'new table statement' );

#--------------------------------------------------------------------
# Remove statement from table.
#--------------------------------------------------------------------

$tent_maker->do_update_table_statement_text(
    'ident_1::foreign_display', 'undefined'
);

@correct_input = split /\n/, <<'EO_remove_table_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int4, primary_key, auto;
        }
        field name {

        }
    }
}
EO_remove_table_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'remove table statement' );

#--------------------------------------------------------------------
# Add statement to new field.
#--------------------------------------------------------------------

$tent_maker->do_update_field_statement_text(
    'ident_4::is', 'varchar'
);

@correct_input = split /\n/, <<'EO_new_field_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int4, primary_key, auto;
        }
        field name {
            is varchar;
        }
    }
}
EO_new_field_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'new is field statement' );

#--------------------------------------------------------------------
# Change field statement.
#--------------------------------------------------------------------
$tent_maker->do_update_field_statement_text(
    'ident_2::is', 'int8][primary_key][assign_by_sequence'
);

@correct_input = split /\n/, <<'EO_change_field_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field name {
            is varchar;
        }
    }
}
EO_change_field_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change is field statement' );

#--------------------------------------------------------------------
# Third field.
#--------------------------------------------------------------------

$tent_maker->do_create_subblock( 'table::ident_1::field::street' );
$tent_maker->do_update_field_statement_text(
    'ident_5::is', 'varchar'
);

@correct_input = split /\n/, <<'EO_other_field_is_update';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field name {
            is varchar;
        }
        field street {
            is varchar;
        }
    }
}
EO_other_field_is_update

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply(
    \@maker_deparse, \@correct_input, 'add second field and statement in it'
);

#--------------------------------------------------------------------
# Change field name
#--------------------------------------------------------------------

$tent_maker->do_update_name( 'field::ident_5', 'street_address' );

@correct_input = split /\n/, <<'EO_change_field_name';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
        }
    }
}
EO_change_field_name

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change field name' );

#--------------------------------------------------------------------
# Set a multi-word label.
#--------------------------------------------------------------------
$tent_maker->do_update_field_statement_text(
    'ident_5::label', 'Street Address'
);

@correct_input = split /\n/, <<'EO_other_field_is_update';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
            label `Street Address`;
        }
    }
}
EO_other_field_is_update

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply(
    \@maker_deparse, \@correct_input, 'set multi-word label'
);

#--------------------------------------------------------------------
# Remove field statement
#--------------------------------------------------------------------
$tent_maker->do_update_field_statement_text(
    'ident_5::label', 'undefined'
);

@correct_input = split /\n/, <<'EO_remove_field_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
        }
    }
}
EO_remove_field_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply(
    \@maker_deparse, \@correct_input, 'removed field statement'
);

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

$tent_maker->do_update_field_statement_pair(
    'ident_5::html_form_options'
);

@correct_input = split /\n/, <<'EO_pair_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
            html_form_options Happy => 1, Unhappy => 0;
        }
    }
}
EO_pair_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply(
    \@maker_deparse, \@correct_input, 'new pair statement'
);

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

$tent_maker->do_update_field_statement_pair(
    'ident_5::html_form_options'
);

@correct_input = split /\n/, <<'EO_update_pair_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
            html_form_options Happy => 1, Neutral => 2, Unhappy => 0;
        }
    }
}
EO_update_pair_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply(
    \@maker_deparse, \@correct_input, 'update pair statement'
);

#--------------------------------------------------------------------
# Remove field statement with pair values
#--------------------------------------------------------------------
$tent_maker->params(
    {
        values => '1][2][0',
        keys   => '',
    }
);

$tent_maker->do_update_field_statement_pair(
    'ident_5::html_form_options'
);

@correct_input = split /\n/, <<'EO_remove_pair_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
        }
    }
}
EO_remove_pair_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply(
    \@maker_deparse, \@correct_input, 'remove pair statement'
);

#--------------------------------------------------------------------
# Delete field.
#--------------------------------------------------------------------

$tent_maker->do_delete_block( 'ident_5' );

@correct_input = split /\n/, <<'EO_remove_pair_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field name {
            is varchar;
        }
    }
}
EO_remove_pair_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply(
    \@maker_deparse, \@correct_input, 'remove field'
);

#--------------------------------------------------------------------
# Delete table.
#--------------------------------------------------------------------

$tent_maker->do_delete_block( 'ident_1' );

@correct_input = split /\n/, <<'EO_new_table_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
    SQL Postgres {  }
    Model GantryCDBI {  }
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor`;
    email `author@example.com`;
    sequence addresses_seq {}
}
EO_new_table_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'delete table' );

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
        'ident_12::sequence', 'new_seq'
    )
} qr/Couldn't change table statement/,
  'attempt to change statement in missing table';

#--------------------------------------------------------------------
# Change table statement value.
#--------------------------------------------------------------------

$tent_maker->do_update_table_statement_text(
    'ident_7::sequence', 'new_seq'
);

@correct_input = split /\n/, <<'EO_updated_table_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
}
app Addresses {
    sequence address_seq {}
    table address {
        sequence new_seq;
    }
}
EO_updated_table_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'update table statement' );

#--------------------------------------------------------------------
# Add table statment by changing its value.
#--------------------------------------------------------------------

$tent_maker->do_update_table_statement_text(
    'ident_7::foreign_display', '%name'
);

@correct_input = split /\n/, <<'EO_new_table_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
}
app Addresses {
    sequence address_seq {}
    table address {
        sequence new_seq;
        foreign_display `%name`;
    }
}
EO_new_table_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'new table statement' );

#use Data::Dumper; warn Dumper( $tent_maker->get_tree() );
#exit;

