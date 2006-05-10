# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::Checkbook::Model::GEN::status;
use strict; use warnings;

use base 'Gantry::Utils::Model::Regular';

use Carp;

sub get_table_name    { return 'status'; }
sub get_sequence_name { return 'status_seq'; }
sub get_primary_col   { return 'id'; }

sub get_essential_cols {
    return 'id';
}

sub get_primary_key {
    goto &id;
}

sub id {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) {
        return $self->set_id( $value );
    }

    return $self->get_id();
}

sub set_id {
    croak 'Can\'t change primary key of row';
}

sub get_id {
    my $self = shift;
    return $self->{id};
}

sub quote_id {
    return $_[1];
}

sub descr {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_descr( $value ); }
    else                  { return $self->get_descr();         }
}

sub set_descr {
    my $self  = shift;
    my $value = shift;

    $self->{descr} = $value;
    $self->{__DIRTY__}{descr}++;

    return $value;
}

sub get_descr {
    my $self = shift;

    if ( not defined $self->{descr} ) {
        $self->lazy_fetch( 'descr' );
    }

    return $self->{descr};
}

sub quote_descr {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

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
