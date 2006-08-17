# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Contact::Model::bday;
use strict; use warnings;

__PACKAGE__->load_components( qw/ PK::Auto Core / );
__PACKAGE__->table( 'bday' );
__PACKAGE__->add_columns( qw/
    id
    contact
    bday
/ );
__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->belongs_to( contact => 'Contact::Model::number' );
__PACKAGE__->base_model( 'Contact::Model' );

sub get_foreign_display_fields {
    return [ qw(  ) ];
}

sub get_foreign_tables {
    return qw(
        Contact::Model::number
    );
}

sub foreign_display {
    my $self = shift;

}

sub table_name {
    return 'bday';
}

1;

=head1 NAME

Contact::Model::GEN::bday - model for bday table (generated part)

=head1 DESCRIPTION

This model inherits from Exotic::Base::Module.
It was generated by Bigtop, and IS subject to regeneration.

=head1 METHODS

You may use all normal Exotic::Base::Module methods and the
ones listed here:

=over 4

=item get_foreign_display_fields

=item get_foreign_tables

=item foreign_display

=item table_name

=back

=cut
