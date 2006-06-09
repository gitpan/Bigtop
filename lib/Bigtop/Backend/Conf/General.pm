package Bigtop::Backend::Conf::General;

use Bigtop::Backend::Conf;
use Inline;

sub what_do_you_make {
    return [
        [ 'docs/AppName.conf'
                => 'Your config info in Config::General format' ],
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

sub gen_Conf {
    my $class        = shift;
    my $base_dir     = shift;
    my $tree         = shift;

    my $conf_content = $class->output_conf( $tree );

    my $docs_dir     = File::Spec->catdir( $base_dir, 'docs' );
    mkdir $docs_dir;

    my $app_name     = $tree->get_appname();
    $app_name        =~ s/::/-/g;
    my $conf_file    = File::Spec->catfile( $docs_dir, "$app_name.conf" );

    my $CONF;
    unless ( open $CONF, '>', $conf_file ) {
        warn "Couldn't write file $conf_file: $!\n";
        return;
    }

    print $CONF $conf_content;

    close $CONF or warn "Problem closing $conf_file: $!\n";
}

sub output_conf {
    my $class = shift;
    my $tree  = shift;

    # first find the base location
    my $location_output = $tree->walk_postorder( 'output_base_location' );
    my $location        = $location_output->[0] || '';

    # now build the <GantryLocation> blocks
    my $locations        = $tree->walk_postorder(
            'output_gantry_locations', $location
    );

    return Bigtop::Backend::Conf::General::conf_file(
        {
            locations        => $locations,
        }
    );
}

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_BLOCKS';
[% BLOCK conf_file %]
[% FOREACH line IN locations %]
[% line %]
[% END %][%# end of foreach line in locations %]
[% END %]

[% BLOCK all_locations %]
[% FOREACH config IN configs %][% config %][% END %]
[% FOREACH literal IN literals %][% literal %][% END %]

[% FOREACH child_piece IN child_output %][% child_piece %][% END %]
[% END %][%# all_locations %]

[% BLOCK config %]
[% IF indent %]    [% END %][% var %] [% value %]

[% END %]

[% BLOCK sub_locations %]
<GantryLocation [% loc %]>
[% FOREACH config IN loc_configs %]
[% config %][% END %]
</GantryLocation>

[% END %]
EO_TT_BLOCKS

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

package # application
    application;
use strict; use warnings;

sub output_gantry_locations {
    my $self         = shift;
    my $child_output = shift;
    my $location     = shift || '/';

    # handle set vars at root location
    my $setvars  = $self->walk_postorder( 'output_setvars' );
    my $literals = $self->walk_postorder( 'output_top_level_literal' );

    my $output   = Bigtop::Backend::Conf::General::all_locations(
        {
            root_loc     => $location,
            configs      => $setvars,
            literals     => $literals,
            child_output => $child_output,
        }
    );

    return [ $output ];
}

package # app_statement
    app_statement;
use strict; use warnings;

sub output_base_location {
    my $self = shift;

    return unless $self->{__KEYWORD__} eq 'location';

    my $location = $self->{__ARGS__}[0];

    return [ $location ];
}

package # app_config_block
    app_config_block;
use strict; use warnings;

sub output_setvars {
    my $self         = shift;
    my $child_output = shift;

    return unless $child_output;

    my $output;

    foreach my $config ( @{ $child_output } ) {
        $output .= Bigtop::Backend::Conf::General::config(
            {
                var   => $config->{__NAME__},
                value => $config->{__VALUE__},
            }
        );
    }

    return [ $output ];
}

package # app_config_statement
    app_config_statement;
use strict; use warnings;

sub output_setvars {
    my $self         = shift;

    my $output_vals = $self->{__ARGS__}->get_args();

    return [ { __NAME__ => $self->{__KEY__}, __VALUE__ => $output_vals } ];
}

package # literal_block
    literal_block;
use strict; use warnings;

sub output_top_level_literal {
    my $self = shift;

    return $self->make_output( 'GantryLocation' );
}

sub output_gantry_locations {
    my $self = shift;

    return $self->make_output( 'Conf' );
}

package # controller_block
    controller_block;
use strict; use warnings;

sub output_gantry_locations {
    my $self         = shift;
    my $child_output = shift;
    my $location     = shift;

    my %child_loc    = @{ $child_output };

    if ( keys %child_loc != 1 ) {
        die "Error: controller '" . $self->get_name()
            . "' must have one location or rel_location statement.\n";
    }

    my $app          = $self->{__PARENT__}{__PARENT__}{__PARENT__};
    my $full_name    = $app->get_name() . '::' . $self->get_name();

    my $loc_configs
            = $self->walk_postorder( 'output_gantry_location_configs' );

    my $literals     = $self->walk_postorder(
                            'output_gantry_location_literal'
                       );

    my $child_location;

    if ( defined $child_loc{rel_location} ) {
        $child_location = "$location/$child_loc{rel_location}";
    }
    else { # must be location
        $child_location = $child_loc{location};
    }

    return unless ( @{ $loc_configs } );

    my $output = Bigtop::Backend::Conf::General::sub_locations(
        {
            loc          => $child_location,
            literal      => join( "\n", @{ $literals } ),
            handler      => $full_name,
            loc_configs  => $loc_configs,
        }
    );

    return [ $output ];
}

package # controller_statement
    controller_statement;
use strict; use warnings;

sub output_gantry_locations {
    my $self         = shift;

    if ( $self->{__KEYWORD__} eq 'rel_location' ) {
        return [ rel_location => $self->{__ARGS__}->get_first_arg() ];
    }
    elsif ( $self->{__KEYWORD__} eq 'location' ) {
        return [ location => $self->{__ARGS__}->get_first_arg() ];
    }
    else {
        return;
    }
}

package # controller_config_block
    controller_config_block;
use strict; use warnings;

sub output_gantry_location_configs {
    my $self         = shift;
    my $child_output = shift;

    return unless $child_output;

    my $output;

    foreach my $config ( @{ $child_output } ) {
        $output .= Bigtop::Backend::Conf::General::config(
            {
                var    => $config->{__NAME__},
                value  => $config->{__VALUE__},
                indent => 1,
            }
        );
    }

    return [ $output ];
}

package # controller_config_statement
    controller_config_statement;
use strict; use warnings;

sub output_gantry_location_configs {
    my $self         = shift;

    my $output_vals = $self->{__ARGS__}->get_args();

    return [ { __NAME__ => $self->{__KEY__}, __VALUE__ => $output_vals } ];
}

package # controller_literal_block
    controller_literal_block;
use strict; use warnings;

sub output_gantry_location_literal {
    my $self = shift;

    my $retval = $self->make_output( 'GantryLocation' );

    return $self->make_output( 'GantryLocation' );
}

1;

=head1 NAME

Bigtop::Backend::Conf::General - makes Config::General conf files

=head1 SYNOPSIS

If your bigtop file includes:

    config {
        Conf General {}
    }

and there are controllers in your app section, this module will generate
docs/httpd.conf when you type:

    bigtop app.bigtop Conf

or

    bigtop app.bigtop all

You can then directly Include this conf in your system httpd.conf or in one
of its virtual hosts.

=head1 DESCRIPTION

This is a Bigtop backend which generates gantry.conf files.  These
have the format of Config::General.

=head1 KEYWORDS

This module does not register any keywords.  See Bigtop::Conf
for a list of allowed keywords (think app and controller level 'location'
and controller level 'rel_location' statements).

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
