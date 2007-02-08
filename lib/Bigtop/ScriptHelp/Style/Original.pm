package Bigtop::ScriptHelp::Style::Original;
use strict; use warnings;

use base 'Bigtop::ScriptHelp::Style';

use Text::Balanced qw( extract_multiple extract_bracketed );

use Bigtop::ScriptHelp qw( valid_ident );

my $default_columns = 'ident,description';

sub get_db_layout {
    my $self   = shift;
    my $art    = shift || '';
    my $tables = shift || {};

    my @new_tables;
    my @joiners;
    my %foreign_key_for;
    my %columns;

    $art =~ s/^\s+//;
    $art =~ s/\s+$//;

    foreach my $art_element ( split /\s+/, $art ) {
        if ( $art_element =~ /<|-|>/ ) {
            # split tables from operator
            my ( $table1, $op, $table2 ) = split /(<->|->|<-|-)/, $art_element;

            # now pull column descriptions, if present
            my ( $cols1, $cols2 );

            ( $table1, $cols1 ) = _get_columns( $table1 );
            ( $table2, $cols2 ) = _get_columns( $table2 );

#            my ( $raw_cols1, $raw_cols2 );
#            if ( $table1 =~ s/$column_rx// ) { $raw_cols1 = $1;               }
#            else                             { $raw_cols1 = $default_columns; }
#
#            if ( $table2 =~ s/$column_rx// ) { $raw_cols2 = $1;               }
#            else                             { $raw_cols2 = $default_columns; }
#
#            my $cols1 = _parse_columns( $raw_cols1 );
#            my $cols2 = _parse_columns( $raw_cols2 );

            unless ( defined $table1 and valid_ident( $table1 )
                        and
                     defined $table2 and valid_ident( $table2 )
                        and
                     defined $op
            ) {
                die "Invalid ASCII art (1): $art_element\n";
            }

            # make sure tables are in the list of all tables
            unless ( defined $tables->{ $table1 } ) {
                push @new_tables, $table1;
                $tables->{ $table1 }++;
                $columns{ $table1 } = $cols1 unless $columns{ $table1 };
            }

            unless ( defined $tables->{ $table2 } ) {
                push @new_tables, $table2;
                $tables->{ $table2 }++;
                $columns{ $table2 } = $cols2 unless $columns{ $table2 };
            }

            # process based on operator
            if ( $op eq '<-' ) {
                push @{ $foreign_key_for{ $table2 } }, $table1;
            }
            elsif ( $op eq '->' ) {
                push @{ $foreign_key_for{ $table1 } }, $table2;
            }
            elsif ( $op eq '-' ) {
                push @{ $foreign_key_for{ $table2 } }, $table1;
                push @{ $foreign_key_for{ $table1 } }, $table2;
            }
            elsif ( $op eq '<->' ) {
                push @joiners, [ $table1, $table2 ];
            }
            else {
                die "Invalid ASCII art (2): $art_element\n";
            }
        }
        elsif ( valid_ident( $art_element ) ) {
            unless ( defined $tables->{ $art_element } ) {
                push @new_tables, $art_element;
                $tables->{ $art_element }++;
                $columns{ $art_element } = _parse_columns( $default_columns )
                    unless $columns{ $art_element };
            }
        }
        else {
            # look for columns
            die "Invalid ASCII art (3): $art_element\n";
        }
    }

    return {
        all_tables => $tables,
        new_tables => \@new_tables,
        joiners    => \@joiners,
        foreigners => \%foreign_key_for,
        columns    => \%columns,
    }
}

sub _get_columns {
    my $table = shift;

    my ( $name, $raw ) = extract_multiple(
        $table, [
            qr/([^(]*)/, sub { extract_bracketed( $_[0], '()' ) }
        ]
    );

    if ( defined $raw ) {

        $raw =~ s/^\(//;
        $raw =~ s/\)$//;

        return ( $name, _parse_columns( $raw ) );
    }
    else {
        return ( $name, _parse_columns( $default_columns ) );
    }
}

sub _parse_columns {
    my $raw = shift;

    my @pieces = split /,/, $raw;

    my $you_dont_want_em  = 0;
    my %is_normal_default = (
        id       => 1,
        created  => 1,
        modified => 1,
    );

    my @columns;
    foreach my $piece ( @pieces ) {
        my ( $name, @types ) = split /:/, $piece;

        foreach my $type ( @types ) {
            $type = "`$type`" unless valid_ident( $type );
        }

        @types = ( 'varchar' ) unless ( @types > 0 );

        push @columns, { name => $name, types => \@types };

        $you_dont_want_em++ if defined $is_normal_default{ $name };
    }

    unless ( $you_dont_want_em ) {
        unshift @columns, {
                    name  => 'id',
                    types => [ 'int4', 'primary_key', 'auto' ]
                };

        push @columns,
             { name => 'created',  types => [ 'datetime' ] },
             { name => 'modified', types => [ 'datetime' ] };
    }

    return \@columns;
}

1;

=head1 NAME

Bigtop::ScriptHelp::Style::Original - handles ASCII art for scripts

=head1 SYNOPSIS

    use Bigtop::ScriptHelp::Style;

    my $style = Bigtop::ScriptHelp::Style->get_style( 'Original' );

    # then pass $style to methods of Bigtop::ScriptHelp

=head1 DESCRIPTION

See C<Bigtop::ScriptHelp::Style> for a description of what this module
must do in general.

=head1 METHODS

=over 4

=item get_db_layout

This method does not use standard in.  Instead, it expects traditional
ASCII art.  See L<ASCII Art> below.

=back

=head1 ASCII Art

ASCII art allows you to quickly note relationships between
tables with simple characters.

Note well: Since the relationships use punctuation that your shell probably
loves, you must surround the art with single quotes.

It is easiest to understand the options by seeing an example.  So, suppose
we have a four table data model describing a bit of our personnel process:

    +-----------+       +----------+
    |    job    |<------| position |
    +-----------+       +----------+
          ^
          |
    +-----------+       +----------+
    | job_skill |------>|  skill   |
    +-----------+       +----------+

First, you'll be happy to know that bigtop's ASCII art is simpler to draw
than the above.

What our data model shows is that each position refers to a job (description),
each job could require many skills, and each skill could be associated with
many jobs.  The last two mean that job and skill share a many-to-many
relationship.

Here's how to specify this data model in bigtop ASCII art:

    bigtop --new HR 'job<-position job<->skill'

This will indicate a foreign key from position to job and an implied
table, called job_skill, to hold the many-to-many relationship between
job and skill.

The same ASCII art can be used with --new and --add for both bigtop
and tentmaker scripts.

There are four art operators:

=over 4

=item <->

Many-to-many.  A new table will be made with foreign keys to each operand
table.  Each operand table will have a has_many relationship.  Note
that your Model backend may not understand these relationships.  At the
time of this writing only Model GantryDBIxClass did, by luck it happens
to be the default.

=item ->

The first table has a foreign key pointing to the second.

=item <-

The second table has a foreign key pointing to the first.  This is really
a convenience synonymn for ->, but the tables are put into generated SQL
in their overall order of appearance.

=item -

The two tables have a one-to-one relationship.  Each of them will have
a foreign key pointing to the other.

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

