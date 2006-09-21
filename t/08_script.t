use strict;

use Test::More tests => 4;

use Bigtop::ScriptHelp;
use Bigtop::Parser;
use Bigtop::Deparser;

my @received;
my @correct;

#-----------------------------------------------------------------
# Default label (two words)
#-----------------------------------------------------------------

my $name  = 'birth_date';
my $label = Bigtop::ScriptHelp->default_label( $name );

is( $label, 'Birth Date' );

#-----------------------------------------------------------------
# Minimal default
#-----------------------------------------------------------------

my $mini  = Bigtop::ScriptHelp->get_minimal_default( 'Simple' );

@received = split /\n/, $mini;
@correct  = split /\n/, << 'EO_minimal';
config {
    engine          CGI;
    template_engine TT;

    Init            Std             {}
    SQL             SQLite          {}
    SQL             Postgres        {}
    SQL             MySQL           {}
    CGI             Gantry          { with_server 1; gen_root 1; flex_db 1; }
    Control         Gantry          { dbix 1; }
    Model           GantryDBIxClass {}
    SiteLook        GantryDefault   {}
}

app Simple {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
}
EO_minimal

is_deeply( \@received, \@correct, 'minimal default' );

#-----------------------------------------------------------------
# Big default
#-----------------------------------------------------------------

my $max   = Bigtop::ScriptHelp->get_big_default(
        'Address', 'family<-birth_date'
);
@received = split /\n/, $max;
@correct  = split /\n/, << 'EO_bigger';
config {
    engine          CGI;
    template_engine TT;

    Init            Std             {}
    SQL             SQLite          {}
    SQL             Postgres        {}
    SQL             MySQL           {}
    CGI             Gantry          { with_server 1; gen_root 1; flex_db 1; }
    Control         Gantry          { dbix 1; }
    Model           GantryDBIxClass {}
    SiteLook        GantryDefault   {}
}

app Address {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    table family {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is             varchar;
            label          Ident;
            html_form_type text;
        }
        field description {
            is             varchar;
            label          Description;
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
    controller Family is AutoCRUD {
        controls_table family;
        rel_location   family;
        text_description `family`;
        page_link_label `Family`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Family`;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table birth_date {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is             varchar;
            label          Ident;
            html_form_type text;
        }
        field description {
            is             varchar;
            label          Description;
            html_form_type text;
        }
        field created {
            is datetime;
        }
        field modified {
            is datetime;
        }
        foreign_display `%ident`;
        field family {
            is             int4;
            label          Family;
            refers_to      family;
            html_form_type select;
        }
    }
    controller BirthDate is AutoCRUD {
        controls_table birth_date;
        rel_location   birth_date;
        text_description `birth date`;
        page_link_label `Birth Date`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Birth Date`;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }

}
EO_bigger

is_deeply( \@received, \@correct, 'bigger default' );

#-----------------------------------------------------------------
# Augment tree
#-----------------------------------------------------------------

my $ast = Bigtop::Parser->parse_string( $max );
Bigtop::ScriptHelp->augment_tree( $ast, 'anniversary_date->family' );

my $augmented = Bigtop::Deparser->deparse( $ast );

@received = split /\n/, $augmented;
@correct  = split /\n/, << 'EO_augmented';
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
app Address {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    table family {
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
    controller Family is AutoCRUD {
        controls_table family;
        rel_location family;
        text_description family;
        page_link_label Family;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Family;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table birth_date {
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
        field family {
            is int4;
            label Family;
            refers_to family;
            html_form_type select;
        }
    }
    controller BirthDate is AutoCRUD {
        controls_table birth_date;
        rel_location birth_date;
        text_description `birth date`;
        page_link_label `Birth Date`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Birth Date`;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
    table anniversary_date {
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
        field family {
            is int4;
            label Family;
            refers_to family;
            html_form_type select;
        }
    }
    controller AnniversaryDate is AutoCRUD {
        controls_table anniversary_date;
        rel_location anniversary_date;
        text_description `anniversary date`;
        page_link_label `Anniversary Date`;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title `Anniversary Date`;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
        }
    }
}
EO_augmented

is_deeply( \@received, \@correct, 'augmented' );

