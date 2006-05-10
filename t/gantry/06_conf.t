use strict;

use Test::More tests => 1;
use Test::Files;

use File::Spec;

use Bigtop::Parser qw/Conf=General Control=Gantry/;

my $bigtop_string;
my $tree;
my @conf;
my $correct_conf;
my @split_dollar_at;
my @correct_dollar_at;
my $base_dir   = File::Spec->catdir( 't', 'gantry' );
my $docs_dir   = File::Spec->catdir( $base_dir, 'docs' );
my $conf       = File::Spec->catfile( $docs_dir, 'Apps-Checkbook.conf' );

#---------------------------------------------------------------------------
# correct (though small)
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_correct_bigtop';
config {}
app Apps::Checkbook {
    location `/app_base`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    controller PayeeOr {
        rel_location   payee;
        config {
            importance     3 => no_accessor;
            lines_per_page 3;
        }
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

<GantryLocation /app_base/payee>
    importance 3
    lines_per_page 3
</GantryLocation>

EO_CORRECT_CONF

file_ok( $conf, $correct_conf, 'generated output' );

use lib 't';
use Purge;
Purge::real_purge_dir( $docs_dir );
