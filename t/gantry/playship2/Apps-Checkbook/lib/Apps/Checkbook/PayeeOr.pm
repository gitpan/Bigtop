package Apps::Checkbook::PayeeOr;

use strict;

use base 'Apps::Checkbook';
use Apps::Checkbook::GEN::PayeeOr qw(
    do_main
    form
);

use Gantry::Plugins::CRUD;

use SomePackage::SomeModule;

use ExportingModule qw(
    sample
    $EXPORTS
);


use Apps::Checkbook::Model::payee qw(
    $PAYEE
);

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
# This method supplied by Apps::Checkbook::GEN::PayeeOr

my $my_crud = Gantry::Plugins::CRUD->new(
    add_action      => \&my_crud_add,
    edit_action     => \&my_crud_edit,
    delete_action   => \&my_crud_delete,
    form            => \&my_crud_form,
    redirect        => \&my_crud_redirect,
    text_descr      => 'Payee/Payor',
    use_clean_dates => 1,
);

#-----------------------------------------------------------------
# $self->my_crud_redirect( $data )
# The generated version mimics the default behavior, feel free
# to delete the redirect key from the constructor call for $crud
# and this sub.
#-----------------------------------------------------------------
sub my_crud_redirect {
    my ( $self, $data ) = @_;
    return $self->location;
}

#-------------------------------------------------
# $self->do_add( )
#-------------------------------------------------
sub do_add {
    my $self = shift;

    $my_crud->add( $self, { data => \@_ } );
}

#-------------------------------------------------
# $self->my_crud_add( $params, $data )
#-------------------------------------------------
sub my_crud_add {
    my ( $self, $params, $data ) = @_;

    my $row = $PAYEE->create( $params );
    $row->dbi_commit();
}

#-------------------------------------------------
# $self->do_delete( $doomed_id, $confirm )
#-------------------------------------------------
sub do_delete {
    my ( $self, $doomed_id, $confirm ) = @_;
    $my_crud->delete( $self, $confirm, { id => $doomed_id } );
}

#-------------------------------------------------
# $self->my_crud_delete( $data )
#-------------------------------------------------
sub my_crud_delete {
    my ( $self, $data ) = @_;

    my $doomed = $PAYEE->retrieve( $data->{id} );
    $doomed->delete;
    $PAYEE->dbi_commit;
}

#-------------------------------------------------
# $self->do_edit( $id )
#-------------------------------------------------
sub do_edit {
    my ( $self, $id ) = @_;

    my $row = $PAYEE->retrieve( $id );

    $my_crud->edit( $self, { row => $row } );
}

#-------------------------------------------------
# $self->my_crud_edit( $param, $data )
#-------------------------------------------------
sub my_crud_edit {
    my( $self, $params, $data ) = @_;

    my %param = %{ $params };

    my $row = $data->{row};

    # Make update
    $row->set( %param );
    $row->update;
    $row->dbi_commit;
}

#-----------------------------------------------------------------
# $self->my_crud_form( $data )
#-----------------------------------------------------------------
sub my_crud_form {
    my ( $self, $data ) = @_;

    my $selections = $PAYEE->get_form_selections();

    return {
        name       => 'payee_crud',
        row        => $data->{row},
        fields     => [
            {
                display_size => 20,
                name => 'name',
                label => 'Name',
                type => 'text',
                is => 'varchar',
            },
        ],
    };
} # END my_crud_form

my $crud = Gantry::Plugins::CRUD->new(
    add_action      => \&crud_add,
    edit_action     => \&crud_edit,
    delete_action   => \&crud_delete,
    form            => \&_form,
    redirect        => \&crud_redirect,
    text_descr      => 'Payee/Payor',
    use_clean_dates => 1,
);

#-----------------------------------------------------------------
# $self->crud_redirect( $data )
# The generated version mimics the default behavior, feel free
# to delete the redirect key from the constructor call for $crud
# and this sub.
#-----------------------------------------------------------------
sub crud_redirect {
    my ( $self, $data ) = @_;
    return $self->location;
}

#-------------------------------------------------
# $self->do_add( )
#-------------------------------------------------
sub do_add {
    my $self = shift;

    $crud->add( $self, { data => \@_ } );
}

#-------------------------------------------------
# $self->crud_add( $params, $data )
#-------------------------------------------------
sub crud_add {
    my ( $self, $params, $data ) = @_;

    my $row = $PAYEE->create( $params );
    $row->dbi_commit();
}

#-------------------------------------------------
# $self->do_delete( $doomed_id, $confirm )
#-------------------------------------------------
sub do_delete {
    my ( $self, $doomed_id, $confirm ) = @_;
    $crud->delete( $self, $confirm, { id => $doomed_id } );
}

#-------------------------------------------------
# $self->crud_delete( $data )
#-------------------------------------------------
sub crud_delete {
    my ( $self, $data ) = @_;

    my $doomed = $PAYEE->retrieve( $data->{id} );
    $doomed->delete;
    $PAYEE->dbi_commit;
}

#-------------------------------------------------
# $self->do_edit( $id )
#-------------------------------------------------
sub do_edit {
    my ( $self, $id ) = @_;

    my $row = $PAYEE->retrieve( $id );

    $crud->edit( $self, { row => $row } );
}

#-------------------------------------------------
# $self->crud_edit( $param, $data )
#-------------------------------------------------
sub crud_edit {
    my( $self, $params, $data ) = @_;

    my %param = %{ $params };

    my $row = $data->{row};

    # Make update
    $row->set( %param );
    $row->update;
    $row->dbi_commit;
}

#-----------------------------------------------------------------
# $self->_form( $data )
#-----------------------------------------------------------------
sub _form {
    my ( $self, $data ) = @_;

    my $selections = $PAYEE->get_form_selections();

    return {
        name       => 'default_form',
        row        => $data->{row},
        fields     => [
            {
                display_size => 20,
                name => 'name',
                label => 'Name',
                type => 'text',
                is => 'varchar',
            },
        ],
    };
} # END _form

#-----------------------------------------------------------------
# $self->form( $row )
#-----------------------------------------------------------------
# This method supplied by Apps::Checkbook::GEN::PayeeOr

#-----------------------------------------------------------------
# $self->do_members(  )
#-----------------------------------------------------------------
sub do_members {
    my ( $self ) = @_;
} # END do_members


#-----------------------------------------------------------------
# $self->init( $r )
#-----------------------------------------------------------------
sub init {
    my ( $self, $r ) = @_;

    # process SUPER's init code
    $self->SUPER::init( $r );

    $self->importance( $self->fish_config( 'importance' ) || '' );
} # END init

sub importance {
    my ( $self, $value ) = @_;

    if ( defined $value ) {
        $self->{importance} = $value;
    }

    return $self->{importance};
}


1;

=head1 NAME

Apps::Checkbook::PayeeOr - A controller in the Apps::Checkbook application

=head1 SYNOPSIS

This package is meant to be used in the Perl block of an httpd.conf file.

    <Perl>
        # ...
        use Apps::Checkbook::PayeeOr;
    </Perl>

    <Location /someurl>
        SetHandler  perl-script
        PerlHandler Apps::Checkbook::PayeeOr
    </Location>

If all went well, the httpd.conf file was correctly written during app
generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS

=over 4

=item do_members

=item get_model_name

=item text_descr

=back

=head1 METHODS MIXED IN FROM Apps::Checkbook::GEN::PayeeOr

=over 4

=item do_main

=item form

=back

=head1 DEPENDENCIES

    Apps::Checkbook
    Apps::Checkbook::GEN::PayeeOr
    SomePackage::SomeModule
    ExportingModule
    Apps::Checkbook::Model::payee
    Gantry::Plugins::CRUD

=head1 AUTHOR

Somebody Somewhere, E<lt>somebody@example.comE<gt>

Somebody Else

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Somebody Somewhere

All rights reserved.

=cut
