# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package AddressBook::GEN::Family;

use strict;

use base 'AddressBook';
use JSON;

use AddressBook::Model::family qw(
    $FAMILY
);

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
sub do_main {
    my ( $self ) = @_;

    $self->stash->view->template( 'results.tt' );
    $self->stash->view->title( 'Family' );

    my $real_location = $self->location() || '';
    if ( $real_location ) {
        $real_location =~ s{/+$}{};
        $real_location .= '/';
    }

    my $retval = {
        headings       => [
            'Name',
            'Street',
        ],
        header_options => [
            {
                text => 'Add',
                link => $real_location . "add",
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

    my $schema = $self->get_schema();
    my @rows   = $FAMILY->get_listing(
        {
            schema   => $schema,
            where    => $search,
        }
    );

    foreach my $row ( @rows ) {
        my $id = $row->id;
        push(
            @{ $retval->{rows} }, {
                data => [
                    $row->name,
                    $row->street,
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

    my $selections = $FAMILY->get_form_selections(
            { schema => $self->get_schema() }
    );

    return {
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
                name => 'street',
                optional => 1,
                label => 'Street',
                type => 'text',
                is => 'varchar',
            },
            {
                name => 'city',
                optional => 1,
                label => 'City',
                type => 'text',
                is => 'varchar',
            },
        ],
    };
} # END form

1;

=head1 NAME

AddressBook::GEN::Family - generated support module for AddressBook::Family

=head1 SYNOPSIS

In AddressBook::Family:

    use base 'AddressBook::GEN::Family';

=head1 DESCRIPTION

This module was generated by bigtop and IS subject to regeneration.
Use it in AddressBook::Family to provide the methods below.
Feel free to override them.

=head1 METHODS

=over 4

=item do_main

=item form


=back

=head1 AUTHOR

Generated by bigtop and subject to regeneration.

=cut

