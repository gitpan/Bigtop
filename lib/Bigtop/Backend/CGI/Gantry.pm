package Bigtop::Backend::CGI::Gantry;

use strict;

use Bigtop::Backend::CGI;
use Inline;

sub what_do_you_make {
    return [
        [ 'app.cgi'    => 'CGI or FastCGI dispatching script' ],
        [ 'app.server' => 'Stand alone Gantry::Server [optional]' ],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },

        { keyword => 'instance',
          label   => 'Instance',
          descr   => 'Your Gantry::Conf instance '
                        .   '[requires Conf General backend]',
          type    => 'text' },

        { keyword => 'with_server',
          label   => 'Build Server',
          descr   => 'Turns on stand alone Gantry::Server generation',
          type    => 'boolean' },

        { keyword => 'server_port',
          label   => 'Server Port',
          descr   => 'Specifies the port for stand alone server '
                        .   '[ignored unless Build Server is checked]',
          type    => 'text' },
    ];
}

sub gen_CGI {
    my $class        = shift;
    my $base_dir     = shift;
    my $tree         = shift;

    my $fast_cgi     = $tree->get_config->{CGI}{fast_cgi} || 0;
    my $content      = $class->output_cgi( $tree, $fast_cgi );
    my $cgi_file     = File::Spec->catfile( $base_dir, 'app.cgi' );
    my $server_file  = File::Spec->catfile( $base_dir, 'app.server' );

    my $CGI_SCRIPT;
    unless ( open $CGI_SCRIPT, '>', $cgi_file ) {
        warn "Couldn't write file $cgi_file: $!\n";
        return;
    }

    print $CGI_SCRIPT $content->{cgi};
    close $CGI_SCRIPT or warn "Problem closing $cgi_file: $!\n";
    chmod 0755, $cgi_file;

    if ( $tree->get_config->{CGI}{with_server} ) {
        my $SERVER;
        unless ( open $SERVER, '>', $server_file ) {
            warn "Couldn't write file $server_file: $!\n";
            return;
        }

        print $SERVER $content->{server};
        close $SERVER or warn "Problem closing $server_file\n";

        chmod 0755, $server_file;
    }
}

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_BLOCKS';
[% BLOCK cgi_script %]
#!/usr/bin/perl
use strict;

[% literal %]

use CGI::Carp qw( fatalsToBrowser );

use [% app_name %] qw{ -Engine=[% engine %] -TemplateEngine=[% template_engine %] };

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
[% config %]
[% locs %]
} );

$cgi->dispatch();

if ( $cgi->{config}{debug} ) {
    foreach ( sort { $a cmp $b } keys %ENV ) {
        print "$_ $ENV{$_}<br />\n";
    }
}
[% END %][%# end of block cgi_script %]

[% BLOCK stand_alone_server %]
#!/usr/bin/perl
use strict;

[% literal %]

use lib qw( blib/lib lib );

use [% app_name %] qw{ -Engine=[% engine %] -TemplateEngine=[% template_engine %] };

use Gantry::Server;

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
[% config %]
[% locs %]
} );

my $port = shift || [% port || 8080 %];

my $server = Gantry::Server->new( $port );
$server->set_engine_object( $cgi );
$server->run();
[% END %][%# end of stand_alone_server %]

[% BLOCK fast_cgi_script %]
#!/usr/bin/perl
use strict;

use FCGI;
use CGI::Carp qw( fatalsToBrowser );

use [% app_name %] qw{ -Engine=[% engine %] -TemplateEngine=[% template_engine %] };

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
[% config %]
[% locs %]
} );

my $request = FCGI::Request();

while ( $request->Accept() >= 0 ) {

    $cgi->dispatch();

    if ( $cgi->{config}{debug} ) {
        foreach ( sort { $a cmp $b } keys %ENV ) {
            print "$_ $ENV{$_}<br />\n";
        }
    }
}
[% END %][%# end of block cgi_script %]

[% BLOCK application_loc %]
    locations => {
        '[% location %]' => '[% name %]',
[% body %]
    },
[% END %][%# end of block application_loc %]

[% BLOCK application_config %]
    config => {
[% body %]
    },
[% END %][%# end of block application_config %]

[% BLOCK controller_block_loc %]
[% IF rel_loc %]
        '[% app_location %]/[% rel_loc %]' => '[% full_name %]',
[% ELSE %]
        '[% abs_loc %]' => '[% full_name %]',
[% END %][%# end of if rel_loc %]
[% END %]

[% BLOCK config_body %]
[% FOREACH config IN configs %]
[% IF config.value.match( '^\d+$' ) %]
        [% config.name %] => [% config.value %],
[% ELSE %]
        [% config.name %] => '[% config.value %]',
[% END %][%# end of if %]
[% END %][%# end of foreach %]
[% END %][%# end of block config %]

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

sub output_cgi {
    my $class    = shift;
    my $tree     = shift;
    my $fast_cgi = shift;

    # first find the base location
    my $location_output = $tree->walk_postorder( 'output_location' );
    my $location        = $location_output->[0] || ''; # default to host root

    $location           =~ s{/+$}{};

    # now build the config and locations hashes
    my $config;
    my $locations = $tree->walk_postorder( 'output_cgi_locations', $location );
    my $literals  = $tree->walk_postorder( 'output_literal' );
    my $app_name  = $tree->get_appname();

    my $literal   = join "\n", @{ $literals };

    my $backend_block = $tree->get_config->{CGI};
    if ( defined $backend_block->{instance} ) {
        $config = [
"    config => {
        GantryConfInstance => '$backend_block->{ instance }'
    },
"
        ];
    }
    else {
        $config = $tree->walk_postorder( 'output_config' );
    }

    my $port;
    $port = $backend_block->{server_port}
            if ( defined $backend_block->{server_port} );

    my $cgi_output;

    if ( $fast_cgi ) {
        $cgi_output = Bigtop::Backend::CGI::Gantry::fast_cgi_script(
            {
                config   => join( '', @{ $config    } ),
                locs     => join( '', @{ $locations } ),
                app_name => $app_name,
                literal  => $literal,
                %{ $tree->get_config() },  # Go Fish! (think template_engine)
            }
        );
    }
    else {
        $cgi_output = Bigtop::Backend::CGI::Gantry::cgi_script(
            {
                config   => join( '', @{ $config    } ),
                locs     => join( '', @{ $locations } ),
                app_name => $app_name,
                literal  => $literal,
                %{ $tree->get_config() },  # Go Fish! (think template_engine)
            }
        );
    }

    my $server_output = Bigtop::Backend::CGI::Gantry::stand_alone_server(
        {
            config   => join( '', @{ $config    } ),
            locs     => join( '', @{ $locations } ),
            app_name => $app_name,
            literal  => $literal,
            port     => $port,
            %{ $tree->get_config() },  # Go Fish! (think template_engine)
        }
    );

    return { cgi => $cgi_output, server => $server_output };
}

package application;
use strict; use warnings;

sub output_config {
    my $self         = shift;
    my $child_output = shift;

    my $output = Bigtop::Backend::CGI::Gantry::application_config(
        {
            body => join '', @{ $child_output },
        }
    );
    return [ $output ];
}

sub output_cgi_locations {
    my $self         = shift;
    my $child_output = shift;
    my $location     = shift || '/';

    my $output = Bigtop::Backend::CGI::Gantry::application_loc(
        {
            location => $location,
            name     => $self->get_name(),
            body     => join '', @{ $child_output },
        }
    );

    return [ $output ];
}

package app_statement;
use strict; use warnings;

sub output_location {
    my $self = shift;

    return unless $self->{__KEYWORD__} eq 'location';

    my $location = $self->{__ARGS__}[0];

    return [ $location ];
}

package app_config_block;
use strict; use warnings;

sub output_config {
    my $self         = shift;
    my $child_output = shift;

    return unless $child_output;

    my $output = Bigtop::Backend::CGI::Gantry::config_body(
        {
            configs => $child_output,
        }
    );

    return [ $output ];
}

package app_config_statement;
use strict; use warnings;

sub output_config {
    my $self         = shift;

    my $output_vals = $self->{__ARGS__}->get_args();

    return [ { name => $self->{__KEY__}, value => $output_vals } ];
}

package controller_block;
use strict; use warnings;

sub output_cgi_locations {
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

    my $output = Bigtop::Backend::CGI::Gantry::controller_block_loc(
        {
            full_name     => $full_name,
            rel_loc       => $child_loc{rel_location},
            abs_loc       => $child_loc{location},
            app_location  => $location,
        }
    );

    return [ $output ];
}

package controller_statement;
use strict; use warnings;

sub output_cgi_locations {
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

package literal_block;
use strict; use warnings;

sub output_literal {
    my $self = shift;

    return $self->make_output( 'PerlTop' );
}

1;

=head1 NAME

Bigtop::CGI::Backend::Gantry - CGI dispatch script generator for the Gantry framework

=head1 SYNOPSIS

If your bigtop file includes:

    config {
        CGI Gantry {
            # optional statements:
                # to get a stand alone server:
                    with_server 1;
                # to use FastCGI instead of regular CGI:
                    fast_cgi 1;
        }
    }

and there are controllers in your app section, this module will generate
app.cgi when you type:

    bigtop app.bigtop CGI

or

    bigtop app.bigtop all

You can then directly point your httpd.conf directly to the generated
app.cgi.

=head1 DESCRIPTION

This is a Bigtop backend which generates cgi dispatching scripts for Gantry
supported apps.

=head1 KEYWORDS

This module does not register any keywords.  See Bigtop::CGI
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
