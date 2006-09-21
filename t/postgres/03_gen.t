use strict;

use File::Spec;
use Test::More tests => 1;
use Test::Files;

use Bigtop::Parser;

use lib 't';
use Purge;

my $dir         = File::Spec->catdir( qw( t postgres ) );
my $sql_file    = File::Spec->catfile(
    $dir, 'Apps-Checkbook', 'docs', 'schema.postgres'
);

my $actual_dir         = File::Spec->catdir( $dir, 'Apps-Checkbook' );

Purge::real_purge_dir( $actual_dir );

my $bigtop_string = << "EO_Bigtop_STRING";
config {
    base_dir   `$dir`;
    SQL        Postgres {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int4, primary_key, auto; }
        field name  { is varchar; }
        data
            name => `Gas Company`;
        data
            id   => 2,
            name => `Phil\\'s Business Center`;
    }
    literal SQL `CREATE INDEX payor_name_ind ON payeepayor ( name );`;
    table not_seen {
        not_for        SQL;
        field id       { is int4, primary_key; }
        field not_much { is varchar; }
    }
    table other {
        field id       { is int4, primary_key; }
    }
    join_table payeeor_other {
        joins payeepayor => other;
    }
}
EO_Bigtop_STRING

Bigtop::Parser->gen_from_string( $bigtop_string, undef, 'create', 'SQL' );

my $correct_sql = <<'EO_CORRECT_SQL';
CREATE TABLE payeepayor (
    id SERIAL PRIMARY KEY,
    name varchar
);

INSERT INTO payeepayor ( name )
    VALUES ( 'Gas Company' );

INSERT INTO payeepayor ( id, name )
    VALUES ( 2, 'Phil\'s Business Center' );

CREATE INDEX payor_name_ind ON payeepayor ( name );
CREATE TABLE other (
    id int4 PRIMARY KEY
);

CREATE TABLE payeeor_other (
    id SERIAL PRIMARY KEY,
    payeepayor int4,
    other int4
);
EO_CORRECT_SQL

file_ok( $sql_file, $correct_sql, 'tiny gened sql file' );

Purge::real_purge_dir( $actual_dir );
