# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Blog::GEN::Post;

use strict;
use warnings;

use base 'Blog';
use JSON;
use Gantry::Utils::TablePerms;

use Blog::Model::post qw(
    $POST
);

#-----------------------------------------------------------------
# $self->controller_config(  )
#-----------------------------------------------------------------
sub controller_config {
    my ( $self ) = @_;

    return {
        permissions => {
            bits  => 'crud-rudcr--',
            group => ''
        },
    };
} # END controller_config

#-----------------------------------------------------------------
# $self->post_form( $data )
#-----------------------------------------------------------------
sub post_form {
    my ( $self, $data ) = @_;

    my $selections = $POST->get_form_selections();

    return {
        row        => $data->{row},
        fields     => [
            {
                name => 'title',
                label => 'Title',
                type => 'text',
                is => 'varchar',
            },
            {
                name => 'body',
                label => 'Body',
                type => 'text',
                is => 'varchar',
            },
        ],
    };
} # END post_form

1;

=head1 NAME

Blog::GEN::Post - generated support module for Blog::Post

=head1 SYNOPSIS

In Blog::Post:

    use base 'Blog::GEN::Post';

=head1 DESCRIPTION

This module was generated by bigtop and IS subject to regeneration.
Use it in Blog::Post to provide the methods below.
Feel free to override them.

=head1 METHODS

=over 4

=item controller_config

=item post_form


=back

=head1 AUTHOR

Generated by bigtop and subject to regeneration.

=cut
