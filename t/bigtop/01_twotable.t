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

`perl $bigtop -n AddressBook '$ascii_art'`;

my $sqlite_db = File::Spec->catdir( qw( AddressBook app.db ) );
unlink $sqlite_db;

compare_dirs_filter_ok(
    $play_dir, $ship_dir, \&stripper, 'bigtop with art'
);

Purge::real_purge_dir( $play_dir );

sub stripper {
    my $line = shift;
    $line    =~ s/\(C\)\s+\d+//;  # no copyrights
    $line    =~ s/^0\.01 .*//;    # no version lines
                                  # (the one in Changes has time stamp)

    if ( $line =~ /E<lt>/ ) {     # remove author lines (emails won't match)
        return '';
    }

    return $line;
}
