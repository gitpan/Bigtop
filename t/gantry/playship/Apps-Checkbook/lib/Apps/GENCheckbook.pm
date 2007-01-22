# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::GENCheckbook;

use strict;

use Gantry qw{ -Engine=MP20 -TemplateEngine=TT };

our @ISA = qw( Gantry );


#-----------------------------------------------------------------
# $self->init( $r )
#-----------------------------------------------------------------
sub init {
    my ( $self, $r ) = @_;

    # process SUPER's init code
    $self->SUPER::init( $r );

    $self->set_DBName( $self->fish_config( 'DBName' ) || '' );
} # END init


#-----------------------------------------------------------------
# $self->set_DBName( $new_value )
#-----------------------------------------------------------------
sub set_DBName {
    my ( $self, $value ) = @_;

    $self->{ __DBName__ } = $value;
}

#-----------------------------------------------------------------
# $self->DBName(  )
#-----------------------------------------------------------------
sub DBName {
    my $self = shift;

    return $self->{ __DBName__ };
}


#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
sub do_main {
    my ( $self ) = @_;

    $self->stash->view->template( 'main.tt' );
    $self->stash->view->title( 'Checkbook App' );

    $self->stash->view->data( { pages => $self->site_links() } );
} # END do_main

#-----------------------------------------------------------------
# $self->site_links(  )
#-----------------------------------------------------------------
sub site_links {
    my ( $self ) = @_;

    return [
        { link => $self->app_rootp() . '/payee', label => 'Payee/Payor' },
        { link => '/foreign/location', label => 'Transactions' },
    ];
} # END site_links

1;

=head1 NAME

Apps::GENCheckbook - generated support module for Apps::Checkbook

=head1 SYNOPSIS

In Apps::Checkbook:

    use base 'Apps::GENCheckbook';

=head1 DESCRIPTION

This module was generated by Bigtop (and IS subject to regeneration) to
provide methods in support of the whole Apps::Checkbook
application.

Apps::Checkbook should inherit from this module.

=head1 METHODS

=over 4

=item init

=item do_main

=item site_links

=item DBName

=item set_DBName


=back

=head1 AUTHOR

Somebody Somewhere, E<lt>somebody@example.comE<gt>

Somebody Else

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Somebody Somewhere

All rights reserved.

=cut

