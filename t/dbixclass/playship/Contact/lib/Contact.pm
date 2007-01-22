package Contact;

use strict;

our $VERSION = '0.01';

use base 'GENContact';

use Contact::Number;
use Contact::BDay;



#-----------------------------------------------------------------
# $self->init( $r )
#-----------------------------------------------------------------
# This method supplied by GENContact

1;

=head1 NAME

Contact - the base module of this web app

=head1 SYNOPSIS

This package is meant to be used in a stand alone server/CGI script or the
Perl block of an httpd.conf file.

Stand Alone Server or CGI script:

    use Contact;

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            #...
        },
        locations => {
            '/' => 'Contact',
            #...
        },
    } );

httpd.conf:

    <Perl>
        # ...
        use Contact;
    </Perl>

If all went well, one of these was correctly written during app generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS (inherited from GENContact)

=over 4

=item init

=item do_main

=item site_links


=back


=head1 SEE ALSO

    Gantry
    GENContact
    Contact::Number
    Contact::BDay

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
