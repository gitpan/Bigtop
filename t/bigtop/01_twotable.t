use strict;

use Test::More tests => 1;
use Test::Files;
use File::Spec;

use lib 't';
use Purge; # exports real_purge_dir and strip_copyright;

my $play_dir = File::Spec->catdir( qw( AddressBook ) );
my $ship_dir = File::Spec->catdir( qw( t bigtop playship ) );
my $bigtop   = File::Spec->catdir( qw( scripts bigtop ) );

Purge::real_purge_dir( $play_dir );

my $ascii_art = 'family(name,+street,+city)<-child(name,birth_day:date)';

`$^X $bigtop -n AddressBook '$ascii_art'`;

my $sqlite_db = File::Spec->catfile( qw( AddressBook app.db ) );
my $wrapper   = File::Spec->catfile(
        qw( AddressBook html templates genwrapper.tt )
);
unlink $sqlite_db, $wrapper;

compare_dirs_filter_ok(
    $play_dir, $ship_dir, \&stripper, 'bigtop with art'
);

Purge::real_purge_dir( $play_dir );

sub stripper {
    my $line = shift;
    $line    =~ s/^Copyright.*//; # no copyrights or authors
    $line    =~ s/^0\.01 .*//;    # no version lines
                                  # (the one in Changes has time stamp)
    $line    =~ s/version\s+\d\.\d\d//; # bigtop version in Changes file

    if ( $line =~ /E<lt>/ ) {     # remove author lines (emails won't match)
        return '';
    }

    $line   =~ s/^#!.*//;

    return $line;
}
