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

=head1 NAME

Apps::Checkbook::Model::GEN::payee - model for payee table (generated part)

=head1 DESCRIPTION

This model mixes into Apps::Checkbook::Model::payee,
because Class::DBI bindings don't really allow a choice.
It was generated by Bigtop, and IS subject to regeneration.

=head1 METHODS

You may use all normal Class::DBI::Sweet methods and the ones listed here:

=over 4

=item get_foreign_display_fields

=item get_foreign_tables

=item foreign_display

=back

=cut