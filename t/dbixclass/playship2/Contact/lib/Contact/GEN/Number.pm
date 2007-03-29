# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Contact::GEN::Number;

use strict;

use base 'Contact';
use JSON;

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

    my $retval = {
        headings       => [
            'Name',
            'Number',
        ],
        header_options => [
            {
                text => 'Add',
                link => $real_location . "add",
            },
            {
                text => 'CSV',
                link => $real_location . "csv",
            },
        ],
    };

    my %param = $self->get_param_hash;

    my $search = {};
    if ( $param{ search } ) {
        my $form = $self->form();

        my @searches;
        foreach my $field ( @{ $form->{ fields } } ) {
            if ( $field->{ searchable } ) {
                push( @searches,
                    ( $field->{ name } => { 'like', "%$param{ search }%"  } )
                );
            }
        }

        $search = {
            -or => \@searches
        } if scalar( @searches ) > 0;
    }

    my $page    = $param{ page } || 1;

    my $schema  = $self->get_schema();
    my $results = $NUMBER->get_listing(
        {
            schema   => $schema,
            rows     => $self->number_rows,
            page     => $page,
            where    => $search,
        }
    );

    $retval->{ page } = $results->pager();
    my $rows          = $results->page();

    while ( my $row = $rows->next ) {
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
                        link => $real_location . "edit/$id",
                    },
                    {
                        text => 'Delete',
                        link => $real_location . "delete/$id",
                    },
                ],
            }
        );
    }

    if ( $param{ json } ) {
        $self->template_disable( 1 );

        my $obj = {
            headings        => $retval->{ headings },
            header_options  => $retval->{ header_options },
            rows            => $retval->{ rows },
        };

        my $json = objToJson( $obj );
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

