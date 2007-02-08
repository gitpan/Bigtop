package Bigtop::ScriptHelp;
use strict; use warnings;

use base 'Exporter';

our @EXPORT = qw( valid_ident );

my %non_entry   = (
    id       => 1,
    created  => 1,
    modified => 1,
);

sub _get_config_block {
    return << "EO_Config_Default";
config {
    engine          CGI;
    template_engine TT;

    Init            Std             {}
    SQL             SQLite          {}
    SQL             Postgres        {}
    SQL             MySQL           {}
    CGI             Gantry          { with_server 1; gen_root 1; flex_db 1; }
    Control         Gantry          { dbix 1; }
    Model           GantryDBIxClass {}
    SiteLook        GantryDefault   {}
}
EO_Config_Default
}

sub get_minimal_default {
    my $class  = shift;
    my $name   = shift || 'Sample';
    my $config = _get_config_block;

    return << "EO_Little_Default";
$config
app $name {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller is base_controller {
        method do_main is base_links {
        }
        method site_links is links {
        }
    }
}
EO_Little_Default
}

sub get_big_default {
    my $class    = shift;
    my $style    = shift;
    my $app_name = shift;
    my @models   = @_;

    my $model_code = _make_model_code( $style, @models );
    return _make_default_string( $app_name, $model_code );
}

sub _make_model_code {
    my $style = shift;

    my $space = ' ';
    my $args  = join $space, @_;

    my %tables;
    my @all_tables;
    my %foreign_key_for;
    my @joiners;

    my $parsed_art = $style->get_db_layout( $args );
    my ( $tables, $new_tables, $joiners, $foreign_key_for, $columns ) = (
            $parsed_art->{ all_tables },
            $parsed_art->{ new_tables },
            $parsed_art->{ joiners },
            $parsed_art->{ foreigners },
            $parsed_art->{ columns },
    );

    my $retval = '';

    foreach my $model ( @{ $new_tables } ) {
        my $schema_free = $model;
        $schema_free    = _strip_schema( $schema_free );

        my $controller  = Bigtop::ScriptHelp->default_controller( $model );

        my $rel_loc     = $model;
        $rel_loc        =~ s/\./_/;

        my $descr       = $schema_free;
        $descr          =~ s/_/ /g;

        my $model_label = Bigtop::ScriptHelp->default_label( $schema_free );

        my ( $native_text, $show_in_main, $those_excluded_from_form )
                = _make_native_fields( $columns, $model );

        my $foreign_text = _make_foreign_key_fields(
                $foreign_key_for, $model
        );

        $retval .= << "EO_MODEL";
    table $model {
$native_text
$foreign_text
    }
    controller $controller is AutoCRUD {
        controls_table `$model`;
        rel_location $rel_loc;
        text_description `$descr`;
        page_link_label `$model_label`;
        method do_main is main_listing {
            cols $show_in_main;
            header_options Add;
            row_options Edit, Delete;
            title `$model_label`;
        }
        method form is AutoCRUD_form {
            all_fields_but $those_excluded_from_form;
            extra_keys
                legend => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }
EO_MODEL
    }

    foreach my $joiner ( @{ $joiners } ) {
        my ( $table1, $table2 ) = @{ $joiner };

        my $join_name = join '_', $table1, $table2;

        $retval .= << "EO_JOINER";
    join_table $join_name {
        joins $table1 => $table2;
    }
EO_JOINER
    }

    return $retval;
}

sub _make_default_string {
    my $app_name   = shift;
    my $model_code = shift;

    my $dbname     = lc $app_name;
    $dbname        =~ s/::/_/g;

    my $config     = _get_config_block();

    return <<"EO_Model_Bigtop";
$config
app $app_name {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }
    controller is base_controller {
        method do_main is base_links {
        }
        method site_links is links {
        }
    }
$model_code
}
EO_Model_Bigtop
}

sub _make_native_fields {
    my $columns_for = shift;
    my $table       = shift;

    my $columns     = $columns_for->{ $table };
    my $foreign_display;
    my $second_main_col;
    my @exclude_from_form;

    # first handle the columns
    my $retval = '';
    my $space  = ' ';
    my $outer_indent = $space x 8;
    my $is_spacing   = $space x 12;

    foreach my $column ( @{ $columns } ) {

        my $type_string = join ', ', @{ $column->{ types } };

        my $decorations = '';
        if ( $non_entry{ $column->{ name } } ) {
            push @exclude_from_form, $column->{ name };
        }
        else {
            $second_main_col = $column->{ name }
                        if $foreign_display and not $second_main_col;

            $foreign_display = $column->{ name } unless $foreign_display;

            $type_string = "${is_spacing}$type_string";

            die "invalid column name $column->{ name }\n"
                    unless valid_ident( $column->{ name } );

            my $label = Bigtop::ScriptHelp->default_label( $column->{ name } );

            $label = "`$label`" if ( $label =~ /\s+/ );

            $decorations = << "EO_DEC";
            label          $label;
            html_form_type text;
EO_DEC
        }

        $retval .= "${outer_indent}field $column->{ name } {\n";
        $retval .= "${outer_indent}    is $type_string;\n";
        $retval .= $decorations if $decorations;
        $retval .= "${outer_indent}}\n";
    }

    # finish by adding foreign_display
    $retval .= "${outer_indent}foreign_display `%$foreign_display`;";

    my $main_cols = $foreign_display;
    $main_cols   .= ", $second_main_col" if $second_main_col;

    return ( $retval, $main_cols, join( ', ', @exclude_from_form ) );
}

sub _make_foreign_key_fields {
    my $foreign_key_for = shift;
    my $model           = shift;

    my @foreign_fields;
    my $foreign_text = "\n";
    if ( defined $foreign_key_for->{ $model } ) {
        foreach my $foreign_key ( @{ $foreign_key_for->{ $model } } ) {
            my $label = Bigtop::ScriptHelp->default_label(
                    _strip_schema( $foreign_key )
            );
            my $name  = $foreign_key;
            $name     =~ s/\./_/;
            my $new_foreigner = <<"EO_Foreign_Field";
        field $name {
            is             int4;
            label          `$label`;
            refers_to      `$foreign_key`;
            html_form_type select;
        }
EO_Foreign_Field
            push @foreign_fields, $new_foreigner;
        }
        $foreign_text = join '', @foreign_fields;
    }

    chomp $foreign_text;

    return $foreign_text;
}

sub _strip_schema {
    my $input = shift;
    $input    =~ s/^[^\.]*\.//;

    return $input;
}

sub augment_tree {
    my $class = shift;
    my $style = shift;
    my $ast   = shift;
    my $art   = shift;

    # parse existing tree, get a list of all the extant tables
    my %initial_tables  = map { $_ => 1 }
                  keys %{ $ast->{application}{lookup}{tables} };
    my $joins   = $ast->{application}{lookup}{join_tables};

    foreach my $join_member ( keys %{ $joins } ) {

        foreach my $membership ( @{ $joins->{ $join_member } } ) {

            my ( $join_table ) = values %{ $membership->{ joins } };

            $initial_tables{ $join_table } = 1;
        }
    }

    my $parsed_art = $style->get_db_layout( $art, \%initial_tables );
    my ( $tables, $new_tables, $joiners, $foreign_key_for, $columns ) = (
        $parsed_art->{ all_tables },
        $parsed_art->{ new_tables },
        $parsed_art->{ joiners    },
        $parsed_art->{ foreigners },
        $parsed_art->{ columns    },
    );

    # make new tables with tentmaker hooks
    my %new_table;
    my %new_controller_for;
    foreach my $table ( @{ $new_tables } ) {
        my $controller  = Bigtop::ScriptHelp->default_controller( $table );

        my $schema_free = _strip_schema( $table );

        my $descr       = $schema_free;
        $descr          =~ s/_/ /g;

        my $model_label = Bigtop::ScriptHelp->default_label( $schema_free );

        my $rel_loc     = $table;
        $rel_loc        =~ s/\./_/;

        $new_table{ $table } = $ast->create_block(
                'table', $table, { columns => $columns->{ $table } }
        );

        my ( $foreign_display, $on_main_listing, $all_fields_but ) = 
                _get_controller_fields( $columns->{ $table } );

        # set a foreign display
        $ast->change_statement(
            {
                type      => 'table',
                ident     => $new_table{ $table }->get_ident,
                keyword   => 'foreign_display',
                new_value => "%$foreign_display",
            }
        );

        # make a controller for the new table
        $new_controller_for{ $table } = $ast->create_block(
                'controller',
                $controller,
                { subtype          => 'AutoCRUD',
                  table            => $table,
                  text_description => $descr,
                  page_link_label  => $model_label,
                  rel_loc          => $rel_loc,
                  on_main_listing  => $on_main_listing,
                  all_fields_but   => $all_fields_but,
                }
        );
    }

    foreach my $point_from ( keys %{ $foreign_key_for } ) {
        my $ident = $ast->{application}
                          {lookup}
                          {tables}
                          {$point_from}
                          {__IDENT__};

        if ( not defined $ident ) {  # must be new
            $ident = $new_table{ $point_from }->get_ident();
        }

        foreach my $foreign_key ( @{ $foreign_key_for->{ $point_from } } ) {

            my $name  = $foreign_key;
            $name     =~ s/\./_/;

            my $label =
                    Bigtop::ScriptHelp->default_label(
                            _strip_schema( $foreign_key )
                    );

            my $refers_to_field = $ast->create_subblock(
                {
                    parent => {
                        type => 'table', ident => $ident
                    },
                    new_child => {
                        type => 'field',
                        name => $name,
                    },
                }
            );

            $ast->change_statement(
                {
                    type => 'field',
                    ident => $refers_to_field->{__IDENT__},
                    keyword => 'is',
                    new_value => 'int4',
                }
            );
            $ast->change_statement(
                {
                    type => 'field',
                    ident => $refers_to_field->{__IDENT__},
                    keyword => 'label',
                    new_value => $label,
                }
            );
            $ast->change_statement(
                {
                    type => 'field',
                    ident => $refers_to_field->{__IDENT__},
                    keyword => 'refers_to',
                    new_value => $foreign_key,
                }
            );
            $ast->change_statement(
                {
                    type      => 'field',
                    ident     => $refers_to_field->{__IDENT__},
                    keyword   => 'html_form_type',
                    new_value => 'select',
                }
            );
        }
    }

    # Make three ways.
    foreach my $joiner ( @{ $joiners } ) {
        my ( $table1, $table2 ) = @{ $joiner };
        my $join_name = "${table1}_${table2}";
        my $join_table = $ast->create_block( 'join_table', $join_name, {} );

        $ast->change_statement(
            {
                type      => 'join_table',
                ident     => $join_table->{ join_table }{ __IDENT__ },
                keyword   => 'joins',
                new_value => {
                    keys => $table1,
                    values => $table2,
                }
            }
        );
    }

    return; # This is an in place tree modifier.
}

sub _get_controller_fields {
    my $columns = shift;

    my $foreign_display;
    my $second_main_col;
    my @exclude_from_form;

    foreach my $column ( @{ $columns } ) {
        if ( $non_entry{ $column->{ name } } ) {
            push @exclude_from_form, $column->{ name };
        }
        else {
            $second_main_col = $column->{ name }
                        if $foreign_display and not $second_main_col;

            $foreign_display = $column->{ name } unless $foreign_display;
        }
    }

    my $main_cols = $foreign_display;
    $main_cols   .= ", $second_main_col" if $second_main_col;

    return ( $foreign_display, $main_cols, join( ', ', @exclude_from_form ) );
}

sub valid_ident {
    my $candidate = shift;

    # XXX this regex is allowing leading digits
    return $candidate =~ /^\w[\w\d_:\.]*$/;
}

sub default_label {
    my $class  = shift;
    my $name   = shift;

    my @output_pieces = _name_breaker( $name, qr/_/ );

    return join ' ', @output_pieces;  # one space separator
}

sub default_controller {
    my $class = shift;
    my $table = shift;

    my $name = $class->default_label( $table );
    $name    =~ s/ //g;

    my @output_pieces = _name_breaker( $name, qr/\./ );

    return join '', @output_pieces;  # no space separator
}

sub _name_breaker {
    my $name     = shift;
    my $split_on = shift;

    my @output_pieces;

    foreach my $piece ( split $split_on, $name ) {
        $piece = ucfirst $piece;
        push @output_pieces, $piece;
    }

    return @output_pieces;
}

1;

=head1 NAME

Bigtop::ScriptHelp - A helper modules for command line utilities

=head1 SYNOPSIS

    #!/usr/bin/perl
    use Bigtop::ScriptHelp;

    my $default = Bigtop::ScriptHelp->get_minimal_default();
    my $tree    = Bigtop::Parser->parse_string( $default );
    # ...

    my $style   = 'SomeStyle';  # must live in Bigtop::ScriptHelp::Style::

    my $better_default = Bigtop::ScriptHelp->get_big_default(
            $style, $name, $art
    );
    my $better_tree    = Bigtop::Parser->parse_string( $better_default );

    Bigtop::ScriptHelp->augment_tree( $style, $bigtop_tree, $art );

    my $new_field_label = Bigtop::ScriptHelp->default_label( $name );

=head1 DESCRIPTION

This module is used by the bigtop and tentmaker scripts.  It provides
convenience functions for them.

=head1 ASCII art

Whenever users are allowed to supply tables, they could just name the
tables, but they will probably want to use ASCII art to show their
relationships.  This section explains those.

Note well: for these to work well, your SQL and Model backends have
to understand what to do with them.  For instance, the only Model
that understands what to do with a many-to-many relationship is
GantryDBIxClass.

Each relationship is between a pair of tables.  These tables must appear
with their relational operator in between them without whitespace.
There are four operators which specify three relations:

=over 4

=item a->b

Table a has a foreign key pointing to table b, this is a many-to-one
relationship from a to b.

=item b<-a

Table a has a foreign key pointing to table b, this is a one-to-many
relationship from b to a.

This is a synonymn, for a->b, except that if the tables have not
already been created, the first one listed is created first.  This might
matter if your SQL backend makes genuine foreign keys and your database won't
allow forward references.

=item a-b

Table a and table b have a one-to-one relationship, each will have
columns pointing to the other.

=item a<->b

Tables a and b have a many-to-many relationship.  A third table called
a_b will be created for you to join them.  The has many relationship in
table a will be called bs (not to be taken literally), whilc the has many
relationship in table b will be called as.  You may use the tentmaker or a
text editor to add a names statement to the generated join_table block,
to provide alternate names.

=back

=head1 METHODS

=over 4

=item get_minimal_default

Params: app_name (optional, defaults to Sample)

Returns: a little default bigtop string suitable for initial building.
It has everything you need for your app except tables and controllers.

=item get_big_default

Params: an app name and a list of ascii art table relationships.

Returns: a bigtop file suitable for immediately creating an app and
starting it.

=item augment_tree

Params: a Bigtop::Parser syntax tree (what you got from a parse_* method)
and a list of ascii art table relationships

Returns: nothing, but the tree you passed will be updated.

=item default_label

Params: a new name

Returns: a default label for that name

Example of conversion: if name is birth_date, the label becomes 'Birth Date'.

=item default_controller

Params: a new table name

Returns: a default label for that table's controller

Example of conversion: if table name is birth_date, the controller
becomes 'BirthDate'.

=back

=head1 FUNCTIONS

The following functions are meant for internal use, but you might like
them too.  Don't call them through the class, call them as functions.

=over 4

=item valid_ident

Params: a proposed ident

Returns: true if the ident looks good, false otherwise.  Note that the
regex is not perfect.  For instance, it will allow leading numbers.

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
