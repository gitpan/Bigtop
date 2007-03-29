use strict;

use Test::More tests => 8;
use Test::Files;

use File::Spec;

use Bigtop::Parser qw/CGI=Gantry Control=Gantry/;

use lib 't';
use Purge; # for strip_shebang filter

my $bigtop_string;
my $tree;
my $correct_script;
my $correct_prod_script;
my $base_dir   = File::Spec->catdir( 't', 'gantry' );
my $script     = File::Spec->catfile( $base_dir, 'app.cgi' );
my $server     = File::Spec->catfile( $base_dir, 'app.server' );

my $prod_script = File::Spec->catfile( $base_dir, 'app.prod.cgi' );
my $prod_server = File::Spec->catfile( $base_dir, 'app.prod.server' );

#---------------------------------------------------------------------------
# regular cgi dispatching script
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_correct_bigtop';
config {
    engine          CGI;
    template_engine TT;
    plugins `PluginA PluginB`;
    CGI Gantry {
        gen_root 1;
        with_server 1;
        flex_db 1;
    }
}
app Apps::Checkbook {
    location `/app_base`;
    literal PerlTop `use lib '/path/to/my/lib';`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
    }
    config prod {
        DBName prod_user;
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

use strict;

use lib '/path/to/my/lib';

use CGI::Carp qw( fatalsToBrowser );

use Apps::Checkbook qw{
    -Engine=CGI
    -TemplateEngine=TT
    -PluginNamespace=Apps::Checkbook
    PluginA PluginB
};

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        DB => 'app_db',
        DBName => 'some_user',
        dbconn => 'dbi:SQLite:dbname=app.db',
        root => 'html:html/templates',
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

$correct_prod_script = <<'EO_CORRECT_PROD_SCRIPT';

use strict;

use lib '/path/to/my/lib';

use CGI::Carp qw( fatalsToBrowser );

use Apps::Checkbook qw{
    -Engine=CGI
    -TemplateEngine=TT
    -PluginNamespace=Apps::Checkbook
    PluginA PluginB
};

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        DBName => 'prod_user',
        DB => 'app_db',
        dbconn => 'dbi:SQLite:dbname=app.db',
        root => 'html:html/templates',
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
EO_CORRECT_PROD_SCRIPT

file_filter_ok(
        $script,
        $correct_script,
        \&strip_shebang,
        'cgi dispatch script'
);
file_filter_ok(
        $prod_script,
        $correct_prod_script,
        \&strip_shebang,
        'prod cgi dispatch script'
);

unlink $script;
unlink $prod_script;

#---------------------------------------------------------------------------
# stand alone server
#---------------------------------------------------------------------------

my $correct_server = <<'EO_CORRECT_SERVER';

use strict;

use lib '/path/to/my/lib';

use lib qw( lib );

use Apps::Checkbook qw{
    -Engine=CGI
    -TemplateEngine=TT
    Static
    -PluginNamespace=Apps::Checkbook
    PluginA PluginB
};

use Getopt::Long;
use Gantry::Server;
use Gantry::Engine::CGI;

my $dbd    = 'SQLite';
my $dbuser = '';
my $dbpass = '';
my $dbname = 'app.db';

GetOptions(
    'dbd|d=s'     => \$dbd,
    'dbuser|u=s'  => \$dbuser,
    'dbpass|p=s'  => \$dbpass,
    'dbname|n=s'  => \$dbname,
    'help|h'      => \&usage,
);

my $dsn = "dbi:$dbd:dbname=$dbname";

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        dbconn => $dsn,
        dbuser => $dbuser,
        dbpass => $dbpass,
        doc_rootp => '/static',
        show_dev_navigation => 1,
        DB => 'app_db',
        DBName => 'some_user',
        root => 'html:html/templates',
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

print STDERR "Available urls:\n";
foreach my $url ( sort keys %{ $cgi->{ locations } } ) {
    print STDERR "  http://localhost:${port}$url\n";
}
print STDERR "\n";

$server->run();

sub usage {
    print << 'EO_HELP';
usage: app.server [options] [port]
    port defaults to 8080

    options:
    -h  --help    prints this message and quits
    -d  --dbd     DBD to use with DBI (like Pg or mysql),
                  defaults to sqlite
    -u  --dbuser  database user, defaults to the empty string
    -p  --dbpass  database user's password defaults to the empty string
    -n  --dbname  database name defaults to app.db

EO_HELP

    exit 0;
}

=head1 NAME

app.server - A generated server for the Apps::Checkbook app

=head1 SYNOPSIS

    usage: app.server [options] [port]

port defaults to 8080

=head1 DESCRIPTION

This is a Gantry::Server based stand alone server for the Apps::Checkbook
app.  It was built to use an SQLite database called app.db.  Use the following
command line flags to change database connection information (all of
them require a value):

=over 4

=item --dbd (or -d)

The DBD for your database, try SQLite, Pg, or mysql.  Defaults to SQLite.

=item --dbuser (or -u)

The database user name, defaults to the empty string.

=item --dbpass (or -p)

The database user's password, defaults to the empty string.

=item --dbname (or -n)

The name of the database, defaults to app.db.

=back

=cut

EO_CORRECT_SERVER

my $correct_prod_server = <<'EO_CORRECT_PROD_SERVER';

use strict;

use lib '/path/to/my/lib';

use lib qw( lib );

use Apps::Checkbook qw{
    -Engine=CGI
    -TemplateEngine=TT
    Static
    -PluginNamespace=Apps::Checkbook
    PluginA PluginB
};

use Getopt::Long;
use Gantry::Server;
use Gantry::Engine::CGI;

my $dbd    = 'SQLite';
my $dbuser = '';
my $dbpass = '';
my $dbname = 'app.db';

GetOptions(
    'dbd|d=s'     => \$dbd,
    'dbuser|u=s'  => \$dbuser,
    'dbpass|p=s'  => \$dbpass,
    'dbname|n=s'  => \$dbname,
    'help|h'      => \&usage,
);

my $dsn = "dbi:$dbd:dbname=$dbname";

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        dbconn => $dsn,
        dbuser => $dbuser,
        dbpass => $dbpass,
        doc_rootp => '/static',
        show_dev_navigation => 1,
        DBName => 'prod_user',
        DB => 'app_db',
        root => 'html:html/templates',
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

print STDERR "Available urls:\n";
foreach my $url ( sort keys %{ $cgi->{ locations } } ) {
    print STDERR "  http://localhost:${port}$url\n";
}
print STDERR "\n";

$server->run();

sub usage {
    print << 'EO_HELP';
usage: app.server [options] [port]
    port defaults to 8080

    options:
    -h  --help    prints this message and quits
    -d  --dbd     DBD to use with DBI (like Pg or mysql),
                  defaults to sqlite
    -u  --dbuser  database user, defaults to the empty string
    -p  --dbpass  database user's password defaults to the empty string
    -n  --dbname  database name defaults to app.db

EO_HELP

    exit 0;
}

=head1 NAME

app.server - A generated server for the Apps::Checkbook app

=head1 SYNOPSIS

    usage: app.server [options] [port]

port defaults to 8080

=head1 DESCRIPTION

This is a Gantry::Server based stand alone server for the Apps::Checkbook
app.  It was built to use an SQLite database called app.db.  Use the following
command line flags to change database connection information (all of
them require a value):

=over 4

=item --dbd (or -d)

The DBD for your database, try SQLite, Pg, or mysql.  Defaults to SQLite.

=item --dbuser (or -u)

The database user name, defaults to the empty string.

=item --dbpass (or -p)

The database user's password, defaults to the empty string.

=item --dbname (or -n)

The name of the database, defaults to app.db.

=back

=cut

EO_CORRECT_PROD_SERVER

file_filter_ok(
        $server,
        $correct_server,
        \&strip_shebang,
        'stand alone server'
);
file_filter_ok(
        $prod_server,
        $correct_prod_server,
        \&strip_shebang,
        'stand alone server, prod conf'
);

unlink $server;
unlink $prod_server;

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

use strict;

use FCGI;
use CGI::Carp qw( fatalsToBrowser );

use Apps::Checkbook qw{
    -Engine=CGI
    -TemplateEngine=TT
};

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

file_filter_ok(
        $script,
        $correct_script,
        \&strip_shebang,
        'fast cgi dispatch script'
);

unlink $script;

#---------------------------------------------------------------------------
# CGI with Gantry::Conf
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_gantry_conf';
config {
    engine          CGI;
    template_engine TT;
    Conf Gantry {
        instance    tinker;
        conffile    `/path/to/something`;
    }
    CGI Gantry {
        with_server 1;
        server_port 8192;
        gantry_conf 1;
    }
}
app Apps::Checkbook {
    location `/app_base`;
    literal PerlTop `use lib '/path/to/my/lib';`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    config prod {
        DBName prod_user;
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

use strict;

use lib '/path/to/my/lib';

use CGI::Carp qw( fatalsToBrowser );

use Apps::Checkbook qw{
    -Engine=CGI
    -TemplateEngine=TT
};

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        GantryConfInstance => 'tinker',
        GantryConfFile => '/path/to/something',
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

$correct_prod_script = $correct_script;
$correct_prod_script =~ s/tinker/tinker_prod/;

file_filter_ok(
        $script,
        $correct_script,
        \&strip_shebang,
        'cgi with Gantry::Conf'
);
file_filter_ok(
        $prod_script,
        $correct_prod_script,
        \&strip_shebang,
        'cgi with Gantry::Conf prod'
);

unlink $script;
unlink $prod_script;

#---------------------------------------------------------------------------
# stand alone server custom port
#---------------------------------------------------------------------------

$correct_server = <<'EO_SERVER_PORT';

use strict;

use lib '/path/to/my/lib';

use lib qw( lib );

use Apps::Checkbook qw{
    -Engine=CGI
    -TemplateEngine=TT
    Static
};

use Gantry::Server;
use Gantry::Engine::CGI;


my $cgi = Gantry::Engine::CGI->new( {
    config => {
        GantryConfInstance => 'tinker',
        GantryConfFile => '/path/to/something',
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

print STDERR "Available urls:\n";
foreach my $url ( sort keys %{ $cgi->{ locations } } ) {
    print STDERR "  http://localhost:${port}$url\n";
}
print STDERR "\n";

$server->run();

EO_SERVER_PORT

file_filter_ok(
        $server,
        $correct_server,
        \&strip_shebang,
        'stand alone server port'
);

unlink $server;

