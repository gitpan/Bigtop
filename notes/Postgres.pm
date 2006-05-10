package application;
use strict; use warnings;

use Data::Dumper;
sub get_app_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub build_sql {
    my $self = shift;

#    print Dumper( $self );

    $self->{app_body}->build_sql();
}

package app_body;
use strict; use warnings;

use Data::Dumper;

sub build_sql {
    my $self = shift;

    foreach my $block ( @{ $self->{'block(s)'} } ) {
        $block->build_sql();
    }
}

package block;
use strict; use warnings;

use Data::Dumper;

sub build_sql {
    my $self = shift;

    return unless defined $self->{sql_block};

    $self->{sql_block}->build_sql();
}

package sql_block;
use strict; use warnings;

use Data::Dumper;

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub build_sql {
    my $self = shift;

    my $output = "CREATE "
               . $self->{__BODY__}->create_keyword() . ' '
               . $self->{__NAME__} . " {\n" ;

    $output   .= $self->{__BODY__}->build_sql();

    $output .= "}\n";

    print $output;
}

package table_body;
use strict; use warnings;

use Data::Dumper;

sub create_keyword { return 'TABLE' }

sub build_sql {
    my $self = shift;

    my $output = '';

    foreach my $element ( @{ $self->{'table_element_block(s)'} } ) {
        $output .= $element->build_sql();
    }

    return $output;
}

package table_element_block;
use strict; use warnings;

use Data::Dumper;

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub build_sql {
    my $self = shift;

    my $output = '    ' . $self->get_name() . ' ';

    $output   .= $self->{__BODY__}->build_sql() . ";\n";

    return $output;
}

package field_body;
use strict; use warnings;

use Data::Dumper;

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub build_sql {
    my $self = shift;

    my $output;

    FIELD_STATEMENT:
    foreach my $field_statement ( @{ $self->{'field_statement(s)'} } ) {
        next unless $field_statement->get_name() eq 'is';
        $output = $field_statement->build_sql();
        last FIELD_STATEMENT;
    }

    return $output;
}

package field_statement;
use strict; use warnings;

use Data::Dumper;

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub build_sql {
    my $self = shift;

    return $self->{__DEF__}->build_sql();
}

package field_statement_def;
use strict; use warnings;

use Data::Dumper;

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub build_sql {
    my $self = shift;

    return $self->{__ARGS__}->get_list();
}

package arg_list;
use strict; use warnings;

use Data::Dumper;

sub get_list {
    my $self = shift;

    return join ', ', @{ $self };
}

1;
