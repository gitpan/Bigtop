use strict;

use Test::More tests => 1;
use Test::Files;
use File::Spec;
use File::Find;

use Bigtop::Parser qw/Model=GantryDBIxClass Control=Gantry/;

my $play_dir = File::Spec->catdir( qw( t dbixclass play ) );
my $ship_dir = File::Spec->catdir( qw( t dbixclass playship ) );
my $edit_loc = '$$site{exlocation}/editor';

mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    app_dir         ``;
    Model           GantryDBIxClass { }
    Control         Gantry { dbix 1; }
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
    controller Number is AutoCRUD {
        autocrud_helper  Gantry::Plugins::AutoCRUDHelper::DBIxClass;
        controls_table   number;
        text_description `contact number`;
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

use lib 't';
use Purge;

Purge::real_purge_dir( $play_dir );
