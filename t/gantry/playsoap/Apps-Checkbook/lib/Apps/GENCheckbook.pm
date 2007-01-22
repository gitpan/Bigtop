# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::GENCheckbook;

use strict;

use Gantry qw{ -TemplateEngine=TT };

our @ISA = qw( Gantry );


##-----------------------------------------------------------------
## $self->init( $r )
##-----------------------------------------------------------------
#sub init {
#    my ( $self, $r ) = @_;
#
#    # process SUPER's init code
#    $self->SUPER::init( $r );
#
#} # END init



#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
sub do_main {
    my ( $self ) = @_;

    $self->stash->view->template( 'main.tt' );
    $self->stash->view->title( 'Main Listing' );

    $self->stash->view->data( { pages => $self->site_links() } );
} # END do_main

#-----------------------------------------------------------------
# $self->site_links(  )
#-----------------------------------------------------------------
sub site_links {
    my ( $self ) = @_;

    return [
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


=back

=head1 AUTHOR

Phil Crow, E<lt>mail@example.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Phil Crow

All rights reserved.

=cut
