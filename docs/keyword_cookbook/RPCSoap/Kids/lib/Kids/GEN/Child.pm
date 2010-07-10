# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Kids::GEN::Child;

use strict;
use warnings;

use base 'Kids';
use JSON;
use Gantry::Utils::TablePerms;

use Kids::Model::child qw(
    $CHILD
);

#-----------------------------------------------------------------
# $self->do_main( $family )
#-----------------------------------------------------------------
sub do_main {
    my ( $self, $family ) = @_;

    $self->stash->view->template( 'results.tt' );
    $self->stash->view->title( 'Child' );

    my $real_location = $self->location() || '';
    if ( $real_location ) {
        $real_location =~ s{/+$}{};
        $real_location .= '/';
    }

    my $header_option_suffix = ( $family ) ? "/$family" : '';

    my @header_options = (
        {
            text => 'Add',
            link => $real_location . "add$header_option_suffix",
            type => 'create',
        },
    );

    my $retval = {
        headings       => [
            'Name',
            'Birth Day',
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

    if ( $family ) {
        $search->{ family } = $family;
    }

    my $schema = $self->get_schema();
    my @rows   = $CHILD->get_listing(
        {
            schema   => $schema,
            where    => $search,
        }
    );

    ROW:
    foreach my $row ( @rows ) {
        last ROW if $perm_obj->hide_all_data;

        my $id = $row->id;

        push(
            @{ $retval->{rows} }, {
                orm_row => $row,
                data => [
                    $row->name,
                    $row->birth_day,
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

        my $json = to_json( $obj, { allow_blessed => 1 } );
        return( $json );
    }

    $self->stash->view->data( $retval );
} # END do_main

#-----------------------------------------------------------------
# $self->form( $row )
#-----------------------------------------------------------------
sub form {
    my ( $self, $row ) = @_;

    my $selections = $CHILD->get_form_selections(
            { schema => $self->get_schema() }
    );

    return {
        name       => 'child',
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
                date_select_text => 'Select Date',
                name => 'birth_day',
                label => 'Birth Day',
                type => 'text',
                is => 'date',
            },
        ],
    };
} # END form

1;

=head1 NAME

Kids::GEN::Child - generated support module for Kids::Child

=head1 SYNOPSIS

In Kids::Child:

    use base 'Kids::GEN::Child';

=head1 DESCRIPTION

This module was generated by bigtop and IS subject to regeneration.
Use it in Kids::Child to provide the methods below.
Feel free to override them.

=head1 METHODS

=over 4

=item do_main

=item form


=back

=head1 AUTHOR

Generated by bigtop and subject to regeneration.

=cut
