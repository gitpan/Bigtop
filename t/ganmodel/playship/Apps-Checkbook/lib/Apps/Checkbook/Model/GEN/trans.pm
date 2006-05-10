# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::Checkbook::Model::GEN::trans;
use strict; use warnings;

use base 'Gantry::Utils::Model::Regular';

use Carp;

sub get_table_name    { return 'trans'; }
sub get_sequence_name { return 'trans_seq'; }
sub get_primary_col   { return 'id'; }

sub get_essential_cols {
    return 'id, status, trans_date, amount, descr';
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

sub amount {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_amount( $value ); }
    else                  { return $self->get_amount();         }
}

sub set_amount {
    my $self  = shift;
    my $value = shift;

    $self->{amount} = $value;
    $self->{__DIRTY__}{amount}++;

    return $value;
}

sub get_amount {
    my $self = shift;

    return $self->{amount};
}

sub quote_amount {
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

    return $self->{descr};
}

sub quote_descr {
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub status {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_status( $value ); }
    else                  { return $self->get_status();         }
}

sub set_status {
    my $self  = shift;
    my $value = shift;

    if ( ref $value ) {
        $self->{status_REF} = $value;
        $self->{status}     = $value->id;
    }
    elsif ( defined $value ) {
        delete $self->{status_REF};
        $self->{status}     = $value;
    }
    else {
        croak 'set_status requires a value';
    }

    $self->{__DIRTY__}{status}++;

    return $value;
}

sub get_status {
    my $self = shift;

    if ( not defined $self->{status_REF} ) {
        $self->{status_REF}
            = Apps::Checkbook::Model::status->retrieve_by_pk(
                    $self->{status}
              );

        $self->{status}     = $self->{status_REF}->get_primary_key()
                if ( defined $self->{status_REF} );
    }

    return $self->{status_REF};
}

sub get_status_raw {
    my $self = shift;

    if ( @_ ) {
        croak 'get_status_raw is only a get accessor, pass it nothing';
    }

    return $self->{status};
}

sub quote_status {
    return 'NULL' unless defined $_[1];
    return ( ref( $_[1] ) ) ? "$_[1]" : $_[1];
}

sub trans_date {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_trans_date( $value ); }
    else                  { return $self->get_trans_date();         }
}

sub set_trans_date {
    my $self  = shift;
    my $value = shift;

    $self->{trans_date} = $value;
    $self->{__DIRTY__}{trans_date}++;

    return $value;
}

sub get_trans_date {
    my $self = shift;

    return $self->{trans_date};
}

sub quote_trans_date {
    return ( defined $_[1] and $_[1] ) ? "'$_[1]'" : 'NULL';
}

sub get_foreign_display_fields {
    return [ qw(  ) ];
}

sub get_foreign_tables {
    return qw(
        Apps::Checkbook::Model::status
    );
}

sub foreign_display {
    my $self = shift;

}

1;
