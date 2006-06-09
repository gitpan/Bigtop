use strict;

use File::Spec;
use lib File::Spec->catdir( 'lib' );

use Module::Build;

my $subclass = Module::Build->subclass(
    class   => 'Bigtop::Builder',
    code    => &_custom_code(),
);

my $build = $subclass->new(
    module_name         => 'Bigtop',
    license             => 'perl',
    create_makefile_pl  => 'passthrough',
    requires            => {
        'Config::General' => 0,
        'Template'        => 2.0,
        'Inline'          => 0.40,
        'Inline::TT'      => 0.06,
    },
    build_requires      => {
        'Test'        => 0,
        'Test::More'  => 0,
        'Test::Warn'  => 0,
        'Test::Files' => 0,
    },
    script_files        => [ glob( 'scripts/*' ) ],
    tentmaker_files     => [ glob( 'tenttemplates/*' ) ],
    test_files          => [
        't/*.t',
        't/tentmaker/*.t',
        't/init/*.t',
        't/postgres/*.t',
        't/sqlite/*.t',
        't/mysql/*.t',
        't/gantry/*.t',
        't/sitelook/*.t',
        't/ganmodel/*.t',
        't/dbixclass/*.t',
        't/cdbi/*.t',
        't/cleanup/*.t',
	],
);

eval { require Gantry; };
my $try_for_tentmaker = ( $@ ) ? 0 : 1;

if ( $try_for_tentmaker ) {

    print "\n\nBigtop has an editor called tentmaker.  It allows\n";
    print "you to edit bigtop files with a DOM compatible browser\n";
    print "(like Firefox).  tentmaker requires some templates.\n\n";

    my $install_tentmaker = $build->y_n(
            "Do you want to install the tentmaker templates?",
            'y'
    );
    $build->notes( install_tentmaker => $install_tentmaker );

    if ( $install_tentmaker ) {
        print "\n\nTentMaker needs to store some templates on your system.\n";
        print "Please choose a location for them.\n\n";

        my $tentmaker_template_path = $build->prompt(
            "Path for TentMaker templates",
            '/usr/local/share/TentMaker'
        );
        $build->notes( tentmaker_template_path => $tentmaker_template_path );

        # Write a module which tentmaker can use to find its templates.
        my $tent_path_module = File::Spec->catfile(
                                    qw( lib Bigtop TentMakerPath.pm )
                                );

        my $template_dir;

        if ( open my $TENT_PATH, '>', $tent_path_module ) {
            print $TENT_PATH <<"EO_TENT_PATH";
package Bigtop::TentMakerPath;
use strict;

sub get_template_path {
    return '$tentmaker_template_path';
}

1;
EO_TENT_PATH
            close $TENT_PATH;
        }
    }
}
else {
    print "\n\n  Bigtop has an editor called tentmaker.  You need to\n";
    print "  install Gantry, AND re-run Build.PL, in order to use it.\n\n\n";
    $build->notes( install_tentmaker => 0 );
}

$build->create_build_script;

sub _custom_code {
    return q{
        sub ACTION_install {
            my $self = shift;

            $self->SUPER::ACTION_install();

            return unless ( $self->notes( 'install_tentmaker' ) );

            my $props = $self->{properties};
            my $files = $props->{tentmaker_files};

            my $path  = $self->notes( 'tentmaker_template_path' );
            foreach my $file ( @{ $files } ) {
                $self->copy_if_modified( $file, $path );
            }
        }
    };
}
