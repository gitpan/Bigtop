# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::Checkbook::Model::auth_db_user;
use strict; use warnings;

Apps::Checkbook::Model::auth_db_user->table   ( 'auth_db_user'     );
Apps::Checkbook::Model::auth_db_user->columns ( Primary   => qw/
    id
/ );

Apps::Checkbook::Model::auth_db_user->columns ( All       => qw/
    id
    something
/ );

Apps::Checkbook::Model::auth_db_user->columns ( Essential => qw/
    id
    something
/ );


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

1;
