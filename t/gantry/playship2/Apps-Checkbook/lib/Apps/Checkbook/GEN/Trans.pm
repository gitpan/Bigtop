# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::Checkbook::GEN::Trans;

use strict;

use base 'Exporter';

our @EXPORT = qw(
    do_main
    form
);

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

    my $retval = {
        headings       => [
            'Status 3',
            '<a href=' . $site->location() . '/date_order' . '>Date</a>',
            'Amount',
            'Paid To/Rec\'v\'d From',
        ],
        header_options => [
            {
                text => 'Add',
                link => $self->location() . "/add",
            },
        ],
    };

    my @rows = $TRANS->get_listing();

    foreach my $row ( @rows ) {
        my $id = $row->id;
        push(
            @{ $retval->{rows} }, {
                data => [
                    $row->status,
                    $row->trans_date,
                    $row->amount,
                    $row->payee_payor->foreign_display(),
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

    my $selections = $TRANS->get_form_selections();

    return {
        name       => 'trans',
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
        ],
    };
} # END form


1;
