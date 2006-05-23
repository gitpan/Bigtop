package Bigtop::Backend::Model::Gantry;
use strict; use warnings;

use Bigtop::Backend::Model;
use File::Spec;
use Inline;
use Bigtop;

#-----------------------------------------------------------------
#   The Default Template
#-----------------------------------------------------------------

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_blocks';
[% BLOCK stub_table_module %]
package [% package_name %];
use strict; use warnings;

use base '[% gen_package_name %]', 'Exporter';

our $[% package_alias %] = '[% package_name %]';

our @EXPORT_OK = ( '$[% package_alias %]' );

1;
[% END %]

[% BLOCK gen_table_module %]
# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package [% gen_package_name %];
use strict; use warnings;

use base '[% base_class || 'Gantry::Utils::Model::Regular' %]';

use Carp;

sub get_table_name    { return '[% table_name %]'; }
[% IF sequence_name %]
sub get_sequence_name { return '[% sequence_name %]'; }
[% END %]
sub get_primary_col   { return '[% primary_key +%]'; }

sub get_essential_cols {
    return '[% FOREACH essential_column IN essential_columns %][% essential_column %][% UNLESS loop.last %], [% END %][% END %]';
}

sub get_primary_key {
    goto &id;
}

sub [% primary_key %] {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) {
        return $self->set_[% primary_key %]( $value );
    }

    return $self->get_[% primary_key %]();
}

sub set_[% primary_key %] {
    croak 'Can\'t change primary key of row';
}

sub get_[% primary_key %] {
    my $self = shift;
    return $self->{[% primary_key %]};
}

sub quote_[% primary_key %] {
    return $_[1];
}

[% FOREACH col IN accessible_columns.keys.sort %]
sub [% col %] {
    my $self  = shift;
    my $value = shift;

    if ( defined $value ) { return $self->set_[% col %]( $value ); }
    else                  { return $self->get_[% col %]();         }
}

sub set_[% col %] {
    my $self  = shift;
    my $value = shift;

[% IF accessible_columns.$col.foreign %]
    if ( ref $value ) {
        $self->{[% col %]_REF} = $value;
        $self->{[% col %]}     = $value->[% primary_key %];
    }
    elsif ( defined $value ) {
        delete $self->{[% col %]_REF};
        $self->{[% col %]}     = $value;
    }
    else {
        croak 'set_[% col %] requires a value';
    }

    $self->{__DIRTY__}{[% col %]}++;

    return $value;
[% ELSE %]
    $self->{[% col %]} = $value;
    $self->{__DIRTY__}{[% col %]}++;

    return $value;
[% END %]
}

sub get_[% col %] {
    my $self = shift;
[% IF accessible_columns.$col.non_essential %]

    if ( not defined $self->{[% col %]} ) {
        $self->lazy_fetch( '[% col %]' );
    }
[% END %]
[% IF accessible_columns.$col.foreign %]

    if ( not defined $self->{[% col %]_REF} ) {
        $self->{[% col %]_REF}
            = [% base_package_name %]::[% accessible_columns.$col.table %]->retrieve_by_pk(
                    $self->{[% col %]}
              );

        $self->{[% col %]}     = $self->{[% col %]_REF}->get_primary_key()
                if ( defined $self->{[% col %]_REF} );
    }

    return $self->{[% col %]_REF};
[% ELSE %][%# its not foreign so give it to them straight %]

    return $self->{[% col %]};
[% END %]
}
[% IF accessible_columns.$col.foreign %]

sub get_[% col %]_raw {
    my $self = shift;

    if ( @_ ) {
        croak 'get_[% col %]_raw is only a get accessor, pass it nothing';
    }

    return $self->{[% col %]};
}

sub quote_[% col %] {
    return 'NULL' unless defined $_[1];
    return ( ref( $_[1] ) ) ? "$_[1]" : $_[1];
}
[% ELSE %][%# not foreign key column %]

sub quote_[% col %] {
[% IF accessible_columns.$col.quote_style == 'number' %]
    return $_[1];
[% ELSIF accessible_columns.$col.quote_style == 'date' %]
    return ( defined $_[1] and $_[1] ) ? "'$_[1]'" : 'NULL';
[% ELSE %]
    return ( defined $_[1] ) ? "'$_[1]'" : 'NULL';
[% END %][%# end of quote_style cascaded if %]
}
[% END %][%# end of if foreign then generate get...raw %]

[% END %][%# end of foreach col IN accessible_columns %]
sub get_foreign_display_fields {
    return [ qw( [% foreign_display_columns %] ) ];
}

sub get_foreign_tables {
    return qw(
[% FOREACH foreign_table IN foreign_tables %]
        [% base_package_name %]::[% foreign_table +%]
[% END %]
    );
}

sub foreign_display {
    my $self = shift;

[% foreign_display_body %]
}

1;
[% END %][%# end of block gen_table_module %]
EO_TT_blocks

#-----------------------------------------------------------------
#   Methods in the Bigtop::Model::Gantry package
#-----------------------------------------------------------------

sub what_do_you_make {
    return [
        [ 'lib/AppName/Model/*.pm'     =>
            'Gantry style model stubs [safe to change]'                 ],
        [ 'lib/AppName/Model/GEN/*.pm' =>
            'Gantry style model specifications [please, do not change]' ],
        [ note => 'This backend is incompatible with other Model backends. '],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' }
    ];
}

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

sub gen_Model {
    my $class       = shift;
    my $build_dir   = shift;
    my $bigtop_tree = shift;

    # make sure the directories are ready for us
    my $model_name    = $bigtop_tree->get_appname() . '::Model';

    my ( $module_dir, @sub_dirs )
                      = Bigtop::make_module_path( $build_dir, $model_name );

    my $gen_dir       = File::Spec->catdir( $module_dir, 'GEN' );

    mkdir $gen_dir;

    # build the individual model packages
    $bigtop_tree->walk_postorder(
        'output_native_model',
        {
            module_dir => $module_dir,
            model_name => $model_name,
            lookup     => $bigtop_tree->{application}{lookup},
        },
    );

}

#-----------------------------------------------------------------
#   Packages named in the grammar
#-----------------------------------------------------------------

package sql_block;
use strict; use warnings;

#no warnings 'redefine';

sub output_native_model {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    # Skip sequences, etc.
    return unless ( $self->{__TYPE__} eq 'tables' );

    my $table_lookup = $data->{lookup}{tables}{ $self->{__NAME__} };

    if ( $table_lookup->{not_for} ) {
        foreach my $skipped_type ( @{ $table_lookup->{not_for}{__ARGS__} } ) {
            return if ( $skipped_type eq 'Model' );
        }
    }

    # get columns sets
    my $lookup       = $table_lookup->{fields};

    my $all        = $self->walk_postorder(
            'output_all_fields_native', $lookup
    );

    my $accessible_columns = {};
    my @quoted_cols;
    foreach my $column ( @{ $all } ) {
        my $col_lookup = $table_lookup->{fields}{$column};

        $accessible_columns->{ $column } = { non_essential => 1 };
        if  ( defined $col_lookup->{refers_to}
                and
              my $foreign_table = $col_lookup->{refers_to}{args}[0]
            )
        {
            $accessible_columns->{ $column }{foreign}++;
            $accessible_columns->{ $column }{table} = $foreign_table;
        }

        $accessible_columns->{ $column }{ quote_style }
            = quote_style( $col_lookup->{is}{args} );

        if ( need_to_quote( $col_lookup->{is}{args} ) ) {
            push @quoted_cols, $column;
        }
    }

    # find all fields which aren't marked non_essential
    my $essentials = $self->walk_postorder(
            'output_essential_fields_native', $lookup
    );

    foreach my $essential ( @{ $essentials } ) {
        $accessible_columns->{ $essential }{non_essential} = 0;
    }

    # deal with foreign keys
    my $foreign_tables = $self->walk_postorder(
            'output_foreign_tables_native',       $lookup
    );

    my @foreign_table_names;
    my @has_a_list;

    foreach my $entry ( @{ $foreign_tables } ) {
        my $entry_hash = { @{ $entry } };
        push @foreign_table_names, $entry_hash->{table};
        push @has_a_list,          $entry_hash;
    }

    # Gone Fishing.
    my $table           = $self->{__NAME__};
    my $module_name     = $data->{model_name} . '::' . $table;
    my $gen_pack_name   = $data->{model_name} . '::GEN::' . $table;
    my $alias           = uc $table;
    my $sequence        = $table_lookup->{sequence};
    my $foreign_display = $table_lookup->{foreign_display};

    my $sequence_name;

    if ( $sequence ) {
        $sequence_name = $sequence->{__ARGS__}[0];
    }

    my $primary_key = _find_primary_key( $table_lookup->{fields} );

    delete $accessible_columns->{ $primary_key };

    my $foreign_display_columns;
    my $foreign_display_body;

    if ( $foreign_display ) {
        my $foreign_display_cols = $foreign_display->{__ARGS__}[0];

        my @field_names          = ( $foreign_display_cols =~ /%([\w\d_]*)/g );
        $foreign_display_columns = "@field_names";

        $foreign_display_body  = _build_foreign_display_body(
            $foreign_display_cols, @field_names
        );
    }

    my $base_class;

    if ( defined $table_lookup->{model_base_class} ) {
        $base_class = $table_lookup->{model_base_class}{__ARGS__}[0];
    }

    # generate output
    my $stub_content = Bigtop::Backend::Model::Gantry::stub_table_module(
        {
            base_package_name       => $data->{model_name},
            gen_package_name        => $gen_pack_name,
            package_name            => $module_name,
            package_alias           => $alias,
        }
    );

    my $gen_content = Bigtop::Backend::Model::Gantry::gen_table_module(
        {
            base_class              => $base_class,
            base_package_name       => $data->{model_name},
            gen_package_name        => $gen_pack_name,
            package_name            => $module_name,
            package_alias           => $alias,
            table_name              => $table,
            sequence_name           => $sequence_name,
            primary_key             => $primary_key,
            foreign_display_columns => $foreign_display_columns,
            foreign_display_body    => $foreign_display_body,
            all_columns             => $all,
            essential_columns       => $essentials,
            has_a_list              => \@has_a_list,
            foreign_tables          => \@foreign_table_names,
            accessible_columns      => $accessible_columns,
            quoted_cols             => \@quoted_cols,
        }
    );

    # store it
    my $module_file = File::Spec->catfile( $data->{module_dir}, "$table.pm" );
    my $gen_dir     = File::Spec->catdir ( $data->{module_dir}, 'GEN' );
    my $gen_file    = File::Spec->catfile( $gen_dir, "$table.pm" );

    eval {
        no warnings qw( Bigtop );
        Bigtop::write_file( $module_file, $stub_content, 'no overwrite' );
    };
    warn $@ if $@;

    eval {
        Bigtop::write_file( $gen_file, $gen_content );
    };
    warn $@ if $@;
}

sub quote_style {
    my $is_args = shift;

    foreach my $arg ( @{ $is_args } ) {
        return 'number' if ( $arg =~ /^int/     );
        return 'number' if ( $arg =~ /^float/   );
        return 'number' if ( $arg =~ /^money/   );
        return 'number' if ( $arg =~ /^numeric/ );

        return 'date'   if ( $arg =~ /^date/    );
    }

    return 'string';
}

sub need_to_quote {
    my $is_args = shift;

    foreach my $arg ( @{ $is_args } ) {
        return 0 if ( $arg =~ /^int/     );
        return 0 if ( $arg =~ /^float/   );
        return 0 if ( $arg =~ /^money/   );
        return 0 if ( $arg =~ /^numeric/ );
    }

    return 1;
}

package table_element_block;
use strict; use warnings;

sub _not_for_gantry_model {
    my $field = shift;

    if ( $field->{not_for} ) {
        my $skipped_backends = $field->{not_for}{args};

        foreach my $skipped_backend ( @{ $skipped_backends } ) {
            return 1 if ( $skipped_backend eq 'Model' );
        }
    }

    return 0;
}

sub output_all_fields_native {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( ref( $self->{__BODY__} ) );

    my $field  = $data->{ $self->{__NAME__} };

    return if ( _not_for_gantry_model( $field ) );

    return [ $self->{__NAME__} ];
}

sub output_essential_fields_native {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( ref( $self->{__BODY__} ) );

    my $field  = $data->{ $self->{__NAME__} };

    if ( $field->{non_essential} ) {
        my $non_essential_value = $field->{non_essential}{args}[0];

        return if ( $non_essential_value );
    }

    return if ( _not_for_gantry_model( $field ) );

    return [ $self->{__NAME__} ];
}

sub output_foreign_tables_native {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( ref( $self->{__BODY__} ) );

    my $field  = $data->{ $self->{__NAME__} };

    if ( $field->{refers_to} ) {
        my $foreign_table_name = $field->{refers_to}{args}[0];

        return [
            [ column => $self->{__NAME__}, table => $foreign_table_name ]
        ];
    }
    return;
}

1;

__END__

=head1 NAME

Bigtop::Backend::Model::Gantry - Bigtop backend generating home made model objects

=head1 SYNOPSIS

If your bigtop file looks like this:

    config {
        base_dir `/home/user`;
        ...
        Model Gantry {}
    }
    app Name {...}

and there are tables in the app block, when you type:

    bigtop your.bigtop Model

or
    bigtop your.bigtop all

this module will make model modules which are subclasses of
Gantry::Utils::Model (which is a simplified replacement for
Class::DBI::Sweet).

All modules will live in the lib subdirectory of the app's build directory.
See Bigtop::Init::Std for an explanation of how base_dir and the
build directory are related.

=head1 DESCRIPTION

This is a Bigtop backend which generates data model modules which are
subclasses of Gantry::Utils::Model.

=head1 KEYWORDS

This module does not register any keywords.  See Bigtop::Model for
a list of keywords models understand.

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
