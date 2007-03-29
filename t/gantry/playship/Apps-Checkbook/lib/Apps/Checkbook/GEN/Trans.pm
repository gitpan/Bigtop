# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::Checkbook::GEN::Trans;

use strict;

use base 'Apps::Checkbook';
use JSON;

use SomePackage::SomeModule qw( a_method $b_scalar );
use SomePackage::OtherModule;

use Apps::Checkbook::Model::trans qw(
    $TRANS
);

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
sub do_main {
    my ( $self ) = @_;

    $self->stash->view->template( 'results.tt' );
    $self->stash->view->title( 'Transactions' );

    my $real_location = $self->location() || '';
    if ( $real_location ) {
        $real_location =~ s{/+$}{};
        $real_location .= '/';
    }

    my $retval = {
        headings       => [
            'Status 3',
            'Cleared',
            '<a href=' . $site->location() . '/date_order' . '>Date</a>',
            'Amount',
            'Paid To/Rec\'v\'d From',
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

    my @rows = $TRANS->get_listing( { order_by => 'trans_date DESC', } );

    foreach my $row ( @rows ) {
        my $id = $row->id;
        my $payee_payor = ( $row->payee_payor )
                ? $row->payee_payor->foreign_display()
                : '';
        push(
            @{ $retval->{rows} }, {
                data => [
                    $row->status,
                    $row->cleared_display(),
                    $row->trans_date,
                    $row->amount,
                    $payee_payor,
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

    my $selections = $TRANS->get_form_selections();

    return {
        row        => $row,
        legend => $self->path_info =~ /edit/i ? 'Edit' : 'Add',
        javascript => $self->calendar_month_js( 'trans' ),
        extraneous => 'uninteresting',
        fields     => [
            {
                display_size => 2,
                name => 'status',
                label => 'Status2',
                type => 'text',
                is => 'int',
            },
            {
                options => [
                    { label => 'Yes', value => '1' },
                    { label => 'No', value => '0' },
                ],
                name => 'cleared',
                constraint => qr{^1|0$},
                label => 'Cleared',
                type => 'select',
                is => 'boolean',
            },
            {
                display_size => 10,
                date_select_text => 'Select',
                name => 'trans_date',
                label => 'Trans Date',
                type => 'text',
                is => 'date',
            },
            {
                display_size => 10,
                name => 'amount',
                label => 'Amount',
                type => 'text',
                is => 'int',
            },
            {
                options => $selections->{payee},
                name => 'payee_payor',
                label => 'Paid To/Rec\'v\'d From',
                type => 'select',
                is => 'int',
            },
            {
                name => 'descr',
                optional => 1,
                label => 'Descr',
                type => 'textarea',
                is => 'varchar',
                rows => 3,
                cols => 60,
            },
            {
                options => $selections->{sch_tbl},
                name => 'sch_tbl',
                type => 'select',
                is => 'int4',
            },
        ],
    };
} # END form

1;

=head1 NAME

Apps::Checkbook::GEN::Trans - generated support module for Apps::Checkbook::Trans

=head1 SYNOPSIS

In Apps::Checkbook::Trans:

    use base 'Apps::Checkbook::GEN::Trans';

=head1 DESCRIPTION

This module was generated by bigtop and IS subject to regeneration.
Use it in Apps::Checkbook::Trans to provide the methods below.
Feel free to override them.

=head1 METHODS

=over 4

=item do_main

=item form


=back

=head1 AUTHOR

Generated by bigtop and subject to regeneration.

=cut

