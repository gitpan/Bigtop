package Contact::Model::number;
use strict; use warnings;

use base 'Exotic::Base::Module', 'Exporter';

use Contact::Model::GEN::number;

our $NUMBER = 'Contact::Model::number';

our @EXPORT_OK = ( '$NUMBER' );

1;

=head1 NAME

Contact::Model::number - model for number table (stub part)

=head1 DESCRIPTION

This model inherits from its generated helper, which inherits from
Exotic::Base::Module.  It was generated by Bigtop, but is
NOT subject to regeneration.

=head1 METHODS (mixed in from Contact::Model::GEN::number)

You may use all normal Exotic::Base::Module methods and the
ones listed here:

=over 4

=item get_foreign_display_fields

=item get_foreign_tables

=item foreign_display

=item table_name

=back

=cut