# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Contact::GEN::BDay;

use strict;

use base 'Contact';

use Contact::Model::bday qw(
    $BDAY
);

#-----------------------------------------------------------------
# $self->do_main( $contact )
#-----------------------------------------------------------------
sub do_main {
    my ( $self, $contact ) = @_;

    $self->stash->view->template( 'results.tt' );
    $self->stash->view->title( 'Birth Days' );

    my $real_location = $self->location() || '';
    if ( $real_location ) {
        $real_location =~ s{/+$}{};
        $real_location .= '/';
    }

    my $retval = {
        headings       => [
            'Contact',
            'Birth Day',
        ],
        header_options => [
            {
                text => 'Add',
                link => $real_location . "add",
            },
        ],
    };

    my $schema = $self->get_schema();
    my $where  = ( $contact ) ? { contact => $contact } : undef;
    my @rows   = $BDAY->get_listing(
        {
            schema => $schema,
            where  => $where,
        }
    );

    foreach my $row ( @rows ) {
        my $id = $row->id;
        push(
            @{ $retval->{rows} }, {
                data => [
                    $row->contact->foreign_display(),
                    $row->bday,
                ],
                options => [
                    {
                        text => 'Edit',
                        link => $real_location . "edit/$id",
                    },
                    {
                        text => 'Delete',
                        link => $real_location . "delete/$id",
                    },
                ],
            }
        );
    }

    $self->stash->view->data( $retval );
} # END do_main

1;

=head1 NAME

Contact::GEN::BDay - generated support module for Contact::BDay

=head1 SYNOPSIS

In Contact::BDay:

    use base 'Contact::GEN::BDay';

=head1 DESCRIPTION

This module was generated by bigtop and IS subject to regeneration.
Use it in Contact::BDay to provide the methods below.
Feel free to override them.

=head1 METHODS

=over 4

=item do_main


=back

=head1 AUTHOR

Generated by bigtop and subject to regeneration.

=cut
