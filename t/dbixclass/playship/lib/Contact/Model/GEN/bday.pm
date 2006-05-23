# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Contact::Model::GEN::bday;
use strict; use warnings;

use base 'Gantry::Utils::DBIxClass';

__PACKAGE__->load_components( qw/ Core / );
__PACKAGE__->table( 'bday' );
__PACKAGE__->add_columns( qw/
    id
    contact
    bday
/ );
__PACKAGE__->set_primary_key( 'id' );
Contact::Model::bday->has_a( contact => 'Contact::Model::number' );

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
