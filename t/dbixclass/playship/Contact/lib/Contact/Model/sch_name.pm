package Contact::Model::sch_name;
use strict; use warnings;

use base 'Gantry::Utils::DBIxClass', 'Exporter';

use Contact::Model::GEN::sch_name;

our $SCH_NAME = 'Contact::Model::sch_name';

our @EXPORT_OK = ( '$SCH_NAME' );

1;

=head1 NAME

Contact::Model::sch_name - model for sch_name table (stub part)

=head1 DESCRIPTION

This model inherits from its generated helper, which inherits from
Gantry::Utils::DBIxClass.  It was generated by Bigtop, but is
NOT subject to regeneration.

=head1 METHODS (mixed in from Contact::Model::GEN::sch_name)

You may use all normal Gantry::Utils::DBIxClass methods and the
ones listed here:

=over 4

=item get_foreign_display_fields

=item get_foreign_tables

=item foreign_display

=item table_name

=back

=cut
