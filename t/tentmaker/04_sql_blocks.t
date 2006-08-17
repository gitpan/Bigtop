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

# ident counting:
#   1   table address
#   2-6 its fields
#   7   controller Address
#   8-9 its methods
my @correct_input = split /\n/, <<'EO_first_table';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    table address {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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

# ident numbering continues:
#  10 addresses_seq
#  11 addresses table
#  12-16 its fields
#  17 controller Addresses
#  18-19 its methods

@correct_input = split /\n/, <<'EO_addresses';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    table address {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
}
EO_addresses

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'create sequence in empty app' );

#--------------------------------------------------------------------
# Reorder blocks
#--------------------------------------------------------------------

$tent_maker->do_move_block_after( 'ident_1', 'ident_7' );

@correct_input = split /\n/, <<'EO_reorder';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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

# this field becomes ident_20

@correct_input = split /\n/, <<'EO_new_field';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {

        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {

        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {

        }
        foreign_display `%name`;
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
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
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {

        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    'ident_20::is', 'varchar'
);

@correct_input = split /\n/, <<'EO_new_field_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {
            is varchar;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {
            is varchar;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    'ident_21::is', 'varchar'
);

# this field is ident_21

@correct_input = split /\n/, <<'EO_other_field_is_update';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {
            is varchar;
        }
        field street {
            is varchar;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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

$tent_maker->do_update_name( 'field::ident_21', 'street_address' );

@correct_input = split /\n/, <<'EO_change_field_name';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    'ident_21::label', 'Street Address'
);

@correct_input = split /\n/, <<'EO_other_field_is_update';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
            label `Street Address`;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    'ident_21::label', 'undefined'
);

@correct_input = split /\n/, <<'EO_remove_field_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    'ident_21::html_form_options'
);

@correct_input = split /\n/, <<'EO_pair_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
            html_form_options Happy => 1, Unhappy => 0;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    'ident_21::html_form_options'
);

@correct_input = split /\n/, <<'EO_update_pair_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
            html_form_options Happy => 1, Neutral => 2, Unhappy => 0;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    'ident_21::html_form_options'
);

@correct_input = split /\n/, <<'EO_remove_pair_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {
            is varchar;
        }
        field street_address {
            is varchar;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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

$tent_maker->do_delete_block( 'ident_21' );

@correct_input = split /\n/, <<'EO_remove_pair_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table address_tbl {
        field id {
            is int8, primary_key, assign_by_sequence;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        field name {
            is varchar;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
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
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller Address is AutoCRUD {
        controls_table address;
        rel_location address;
        text_description address;
        page_link_label Address;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Address;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    sequence addresses_seq {}
    table addresses {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is date;
        }
        field modified {
            is date;
        }
        sequence addresses_seq;
    }
    controller Addresses is AutoCRUD {
        controls_table addresses;
        rel_location addresses;
        text_description addresses;
        page_link_label Addresses;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Addresses;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
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
        'ident_25::sequence', 'new_seq'
    )
} qr/Couldn't change table statement/,
  'attempt to change statement in missing table';

#--------------------------------------------------------------------
# Change table statement value.
#--------------------------------------------------------------------

$tent_maker->do_update_table_statement_text(
    'ident_23::sequence', 'new_seq'
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
    'ident_23::foreign_display', '%name'
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

