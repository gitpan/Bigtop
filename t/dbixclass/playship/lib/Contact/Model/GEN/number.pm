# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Contact::Model::GEN::number;
use strict; use warnings;

use base 'Gantry::Utils::DBIxClass';

__PACKAGE__->load_components( qw/ Core / );
__PACKAGE__->table( 'number' );
__PACKAGE__->add_columns( qw/
    id
    name
    number
/ );
__PACKAGE__->set_primary_key( 'id' );

sub get_foreign_display_fields {
    return [ qw( name ) ];
}

sub get_foreign_tables {
    return qw(
    );
}

sub foreign_display {
    my $self = shift;

    my $name = $self->name();

    return "$name";
}

sub table_name {
    return 'number';
}

1;
