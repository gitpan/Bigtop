use strict;

use Test::More tests => 1;
use Test::Files;
use File::Spec;
use File::Find;
use Cwd;

use Bigtop::Parser qw/SQL=Postgres Model=Gantry/;

my $play_dir   = File::Spec->catdir( qw( t ganmodel play ) );
my $ship_dir   = File::Spec->catdir( qw( t ganmodel playship ) );

mkdir $play_dir;

#------------------------------------------------------------------------
# Comprehensive test of controller generation for Gantry
#------------------------------------------------------------------------

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    Model           Gantry { }
}
app Apps::Checkbook {
    sequence status_seq {}
    sequence trans_seq  {}
    table status {
        sequence status_seq;
        # no_mutators 1;
        field id    { is int4, primary_key, assign_by_sequence; }
        field descr {
            is                     varchar;
            non_essential          1;
        }
    }
    table trans {
        sequence trans_seq;
        field id { is int4, primary_key, assign_by_sequence; }
        field status {
            is                     int4; 
            refers_to              status;
            # no_raw_access             1;
        }
        field trans_date {
            is                     date;
            # no_mutator  1;
            # inflate     Date::SomeModule => method;
            # deflate     Date::SomeModule => some_other_method;
        }
        field amount {
            is                     int4; 
        }
        field descr {
            is                     varchar;
        }
    }
}
EO_Bigtop_File

Bigtop::Parser->gen_from_string( $bigtop_string, undef, 'create', 'Model' );

compare_dirs_ok( $play_dir, $ship_dir, 'gantry models' );

use lib 't';
use Purge;
Purge::real_purge_dir( $play_dir );
