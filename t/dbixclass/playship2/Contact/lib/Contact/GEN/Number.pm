# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Contact::GEN::Number;

use strict;
use warnings;

use base 'Contact';
use JSON;
use Gantry::Utils::TablePerms;

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

    my $real_location = $self->location() || '';
    if ( $real_location ) {
        $real_location =~ s{/+$}{};
        $real_location .= '/';
    }

    my @header_options = (
        {
            text => 'Add',
            link => $real_location . "add",
            type => 'create',
        },
        {
            text => 'CSV',
            link => $real_location . "csv",
            type => 'retrieve',
        },
    );

    my $retval = {
        headings       => [
            'Name',
            'Number',
        ],
    };

    my $params = $self->params;

    my $search = {};
    if ( $params->{ search } ) {
        my $form = $self->form();

        my @searches;
        foreach my $field ( @{ $form->{ fields } } ) {
            if ( $field->{ searchable } ) {
                push( @searches,
                    ( $field->{ name } => { 'like', "%$params->{ search }%"  } )
                );
            }
        }

        $search = {
            -or => \@searches
        } if scalar( @searches ) > 0;
    }

    my @row_options = (
        {
            text => 'Edit',
            type => 'update',
        },
        {
            text => 'Delete',
            type => 'delete',
        },
    );

    my $perm_obj = Gantry::Utils::TablePerms->new(
        {
            site           => $self,
            real_location  => $real_location,
            header_options => \@header_options,
            row_options    => \@row_options,
        }
    );

    $retval->{ header_options } = $perm_obj->real_header_options;

    my $limit_to_user_id = $perm_obj->limit_to_user_id;
    $search->{ user_id } = $limit_to_user_id if ( $limit_to_user_id );

    my $page    = $params->{ page } || 1;

    my $schema  = $self->get_schema();
    my $results = $NUMBER->get_listing(
        {
            schema   => $schema,
            rows     => $self->number_rows,
            where    => $search,
        }
    );

    my $rows          = $results->page( $page );
    $retval->{ page } = $rows->pager();

    ROW:
    while ( my $row = $rows->next ) {
        last ROW if $perm_obj->hide_all_data;

        my $id = $row->id;

        push(
            @{ $retval->{rows} }, {
                orm_row => $row,
                data => [
                    $row->name,
                    $row->number,
                ],
                options => $perm_obj->real_row_options( $row ),
            }
        );
    }

    if ( $params->{ json } ) {
        $self->template_disable( 1 );

        my $obj = {
            headings        => $retval->{ headings },
            header_options  => $retval->{ header_options },
            rows            => $retval->{ rows },
        };

        my $json = objToJson( $obj, { skipinvalid => 1 } );
        return( $json );
    }

    $self->stash->view->data( $retval );
} # END do_main

#-----------------------------------------------------------------
# $self->form( $row )
#-----------------------------------------------------------------
sub form {
    my ( $self, $row ) = @_;

    my $selections = $NUMBER->get_form_selections(
            { schema => $self->get_schema() }
    );

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

=head1 NAME

Contact::GEN::Number - generated support module for Contact::Number

=head1 SYNOPSIS

In Contact::Number:

    use base 'Contact::GEN::Number';

=head1 DESCRIPTION

This module was generated by bigtop and IS subject to regeneration.
Use it in Contact::Number to provide the methods below.
Feel free to override them.

=head1 METHODS

=over 4

=item do_main

=item form


=back

=head1 AUTHOR

Generated by bigtop and subject to regeneration.

=cut

