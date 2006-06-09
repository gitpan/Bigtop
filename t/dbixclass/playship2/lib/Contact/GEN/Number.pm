# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Contact::GEN::Number;

use strict;

use base 'Exporter';

our @EXPORT = qw(
    do_main
    form
);

use Contact::Model::number qw(
    $NUMBER
);

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
sub do_main {
    my ( $self ) = @_;

    $self->stash->view->template( 'results.tt' );
    $self->stash->view->title( 'Contacts' );

    my $retval = {
        headings       => [
            'Name',
            'Number',
        ],
        header_options => [
            {
                text => 'Add',
                link => $self->location() . "/add",
            },
            {
                text => 'CSV',
                link => $self->location() . "/csv",
            },
        ],
    };

    my $schema = $self->get_schema();
    my @rows   = $NUMBER->get_listing( { schema => $schema } );

    foreach my $row ( @rows ) {
        my $id = $row->id;
        push(
            @{ $retval->{rows} }, {
                data => [
                    $row->name,
                    $row->number,
                ],
                options => [
                    {
                        text => 'Edit',
                        link => $self->location() . "/edit/$id",
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

    my $selections = $NUMBER->get_form_selections();

    return {
        name       => 'contact',
        row        => $row,
        fields     => [
            {
                name => 'name',
                label => 'Name',
                type => 'text',
                is => 'varchar',
            },
            {
                name => 'number',
                label => 'Number',
                type => 'text',
                is => 'varchar',
            },
        ],
    };
} # END form


1;
