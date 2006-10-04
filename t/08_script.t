use strict;

use Test::More tests => 4;
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
# Minimal default
#-----------------------------------------------------------------

my $mini  = Bigtop::ScriptHelp->get_minimal_default( 'Simple' );

$expected_file = File::Spec->catfile( $expected_dir, 'minimal' );

file_ok( $expected_file, $mini, 'minimal default' );

#-----------------------------------------------------------------
# Big default
#-----------------------------------------------------------------

my $max   = Bigtop::ScriptHelp->get_big_default(
        'Address', 'family_address<-birth_date a<->b'
);

$expected_file = File::Spec->catfile( $expected_dir, 'big_default' );

file_ok( $expected_file, $max, 'bigger default' );

#-----------------------------------------------------------------
# Augment tree
#-----------------------------------------------------------------

my $ast = Bigtop::Parser->parse_string( $max );
Bigtop::ScriptHelp->augment_tree(
    $ast, 'anniversary_date->family_address a->family_address a->birth_date'
);

my $augmented = Bigtop::Deparser->deparse( $ast ) . "\n";;

$expected_file = File::Spec->catfile( $expected_dir, 'augmented' );

file_ok( $expected_file, $augmented, 'augmented' );

