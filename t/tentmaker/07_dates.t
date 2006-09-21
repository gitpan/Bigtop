use strict;

use Test::More tests => 2;

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 4 if $skip_all;
    }
    exit 0 if $skip_all;
}

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=Default /;

Bigtop::TentMaker->take_performance_hit( undef, 'family', 'Address' );

my $tent_maker = Bigtop::TentMaker->new();

my @maker_deparse;
my @correct_input;

#--------------------------------------------------------------------
# Sanity Check
#--------------------------------------------------------------------

@correct_input = split /\n/, <<'EO_sanity';
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
}
EO_sanity

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'one table sanity check' );

#--------------------------------------------------------------------
# Change description's type to date -- see the magic
#--------------------------------------------------------------------

# There are variation tests commented out.  I'll add real ones for them
# if they prove problematic.  The ones in current use work the harder
# option in each case.

#$tent_maker->do_update_field_statement_text(
#    'ident_4::date_select_text', 'Set Date'
#);

$tent_maker->do_update_controller_statement_text(
    'ident_7::uses', 'Missing][Module'
);

#$tent_maker->do_update_method_statement_text(
#    'ident_9::form_name', 'family_form'
#);

$tent_maker->params(
    {
        'values' => '4',
        'keys'   => 'xtr',
    }
);
$tent_maker->do_update_method_statement_pair( 'ident_9::extra_keys' );

my $result = $tent_maker->do_update_field_statement_text(
    'ident_4::is', 'date'
);

@correct_input = split /\n/, <<'EO_change_is_to_date';
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
            is date;
            label Description;
            html_form_type text;
            date_select_text `Select Date`;
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
            extra_keys xtr => 4, javascript => `$self->calendar_month_js( 'family' )`;
            form_name family;
        }
        uses Missing, Module, Gantry::Plugins::Calendar;
    }
}
EO_change_is_to_date

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'field is changed to date' );

