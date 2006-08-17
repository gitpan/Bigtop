use strict;

use Test::More tests => 8;

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 8 if $skip_all;
    }
    exit 0 if $skip_all;
}

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=Default /;

#--------------------------------------------------------------------
# Reading sample file from TentMaker __DATA__ block.
#--------------------------------------------------------------------

Bigtop::TentMaker->take_performance_hit();

my @correct_input = split /\n/, <<'EO_sample_input';
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
}
EO_sample_input

my $tent_maker = Bigtop::TentMaker->new();

my @maker_input = split /\n/, $tent_maker->input();

is_deeply( \@maker_input, \@correct_input, 'simple sample input' );

#--------------------------------------------------------------------
# Deparsing __DATA__ input
#--------------------------------------------------------------------

my @maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'simple sample deparse' );

#--------------------------------------------------------------------
# Change App Name
#--------------------------------------------------------------------

$tent_maker->do_update_std( 'appname', 'MySample' );

@correct_input = split /\n/, <<'EO_changed_app_name';
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
app MySample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
}
EO_changed_app_name

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'app name change' );

#--------------------------------------------------------------------
# Change backend keyword
#--------------------------------------------------------------------

$tent_maker->do_update_conf_text(
    'SiteLook::GantryDefault::gantry_wrapper', '/path/to/gantry/root'
);

@correct_input = split /\n/, <<'EO_backend_keyword';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault { gantry_wrapper `/path/to/gantry/root`; }
}
app MySample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
}
EO_backend_keyword

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change backend keyword' );

#--------------------------------------------------------------------
# Add backend keyword
#--------------------------------------------------------------------

$tent_maker->do_update_conf_text(
    'Init::Std::fake_keyword', 'meaning_less_value'
);

@correct_input = split /\n/, <<'EO_change_backend_keyword';
config {
    engine CGI;
    template_engine TT;
    Init Std { fake_keyword meaning_less_value; }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault { gantry_wrapper `/path/to/gantry/root`; }
}
app MySample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
}
EO_change_backend_keyword

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change backend keyword' );

#--------------------------------------------------------------------
# Add backend bool
#--------------------------------------------------------------------

$tent_maker->do_update_conf_bool( 'SiteLook::GantryDefault::no_gen', 'true' );

@correct_input = split /\n/, <<'EO_add_bool';
config {
    engine CGI;
    template_engine TT;
    Init Std { fake_keyword meaning_less_value; }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault { no_gen 1; gantry_wrapper `/path/to/gantry/root`; }
}
app MySample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
}
EO_add_bool

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'add backend bool' );

#--------------------------------------------------------------------
# Turn off backend bool
#--------------------------------------------------------------------

$tent_maker->do_update_conf_bool( 'SiteLook::GantryDefault::no_gen', 'false' );

@correct_input = split /\n/, <<'EO_change_backend_keyword';
config {
    engine CGI;
    template_engine TT;
    Init Std { fake_keyword meaning_less_value; }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault { no_gen 0; gantry_wrapper `/path/to/gantry/root`; }
}
app MySample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
}
EO_change_backend_keyword

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change backend bool' );

#--------------------------------------------------------------------
# Add base location statement
#--------------------------------------------------------------------

$tent_maker->do_update_app_statement_text( 'location', '/site' );

@correct_input = split /\n/, <<'EO_add_app_st';
config {
    engine CGI;
    template_engine TT;
    Init Std { fake_keyword meaning_less_value; }
    CGI Gantry { gen_root 1; with_server 1; }
    Control Gantry { dbix 1; }
    SQL SQLite {  }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault { no_gen 0; gantry_wrapper `/path/to/gantry/root`; }
}
app MySample {
    location `/site`;
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
}
EO_add_app_st

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'add app statement' );
