package Bigtop::Backend::HttpdConf::Gantry;

use Bigtop::Backend::HttpdConf;
use Inline;

sub what_do_you_make {
    return [
        [ 'docs/httpd.conf' => 'Include file for mod_perl apache conf' ],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },

        { keyword => 'instance',
          label   => 'Conf Instance',
          descr   => 'Your Gantry::Conf instance '
                        .   '[use with skip_config; '
                        .   'requires Conf General backend]',
          type    => 'text' },

        { keyword => 'conffile',
          label   => 'Conf File',
          descr   => 'Replacement for /etc/gantry.conf '
                        .   '[use with Conf Instance]',
          type    => 'text' },

        { keyword => 'full_use',
          label   => 'Full Use Statement',
          descr   => 'use Gantry qw( -Engine=... ); [defaults to true]',
          type    => 'boolean',
          default => 'true'},

        { keyword => 'skip_config',
          label   => 'Skip Config',
          descr   => 'do not generate PerlSetVar statements',
          type    => 'boolean' },

        { keyword => 'gen_root',
          label   => 'Generate Root Path',
          descr   => q!Adds a root => 'html' statement to config!,
          type    => 'boolean' },

        { keyword => 'template',
          label   => 'Alternate Template',
          descr   => 'A custom TT template.',
          type    => 'text' },
    ];
}

sub gen_HttpdConf {
    my $class         = shift;
    my $base_dir      = shift;
    my $tree          = shift;

    my $conf_content  = $class->output_httpd_conf( $tree );

    my $docs_dir      = File::Spec->catdir( $base_dir, 'docs' );
    mkdir $docs_dir;

    my $conf_file     = File::Spec->catfile( $docs_dir, 'httpd.conf' );

    my $CONF;
    unless ( open $CONF, '>', $conf_file ) {
        warn "Couldn't write file $conf_file: $!\n";
        return;
    }

    print $CONF $conf_content;

    close $CONF or warn "Problem closing $conf_file: $!\n";
}

sub output_httpd_conf {
    my $class = shift;
    my $tree  = shift;

    my $skip_config = $tree->get_config->{HttpdConf}{skip_config} || 0;
    my $instance    = $tree->get_config->{HttpdConf}{instance   } || 0;
    my $conffile    = $tree->get_config->{HttpdConf}{conffile   } || 0;
    my $gen_root    = $tree->get_config->{HttpdConf}{gen_root   } || 0;

    # first find the base location
    my $location_output = $tree->walk_postorder( 'output_httpd_conf_loc' );
    my $location        = $location_output->[0] || ''; # default to host root
    $location           =~ s{/+$}{};

    # now build the <Perl> and <Location> blocks
    my $perl_block_lines = $tree->walk_postorder(
            'output_perl_block',
            $tree->get_config()
    );
    my $locations        = $tree->walk_postorder(
            'output_httpd_conf_locations',
            {
                location    => $location,
                skip_config => $skip_config,
                instance    => $instance,
                conffile    => $conffile,
                gen_root    => $gen_root,
            }
    );

    return Bigtop::Backend::HttpdConf::Gantry::conf_file(
        {
            perl_block_lines => $perl_block_lines,
            locations        => $locations,
        }
    );
}

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_BLOCKS';
[% BLOCK conf_file %]
[% FOREACH line IN perl_block_lines %]
[% line %]
[% END %][%# end of foreach line in perl_block_lines %]

[% FOREACH line IN locations %]
[% line %]
[% END %][%# end of foreach line in locations %]
[% END %]

[% BLOCK perl_block %]
<Perl>
    #!/usr/bin/perl

[% FOREACH line IN top_lines %]
[% line %]
[% END %]
[% IF full_base_use %]
    use [% base_module %] qw{[% IF engine %] -Engine=[% engine %][% END %][% IF template_engine %] -TemplateEngine=[% template_engine %][% END %] };
[% ELSE %]
    use [% base_module %];
[% END %]
[% FOREACH line IN child_output %]
[% line %]
[% END %]
</Perl>
[% END %]

[% BLOCK all_locations %]
<Location [% root_loc %]>
[% FOREACH config IN configs %][% config %][% END %]
[% FOREACH literal IN literals %][% literal %][% END %]
</Location>

[% FOREACH child_piece IN child_output %][% child_piece %][% END %]
[% END %][%# all_locations %]

[% BLOCK config %]
    PerlSetVar [% var %] [% value %]

[% END %]

[% BLOCK sub_locations %]
<Location [% loc %]>
    SetHandler  perl-script
    PerlHandler [% handler %]
[% FOREACH config IN loc_configs %]

[% config %]
[% END %]
[% IF literal %]

[% literal %]
[% END %]

</Location>

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

# application
package # application
    application;
use strict; use warnings;

sub output_perl_block {
    my $self         = shift;
    my $child_output = shift;
    my $config       = shift;

    my $base_module  = $self->get_name();

    my @top_lines;
    my @regular_lines;

    foreach my $child_hash ( @{ $child_output } ) {
        my ( $key, $value ) = each %{ $child_hash };

        if ( $key eq 'PerlTop' ) { push @top_lines,     $value; }
        else                     { push @regular_lines, $value; }
    }

    my $backend_config      = $config->{HttpdConf};
    my $full_base_use       = 1;

    if ( defined $backend_config->{full_use}
            and
         not $backend_config->{full_use} )
    {
        $full_base_use      = 0;
    }

    my $output = Bigtop::Backend::HttpdConf::Gantry::perl_block(
        {
            base_module   => $base_module,
            child_output  => \@regular_lines,
            top_lines     => \@top_lines,
            full_base_use => $full_base_use,
            %{ $config }, # in case full use is true
        }
    );

    return [ $output ];
}

sub output_httpd_conf_locations {
    my $self          = shift;
    my $child_output  = shift;
    my $data          = shift;
    my $location      = $data->{location};
    my $skip_config   = $data->{skip_config};
    my $gen_root      = $data->{gen_root};

    # handle configs at root location
    my $configs;
    if ( $skip_config ) {
        if ( $data->{ instance } ) {
            $configs .= Bigtop::Backend::HttpdConf::Gantry::config(
                {
                    var   => 'GantryConfInstance',
                    value => $data->{ instance },
                }
            );
            if ( $data->{ conffile } ) {
                $configs .= Bigtop::Backend::HttpdConf::Gantry::config(
                    {
                        var   => 'GantryConfFile',
                        value => $data->{ conffile },
                    }
                );
            }
        }
    }
    else {
        $configs  = $self->walk_postorder( 'output_configs', $gen_root );
    }
    my $literals = $self->walk_postorder( 'output_root_literal' );

    my $output   = Bigtop::Backend::HttpdConf::Gantry::all_locations(
        {
            root_loc     => $location || '/',
            configs      => $configs,
            literals     => $literals,
            child_output => $child_output,
        }
    );

    return [ $output ];
}

package # app_statement
    app_statement;
use strict; use warnings;

sub output_httpd_conf_loc {
    my $self = shift;

    return unless $self->{__KEYWORD__} eq 'location';

    my $location = $self->{__ARGS__}[0];

    return [ $location ];
}

# app_config_block
package # app_config_block
    app_config_block;
use strict; use warnings;

sub output_configs {
    my $self         = shift;
    my $child_output = shift;
    my $gen_root     = shift;

    return unless $child_output;

    my $output;

    foreach my $config ( @{ $child_output } ) {
        $output .= Bigtop::Backend::HttpdConf::Gantry::config(
            {
                var   => $config->{__KEYWORD__},
                value => $config->{__ARGS__},
            }
        );
    }

    if ( defined $gen_root and $gen_root ) {
        $output .= Bigtop::Backend::HttpdConf::Gantry::config(
            {
                var   => 'root',
                value => 'html',
            }
        );
    }

    return [ $output ];
}

package # app_config_statement
    app_config_statement;
use strict; use warnings;

sub output_configs {
    my $self         = shift;

    my $output_vals = $self->{__ARGS__}->get_args();

    return [ {
            __KEYWORD__ => $self->{__KEYWORD__},
            __ARGS__    => $output_vals
    } ];
}

package # literal_block
    literal_block;
use strict; use warnings;

sub output_perl_block {
    my $self = shift;

    my $retval = $self->make_output( 'PerlBlock', 'I want a hash' );

    return $retval if $retval;

    return $self->make_output( 'PerlTop', 'I want a hash' );
}

sub output_root_literal {
    my $self = shift;

    return $self->make_output( 'Location' );
}

sub output_httpd_conf_locations {
    my $self = shift;

    return $self->make_output( 'HttpdConf' );
}

# controller_block
package # controller_block
    controller_block;
use strict; use warnings;

sub output_perl_block {
    my $self         = shift;
    my $app          = $self->{__PARENT__}{__PARENT__}{__PARENT__};
    my $full_name    = $app->get_name() . '::' . $self->get_name();

    return [ { PerlBlock => ' ' x 4 . "use $full_name;\n" } ];
}

sub output_httpd_conf_locations {
    my $self         = shift;
    my $child_output = shift;
    my $data          = shift;
    my $location      = $data->{location};
    my $skip_config   = $data->{skip_config};

    my %child_loc    = @{ $child_output };

    if ( keys %child_loc != 1 ) {
        die "Error: controller '" . $self->get_name()
            . "' must have one location or rel_location statement.\n";
    }

    my $app          = $self->{__PARENT__}{__PARENT__}{__PARENT__};
    my $full_name    = $app->get_name() . '::' . $self->get_name();

    my $loc_configs  = $self->walk_postorder(
            'output_controller_configs', $skip_config
    );

    my $literals     = $self->walk_postorder( 'output_location_literal' );

    my $child_location;

    if ( defined $child_loc{rel_location} ) {
        $child_location = "$location/$child_loc{rel_location}";
    }
    else { # must be location
        $child_location = $child_loc{location};
    }

    my $output = Bigtop::Backend::HttpdConf::Gantry::sub_locations(
        {
            loc          => $child_location,
            literal      => join( "\n", @{ $literals } ),
            handler      => $full_name,
            loc_configs  => $loc_configs,
        }
    );

    return [ $output ];
}

# controller_statement
package # controller_statement
    controller_statement;
use strict; use warnings;

sub output_httpd_conf_locations {
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

# controller_config_block
package # controller_config_block
    controller_config_block;
use strict; use warnings;

sub output_controller_configs {
    my $self          = shift;
    my $child_output  = shift;
    my $skip_config   = shift;

    return unless $child_output;
    return if     $skip_config;

    my $output;

    foreach my $config ( @{ $child_output } ) {
        $output .= Bigtop::Backend::HttpdConf::Gantry::config(
            {
                var   => $config->{__KEYWORD__},
                value => $config->{__ARGS__},
            }
        );
    }

    return [ $output ];
}

package # controller_config_statement
    controller_config_statement;
use strict; use warnings;

sub output_controller_configs {
    my $self         = shift;

    my $output_vals = $self->{__ARGS__}->get_args();

    return [ {
            __KEYWORD__ => $self->{__KEYWORD__},
            __ARGS__    => $output_vals
    } ];
}

# controller_literal_block
package # controller_literal_block
    controller_literal_block;
use strict; use warnings;

sub output_location_literal {
    my $self = shift;

    return $self->make_output( 'Location' );
}

1;

=head1 NAME

Bigtop::Backend::HttpdConf::Gantry - httpd.conf generator for the Gantry framework

=head1 SYNOPSIS

If your bigtop file includes:

    config {
        HttpdConf Gantry {}
    }

and there are controllers in your app section, this module will generate
docs/httpd.conf when you type:

    bigtop app.bigtop HttpdConf

or

    bigtop app.bigtop all

You can then directly Include this conf in your system httpd.conf or in one
of its virtual hosts.

=head1 DESCRIPTION

This is a Bigtop backend which generates httpd.conf files.

By default, this module converts every statement in an app or controller
level config block into a PerlSetVar statement.  If you have a different
conf scheme in mind (like Gantry::Conf with flat files), you may not want
to define those set vars.  In that, case do this in the Bigtop config section:

    config {
        HttpdConf Gantry { skip_config 1; }
    }

Any PerlSetVar statements you put in literal Location statements will
still appear (remember: literal means literal).  But, no PerlSetVar statements
will be made by the module.

=head1 KEYWORDS

This module does not register any keywords.  See Bigtop::HttpdConf
for a list of allowed keywords (think app and controller level 'location'
and controller level 'rel_location' statements).

=head1 METHODS

To keep podcoverage tests happy.

=over 4

=item backend_block_keywords

Tells tentmaker that I understand these config section backend block keywords:

    no_gen
    instance
    conffile
    gen_root
    full_use
    skip_config
    template

=item what_do_you_make
    
Tells tentmaker what this module makes.  Summary: docs/httpd.conf.

=item gen_HttpdConf

Called by Bigtop::Parser to get me to do my thing.

=item output_httpd_conf

What I call on the AST packages to do my thing.

=item setup_template

Called by Bigtop::Parser so the user can substitute an alternate template
for the hard coded one here.

=back

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
