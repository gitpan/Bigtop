package Apps::Checkbook::Model::payee;
use strict; use warnings;

use base 'Gantry::Utils::CDBI', 'Exporter';

use Apps::Checkbook::Model::GEN::payee;

our $PAYEE = 'Apps::Checkbook::Model::payee';

our @EXPORT_OK = ( '$PAYEE' );

1;
