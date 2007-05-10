package Apps::Checkbook::Trans::Action;

use strict;
use warnings;

use base 'Apps::Checkbook::GEN::Trans::Action';

use Gantry::Plugins::AutoCRUD qw(
    do_add
    do_edit
    do_delete
    form_name
    write_file
);

use Apps::Checkbook::Model::trans qw(
    $TRANS
);

#-----------------------------------------------------------------
# $self->form( $row )
#-----------------------------------------------------------------
# This method inherited from Apps::Checkbook::GEN::Trans::Action

#-----------------------------------------------------------------
# $self->controller_config(  )
#-----------------------------------------------------------------
# This method inherited from Apps::Checkbook::GEN::Trans::Action

#-----------------------------------------------------------------
# get_model_name( )
#-----------------------------------------------------------------
sub get_model_name {
    return $TRANS;
}


1;

=head1 NAME

Apps::Checkbook::Trans::Action - A controller in the Apps::Checkbook application

=head1 SYNOPSIS

This package is meant to be used in a stand alone server/CGI script or the
Perl block of an httpd.conf file.

Stand Alone Server or CGI script:

    use Apps::Checkbook::Trans::Action;

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            #...
        },
        locations => {
            '/someurl' => 'Apps::Checkbook::Trans::Action',
            #...
        },
    } );

httpd.conf:

    <Perl>
        # ...
        use Apps::Checkbook::Trans::Action;
    </Perl>

    <Location /someurl>
        SetHandler  perl-script
        PerlHandler Apps::Checkbook::Trans::Action
    </Location>

If all went well, one of these was correctly written during app generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS

=over 4

=item get_model_name

=item text_descr


=back


=head1 METHODS INHERITED FROM Apps::Checkbook::GEN::Trans::Action

=over 4

=item form

=item controller_config

=item namespace


=back


=head1 DEPENDENCIES

    Apps::Checkbook
    Apps::Checkbook::GEN::Trans::Action
    Apps::Checkbook::Model::trans
    Gantry::Plugins::AutoCRUD

=head1 AUTHOR

Somebody Somewhere, E<lt>somebody@example.comE<gt>

Somebody Else

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Somebody Somewhere

All rights reserved.

=cut
