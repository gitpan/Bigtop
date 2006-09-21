use strict;

use Test::More tests => 29;
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

$tent_maker->do_create_app_block( 'table::street_address' );

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
    table street_address {
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        foreign_display `%ident`;
    }
    controller StreetAddress is AutoCRUD {
        controls_table street_address;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
    table street_address {
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        foreign_display `%ident`;
    }
    controller StreetAddress is AutoCRUD {
        controls_table street_address;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
    controller StreetAddress is AutoCRUD {
        controls_table street_address;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table street_address {
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        foreign_display `%ident`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
    controller StreetAddress is AutoCRUD {
        controls_table street_address;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table street_address {
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        foreign_display `%ident`;
        field name {
            is varchar;
            label Name;
            html_form_type text;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        foreign_display `%ident`;
        field name {
            is varchar;
            label Name;
            html_form_type text;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        foreign_display `%name`;
        field name {
            is varchar;
            label Name;
            html_form_type text;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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

$tent_maker->do_update_field_statement_bool(
    'ident_20::html_form_optional', 'true'
);

@correct_input = split /\n/, <<'EO_new_field_statement';
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
$tent_maker->do_update_table_statement_text(
    'ident_1::foreign_display', '%street'
);

# this field is ident_21

@correct_input = split /\n/, <<'EO_other_field_is_update';
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
        }
        field street {
            is varchar;
            label Street;
            html_form_type text;
        }
        foreign_display `%street`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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

# pretend street was popular in the controller
$tent_maker->do_update_method_statement_text(
    'ident_8::cols', 'ident][street][description'
);
$tent_maker->do_update_method_statement_text(
    'ident_9::all_fields_but', 'id][created][street][modified'
);
$tent_maker->do_update_method_statement_text(
    'ident_9::fields', 'street'
);
$tent_maker->do_update_name( 'field::ident_21', 'street_address' );

@correct_input = split /\n/, <<'EO_change_field_name';
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, street_address, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, street_address, modified;
            fields street_address;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
        }
        field street_address {
            is varchar;
            label `Street Address`;
            html_form_type text;
        }
        foreign_display `%street_address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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

$tent_maker->do_update_field_statement_text(
    'ident_21::label', 'Their Street Address'
);

@correct_input = split /\n/, <<'EO_other_field_is_update';
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
        }
        field street_address {
            is varchar;
            label `Their Street Address`;
            html_form_type text;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
        }
        field street_address {
            is varchar;
            html_form_type text;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
        }
        field street_address {
            is varchar;
            html_form_type text;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
        }
        field street_address {
            is varchar;
            html_form_type text;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
        }
        field street_address {
            is varchar;
            html_form_type text;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
# Add a foreign key to table, change other table name
#--------------------------------------------------------------------
$tent_maker->do_update_field_statement_text(
    'ident_21::refers_to', 'addresses'
);

@correct_input = split /\n/, <<'EO_add_refers_to';
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
        }
        field street_address {
            is varchar;
            html_form_type text;
            refers_to addresses;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
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
EO_add_refers_to

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply(
    \@maker_deparse, \@correct_input, 'add refers_to statement'
);

#--------------------------------------------------------------------
# Change table name, check foreign key updates
#--------------------------------------------------------------------
$tent_maker->do_update_name( 'table::ident_11', 'new_table_name' );

@correct_input = split /\n/, <<'EO_second_table_name_change';
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
        }
        field street_address {
            is varchar;
            html_form_type text;
            refers_to new_table_name;
        }
    }
    sequence addresses_seq {}
    table new_table_name {
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
    }
    controller Addresses is AutoCRUD {
        controls_table new_table_name;
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
EO_second_table_name_change

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply(
    \@maker_deparse, \@correct_input, 'refers_to updates on table name change'
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        field name {
            is varchar;
            label Name;
            html_form_type text;
            html_form_optional 1;
        }
    }
    sequence addresses_seq {}
    table new_table_name {
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
    }
    controller Addresses is AutoCRUD {
        controls_table new_table_name;
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
    controller StreetAddress is AutoCRUD {
        controls_table address_tbl;
        rel_location street_address;
        text_description `street address`;
        page_link_label `Street Address`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Street Address`;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    sequence addresses_seq {}
    table new_table_name {
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
            is datetime;
        }
        field modified {
            is datetime;
        }
        sequence addresses_seq;
        foreign_display `%ident`;
    }
    controller Addresses is AutoCRUD {
        controls_table new_table_name;
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

#--------------------------------------------------------------------
# Add join_table
#--------------------------------------------------------------------
$tent_maker->do_create_app_block( 'join_table::fox_sock' );

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
    join_table fox_sock {
    }
}
EO_new_table_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'new join_table' );

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

$tent_maker->do_update_join_table_statement_pair(
    'ident_24::joins'
);


@correct_input = split /\n/, <<'EO_new_join_table_statement';
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
    join_table fox_sock {
        joins fox => sock;
    }
}
EO_new_join_table_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'new join table statement' );

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

$tent_maker->do_update_join_table_statement_pair(
    'ident_24::joins'
);


@correct_input = split /\n/, <<'EO_new_join_table_statement';
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
    join_table fox_sock {
        joins fox => stocking;
    }
}
EO_new_join_table_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change join table statement' );

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

$tent_maker->do_update_join_table_statement_pair(
    'ident_24::joins'
);

@correct_input = split /\n/, <<'EO_new_join_table_statement';
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
    join_table fox_sock {
    }
}
EO_new_join_table_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'remove join table statement' );

#use Data::Dumper; warn Dumper( \@maker_deparse );

#use Data::Dumper; warn Dumper( $tent_maker->get_tree() );
#exit;

