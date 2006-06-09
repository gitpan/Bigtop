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

use File::Spec;

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=Default /;

#--------------------------------------------------------------------
# Sanity Check (repeated test from 02....t)
#--------------------------------------------------------------------

Bigtop::TentMaker->take_performance_hit();

my @correct_input = split /\n/, <<'EO_sample_input';
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
    authors `A. U. Thor` => `author@example.com`;
}
EO_sample_input

my $tent_maker = Bigtop::TentMaker->new();

my @maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'simple sample deparse' );

#--------------------------------------------------------------------
# Add config statement when there is no config block
#--------------------------------------------------------------------

$tent_maker->do_update_app_conf_statement( 'new_conf_st', 'new_value' );

@correct_input = split /\n/, <<'EO_brand_new_config';
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
        new_conf_st new_value;
    }
    authors `A. U. Thor` => `author@example.com`;
}
EO_brand_new_config

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'new conf block' );

#--------------------------------------------------------------------
# Add config statement when config block exists, but is empty
#--------------------------------------------------------------------

my $empty_config = File::Spec->catfile( 't', 'tentmaker', 'sample' );

Bigtop::TentMaker->take_performance_hit( $empty_config );

$tent_maker->do_update_app_conf_statement( 'new_conf_st', 'value' );

@correct_input = split /\n/, <<'EO_first_config_statement';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
}
app Sample {
    config {
        new_conf_st value;
    }
}
EO_first_config_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'first conf statement' );

#--------------------------------------------------------------------
# Change statement value
#--------------------------------------------------------------------

$tent_maker->do_update_app_conf_statement( 'new_conf_st', 'other_value' );

@correct_input = split /\n/, <<'EO_statement_change';
config {
    engine CGI;
    template_engine TT;
    Init Std {  }
}
app Sample {
    config {
        new_conf_st other_value;
    }
}
EO_statement_change

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'add backend keyword' );

