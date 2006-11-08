use strict;

use Test::More tests => 1;

use Bigtop::Parser qw/SQL=MySQL/;

my $bigtop_string = join '', <DATA>;

my $tree        = Bigtop::Parser->parse_string($bigtop_string);
my $lookup      = $tree->{application}{lookup};

my $output      = $tree->walk_postorder( 'output_sql_mysql', $lookup );

my @sql         = split /\n/, join '', @{ $output };

my @correct_sql = split /\n/, <<'EO_CORRECT_SQL';
CREATE TABLE payeepayor (
    id MEDIUMINT PRIMARY KEY AUTO_INCREMENT
);

CREATE TABLE multiplier (
    id MEDIUMINT,
    subid MEDIUMINT,
    PRIMARY KEY( id, subid )
);
EO_CORRECT_SQL

is_deeply( \@sql, \@correct_sql, 'tiny sql' );

__DATA__
config { }
app Apps::Checkbook {
    sequence payeepayor_seq {}
    table payeepayor {
        field id    { is int4, primary_key, auto; }
        sequence payeepayor_seq;
    }
    table multiplier {
        field id    { is int4, primary_key; }
        field subid { is int4, primary_key; }
    }
}
