package Billing::Model::status;
use strict; use warnings;

use base 'Gantry::Utils::DBIxClass', 'Exporter';

use Billing::Model::GEN::status;

our $STATUS = 'Billing::Model::status';

our @EXPORT_OK = ( '$STATUS' );

1;

=head1 NAME

Billing::Model::status - model for status table (stub part)

=head1 DESCRIPTION

This model inherits from its generated helper, which inherits from
Gantry::Utils::DBIxClass.  It was generated by Bigtop, but is
NOT subject to regeneration.

=head1 METHODS (mixed in from Billing::Model::GEN::status)

You may use all normal Gantry::Utils::DBIxClass methods and the
ones listed here:

=over 4

=item get_foreign_display_fields

=item get_foreign_tables

=item foreign_display

=item table_name

=back

=cut
