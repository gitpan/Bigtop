# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::Checkbook::GEN::Trans::Action;

use strict;

use base 'Exporter';

our @EXPORT = qw(
    form
);

use Apps::Checkbook::Model::trans qw(
    $TRANS
);

#-----------------------------------------------------------------
# $self->form( $row )
#-----------------------------------------------------------------
sub form {
    my ( $self, $row ) = @_;

    my $selections = $TRANS->get_form_selections();

    return {
        name       => 'trans',
        row        => $row,
        fields     => [
            {
                display_size => 2,
                name => 'status',
                label => 'Status2',
                type => 'text',
                is => 'int',
            },
        ],
    };
} # END form


1;
