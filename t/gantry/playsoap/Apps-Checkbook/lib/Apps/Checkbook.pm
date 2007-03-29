package Apps::Checkbook;

use strict;

our $VERSION = '0.01';

use base 'Apps::GENCheckbook';

use Apps::Checkbook::SOAP;


#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
# This method inherited from Apps::GENCheckbook

#-----------------------------------------------------------------
# $self->site_links(  )
#-----------------------------------------------------------------
# This method inherited from Apps::GENCheckbook


#-----------------------------------------------------------------
# $self->init( $r )
#-----------------------------------------------------------------
# This method inherited from Apps::GENCheckbook

1;

=head1 NAME

Apps::Checkbook - the base module of this web app

=head1 SYNOPSIS

This package is meant to be used in a stand alone server/CGI script or the
Perl block of an httpd.conf file.

Stand Alone Server or CGI script:

    use Apps::Checkbook;

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            #...
        },
        locations => {
            '/' => 'Apps::Checkbook',
            #...
        },
    } );

httpd.conf:

    <Perl>
        # ...
        use Apps::Checkbook;
    </Perl>

If all went well, one of these was correctly written during app generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS

=over 4


=back


=head1 METHODS INHERITED FROM Apps::GENCheckbook

=over 4

=item init

=item do_main

=item site_links


=back


=head1 SEE ALSO

    Gantry
    Apps::GENCheckbook
    Apps::Checkbook::SOAP

=head1 AUTHOR

Phil Crow, E<lt>mail@example.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Phil Crow

All rights reserved.

=cut
