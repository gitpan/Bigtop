package Apps::Checkbook::Model::auth_db_user;
use strict; use warnings;

use base 'Gantry::Utils::AuthCDBI', 'Exporter';

use Apps::Checkbook::Model::GEN::auth_db_user;

our $AUTH_DB_USER = 'Apps::Checkbook::Model::auth_db_user';

our @EXPORT_OK = ( '$AUTH_DB_USER' );

1;
