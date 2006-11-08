package Billing::Company;

use strict;

use base 'Billing::GEN::Company';

use Gantry::Plugins::AutoCRUD qw(
    do_add
    do_edit
    do_delete
    form_name
);

use Billing::Model::my_company qw(
    $MY_COMPANY
);
use Billing::Model;
sub schema_base_class { return 'Billing::Model'; }
use Gantry::Plugins::DBIxClassConn qw( get_schema );

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
# This method supplied by Billing::GEN::Company

#-----------------------------------------------------------------
# $self->form( $row )
#-----------------------------------------------------------------
# This method supplied by Billing::GEN::Company


#-----------------------------------------------------------------
# get_model_name( )
#-----------------------------------------------------------------
sub get_model_name {
    return $MY_COMPANY;
}

#-----------------------------------------------------------------
# get_orm_helper( )
#-----------------------------------------------------------------
sub get_orm_helper {
    return 'Gantry::Plugins::AutoCRUDHelper::DBIxClass';
}

#-----------------------------------------------------------------
# text_descr( )
#-----------------------------------------------------------------
sub text_descr     {
    return 'company';
}

1;

=head1 NAME

Billing::Company - A controller in the Billing application

=head1 SYNOPSIS

This package is meant to be used in a stand alone server/CGI script or the
Perl block of an httpd.conf file.

Stand Alone Server or CGI script:

    use Billing::Company;

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            #...
        },
        locations => {
            '/someurl' => 'Billing::Company',
            #...
        },
    } );

httpd.conf:

    <Perl>
        # ...
        use Billing::Company;
    </Perl>

    <Location /someurl>
        SetHandler  perl-script
        PerlHandler Billing::Company
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


=head1 METHODS MIXED IN FROM Billing::GEN::Company

=over 4

=item do_main

=item form


=back


=head1 DEPENDENCIES

    Billing
    Billing::GEN::Company
    Billing::Model::my_company
    Gantry::Plugins::AutoCRUD

=head1 AUTHOR

Phil Crow

Tim Keefer

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut