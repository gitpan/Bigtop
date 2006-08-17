use strict;

use Test::More tests => 4;

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

Bigtop::TentMaker->take_performance_hit();

my $tent_maker = Bigtop::TentMaker->new();

#--------------------------------------------------------------------
# Add literal
#--------------------------------------------------------------------

$tent_maker->do_create_app_block( 'literal::' );

my @correct_input = split /\n/, <<'EO_first_literal';
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
    literal None
      ``;

}
EO_first_literal

my @maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'create empty literal' );

#--------------------------------------------------------------------
# Change literal type
#--------------------------------------------------------------------

$tent_maker->do_type_change( 'ident_1', 'Location' );

@correct_input = split /\n/, <<'EO_change_literal_type';
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
    literal Location
      ``;

}
EO_change_literal_type

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change literal type' );

#--------------------------------------------------------------------
# Change literal value
#--------------------------------------------------------------------

$tent_maker->do_update_literal( 'ident_1', '    require valid-user' );

@correct_input = split /\n/, <<'EO_change_literal_value';
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
    literal Location
      `    require valid-user`;

}
EO_change_literal_value

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change literal value' );

#--------------------------------------------------------------------
# Delete literal
#--------------------------------------------------------------------

$tent_maker->do_delete_block( 'ident_1' );

@correct_input = split /\n/, <<'EO_delete_literal';
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
EO_delete_literal

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'delete literal' );
