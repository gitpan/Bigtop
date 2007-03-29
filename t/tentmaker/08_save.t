use strict;

use Test::More tests => 2;
use Test::Files;
use File::Spec;

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
use Bigtop::ScriptHelp::Style;

my $style      = Bigtop::ScriptHelp::Style->get_style();

Bigtop::TentMaker->take_performance_hit( $style ); # all defaults please

my $tent_maker = Bigtop::TentMaker->new();

my $correct_input;
my $answer;

#--------------------------------------------------------------------
# Save minimal default
#--------------------------------------------------------------------

$correct_input = <<'EO_Minimal';
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
    controller is base_controller {
        method do_main is base_links {
        }
        method site_links is links {
        }
    }
}
EO_Minimal

my $minimal = File::Spec->catfile( qw( t tentmaker minimal.bigtop ) );
unlink $minimal;

$answer     = $tent_maker->do_save( $minimal );

file_ok( $minimal, $correct_input, 'saved minimal default' );

unlink $minimal;

#--------------------------------------------------------------------
# Save with no file name
#--------------------------------------------------------------------

$answer = $tent_maker->do_save();

is( $answer, 'Error: No file name given.', 'do_save missing file name' );

