package Bigtop::Deparser;
use strict; use warnings;

sub deparse {
    my $class = shift;
    my $ast   = shift;

    my $source;

    # Do the config section.
    $source  = "config {\n";

    my $config = $ast->get_config;

    foreach my $statement ( @{ $config->{__STATEMENTS__} } ) {
        my ( $keyword, $value ) = @{ $statement };

        if ( ref( $value ) eq 'HASH' ) {
            my $type    = $keyword;
            my $backend = $value->{__NAME__};

            my $content = _get_backend_block_content( $value );

            $source .= "    $type $backend { $content }\n";
        }
        else {
            $source .= "    $keyword $value;\n";
        }
    }

    $source .= "}\n";

    # Use walk_postorder to do the app section.
    my $app_elements = $ast->walk_postorder( 'output_app_body' );
    my $app_body     = join "\n", @{ $app_elements };

    $source .= 'app ' . $ast->get_appname() . " {\n";
    $source .= "$app_body\n";
    $source .= "}\n";

    return $source;
}

sub _get_backend_block_content {
    my $backend_hash = shift;

    my @statements;

    STATEMENT:
    foreach my $statement ( keys %{ $backend_hash } ) {
        next STATEMENT if $statement eq '__NAME__';

        my $value = $backend_hash->{ $statement };

        unless ( $value =~ /^\w[\w\d_]*$/ ) {
            $value = "`$value`";
        }

        push @statements, "$statement $value;";
    }

    return join ' ', @statements;
}

package app_statement;
use strict; use warnings;

sub output_app_body {
    my $self = shift;

    my $retval = "    $self->{__KEYWORD__} ";

    $retval   .= $self->{__ARGS__}->get_quoted_args . ';';

    return [ $retval ];

}

package app_config_block;
use strict; use warnings;

sub output_app_body {
    my $self          = shift;
    my $child_output  = shift;

    my $block_content = join "\n", @{ $child_output };

    my $retval = qq(    config {
$block_content
    });

    return [ $retval ];
}

package app_config_statement;
use strict; use warnings;

sub output_app_body {
    my $self    = shift;

    my $retval  = "        $self->{__KEY__} ";
    $retval    .= $self->{__ARGS__}->get_quoted_args . ';';

    return [ $retval ];
}

package sql_block;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;
    my $child_output = shift;

    my $retval;

    if ( $self->{__TYPE__} eq 'sequences' ) {
        $retval = "    sequence $self->{__NAME__} {}";
    }
    else {
        $retval  = "    table $self->{__NAME__} {\n";
        $retval .= join "\n", @{ $child_output };
        $retval .= "\n    }";
    }

    return [ $retval ];

}

package table_element_block;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;
    my $child_output = shift;

    my $retval;

    if ( $self->{__TYPE__} eq 'field' ) {
        $retval  = "        field $self->{__NAME__} {\n";
        $retval .= join "\n", @{ $child_output };
        $retval .= "\n        }";
    }
    else {
        my $args = $self->{__VALUE__}->get_quoted_args;
        $retval  = "        $self->{__TYPE__} $args;";
    }

    return [ $retval ];
}

package field_statement;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;
    my $child_output = shift;

    my $retval = ' ' x 12 . "$self->{__NAME__} ";
    $retval   .= join( '', @{ $child_output } ) . ';';

    return [ $retval ];
}

package field_statement_def;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;

    return [ $self->{__ARGS__}->get_quoted_args ];
}

package controller_block;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;
    my $child_output = shift;

    my $retval;

    my $is_type = $self->{__TYPE__}[0] || '';
    $is_type    = ( $is_type ) ? " is $is_type " : ' ';

    $retval  = "    controller $self->{__NAME__}$is_type\{\n";
    $retval .= join "\n", @{ $child_output };
    $retval .= "\n    }";

    return [ $retval ];
}

package controller_statement;
use strict; use warnings;

sub output_app_body {
    my $self    = shift;

    my $retval  = "        $self->{__KEYWORD__} ";
    $retval    .= $self->{__ARGS__}->get_quoted_args . ';';

    return [ $retval ];
}

package controller_method;
use strict; use warnings;

sub output_app_body {
    my $self          = shift;
    my $child_output  = shift;

    my $block_content = join "\n", @{ $child_output };

    my $type = '';

    my $retval = qq(        method $self->{__NAME__} is $self->{__TYPE__} {
$block_content
        });

    return [ $retval ];
}

package method_statement;
use strict; use warnings;

sub output_app_body {
    my $self          = shift;

    my $retval  = "            $self->{__KEY__} ";
    $retval    .= $self->{__ARGS__}->get_quoted_args . ';';

    return [ $retval ];
}

package literal_block;
use strict; use warnings;

sub output_app_body {
    my $self = shift;

    my $retval = "    literal $self->{__BACKEND__}\n";
    $retval   .= "      `$self->{__BODY__}`;\n";

    return [ $retval ];
}

1;

=head1 NAME

Bigtop::Deparse - given an AST, makes a corresponding bigtop source file

=head1 SYNOPSIS

    use Bigtop::Deparser;

    my $source = Bigtop::Deparser->deparse( $ast );

=head1 DESCRIPTION

This module support TentMaker.  It takes an ast as built by Bigtop::Parser.

=head1 AUTHOR

Phil Crow, E<lt>philcrow2000@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
