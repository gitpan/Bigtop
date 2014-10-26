use strict;

use Test::More tests => 4;
use Test::Files;

use File::Spec;

use Bigtop::Parser qw/HttpdConf=Gantry Control=Gantry/;

my $bigtop_string;
my $tree;
my @conf;
my $correct_conf;
my @split_dollar_at;
my @correct_dollar_at;
my $base_dir   = File::Spec->catdir( 't', 'gantry' );
my $docs_dir   = File::Spec->catdir( $base_dir, 'docs' );
my $httpd_conf = File::Spec->catfile( $docs_dir, 'httpd.conf' );

#---------------------------------------------------------------------------
# controller with no location
#---------------------------------------------------------------------------

$bigtop_string = <<'EO_no_location';
config {
    HttpdConf       Gantry { full_use 0; }
}
app Apps::Checkbook {
    config {
        DB     app_db;
        DBName some_user;
    }
    controller PayeeOr {
        rel_location   payee;
    }
    controller Trans {
        controls_table some_table;
    }
}
EO_no_location

$tree = Bigtop::Parser->parse_string($bigtop_string);

eval {
    my $out = Bigtop::Backend::HttpdConf::Gantry->output_httpd_conf( $tree );
};

@split_dollar_at = split /\n/, $@;
@correct_dollar_at = split /\n/, <<'EO_no_location_error';
Error: controller 'Trans' must have one location or rel_location statement.
EO_no_location_error

is_deeply( \@split_dollar_at, \@correct_dollar_at, 'no location' );

#---------------------------------------------------------------------------
# correct (though small)
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_correct_bigtop';
config {
    HttpdConf Gantry { gen_root 1; full_use 0; }
}
app Apps::Checkbook {
    location `/app_base`;
    literal Location `    PerlSetVar Trivia 0`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    literal PerlTop `    use lib '/home/user/lib';`;
    controller PayeeOr {
        rel_location   payee;
        literal        Location `    PerlSetVar Trivia 1`;
        config {
            importance     3 => no_accessor;
            lines_per_page 3;
        }
    }
    literal HttpdConf `Include /some/file.conf

`;
    controller Trans {
        location   `/foreign_loc/trans`;
    }
    literal PerlBlock
`    use Some::Module;
    use Some::OtherModule;`;
}
EO_correct_bigtop

$tree = Bigtop::Parser->parse_string($bigtop_string);

Bigtop::Backend::HttpdConf::Gantry->gen_HttpdConf( $base_dir, $tree );

$correct_conf = <<'EO_CORRECT_CONF';
<Perl>
    #!/usr/bin/perl

    use lib '/home/user/lib';
    use Apps::Checkbook;
    use Apps::Checkbook::PayeeOr;
    use Apps::Checkbook::Trans;
    use Some::Module;
    use Some::OtherModule;
</Perl>

<Location /app_base>
    PerlSetVar DB app_db
    PerlSetVar DBName some_user
    PerlSetVar root html
    PerlSetVar Trivia 0
</Location>

<Location /app_base/payee>
    SetHandler  perl-script
    PerlHandler Apps::Checkbook::PayeeOr
    PerlSetVar importance 3
    PerlSetVar lines_per_page 3

    PerlSetVar Trivia 1

</Location>

Include /some/file.conf

<Location /foreign_loc/trans>
    SetHandler  perl-script
    PerlHandler Apps::Checkbook::Trans
</Location>

EO_CORRECT_CONF

file_ok( $httpd_conf, $correct_conf, 'generated output' );

unlink $httpd_conf;

#---------------------------------------------------------------------------
# same as previous but with no PerlSetVars and default base location
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_no_set_vars';
config {
    Conf Gantry {
        instance app;
        conffile `/path/to/something`;
    }
    HttpdConf Gantry {
        skip_config 1;
        full_use    0;
        gantry_conf 1;
    }
}
app Apps::Checkbook {
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    controller PayeeOr {
        rel_location   payee;
        config {
            importance     3 => no_accessor;
            lines_per_page 3;
        }
    }
    literal HttpdConf `Include /some/file.conf

`;
    controller Trans {
        location   `/foreign_loc/trans`;
    }
    literal PerlBlock
`    use Some::Module;
    use Some::OtherModule;
`;
}
EO_no_set_vars

$tree = Bigtop::Parser->parse_string($bigtop_string);

Bigtop::Backend::HttpdConf::Gantry->gen_HttpdConf( $base_dir, $tree );

$correct_conf = <<'EO_CORRECT_CONF';
<Perl>
    #!/usr/bin/perl

    use Apps::Checkbook;
    use Apps::Checkbook::PayeeOr;
    use Apps::Checkbook::Trans;
    use Some::Module;
    use Some::OtherModule;
</Perl>

<Location />
    PerlSetVar GantryConfInstance app
    PerlSetVar GantryConfFile /path/to/something
</Location>

<Location /payee>
    SetHandler  perl-script
    PerlHandler Apps::Checkbook::PayeeOr
</Location>

Include /some/file.conf

<Location /foreign_loc/trans>
    SetHandler  perl-script
    PerlHandler Apps::Checkbook::Trans
</Location>

EO_CORRECT_CONF

file_ok( $httpd_conf, $correct_conf, 'skip PerlSetVars' );

#---------------------------------------------------------------------------
# same as previous but with full use statement in the Perl block
# AND base controller with non-default location
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_full_use';
config {
    engine          MP13;
    template_engine TT;
    HttpdConf Gantry { skip_config 1; full_use 1; }
}
app Apps::Checkbook {
    controller is base_controller {
        location `/site`;
    }
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    controller PayeeOr {
        rel_location   payee;
        config {
            importance     3 => no_accessor;
            lines_per_page 3;
        }
    }
    literal HttpdConf `Include /some/file.conf

`;
    controller Trans {
        location   `/foreign_loc/trans`;
    }
    literal PerlBlock
`    use Some::Module;
    use Some::OtherModule;
`;
}
EO_full_use

$tree = Bigtop::Parser->parse_string($bigtop_string);

Bigtop::Backend::HttpdConf::Gantry->gen_HttpdConf( $base_dir, $tree );

$correct_conf = <<'EO_CORRECT_CONF';
<Perl>
    #!/usr/bin/perl

    use Apps::Checkbook qw{ -Engine=MP13 -TemplateEngine=TT };
    use Apps::Checkbook::PayeeOr;
    use Apps::Checkbook::Trans;
    use Some::Module;
    use Some::OtherModule;
</Perl>

<Location /site>

    SetHandler  perl-script
    PerlHandler Apps::Checkbook

</Location>

<Location /site/payee>
    SetHandler  perl-script
    PerlHandler Apps::Checkbook::PayeeOr
</Location>

Include /some/file.conf

<Location /foreign_loc/trans>
    SetHandler  perl-script
    PerlHandler Apps::Checkbook::Trans
</Location>

EO_CORRECT_CONF

file_ok( $httpd_conf, $correct_conf, 'full use statement' );

use lib 't';
use Purge;
Purge::real_purge_dir( $docs_dir );
