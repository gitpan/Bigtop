# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::Checkbook::Model::trans;
use strict; use warnings;

Apps::Checkbook::Model::trans->table   ( 'trans'     );
Apps::Checkbook::Model::trans->sequence( 'trans_seq' );
Apps::Checkbook::Model::trans->columns ( Primary   => qw/
    id
/ );

Apps::Checkbook::Model::trans->columns ( All       => qw/
    id
    status
    trans_date
    amount
    payee_payor
    descr
/ );

Apps::Checkbook::Model::trans->columns ( Essential => qw/
    id
    status
    trans_date
    amount
    payee_payor
/ );

Apps::Checkbook::Model::trans->has_a( status => 'Apps::Checkbook::Model::status' );
Apps::Checkbook::Model::trans->has_a( payee_payor => 'Apps::Checkbook::Model::payee' );

sub get_foreign_display_fields {
    return [ qw( id ) ];
}

sub get_foreign_tables {
    return qw(
        Apps::Checkbook::Model::status
        Apps::Checkbook::Model::payee
    );
}

sub foreign_display {
    my $self = shift;

    my $id = $self->id();

    return "$id";
}

1;
