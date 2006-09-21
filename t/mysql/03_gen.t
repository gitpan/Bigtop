use strict;

use File::Spec;
use Test::More tests => 1;
use Test::Files;

use Bigtop::Parser;

my $dir         = File::Spec->catdir( qw( t mysql ) );
my $sql_file    = File::Spec->catfile(
    $dir, 'Apps-Checkbook', 'docs', 'schema.mysql'
);
my $bigtop_string = << "EO_Bigtop_STRING";
config {
    base_dir   `$dir`;
    SQL        MySQL {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int4, primary_key, assign_by_sequence; }
        field name  { is `varchar(20)`; }
        field user  { is varchar; }
        data
            name => `Gas Company`;
        data
            id   => 2,
            name => `Crow Business Center`;
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
    id MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    name varchar(20),
    user VARCHAR(100)
);

INSERT INTO payeepayor ( name )
    VALUES ( 'Gas Company' );

INSERT INTO payeepayor ( id, name )
    VALUES ( 2, 'Crow Business Center' );

CREATE INDEX payor_name_ind ON payeepayor ( name );
CREATE TABLE other (
    id MEDIUMINT PRIMARY KEY
);

CREATE TABLE payeeor_other (
    id MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    payeepayor MEDIUMINT,
    other MEDIUMINT
);
EO_CORRECT_SQL

file_ok( $sql_file, $correct_sql, 'tiny gened sql file' );

my $actual_dir         = File::Spec->catdir( $dir, 'Apps-Checkbook' );

use lib 't';
use Purge;

Purge::real_purge_dir( $actual_dir );
