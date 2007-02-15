# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package AddressBook::Model::child;
use strict; use warnings;

__PACKAGE__->load_components( qw/ PK::Auto Core / );
__PACKAGE__->table( 'child' );
__PACKAGE__->add_columns( qw/
    id
    name
    birth_day
    created
    modified
    family
/ );
__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->belongs_to( family => 'AddressBook::Model::family' );
__PACKAGE__->base_model( 'AddressBook::Model' );

sub get_foreign_display_fields {
    return [ qw( name ) ];
}

sub get_foreign_tables {
    return qw(
        AddressBook::Model::family
    );
}

sub foreign_display {
    my $self = shift;

    my $name = $self->name() || '';

    return "$name";
}

sub table_name {
    return 'child';
}

1;

=head1 NAME

AddressBook::Model::GEN::child - model for child table (generated part)

=head1 DESCRIPTION

This model inherits from Gantry::Utils::DBIxClass.
It was generated by Bigtop, and IS subject to regeneration.

=head1 METHODS

You may use all normal Gantry::Utils::DBIxClass methods and the
ones listed here:

=over 4

=item get_foreign_display_fields

=item get_foreign_tables

=item foreign_display

=item table_name

=back

=cut