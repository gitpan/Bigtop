use strict;

use Test::More tests => 11;

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 11 if $skip_all;
    }
    exit 0 if $skip_all;
}

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=Default /;

Bigtop::TentMaker->take_performance_hit();

my $tent_maker = Bigtop::TentMaker->new();

#--------------------------------------------------------------------
# Add controller
#--------------------------------------------------------------------

$tent_maker->do_create_app_block( 'controller::Address', 'AutoCRUD' );

my @correct_input = split /\n/, <<'EO_first_table';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller Address is AutoCRUD {

    }
}
EO_first_table

my @maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'create empty controller' );

#--------------------------------------------------------------------
# Add method
#--------------------------------------------------------------------

$tent_maker->do_create_subblock(
    'controller::ident_1::method::do_main', 'main_listing'
);

@correct_input = split /\n/, <<'EO_new_field';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller Address is AutoCRUD {
        method do_main is main_listing {

        }
    }
}
EO_new_field

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'add method to controller' );

#--------------------------------------------------------------------
# Add statement to new controller.
#--------------------------------------------------------------------

$tent_maker->do_update_controller_statement_text(
    'ident_1::uses', 'Date::Calc][Carp'
);

@correct_input = split /\n/, <<'EO_controller_statement';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller Address is AutoCRUD {
        method do_main is main_listing {

        }
        uses `Date::Calc`, Carp;
    }
}
EO_controller_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'new controller statement' );

#--------------------------------------------------------------------
# Change previous statement.
#--------------------------------------------------------------------

$tent_maker->do_update_controller_statement_text(
    'ident_1::uses', 'Carp][Date::Calc'
);

@correct_input = split /\n/, <<'EO_change_controller_statement';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller Address is AutoCRUD {
        method do_main is main_listing {

        }
        uses Carp, `Date::Calc`;
    }
}
EO_change_controller_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change controller statement' );

#--------------------------------------------------------------------
# Add method statement.
#--------------------------------------------------------------------
$tent_maker->do_update_method_statement_text(
    'ident_2::page_link_label', 'A Label'
);

@correct_input = split /\n/, <<'EO_new_method_statement';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller Address is AutoCRUD {
        method do_main is main_listing {
            page_link_label `A Label`;
        }
        uses Carp, `Date::Calc`;
    }
}
EO_new_method_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'new method statement' );

#--------------------------------------------------------------------
# Change method statement.
#--------------------------------------------------------------------
$tent_maker->do_update_method_statement_text(
    'ident_2::page_link_label', 'Addresses'
);

@correct_input = split /\n/, <<'EO_change_method_statement';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller Address is AutoCRUD {
        method do_main is main_listing {
            page_link_label Addresses;
        }
        uses Carp, `Date::Calc`;
    }
}
EO_change_method_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change method statement' );

#--------------------------------------------------------------------
# Change controller name.
#--------------------------------------------------------------------
$tent_maker->do_update_name(
    'controller::ident_1', 'AddressControl'
);

@correct_input = split /\n/, <<'EO_change_controller_name';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller AddressControl is AutoCRUD {
        method do_main is main_listing {
            page_link_label Addresses;
        }
        uses Carp, `Date::Calc`;
    }
}
EO_change_controller_name

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change controller name' );

#--------------------------------------------------------------------
# Change method name.
#--------------------------------------------------------------------
$tent_maker->do_update_name(
    'method::ident_2', 'do_main_listing'
);

@correct_input = split /\n/, <<'EO_change_method_name';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller AddressControl is AutoCRUD {
        method do_main_listing is main_listing {
            page_link_label Addresses;
        }
        uses Carp, `Date::Calc`;
    }
}
EO_change_method_name

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'change method name' );

#--------------------------------------------------------------------
# Remove controller statement.
#--------------------------------------------------------------------

$tent_maker->do_update_controller_statement_text(
    'ident_1::uses', 'undefined'
);

@correct_input = split /\n/, <<'EO_remove_controller_statement';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller AddressControl is AutoCRUD {
        method do_main_listing is main_listing {
            page_link_label Addresses;
        }
    }
}
EO_remove_controller_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'remove controller statement' );

#--------------------------------------------------------------------
# Remove method statement.
#--------------------------------------------------------------------
$tent_maker->do_update_method_statement_text(
    'ident_2::page_link_label', 'undefined'
);

@correct_input = split /\n/, <<'EO_remove_method_statement';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller AddressControl is AutoCRUD {
        method do_main_listing is main_listing {

        }
    }
}
EO_remove_method_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'remove method statement' );

#--------------------------------------------------------------------
# Remove method.
#--------------------------------------------------------------------
$tent_maker->do_delete_block( 'ident_2' );

@correct_input = split /\n/, <<'EO_remove_method_statement';
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
    authors `A. U. Thor`;
    email `author@example.com`;
    controller AddressControl is AutoCRUD {

    }
}
EO_remove_method_statement

@maker_deparse = split /\n/, $tent_maker->deparsed();

is_deeply( \@maker_deparse, \@correct_input, 'remove method' );

