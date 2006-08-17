package Bigtop::Backend::SQL::SQLite;
use strict; use warnings;

use Bigtop::Backend::SQL;
use Inline;

sub what_do_you_make {
    return [
        [ 'docs/schema.sqlite' => 'SQLite database schema' ],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },
    ];
}

sub gen_SQL {
    shift;
    my $base_dir = shift;
    my $tree     = shift;

    # walk tree generating sql
    my $lookup       = $tree->{application}{lookup};
    my $sql          = $tree->walk_postorder( 'output_sql_lite', $lookup );
    my $sql_output   = join '', @{ $sql };

    # write the schema.postgres
    my $docs_dir     = File::Spec->catdir( $base_dir, 'docs' );
    mkdir $docs_dir;

    my $sql_file     = File::Spec->catfile( $docs_dir, 'schema.sqlite' );

    open my $SQL, '>', $sql_file or die "Couldn't write $sql_file: $!\n";

    print $SQL $sql_output;

    close $SQL or die "Couldn't close $sql_file: $!\n";
}

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_blocks';
[% BLOCK sql_block %]
CREATE [% keyword %] [% name %][% child_output %]

[% END %]

[% BLOCK table_body %]
 (
[% FOREACH child_element IN child_output %]
[% child_element +%][% UNLESS loop.last %],[% END %]

[% END %]
);
[% END %]

[% BLOCK table_element_block %]    [% name %] [% child_output %][% END %]

[% BLOCK field_statement %]
[% keywords.join( ' ' ) %]
[% END %]

[% BLOCK insert_statement %]
INSERT INTO [% table %] ( [% columns.join( ', ' ) %] )
    VALUES ( [% values.join( ', ' ) %] );
[% END %]
EO_TT_blocks

sub setup_template {
    my $class         = shift;
    my $template_text = shift || $default_template_text;

    return if ( $template_is_setup );

    Inline->bind(
        TT                  => $template_text,
        POST_CHOMP          => 1,
        TRIM_LEADING_SPACE  => 0,
        TRIM_TRAILING_SPACE => 0,
    );

    $template_is_setup = 1;
}

# sql_block
package #
    sql_block;
use strict; use warnings;

sub output_sql_lite {
    my $self         = shift;
    my $child_output = shift;

    return if ( $self->_skip_this_block );

    my $child_out_str = '';
    if ( defined $child_output ) {
        $child_out_str = join "\n", @{ $child_output };
    }
    else {
        return;
    }

    my $output = Bigtop::Backend::SQL::SQLite::sql_block(
        {
            keyword      => $self->get_create_keyword(),
            child_output => $child_out_str,
            name         => $self->get_name(),
        }
    );

    return [ $output ];
}

# sequence_body
package #
    sequence_body;
use strict; use warnings;

sub output_sql_lite {
#    warn "Warning: SQLite does not support user defined sequences.\n";

    return;
}

# table_body
package #
    table_body;
use strict; use warnings;

sub output_sql_lite {
    my $self         = shift;
    my $child_output = shift;

    my %output;
    foreach my $statement ( @{ $child_output } ) {
        my ( $type, $output ) = @{ $statement };
        push @{ $output{ $type } }, $output;
    }

    my $output = Bigtop::Backend::SQL::SQLite::table_body(
        { child_output => $output{table_body} }
    );

    if ( defined $output{insert_statements} ) {
        $output .= "\n" . join "\n", @{ $output{insert_statements} };
    }

    return [ $output ]
}

# table_element_block
package #
    table_element_block;
use strict; use warnings;

sub output_sql_lite {
    my $self         = shift;
    my $child_output = shift;

    if ( defined $child_output) {

        my $child_out_str = join "\n", @{ $child_output };

        my $output = Bigtop::Backend::SQL::SQLite::table_element_block(
            { name => $self->get_name(), child_output => $child_out_str }
        );

        return [ [ table_body => $output ] ];
    }
    else {
        return unless ( $self->{__TYPE__} eq 'data' );

        my @columns;
        my @values;
        foreach my $insertion ( @{ $self->{__VALUE__} } ) {
            my ( $column, $value ) = %{ $insertion };

            $value = "'$value'" unless $value =~ /^\d+$/;

            push @columns, $column;
            push @values,  $value;
        }

        my $output = Bigtop::Backend::SQL::SQLite::insert_statement(
            {
                table   => $self->get_table_name,
                columns => \@columns,
                values  => \@values,
            }
        );
        return [ [ insert_statements => $output ] ];
    }
}

# field_statement
package #
    field_statement;
use strict; use warnings;

my %expansion_for = (
    int4               => 'INTEGER',
    primary_key        => 'PRIMARY KEY',
    assign_by_sequence => 'AUTOINCREMENT',
    auto               => 'AUTOINCREMENT',
);

sub output_sql_lite {
    my $self   = shift;
    shift;  # there is no child output
    my $lookup = shift;

    return unless $self->get_name() eq 'is';

    my @keywords;
    foreach my $arg ( @{ $self->{__DEF__}{__ARGS__} } ) {
        my $expanded_form = $expansion_for{$arg};

        if ( defined $expanded_form ) {
            push @keywords, $expanded_form;
        }
        else {
            push @keywords, $arg;
        }
    }
    my $output = Bigtop::Backend::SQL::SQLite::field_statement(
        { keywords => \@keywords }
    );

    return [ $output ];
}

# literal_block
package #
    literal_block;
use strict; use warnings;

sub output_sql_lite {
    my $self = shift;

    return $self->make_output( 'SQL' );
}

1;

__END__

=head1 NAME

Bigtop::Backend::SQL::SQLite - backend to generate sql for SQLite database creation

=head1 SYNOPSIS

If your bigtop file looks like this:

    config {
        SQL  SQLite {}
    }
    app App::Name {
    }

and there are table and/or sequence blocks in the app block, this
module will make docs/schema.postgres (relative to the build_dir) when
you type:

    bigtop app.bigtop SQL

or

    bigtop app.bigtop all

You can feed that file directly to psql, once you have created
a database.  That is type:

    sqlite dbname < docs/schema.sqlite

=head1 DESCRIPTION

This is a Bigtop backend which generates SQL SQLite can understand.

=head1 KEYWORDS

This module defines no keywords.  Look in Bigtop::SQL for a list
of the keywords you can use in table and sequence blocks.

Note that SQLite does not support sequences.  Trying to use them with
this backend will be fatal.

=head1 SHORTHAND for is arguments

This module does provide a couple of bits of shorthand (some aren't so short)
for the arguments of the is field statement.

    field id {
        is int4, primary_key, auto;
    }

This translates into:

    id INTEGER PRIMARY KEY AUTOINCREMENT

You can also type 'assign_by_sequence' instead of 'auto'.  That might
aid understanding, if you can type it correctly.

Note that using 'primary_key' instead of the literal 'PRIMARY KEY' is
important.  It tells the SQL and the Model back ends that this is the
primary key.

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
