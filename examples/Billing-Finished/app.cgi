#!/usr/bin/perl
use strict;


use CGI::Carp qw( fatalsToBrowser );

use Billing qw{ -Engine=CGI -TemplateEngine=TT };

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        dbconn => 'dbi:SLQite:dbname=app.db',
        template_wrapper => 'genwrapper.tt',
        root => 'html',
    },
    locations => {
        '/' => 'Billing',
        '/status' => 'Billing::Status',
        '/company' => 'Billing::Company',
        '/customer' => 'Billing::Customer',
        '/lineitem' => 'Billing::LineItem',
        '/invoice' => 'Billing::Invoice',
    },
} );

$cgi->dispatch();

if ( $cgi->{config}{debug} ) {
    foreach ( sort { $a cmp $b } keys %ENV ) {
        print "$_ $ENV{$_}<br />\n";
    }
}
