use strict;

use Test::More tests => 3;
use Test::Files;
use Test::Exception;
use File::Spec;
use File::Find;

use lib 't';
use Purge;

use Bigtop::Parser qw/Model=GantryDBIxClass Control=Gantry/;

#---------------------------------------------------------------------------
# Large scale DBIx::Class model generation test
#---------------------------------------------------------------------------

my $play_dir = File::Spec->catdir( qw( t dbixclass play ) );
my $ship_dir = File::Spec->catdir( qw( t dbixclass playship ) );
my $edit_loc = '$$site{exlocation}/editor';

Purge::real_purge_dir( $play_dir );
mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    app_dir         ``;
    Model           GantryDBIxClass { }
    Control         Gantry { dbix 1; full_use 1; }
    SQL             Postgres { }
    SQL             MySQL    { }
}
app Contact {
    config {
        dbconn `dbi:Pg:dbname=contact` => no_accessor;
        dbuser `apache` => no_accessor;
    }
    authors `Phil Crow` => `philcrow2000\@yahoo.com`;
    sequence number_seq {}
    table number {
        field id   { is int4, primary_key, assign_by_sequence; }
        field name {
            is                     varchar;
            label                  `Name`;
            html_form_type         text;
        }
        field number {
            is                     varchar;
            label                  `Number`;
            html_form_type         text;
        }
        sequence        number_seq;
        foreign_display `%name`;
    }
    table bday {
        field id      { is int4, primary_key, assign_by_sequence; }
        field contact {
            is               int4;
            refers_to        number;
            html_form_type   select;
        }
        field bday    {
            is               date;
            html_form_type   text;
        }
    }
    table tshirt {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    table color {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    join_table tshirt_color {
        joins tshirt => color;
    }
    join_table tshirt_author {
        joins tshirt => author;
    }
    table author {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    table book {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    join_table author_book {
        joins author  => book;
        names writers => books;
    }
    controller Number is AutoCRUD {
        autocrud_helper  Gantry::Plugins::AutoCRUDHelper::DBIxClass;
        controls_table   number;
        text_description `contact number`;
        rel_location `number`;
        method do_main is main_listing {
            title             Contacts;
            cols              name, number;
            header_options    Add, CSV;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         contact;
            all_fields_but    id;
        }
        method do_csv is stub {
            extra_args `\$id`;
        }
    }
}
EO_Bigtop_File

Bigtop::Parser->gen_from_string(
        $bigtop_string, undef, 'create', 'Control', 'Model'
);

compare_dirs_ok( $play_dir, $ship_dir, 'DBIxClass models' );

Purge::real_purge_dir( $play_dir );

#---------------------------------------------------------------------------
# multiple joins statements in a join_table block error test
#---------------------------------------------------------------------------

my $errant_string = <<"EO_Double_Joiner";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    app_dir         ``;
    Model           GantryDBIxClass { }
    Control         Gantry { dbix 1; full_use 1; }
    SQL             Postgres { }
    SQL             MySQL    { }
}
app Contact {
    table tshirt {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    table color {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    join_table tshirt_color {
        joins tshirt => color;
        joins author => book;
    }
    table author {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    table book {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    join_table author_book {
        joins author => book;
    }
}
EO_Double_Joiner

dies_ok {
    Bigtop::Parser->parse_string( $errant_string );
} "multiple joins fatal to join_table";

like(
    $@,
    qr/^join_table tshirt_color has multiple/,
    'multiple error message'
);

