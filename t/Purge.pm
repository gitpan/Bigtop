package Purge;
use strict; use warnings;

use base 'Exporter';
use File::Find;

our @EXPORT = ( 'purge_dir' );

sub purge_dir {
}

sub real_purge_dir {
    my $doomed_dir = shift;

    my $purger = sub {
        my $name = $_;

        if    ( -f $name ) { unlink $name; }
        elsif ( -d $name ) { rmdir $name;  }
    };

    finddepth( $purger, $doomed_dir );
    rmdir $doomed_dir;
}
