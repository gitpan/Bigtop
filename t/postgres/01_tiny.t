use strict;

use Test::More tests => 1;

use Bigtop::Parser qw/SQL=Postgres/;

my $bigtop_string = join '', <DATA>;

my $tree        = Bigtop::Parser->parse_string($bigtop_string);
my $lookup      = $tree->{application}{lookup};

my $output      = $tree->walk_postorder( 'output_sql', $lookup );
my @sql         = split /\n/, join '', @{ $output };

my @correct_sql = split /\n/, <<'EO_CORRECT_SQL';
CREATE SEQUENCE payeepayor_seq;
CREATE TABLE payeepayor (
    id int4 PRIMARY KEY DEFAULT NEXTVAL( 'payeepayor_seq' )
);
EO_CORRECT_SQL

is_deeply( \@sql, \@correct_sql, 'tiny sql' );

__DATA__
config { }
app Apps::Checkbook {
    sequence payeepayor_seq { }
    table payeepayor {
        field id    { is int4, primary_key, assign_by_sequence; }
        sequence payeepayor_seq;
    }
}
