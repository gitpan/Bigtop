use strict;

use Test::More;
use Test::Files;

eval "use Gantry::Plugins::SOAPMP20";
if ( $@ ) {
    plan skip_all => 'SOAP only supported for mod_perl 2' if $@;
}
else {
    plan tests => 1;
}

use lib 't';

use Bigtop::Parser;
use Purge;  # for real_purge_dir and strip_copyright

my $play_dir = File::Spec->catdir( qw( t gantry play ) );
my $ship_dir = File::Spec->catdir( qw( t gantry playsoap ) );

Purge::real_purge_dir( $play_dir );
mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    Control         Gantry { }
}
app Apps::Checkbook {
    authors `Phil Crow` => `mail\@example.com`;
    license_text `All rights reserved.`;
    controller is base_controller {
        method do_main is base_links {}
        method site_links is links {}
    }
    controller SOAP is SOAP {
        soap_name Checkbook;
        namespace_base `www.example.com/wsdl`;
        rel_location SOAP;
        skip_test 1;
        method do_greet is SOAP {
            expects name;
            returns greeting;
        }
        method do_cube_root is SOAP {
            expects target    => `xsd:double`,
                    tolerance => `xsd:double`;
            returns answer    => `xsd:double`;
        }
    }
}
EO_Bigtop

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'Control' ],
    }
);

compare_dirs_filter_ok(
    $play_dir, $ship_dir, \&strip_copyright, 'SOAP'
);

Purge::real_purge_dir( $play_dir );
