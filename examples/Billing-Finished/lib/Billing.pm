package Billing;

use strict;

our $VERSION = '0.01';

use base 'GENBilling';

use Billing::Status;
use Billing::Company;
use Billing::Customer;
use Billing::LineItem;
use Billing::Invoice;

1;

=head1 NAME

Billing - the base module of this web app

=head1 SYNOPSIS

This package is meant to be used in a stand alone server/CGI script or the
Perl block of an httpd.conf file.

Stand Alone Server or CGI script:

    use Billing;

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            #...
        },
        locations => {
            '/' => 'Billing',
            #...
        },
    } );

httpd.conf:

    <Perl>
        # ...
        use Billing;
    </Perl>

If all went well, one of these was correctly written during app generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS (inherited from GENBilling)

=over 4

=item init

=item do_main

=item site_links


=back


=head1 SEE ALSO

    Gantry
    GENBilling
    Billing::Status
    Billing::Company
    Billing::Customer
    Billing::LineItem
    Billing::Invoice

=head1 AUTHOR

Phil Crow

Tim Keefer

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut