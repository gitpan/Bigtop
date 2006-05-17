use strict;

use Test::More tests => 3;
use Test::Files;
use File::Spec;
use File::Find;
use Cwd;

use lib 't';

use Bigtop::Parser qw/SQL=Postgres Control=Gantry/;

my $play_dir   = File::Spec->catdir( qw( t gantry play ) );
my $ship_dir   = File::Spec->catdir( qw( t gantry playship ) );
my $ship_dir_2 = File::Spec->catdir( qw( t gantry playship2 ) );
my $base_module= File::Spec->catfile(
    qw( t gantry play Apps-Checkbook lib Apps Checkbook.pm )
);
my $add_loc    = '$self->exoticlocation() . "/strangely_named_add"';
my $edit_loc   = '$$self{exlocation}/editor';
my $email      = 'somebody@example.com';

mkdir $play_dir;

SKIP: {

    eval { require Gantry::Plugins::AutoCRUD; };
    my $skip_all = ( $@ ) ? 1 : 0;

    skip "Gantry::Plugins::AutoCRUD not installed", 3 if $skip_all;

#------------------------------------------------------------------------
# Comprehensive test of controller generation for Gantry
#------------------------------------------------------------------------

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    Control         Gantry { full_use 1; }
}
app Apps::Checkbook {
    authors          `Somebody Somewhere`;
    email            `$email`;
    copyright_holder `Somebody Somewhere`;
    license_text     `All rights reserved.`;
    config {
        DB     app_db => no_accessor;
        DBName someone;
    }
    sequence payee_seq {}
    sequence trans_seq {}
    table payee {
        sequence payee_seq;
        field id   { is int, primary_key, assign_by_sequence; }
        field name {
            is                     varchar;
            label                  Name;
            html_form_type         text;
            html_form_display_size 20;
        }
    }
    table trans {
        sequence trans_seq;
        field id { is int, primary_key, assign_by_sequence; }
        field status {
            is                     int; 
            label                  `Status2`;
            html_form_type         text;
            html_form_display_size 2;
        }
        field cleared {
            is                     boolean;
            label                  Cleared;
            html_form_type         select;
            html_form_options      Yes => 1, No => 0;
            html_form_constraint   `qr{^1|0\$}`;
        }
        field trans_date {
            is                     date;
            label                  `Trans Date`;
            html_form_type         text;
            html_form_display_size 10;
            date_select_text       Select;
        }
        field amount {
            is                     int; 
            label                  Amount;
            html_form_type         text;
            html_form_display_size 10;
        }
        field payee_payor {
            is                     int; 
            refers_to              payee;
            label                  `Paid To/Rec\\'v\\'d From`;
            html_form_type         select;
        }
        field descr {
            is                     varchar;
            label                  Descr;
            html_form_type         textarea;
            html_form_rows         3;
            html_form_cols         60;
            html_form_optional     1;
        }
    }
    controller PayeeOr is CRUD {
        uses              SomePackage::SomeModule, ExportingModule;
        controls_table    payee;
        text_description `Payee/Payor`;
        config {
            importance 1;
        }
        method do_main is main_listing {
            title             Payees;
            cols              name;
            header_options    Add => `$add_loc`;
            row_options       Edit, `Make Some`, Delete;
        }
        method my_crud_form is CRUD_form {
            form_name         payee_crud;
            fields            name;
        }
        method _form is CRUD_form {
            form_name default_form;
            fields    name;
        }
        method form is AutoCRUD_form {
            form_name         payee;
            fields            name;
            extra_keys
                legend => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
        method do_members is stub {}
        method do_nothing is stub {
            no_gen 1;
        }
    }
    controller Trans is AutoCRUD {
        uses             SomePackage::SomeModule => `qw( a_method \$b_scalar )`,
                         SomePackage::OtherModule => ``;
        controls_table   trans;
        text_description Transactions;
        config {
            trivia 1 => no_accessor;
        }
        method do_detail is stub {
            extra_args   `\$id`;
        }
        method do_main is main_listing {
            title             Transactions;
            cols              status, trans_date, amount, payee_payor;
            col_labels        `Status 3`,
                              Date => `\$site->location() . '/date_order'`;
            header_options    Add;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         trans;
            all_fields_but    id;
            extra_keys
                legend     => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`,
                javascript => `\$self->calendar_month_js( 'trans' )`,
                extraneous => `'uninteresting'`;
        }
    }
    controller Trans::Action is AutoCRUD {
        controls_table trans;
        method form is AutoCRUD_form {
            form_name trans;
            fields    status;
        }
    }
    controller NoOp { }
}
EO_Bigtop_File

# Add this to status field of trans table:
#            validate_with          `R|O|C`;
# Add this to amount field of trans table:
#            to_db_filter           strip_decimal_point;
#            from_db_filter         insert_decimal_point;
# strip_decimal_point and insert_decimal_point would be functions in the
# data model class.

Bigtop::Parser->gen_from_string( $bigtop_string, undef, 'create', 'Control' );

compare_dirs_ok( $play_dir, $ship_dir, 'gantry controls' );

#------------------------------------------------------------------------
# Regen test - not in create mode
#------------------------------------------------------------------------

my $new_bigtop = <<"EO_Second_Bigtop";
config {
    engine          MP20;
    template_engine TT;
    Control         Gantry { }
}
app Apps::Checkbook {
    sequence payee_seq {}
    table payee {
        sequence payee_seq;
        field id   { is int, primary_key, assign_by_sequence; }
        field name {
            is                     varchar;
            label                  Name;
            html_form_type         text;
            html_form_display_size 20;
        }
    }
    controller PayeeOr {
        controls_table    payee;
        text_description `Payee/Payor`;
        method do_main is main_listing {
            title             Payees;
            cols              name;
            header_options    Add;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         payee;
            fields            name;
            extra_keys
                legend => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
        method do_members is stub {}
    }
}
EO_Second_Bigtop

my $old_cwd = cwd();

my $building_dir = File::Spec->catdir( $play_dir, 'Apps-Checkbook' );

chdir $building_dir;

Bigtop::Parser->gen_from_string( $new_bigtop, undef, 0, 'Control' );

chdir $old_cwd;

compare_dirs_ok( $play_dir, $ship_dir_2, 'gantry controls - regen' );

# Note that the regen did not overwrite the stub for PayeeOr, even though
# the bigtop input was different.  Once a stub is written, it is not
# overwritten.

use lib 't';
use Purge;
Purge::real_purge_dir( $play_dir );

#------------------------------------------------------------------------
# Rerun of Comprehensive test (1 above) without full gantry use
#------------------------------------------------------------------------

$bigtop_string = <<"EO_No_Full_Use";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    Control         Gantry { full_use 0; }
}
app Apps::Checkbook {
    authors          `Somebody Somewhere`;
    email            `$email`;
    copyright_holder `Somebody Somewhere`;
    license_text     `All rights reserved.`;
    uses              Some::Module, Some::Other::Module;
    config {
        DB     app_db  => no_accessor;
        DBName someone => no_accessor;
    }
    sequence payee_seq {}
    sequence trans_seq {}
    table payee {
        sequence payee_seq;
        field id   { is int, primary_key, assign_by_sequence; }
        field name {
            is                     varchar;
            label                  Name;
            html_form_type         text;
            html_form_display_size 20;
        }
    }
    table trans {
        sequence trans_seq;
        field id { is int, primary_key, assign_by_sequence; }
        field status {
            is                     int; 
            label                  `Status2`;
            html_form_type         text;
            html_form_display_size 2;
        }
        field cleared {
            is                     boolean;
            label                  Cleared;
            html_form_type         select;
            html_form_options      Yes => 1, No => 0;
            html_form_constraint   `qr{^1|0\$}`;
        }
        field trans_date {
            is                     date;
            label                  `Trans Date`;
            html_form_type         text;
            html_form_display_size 10;
            date_select_text       Select;
        }
        field amount {
            is                     int; 
            label                  Amount;
            html_form_type         text;
            html_form_display_size 10;
        }
        field payee_payor {
            is                     int; 
            refers_to              payee;
            label                  `Paid To/Rec\\'v\\'d From`;
            html_form_type         select;
        }
        field descr {
            is                     varchar;
            label                  Descr;
            html_form_type         textarea;
            html_form_rows         3;
            html_form_cols         60;
            html_form_optional     1;
        }
    }
    controller PayeeOr is CRUD {
        uses              SomePackage::SomeModule, ExportingModule;
        controls_table    payee;
        text_description `Payee/Payor`;
        config {
            importance 1;
        }
        method do_main is main_listing {
            title             Payees;
            cols              name;
            header_options    Add => `$add_loc`;
            row_options       Edit, Delete;
        }
        method my_crud_form is CRUD_form {
            form_name         payee_crud;
            fields            name;
        }
        method form is AutoCRUD_form {
            form_name         payee;
            fields            name;
            extra_keys
                legend => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
        method do_members is stub {}
        method do_nothing is stub {
            no_gen 1;
        }
    }
    controller Trans is AutoCRUD {
        uses             SomePackage::SomeModule => `qw( a_method \$b_scalar )`,
                         SomePackage::OtherModule => ``;
        controls_table   trans;
        text_description Transactions;
        config {
            trivia 1 => no_accessor;
        }
        method do_detail is stub {
            extra_args   `\$id`;
        }
        method do_main is main_listing {
            title             Transactions;
            cols              status, trans_date, amount, payee_payor;
            col_labels        `Status 3`,
                              Date => `\$site->location() . '/date_order'`;
            header_options    Add;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         trans;
            all_fields_but    id;
            extra_keys
                legend     => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`,
                javascript => `\$self->calendar_month_js( 'trans' )`,
                extraneous => `'uninteresting'`;
        }
    }
    controller Trans::Action is AutoCRUD {
        controls_table trans;
        method form is AutoCRUD_form {
            form_name trans;
            fields    status;
        }
    }
    controller NoOp { }
}
EO_No_Full_Use

mkdir $play_dir;

Bigtop::Parser->gen_from_string( $bigtop_string, undef, 'create', 'Control' );

my $correct = <<'EO_Correct_Simple_Use';
package Apps::Checkbook;

use strict;

our $VERSION = '0.01';

use base 'Gantry';

use Some::Module;
use Some::Other::Module;
use Apps::Checkbook::PayeeOr;
use Apps::Checkbook::Trans;
use Apps::Checkbook::Trans::Action;
use Apps::Checkbook::NoOp;

##-----------------------------------------------------------------
## $self->init( $r )
##-----------------------------------------------------------------
#sub init {
#    my ( $self, $r ) = @_;
#
#    # process SUPER's init code
#    $self->SUPER::init( $r );
#
#} # END init


1;

=head1 NAME

Apps::Checkbook - the base module of this web app

=head1 SYNOPSIS

This package is meant to be used in the Perl block of an httpd.conf file.

    <Perl>
        # ...
        use Apps::Checkbook;
    </Perl>

If all went well, the httpd.conf file was correctly written during app
generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS

=over 4

=item init

=back

=head1 SEE ALSO

    Gantry
    Apps::Checkbook::PayeeOr
    Apps::Checkbook::Trans
    Apps::Checkbook::Trans::Action
    Apps::Checkbook::NoOp

=head1 AUTHOR

Somebody Somewhere, E<lt>somebody@example.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Somebody Somewhere

All rights reserved.

=cut
EO_Correct_Simple_Use

file_ok(
    $base_module,
    $correct,
    'controller with simple use Gantry statement'
);

Purge::real_purge_dir( $play_dir );

} # END of SKIP block
