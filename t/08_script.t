use strict;

use Test::More tests => 8;
use Test::Files;

use File::Spec;

use Bigtop::ScriptHelp;
use Bigtop::Parser;
use Bigtop::Deparser;

my @received;
my @correct;

my $expected_dir = File::Spec->catdir( 't', 'expected' );
my $expected_file;

#-----------------------------------------------------------------
# Default label (two words)
#-----------------------------------------------------------------

my $name  = 'birth_date';
my $label = Bigtop::ScriptHelp->default_label( $name );

is( $label, 'Birth Date' );

#-----------------------------------------------------------------
# Default controller name (two words)
#-----------------------------------------------------------------

my $controller_label = Bigtop::ScriptHelp->default_controller( $name );

is( $controller_label, 'BirthDate' );

#-----------------------------------------------------------------
# Default controller name (schema style table name)
#-----------------------------------------------------------------

$controller_label = Bigtop::ScriptHelp->default_controller( 'sch.bday' );

is( $controller_label, 'SchBday' );

#-----------------------------------------------------------------
# Minimal default
#-----------------------------------------------------------------

my $mini  = Bigtop::ScriptHelp->get_minimal_default( 'Simple' );

$expected_file = File::Spec->catfile( $expected_dir, 'minimal' );

file_ok( $expected_file, $mini, 'minimal default (minimal)' );

#-----------------------------------------------------------------
# Big default
#-----------------------------------------------------------------

my $max   = Bigtop::ScriptHelp->get_big_default(
        'Address', 'family_address<-birth_date a<->b'
);

$expected_file = File::Spec->catfile( $expected_dir, 'big_default' );

file_ok( $expected_file, $max, 'bigger default (big_default)' );

#-----------------------------------------------------------------
# Augment tree
#-----------------------------------------------------------------

my $ast = Bigtop::Parser->parse_string( $max );
Bigtop::ScriptHelp->augment_tree(
    $ast, 'anniversary_date->family_address a->family_address a->birth_date'
);

my $augmented = Bigtop::Deparser->deparse( $ast );

$expected_file = File::Spec->catfile( $expected_dir, 'augmented' );

file_ok( $expected_file, $augmented, '(augmented)' );

#-----------------------------------------------------------------
# Schema bigtop -n path
#-----------------------------------------------------------------

my $schemer   = Bigtop::ScriptHelp->get_big_default(
        'Address', 'fam.family_address<-fam.birth_date'
);

$expected_file = File::Spec->catfile( $expected_dir, 'schema_default' );

file_ok(
    $expected_file, $schemer, 'big default schema style (schema_default)'
);

#-----------------------------------------------------------------
# Schema bigtop -a and tentmaker -a and -n paths
#-----------------------------------------------------------------

$ast = Bigtop::Parser->parse_string( $mini );
Bigtop::ScriptHelp->augment_tree( $ast, 'fam.address<-fam.bday' );

$augmented = Bigtop::Deparser->deparse( $ast );

$expected_file = File::Spec->catfile( $expected_dir, 'schema_aug' );

file_ok( $expected_file, $augmented, 'augment schema style (schema_aug)' );

