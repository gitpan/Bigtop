use strict;

use Test::More tests => 5;
use Test::Files;

use File::Spec;

use Bigtop::Parser qw/CGI=Gantry Control=Gantry/;

my $bigtop_string;
my $tree;
my $correct_script;
my $base_dir   = File::Spec->catdir( 't', 'gantry' );
my $script     = File::Spec->catfile( $base_dir, 'app.cgi' );
my $server     = File::Spec->catfile( $base_dir, 'app.server' );

#---------------------------------------------------------------------------
# regular cgi dispatching script
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_correct_bigtop';
config {
    engine          CGI;
    template_engine TT;
    CGI Gantry { with_server 1; }
}
app Apps::Checkbook {
    location `/app_base`;
    literal PerlTop `use lib '/path/to/my/lib';`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    controller PayeeOr {
        rel_location   payee;
    }
    controller Trans {
        location       `/foreign_loc/trans`;
    }
}
EO_correct_bigtop

$tree = Bigtop::Parser->parse_string( $bigtop_string );

Bigtop::Backend::CGI::Gantry->gen_CGI( $base_dir, $tree );

$correct_script = <<'EO_CORRECT_SCRIPT';
#!/usr/bin/perl
use strict;

use lib '/path/to/my/lib';

use CGI::Carp qw( fatalsToBrowser );

use Apps::Checkbook qw{ -Engine=CGI -TemplateEngine=TT };

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        DB => 'app_db',
        DBName => 'some_user',
    },
    locations => {
        '/app_base' => 'Apps::Checkbook',
        '/app_base/payee' => 'Apps::Checkbook::PayeeOr',
        '/foreign_loc/trans' => 'Apps::Checkbook::Trans',
    },
} );

$cgi->dispatch();

if ( $cgi->{config}{debug} ) {
    foreach ( sort { $a cmp $b } keys %ENV ) {
        print "$_ $ENV{$_}<br />\n";
    }
}
EO_CORRECT_SCRIPT

file_ok( $script, $correct_script, 'cgi dispatch script' );

unlink $script;

#---------------------------------------------------------------------------
# stand alone server
#---------------------------------------------------------------------------

my $correct_server = <<'EO_CORRECT_SERVER';
#!/usr/bin/perl
use strict;

use lib '/path/to/my/lib';

use lib qw( blib/lib lib );

use Apps::Checkbook qw{ -Engine=CGI -TemplateEngine=TT };

use Gantry::Server;

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        DB => 'app_db',
        DBName => 'some_user',
    },
    locations => {
        '/app_base' => 'Apps::Checkbook',
        '/app_base/payee' => 'Apps::Checkbook::PayeeOr',
        '/foreign_loc/trans' => 'Apps::Checkbook::Trans',
    },
} );

my $port = shift || 8080;

my $server = Gantry::Server->new( $port );
$server->set_engine_object( $cgi );
$server->run();
EO_CORRECT_SERVER

file_ok( $server, $correct_server, 'stand alone server' );

unlink $server;

#-------------------------------------------------------------------------
# fast cgi
#-------------------------------------------------------------------------
$bigtop_string = << 'EO_second_bigtop';
config {
    engine FastCGI;
    template_engine TT;
    CGI Gantry { fast_cgi 1; }
}
app Apps::Checkbook {
    location `/`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    controller PayeeOr {
        rel_location   payee;
    }
    controller Trans {
        rel_location   trans;
    }
}
EO_second_bigtop

$tree = Bigtop::Parser->parse_string( $bigtop_string );

Bigtop::Backend::CGI::Gantry->gen_CGI( $base_dir, $tree );

$correct_script = <<'EO_CORRECT_FAST_CGI';
#!/usr/bin/perl
use strict;

use FCGI;
use CGI::Carp qw( fatalsToBrowser );

use Apps::Checkbook qw{ -Engine=FastCGI -TemplateEngine=TT };

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        DB => 'app_db',
        DBName => 'some_user',
    },
    locations => {
        '/' => 'Apps::Checkbook',
        '/payee' => 'Apps::Checkbook::PayeeOr',
        '/trans' => 'Apps::Checkbook::Trans',
    },
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
EO_CORRECT_FAST_CGI

file_ok( $script, $correct_script, 'fast cgi dispatch script' );

unlink $script;

#---------------------------------------------------------------------------
# CGI with Gantry::Conf
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_gantry_conf';
config {
    engine          CGI;
    template_engine TT;
    CGI Gantry {
        instance    tinker;
        with_server 1;
        server_port 8192;
    }
}
app Apps::Checkbook {
    location `/app_base`;
    literal PerlTop `use lib '/path/to/my/lib';`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    controller PayeeOr {
        rel_location   payee;
    }
    controller Trans {
        location       `/foreign_loc/trans`;
    }
}
EO_gantry_conf

$tree = Bigtop::Parser->parse_string( $bigtop_string );

Bigtop::Backend::CGI::Gantry->gen_CGI( $base_dir, $tree );

$correct_script = <<'EO_CORRECT_SCRIPT';
#!/usr/bin/perl
use strict;

use lib '/path/to/my/lib';

use CGI::Carp qw( fatalsToBrowser );

use Apps::Checkbook qw{ -Engine=CGI -TemplateEngine=TT };

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        GantryConfInstance => 'tinker'
    },
    locations => {
        '/app_base' => 'Apps::Checkbook',
        '/app_base/payee' => 'Apps::Checkbook::PayeeOr',
        '/foreign_loc/trans' => 'Apps::Checkbook::Trans',
    },
} );

$cgi->dispatch();

if ( $cgi->{config}{debug} ) {
    foreach ( sort { $a cmp $b } keys %ENV ) {
        print "$_ $ENV{$_}<br />\n";
    }
}
EO_CORRECT_SCRIPT

file_ok( $script, $correct_script, 'cgi with Gantry::Conf' );

unlink $script;

#---------------------------------------------------------------------------
# stand alone server custom port
#---------------------------------------------------------------------------

$correct_server = <<'EO_SERVER_PORT';
#!/usr/bin/perl
use strict;

use lib '/path/to/my/lib';

use lib qw( blib/lib lib );

use Apps::Checkbook qw{ -Engine=CGI -TemplateEngine=TT };

use Gantry::Server;

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        GantryConfInstance => 'tinker'
    },
    locations => {
        '/app_base' => 'Apps::Checkbook',
        '/app_base/payee' => 'Apps::Checkbook::PayeeOr',
        '/foreign_loc/trans' => 'Apps::Checkbook::Trans',
    },
} );

my $port = shift || 8192;

my $server = Gantry::Server->new( $port );
$server->set_engine_object( $cgi );
$server->run();
EO_SERVER_PORT

file_ok( $server, $correct_server, 'stand alone server port' );

unlink $server;

