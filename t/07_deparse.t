use strict;

use Test::More tests => 2;

BEGIN { use_ok( 'Bigtop::Deparser' ) }

use Bigtop::Parser;

my $bigtop_string = join '', <DATA>;

my $ast = Bigtop::Parser->parse_string( $bigtop_string );

my $redone = Bigtop::Deparser->deparse( $ast );

#use Data::Dumper; warn Dumper( $ast );

my @redone_pieces = split /\n/, $redone;

my @correct_rebuild = split /\n/, <<EO_CORRECT_REBUILD;
config {
    engine MP13;
    template_engine TT;
    Init Std {  }
    SQL Postgres {  }
    CGI Gantry { with_server 1; }
    Control Gantry {  }
}
app Name {
    authors `Phil Crow` => `philcrow2000\@yahoo.com`, `Tim Keefer`;
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        var value;
    }
    sequence names_seq {}
    table names {
        sequence names;
        field id {
            is int4, primary_key, auto;
        }
        field last {
            is varchar;
            html_form_type text;
            html_form_display_size 40;
        }
        field first {
            is varchar;
            html_form_optional 1;
        }
    }
    controller Names is AutoCRUD {
        controls_table names;
        rel_location names;
        method do_main is main_listing {
            title Address;
            cols name, phone;
            header_options Add;
            row_options Edit, Delete;
        }
        method _form is AutoCRUD_form {
            form_name address;
            all_fields_but id;
            extra_keys legend => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }
    controller Nothing {
        method do_nothing is stub {

        }
    }
}
EO_CORRECT_REBUILD

is_deeply( \@redone_pieces, \@correct_rebuild, 'moderate deparse' );

#use Data::Dumper; warn Dumper( \@redone_pieces );

__DATA__
config {
    engine MP13;
    template_engine TT;
    Init Std {}
    SQL Postgres {  }
    CGI  Gantry { with_server 1; }
    Control Gantry {}
}
app Name {
    authors `Phil Crow` => `philcrow2000@yahoo.com`, `Tim Keefer`;
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        var value;
    }
    sequence names_seq {}
    table names {
        sequence names;
        field id {
            is int4, primary_key, auto;
        }
        field last {
            is varchar;
            html_form_type text;
            html_form_display_size 40;
        }
        field first {
            is varchar;
            html_form_optional 1;
        }
    }
    controller Names is AutoCRUD {
        controls_table names;
        rel_location   names;
        method do_main is main_listing {
            title            `Address`;
            cols             name, phone;
            header_options   Add;
            row_options      Edit, Delete;
        }
        method _form is AutoCRUD_form {
            form_name        address;
            all_fields_but   id;
            extra_keys
                legend     => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }
    controller Nothing {
        method do_nothing is stub {

        }
    }
}
