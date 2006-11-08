# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Billing::GEN::Status;

use strict;

use base 'Billing';

use Billing::Model::status qw(
    $STATUS
);

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
sub do_main {
    my ( $self ) = @_;

    $self->stash->view->template( 'results.tt' );
    $self->stash->view->title( 'Status' );

    my $retval = {
        headings       => [
            'Name',
        ],
        header_options => [
            {
                text => 'Add',
                link => $self->location() . "/add",
            },
        ],
    };

    my $schema = $self->get_schema();
    my @rows   = $STATUS->get_listing( { schema => $schema } );

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

    my $selections = $STATUS->get_form_selections(
            { schema => $self->get_schema() }
    );

    return {
        name       => 'status',
        row        => $row,
        legend => $self->path_info =~ /edit/i ? 'Edit' : 'Add',
        fields     => [
            {
                name => 'name',
                label => 'Name',
                type => 'text',
                is => 'varchar',
            },
            {
                name => 'description',
                label => 'Description',
                type => 'text',
                is => 'varchar',
            },
        ],
    };
} # END form


1;

=head1 NAME

Billing::GEN::Status - generated support module for Billing::Status

=head1 SYNOPSIS

In Billing::Status:

    use Billing::GEN::Status qw(
        do_main
        form
    );

=head1 DESCRIPTION

This module was generated by bigtop and IS subject to regeneration.
Use it in Billing::Status to provide the methods below.
They are exported by default.

=head1 METHODS

=over 4

=item do_main

=item form


=back

=head1 AUTHOR

Generated by bigtop and subject to regeneration.

=cut
