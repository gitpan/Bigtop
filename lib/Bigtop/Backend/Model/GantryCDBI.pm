package Bigtop::Backend::Model::GantryCDBI;
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

use base '[% base_class || 'Gantry::Utils::CDBI' %]', 'Exporter';

use [% gen_package_name %];

our $[% package_alias %] = '[% package_name %]';

our @EXPORT_OK = ( '$[% package_alias %]' );

1;
[% END %]

[% BLOCK gen_table_module %]
# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package [% package_name %];
use strict; use warnings;

[% package_name %]->table   ( '[% table_name %]'     );
[% IF sequence_name %]
[% package_name %]->sequence( '[% sequence_name %]' );
[% END %]
[% package_name %]->columns ( Primary   => qw/
    [% primary_key +%]
/ );

[% package_name %]->columns ( All       => qw/
[% FOREACH column IN all_columns %]
    [% column +%]
[% END %]
/ );

[% package_name %]->columns ( Essential => qw/
[% FOREACH essential_column IN essential_columns %]
    [% essential_column +%]
[% END %]
/ );

[% FOREACH has_a IN has_a_list %]
[% package_name %]->has_a( [% has_a.column %] => '[% base_package_name %]::[% has_a.table %]' );
[% END +%]
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
[% END %]
EO_TT_blocks

#-----------------------------------------------------------------
#   Methods in the Bigtop::Model::GantryCDBI package
#-----------------------------------------------------------------

sub what_do_you_make {
    return [
        [ 'lib/AppName/Model/*.pm'     =>
            'Class::DBI style model stubs [safe to change]'                 ],
        [ 'lib/AppName/Model/GEN/*.pm' =>
            'Class::DBI style model specifications [please, do not change]' ],
        [ 'note' =>
            'This backend is incompatible with other Model backends.' ],
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
        'output_model',
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

sub output_model {
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
            'output_all_fields_cdbi', $lookup
    );
    my $essentials = $self->walk_postorder(
            'output_essential_fields_cdbi', $lookup
    );

    # deal with foreign keys
    my $foreign_tables = $self->walk_postorder(
            'output_foreign_tables_cdbi',       $lookup
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
    my $stub_content = Bigtop::Backend::Model::GantryCDBI::stub_table_module(
        {
            base_class              => $base_class,
            base_package_name       => $data->{model_name},
            gen_package_name        => $gen_pack_name,
            package_name            => $module_name,
            package_alias           => $alias,
        }
    );

    my $gen_content = Bigtop::Backend::Model::GantryCDBI::gen_table_module(
        {
            base_package_name       => $data->{model_name},
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

package table_element_block;
use strict; use warnings;

sub output_all_fields_cdbi {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( ref( $self->{__BODY__} ) );

    my $field  = $data->{ $self->{__NAME__} };

    return if ( _not_for_model( $field ) );

    return [ $self->{__NAME__} ];
}

sub output_essential_fields_cdbi {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( ref( $self->{__BODY__} ) );

    my $field  = $data->{ $self->{__NAME__} };

    if ( $field->{non_essential} ) {
        my $non_essential_value = $field->{non_essential}{args}[0];

        return if ( $non_essential_value );
    }

    return if ( _not_for_model( $field ) );

    return [ $self->{__NAME__} ];
}

sub output_foreign_tables_cdbi {
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

Bigtop::Backend::Model::GantryCDBI - Bigtop backend generating Class::DBI::Sweet models

=head1 SYNOPSIS

If your bigtop file looks like this:

    config {
        base_dir `/home/user`;
        ...
        Model GantryCDBI {}
    }
    app Name {...}

and there are tables in the app block, when you type:

    bigtop your.bigtop Model

or
    bigtop your.bigtop all

this module will make model modules which are subclasses of
Gantry::Utils::CDBI (which inherits from Class::DBI::Sweet in a
mod_perl safe way).

All modules will live in the lib subdirectory of the app's build directory.
See Bigtop::Init::Std for an explanation of how base_dir and the
build directory are related.

=head1 DESCRIPTION

This is a Bigtop backend which generates data model modules which are
subclasses of Gantry::Utils::CDBI.

=head1 KEYWORDS

This module does not register any keywords.  See Bigtop::Model for
a list of keywords models understand.

The default for the model_base_class keyword is Gantry::Utils::CDBI.

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
