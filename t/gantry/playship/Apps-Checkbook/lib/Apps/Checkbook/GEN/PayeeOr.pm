# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::Checkbook::GEN::PayeeOr;

use strict;

use base 'Exporter';

our @EXPORT = qw(
    do_main
    form
);

use Apps::Checkbook::Model::payee qw(
    $PAYEE
);

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
sub do_main {
    my ( $self ) = @_;

    $self->stash->view->template( 'results.tt' );
    $self->stash->view->title( 'Payees' );

    my $retval = {
        headings       => [
            'Name',
        ],
        header_options => [
            {
                text => 'Add',
                link => $self->exoticlocation() . "/strangely_named_add",
            },
        ],
    };

    my @rows = $PAYEE->retrieve_all_for_main_listing();

    foreach my $row ( @rows ) {
        my $id = $row->id;
        push(
            @{ $retval->{rows} }, {
                data => [
                    $row->name,
                ],
                options => [
                    {
                        text => 'Edit',
                        link => $self->location() . "/edit/$id",
                    },
                    {
                        text => 'Make Some',
                        link => $self->location() . "/make_some/$id",
                    },
                    {
                        text => 'Delete',
                        link => $self->location() . "/delete/$id",
                    },
                ],
            }
        );
    }

    $self->stash->view->data( $retval );
} # END do_main

#-----------------------------------------------------------------
# $self->form( $row )
#-----------------------------------------------------------------
sub form {
    my ( $self, $row ) = @_;

    my $selections = $PAYEE->get_form_selections();

    return {
        name       => 'payee',
        row        => $row,
        legend => $self->path_info =~ /edit/i ? 'Edit' : 'Add',
        fields     => [
            {
                display_size => 20,
                name => 'name',
                label => 'Name',
                type => 'text',
                is => 'varchar',
            },
        ],
    };
} # END form


1;
