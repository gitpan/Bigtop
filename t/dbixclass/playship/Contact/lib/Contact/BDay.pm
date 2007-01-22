package Contact::BDay;

use strict;

use base 'Contact::GEN::BDay';
use Contact::Model::bday qw(
    $BDAY
);
use Contact::Model;
sub schema_base_class { return 'Contact::Model'; }
use Gantry::Plugins::DBIxClassConn qw( get_schema );

#-----------------------------------------------------------------
# $self->do_main( $contact )
#-----------------------------------------------------------------
# This method supplied by Contact::GEN::BDay


#-----------------------------------------------------------------
# get_model_name( )
#-----------------------------------------------------------------
sub get_model_name {
    return $BDAY;
}

#-----------------------------------------------------------------
# get_orm_helper( )
#-----------------------------------------------------------------
sub get_orm_helper {
    return 'Gantry::Plugins::AutoCRUDHelper::DBIxClass';
}


1;

=head1 NAME

Contact::BDay - A controller in the Contact application

=head1 SYNOPSIS

This package is meant to be used in a stand alone server/CGI script or the
Perl block of an httpd.conf file.

Stand Alone Server or CGI script:

    use Contact::BDay;

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            #...
        },
        locations => {
            '/someurl' => 'Contact::BDay',
            #...
        },
    } );

httpd.conf:

    <Perl>
        # ...
        use Contact::BDay;
    </Perl>

    <Location /someurl>
        SetHandler  perl-script
        PerlHandler Contact::BDay
    </Location>

If all went well, one of these was correctly written during app generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS

=over 4

=item get_model_name

=item text_descr

=item schema_base_class

=item get_orm_helper


=back


=head1 METHODS INHERITED FROM Contact::GEN::BDay

=over 4

=item do_main


=back


=head1 DEPENDENCIES

    Contact
    Contact::GEN::BDay
    Contact::Model::bday

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
