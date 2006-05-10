package Apps::Checkbook::Model::trans;
use strict; use warnings;

use base 'Gantry::Utils::CDBI', 'Exporter';

use Apps::Checkbook::Model::GEN::trans;

our $TRANS = 'Apps::Checkbook::Model::trans';

our @EXPORT_OK = ( '$TRANS' );

1;
