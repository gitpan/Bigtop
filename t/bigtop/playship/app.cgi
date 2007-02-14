#!/usr/bin/perl
use strict;


use CGI::Carp qw( fatalsToBrowser );

use AddressBook qw{ -Engine=CGI -TemplateEngine=TT };

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        dbconn => 'dbi:SQLite:dbname=app.db',
        template_wrapper => 'genwrapper.tt',
        root => 'html/templates',
    },
    locations => {
        '/' => 'AddressBook',
        '/family' => 'AddressBook::Family',
        '/child' => 'AddressBook::Child',
    },
} );

$cgi->dispatch();

if ( $cgi->{config}{debug} ) {
    foreach ( sort { $a cmp $b } keys %ENV ) {
        print "$_ $ENV{$_}<br />\n";
    }
}
