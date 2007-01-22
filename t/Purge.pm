package Purge;
use strict; use warnings;

use base 'Exporter';
use File::Find;

our @EXPORT = qw( purge_dir strip_copyright );

sub purge_dir {
}

sub real_purge_dir {
    my $doomed_dir = shift;

    return unless -d $doomed_dir;

    my $purger = sub {
        my $name = $_;

        if    ( -f $name ) { unlink $name; }
        elsif ( -d $name ) { rmdir $name;  }
    };

    finddepth( $purger, $doomed_dir );
    rmdir $doomed_dir;
}

sub strip_copyright {
    my $line = shift;
    $line    =~ s/\(C\)\s+\d+//;
    return $line;
}

