# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Contact::Model::tshirt;
use strict; use warnings;

__PACKAGE__->load_components( qw/ PK::Auto Core / );
__PACKAGE__->table( 'tshirt' );
__PACKAGE__->add_columns( qw/
    id
    ident
/ );
__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->base_model( 'Contact::Model' );
__PACKAGE__->has_many(
    tshirt_colors => 'Contact::Model::tshirt_color',
    'tshirt'
);
__PACKAGE__->many_to_many(
    colors => 'tshirt_colors',
    'color'
);
__PACKAGE__->has_many(
    tshirt_authors => 'Contact::Model::tshirt_author',
    'tshirt'
);
__PACKAGE__->many_to_many(
    authors => 'tshirt_authors',
    'author'
);

sub get_foreign_display_fields {
    return [ qw(  ) ];
}

sub get_foreign_tables {
    return qw(
    );
}

sub foreign_display {
    my $self = shift;

}

sub table_name {
    return 'tshirt';
}

1;

=head1 NAME

Contact::Model::GEN::tshirt - model for tshirt table (generated part)

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
