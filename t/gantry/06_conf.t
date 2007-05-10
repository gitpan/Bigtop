use strict;

use Test::More tests => 2;
use Test::Files;

use File::Spec;

use Bigtop::Parser;

use lib 't';
use Purge;

my $bigtop_string;
my $tree;
my @conf;
my $correct_conf;
my @split_dollar_at;
my @correct_dollar_at;
my $base_dir   = File::Spec->catdir( 't', 'gantry' );
my $docs_dir   = File::Spec->catdir( $base_dir, 'docs' );
my $conf       = File::Spec->catfile( $docs_dir, 'Apps-Checkbook.conf' );
my $gconf      = File::Spec->catfile(
        $docs_dir,
        'Apps-Checkbook.gantry.conf'
);

#---------------------------------------------------------------------------
# correct (though small) for Conf General backend
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_correct_bigtop';
config {
    Conf General { gen_root 1; }
}
app Apps::Checkbook {
    location `/app_base`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    literal Conf `hello shane`;
    controller PayeeOr {
        rel_location   payee;
        config {
            importance     3 => no_accessor;
            lines_per_page 3;
        }
        literal GantryLocation `    hello savine`;
    }
    controller Trans {
        location   `/foreign_loc/trans`;
    }
}
EO_correct_bigtop

$tree = Bigtop::Parser->parse_string($bigtop_string);

Bigtop::Backend::Conf::General->gen_Conf( $base_dir, $tree );

$correct_conf = <<'EO_CORRECT_CONF';
DB app_db
DBName some_user
root html:html/templates
hello shane

<GantryLocation /app_base/payee>
    importance 3
    lines_per_page 3
    hello savine
</GantryLocation>

EO_CORRECT_CONF

file_ok( $conf, $correct_conf, 'generated output' );

Purge::real_purge_dir( $docs_dir );

#---------------------------------------------------------------------------
# for Conf Gantry backend
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_correct_bigtop';
config {
    Conf Gantry { gen_root 1; instance happy; }
}
app Apps::Checkbook {
    location `/app_base`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    config prod {
        DB prod_db;
    }
    literal Conf `hello shane`;
    controller PayeeOr {
        rel_location   payee;
        config {
            importance     3 => no_accessor;
            lines_per_page 3;
        }
        config prod {
            lines_per_page 25;
        }
        literal GantryLocation `    hello savine`;
    }
    controller Trans {
        location   `/foreign_loc/trans`;
    }
}
EO_correct_bigtop

$tree = Bigtop::Parser->parse_string($bigtop_string);

Bigtop::Backend::Conf::Gantry->gen_Conf( $base_dir, $tree );

$correct_conf = <<'EO_CORRECT_CONF';
<instance happy>
    DB app_db
    DBName some_user
    root html:html/templates
    hello shane
    <GantryLocation /app_base/payee>
        importance 3
        lines_per_page 3
        hello savine
    </GantryLocation>
</instance>

<instance happy_prod>
    DB prod_db
    root html:html/templates
    DBName some_user
    hello shane
    <GantryLocation /app_base/payee>
        lines_per_page 25
        importance 3
        hello savine
    </GantryLocation>
</instance>

EO_CORRECT_CONF

file_ok( $gconf, $correct_conf, 'generated gantry output' );

Purge::real_purge_dir( $docs_dir );
