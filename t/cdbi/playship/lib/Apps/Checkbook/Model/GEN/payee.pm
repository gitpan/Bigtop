# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::Checkbook::Model::payee;
use strict; use warnings;

Apps::Checkbook::Model::payee->table   ( 'payee'     );
Apps::Checkbook::Model::payee->sequence( 'payee_seq' );
Apps::Checkbook::Model::payee->columns ( Primary   => qw/
    id
/ );

Apps::Checkbook::Model::payee->columns ( All       => qw/
    id
    first_name
    last_name
/ );

Apps::Checkbook::Model::payee->columns ( Essential => qw/
    id
    first_name
    last_name
/ );


sub get_foreign_display_fields {
    return [ qw( last_name first_name ) ];
}

sub get_foreign_tables {
    return qw(
    );
}

sub foreign_display {
    my $self = shift;

    my $last_name = $self->last_name();
    my $first_name = $self->first_name();

    return "$last_name, $first_name";
}

1;
