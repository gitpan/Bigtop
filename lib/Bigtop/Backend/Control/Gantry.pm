package Bigtop::Backend::Control::Gantry;
use strict; use warnings;

# I apologize to all developers for littering the top of this file with POD.
# If I don't the first POD that perldoc shows is the POD template for generated
# code.  Try vim folding.

=head1 NAME

Bigtop::Backend::Control::Gantry - controller generator for the Gantry framework

=head1 SYNOPSIS

Build a file like this called my.bigtop:

    config {
        base_dir `/home/username`;
        Control Gantry {}
    }
    app App::Name {
        controller SomeController {}
    }

Then run this command:

    bigtop my.bigtop Control

=head1 DESCRIPTION

When your bigtop config includes Control Gantry, this module will be
loaded by Bigtop::Parser when bigtop is run with all or Control
in its build list.

This module builds files in the lib subdirectory of base_dir/App-Name.
(But you can change name by supplying app_dir, as explained in
Bigtop::Parser's pod.)

There will generally be two files for each controller you define.  One
will have the name you give it with the app name in front.  For the SYNOPSIS
example, that file will be called

    /home/username/App-Name/lib/App/Name/SomeController.pm

I call this file the stub.  It won't have much useful code in it, though
it might have method stubs depending on what's in its controller block.

The other file will have generated code in it.  As such it will go in the
GEN subdirectory of the directory where the stub lives.  In the example,
the name will be:

    /home/username/App-Name/lib/App/Name/GEN/SomeController.pm

During the intial build, both of these files will be made.  Subsequently,
the stub will not be regenerated (unless you delete it), but the GEN file
will be.  To prevent regeneration you may either put no_gen in the
Control Gantry block of the config, like this:

    config {
        ...
        Control Gantry { no_gen 1; }
    }

or you may mark the controller itself:

    controller SomeController {
        no_gen 1;
    }

=head2 controller KEYWORDS

Each controller has the form

    controller name is type {
        keyword arg, list;
        method name is type {
            keyword arg, list;
        }
    }

For a list of the keywords you can include in the controller block see the pod
for Bigtop::Control.  For a list of the keywords you can include in the
method block, see below (and note that most of these vary by the method's
type).

The controller phrase 'is type' is optional and defaults to 'is stub' which
has no effect.  The supported types are:

=over 4

=item AutoCRUD

This simply adds Gantry::Plugins::AutoCRUD to your uses list (it
will create the list if you don't have one).  Do not manually put
Gantry::Plugins::AutoCRUD in the uses list if you use type AutoCRUD, or
it will have two use statements.

=item CRUD

This adds Gantry::Plugins::CRUD to your uses list (it will create the list
if you don't have one).  As with AutoCRUD, don't manually put
Gantry::Plugins::CRUD in your uses list if you set the type to CRUD.

In addition to modifying your uses list, this type will make extra code.
Each time it sees a method of type AutoCRUD_form, it will make the following
things (suppose the AutoCRUD_form method is called my_crud_form):

=over 4

=item form method

This method will be suitable for use as the form named parameter to the
Gantry::Plugins::CRUD constructor.

You get this whether you set the controller type to CRUD or not.

=item constructed crud object

    my $my_crud = Gantry::Plugins::CRUD->new(
        add_action    => \&my_crud_add,
        edit_action   => \&my_crud_edit,
        delete_action => \&my_crud_delete,
        form          => \&my_crud_form,
        redirect      => \&my_crud_redirect,
        text_descr    => 'your text_description here',
    );

=item redirect method

Replicates the default behavior of always sending the user back to
$self->location on successful save or cancel.

=item do_* methods

A set of methods for add, edit, and delete which Gantry's handler will call.
These are stubs.  Example:

    #-------------------------------------------------
    # $self->do_add( )
    #-------------------------------------------------
    sub do_add {
        my $self = shift;

        $crud->add( $self, { data => \@_ } );
    }

Note that you should do something better with the data.  This method
leaves you having to fish through an array in the action method, and
therefore makes it harder for code readers to find out what is in the data.

=item action methods

A set of methods corresponding to do_add, do_edit, and do_delete which
are specified during the construction of the crud object.  Example:

    #-------------------------------------------------
    # $self->my_crud_add( $id )
    #-------------------------------------------------
    sub my_crud_add {
        my ( $self, $params, $data ) = @_;

        my $row = $YOUR_CONTROLLED_TABLE->create( $param );
        $row->dbi_commit();
    }

Note that the new object creation code a Class::DBI style API can be
called against the model alias of the table this controller controls.
That won't work if you are controlling multiple tables.  The same
holds for the edit and delete methods.

=back

Note that all generated names are based on the name of the form method.
The name is made with a brain dead regex which simply strips _form from
that name.

=back

=head2 method KEYWORDS

Most of the method keywords depend on the method's type.  This one doesn't:

=over 4

=item extra_args

Make this a comma separated list of arguments your method should expect.
Example:

    extra_args   `$cust_id`, `@params`;

Note that there is almost no magic here.  These will simply be added
to the method's opening comment and argument capturing code.  So
if the above example appeared in a handler method, the stub would look
roughly like this:

    #--------------------------------------------------
    # $self->method_name( $cust_id, @params )
    #--------------------------------------------------
    sub method_name {
        my ( $self, $cust_id, @params ) = @_;
    }

=back

=head1 SUPPORTED METHOD TYPES

Note Well:  Gantry's handlers must be called do_*.  The leading do_
will not be magically supplied.  Type it yourself.

Each method must have a type.  This backend supports the following types
(where support may vary depending on the type):

=over 4

=item stub

Generates an empty method body.  (But it handles arguments, see
extra_args above.)

=item main_listing

Generates a method, which you should probably name do_main, which produces
a listing of all the items in a table sorted by the columns in the table's
foreign_display.

You may include the following keys in the method block:

=over 4

=item cols

This is the list of columns that should appear in the listing.
More than 5 or 6 will likely look funny.  Use the field names from
the table you are controlling.

=item col_labels

This optional list allows you to specify labels for the columns instead
of using the label specfied in the field block of the controlled table.
Each list element is either a simple string which becomes the label
or a pair in which the key is the label and the value is a url (or code
which builds one) which becomes the href of an html link.  Example:

    col_labels   `Better Text`,
                 Label => `$self->location() . '/exotic/locaiton'`;

Note that for pairs, you may use any valid Perl in the link text.  Enclose
it in backquotes.  It will not be modified, mind your own quotes.

=item extra_args

See above.

=item header_options

These are the options that will appear at the end of the column label
stripe at the top of the output table.  Typically this is just:

    header_options Add;

But you can expand on that in a couple of ways.  You can have other
options:

    header_options AddBuyer, AddSeller;

These will translate into href links in the html page as

    current_base_uri/addbuyer
    current_base_uri/addseller

(In Gantry this means you should have do_addbuyer and do_addseller
methods in the same .pm file where the main_listing lives.)

You can also control the generated url:

    header_options AddUser => `$self->exotic_location() . "/strange_add"`;

Put valid Perl inside the backquotes.  It will NOT be changed in any way.
You must ensure that the code will work in the final app.  In this case
that likely means that exotic_location should return a uri which is
mentioned in a Location block in httpd.conf.  Further, the module
set as the handler for that location must have a method called
do_strange_add.

=item html_template

The name of the Template Toolkit file to use as the view for this page.
By default this is results.tt.

=item row_options

These yield href links at the end of each row in the output table.
Typical example:

    row_options Edit, Delete;

These work just like header_options with one exception.  The url has
the id of the row appended at the end.

If you say

    row_options Edit => `$url`;

You must make sure that the url is exactly correct (including appending
'/$id' to it).  Supplied values will be taken literally.

=item title

The browser window title for this page.

=back

=item AutoCRUD_form

Generates a method, usually called _form, which Gantry::Plugins::AutoCRUD
calls from its do_add and do_edit methods.

You may include the following keys in the method block:

=over 4

=item all_fields_but

A comma separated list of fields that should not appear on the form.
Typical example:

    all_fields_but id;

=item extra_args

See above.  Note that for the extra_args to be available, they must
be passed from the AutoCRUD calling method.

=item extra_keys

List key/value pairs you want to appear in the hash returned by the method.
Example:

    extra_keys
        legend     => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`,
        javascript => `$self->calendar_month_js( 'customer' )`;

The javascript entry is exactly correct for a form named customer
using Gantry::Plugins::Calendar.

Note that whatever you put inside the backquotes appears EXACTLY as is
in the generated output.  Nothing will be done to it, not even quote
escaping.

=item fields

A comma separated list of the fields to include on the form.  The
names must match fields of table you are controlling.
Example:

    fields first_name, last_name, street, city, state, zip;

Note that all_fields_but is usually easier, but directly using fields
allows you to change the order in which the entry widgets appear.

=item form_name

The name of the html form.  This is important if you are using javascript
which needs to refer to the form (for example if you are using
Gantry::Plugins::Calendar).

=back

=item CRUD_form

Takes the same keywords as AutoCRUD_form but makes a form method suitable
for use with Gantry::Plugins::CRUD.  Note that due to the callback scheme
used in that module, the name you give the generated method is entirely up
to you.  Note that the method is generated in the stub and therefore must
be included during initial building to avoid gymnastics (like renaming the
stub, genning, renaming the regened stub, moving the form method from that
file back into the real stub...).

=back

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 IGNORE the REST

After this paragraph, you will likely see other POD.  It belongs to
the generated modules.  I just couldn't figure out how to hide it.

=cut

use Bigtop::Backend::Control;
use File::Spec;
use Inline;
use Bigtop;

#-----------------------------------------------------------------
#   Register keywords in the grammar
#-----------------------------------------------------------------

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'method',
            qw(
                extra_args
                cols
                col_labels
                header_options
                row_options
                title
                html_template
                all_fields_but
                fields
                extra_keys
                form_name
            )
        )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'field',
            qw(
                label
                html_form_type
                html_form_constraint
                html_form_optional
                html_form_cols
                html_form_rows
                html_form_display_size
                html_form_options
                date_select_text
            )
        )
    );
}

#-----------------------------------------------------------------
#   The Default Template
#-----------------------------------------------------------------

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_blocks';
[% BLOCK base_module %]
package [% app_name %];

use strict;

our $VERSION = '0.01';

[% IF full_use_statement %]
use Gantry qw{[% IF engine %] -Engine=[% engine %][% END %][% IF template_engine %] -TemplateEngine=[% template_engine %][% END %] };

our @ISA = ( 'Gantry' );
[% ELSE %]
use base 'Gantry';
[% END %]

[% FOREACH module IN external_modules %]
use [% module %];
[% END %]
[% FOREACH module IN sub_modules %]
use [% module %];
[% END %]

[% init_sub %]

[% config_accessors %]
1;

[% pod %]
[% END %]

[% BLOCK test_file %]
use strict;

use Test::More tests => [% module_count %];

[% FOREACH module IN modules %]
use_ok( '[% module %]' );
[% END %]
[% END %]

[% BLOCK controller_block %]
package [% package_name %];

use strict;

use base '[% app_name %]';
[% gen_use_statement %]
[% child_output %]


[% IF init_sub %]
[% init_sub %]
[% END %]
[% IF config_accessors %]
[% config_accessors %]
[% END %]
[% class_accessors %]

1;

[% pod %]
[% END %]

[% BLOCK pod %]
=head1 NAME

[% IF sub_module %]
[% package_name %] - A controller in the [% app_name %] application
[% ELSE %]
[% package_name %] - the base module of this web app
[% END %]

=head1 SYNOPSIS

This package is meant to be used in the Perl block of an httpd.conf file.

    <Perl>
        # ...
        use [% package_name %];
    </Perl>
[% IF sub_module %]

    <Location /someurl>
        SetHandler  perl-script
        PerlHandler [% package_name +%]
    </Location>
[% END %]

If all went well, the httpd.conf file was correctly written during app
generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS

=over 4

[% FOREACH method IN methods %]
=item [% method %]


[% END %]
=back
[% IF gen_package_name %]

=head1 METHODS MIXED IN FROM [% gen_package_name +%]

=over 4

[% FOREACH mixin IN mixins %]
=item [% mixin %]


[% END %]
=back
[% END -%]

=head1 [% other_module_text +%]

[% FOREACH used_module IN used_modules %]
    [% used_module +%]
[% END %]

=head1 AUTHOR

[% author %][% IF email %], E<lt>[% email %]E<gt>[% END %]


=head1 COPYRIGHT AND LICENSE

Copyright (C) [% year %] [% copyright_holder %]


[% IF license_text %]
[% license_text %]

[% ELSE %]
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.
[% END %]

=cut
[% END %]

[% BLOCK gen_controller_block %]
# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package [% gen_package_name %];

use strict;

use base 'Exporter';

[% export_array %]

[% child_output %]


1;
[% END %]

[% BLOCK use_stub %]
use [% module -%]
[%- IF imports -%] qw(
    [% imports.join("\n    ") %]

);

[%- ELSE -%];
[% END %]
[% END %]

[% BLOCK explicit_use_stub %]
use [% module %][% IF import_list %] [% import_list %][% END %];
[% END %]

[% BLOCK export_array %]
our @EXPORT = qw(
[% FOREACH exported_sub IN exported_subs %]
    [% exported_sub +%]
[% END %]
);
[% END %]

[% BLOCK class_access %]
#-----------------------------------------------------------------
# get_model_name( )
#-----------------------------------------------------------------
sub get_model_name {
    return $[% model_alias %];
}

[% END %]

[% BLOCK text_description %]
#-----------------------------------------------------------------
# text_descr( )
#-----------------------------------------------------------------
sub text_descr     {
    return '[% description %]';
}
[% END %]

[% BLOCK controller_method +%]
#-----------------------------------------------------------------
# $self->[% method_name %]( [% child_output.doc_args.join( ', ' ) %] )
#-----------------------------------------------------------------
# This method supplied by [% gen_package_name %]

[% END %]

[% BLOCK gen_controller_method +%]
#-----------------------------------------------------------------
# $self->[% method_name %]( [% child_output.doc_args.join( ', ' ) %] )
#-----------------------------------------------------------------
sub [% method_name %] {
[% child_output.body %]
} # END [% method_name %]

[% END %]

[% BLOCK init_method_body %]
[% arg_capture %]

    # process SUPER's init code
    $self->SUPER::init( $r );

[% FOREACH config IN configs %]
    $self->[% config %]( $self->fish_config( '[% config %]' ) || '' );
[% END %]
[% END %]

[% BLOCK config_accessors %]
[% FOREACH config IN configs %]
sub [% config %] {
    my ( $self, $value ) = @_;

    if ( defined $value ) {
        $self->{[% config %]} = $value;
    }

    return $self->{[% config %]};
}

[% END %]
[% END %]

[% BLOCK arg_capture %]
[% FOREACH arg IN args %]
    my [% arg %] = shift;
[% END %]
[% END %]

[% BLOCK arg_capture_st_nick_style %]
    my ( [% args.join( ', ' ) %] ) = @_;
[% END %]

[% BLOCK self_setup %]
    $self->stash->view->template( '[% template %]' );
    $self->stash->view->title( '[% title %]' );
[% END %]

[% BLOCK main_heading %]
    my $retval = {
        headings       => [
[% FOREACH heading IN headings %]
[% IF heading.simple %]
            '[% heading.simple %]',
[% ELSIF heading.href %]
            '<a href=' . [% heading.href.link %] . '>[% heading.href.text %]</a>',
[% END %]
[% END %]
        ],
        header_options => [
[% FOREACH option IN header_options %]
            {
                text => '[% option.text %]',
                link => [% option.location +%],
            },
[% END %]
        ],
    };
[% END %]

[% BLOCK main_table %]
    my @rows = $[% model %]->retrieve_all_for_main_listing();

    foreach my $row ( @rows ) {
        my $id = $row->id;
        push(
            @{ $retval->{rows} }, {
                data => [
[% FOREACH data_col IN data_cols %]
                    $row->[% data_col %],
[% END %]
                ],
                options => [
[% FOREACH row_option IN row_options %]
                    {
                        text => '[% row_option.text %]',
                        link => [% row_option.location %],
                    },
[% END %]
                ],
            }
        );
    }

    $self->stash->view->data( $retval );
[% END %]

[% BLOCK form_body %]
[% arg_capture %]
    my $selections = $[% model %]->get_form_selections();

    return {
        name       => '[% form_name %]',
[% IF raw_row %]        row        => $row,
[% ELSE %]        row        => $data->{row},
[% END -%]
[% FOREACH extra_key_name IN extra_keys.keys() %]
        [% extra_key_name %] => [% extra_keys.$extra_key_name %],
[% END %]
        fields     => [
[% FOREACH field IN fields %]
            {
[% FOREACH key = field.keys %]
[% IF key == 'options_string' %]
                options => [% field.$key %],
[% ELSIF key == 'constraint' OR field.$key.match( '^\d+$' ) %]
                [% key %] => [% field.$key %],
[% ELSIF key == 'options' %]
                options => [
[% arg_list = field.$key %]
[% FOREACH pair IN arg_list %]
[% FOREACH pair_key IN pair.keys() %]
                    { label => '[% pair_key %]', value => '[% pair.$pair_key %]' },
[% END %]
[% END %]
                ],
[% ELSE %]
                [% key %] => '[% field.$key %]',
[% END %]
[% END %]
            },
[% END %]
        ],
    };
[% END %]

[% BLOCK crud_helpers %]

my $[% crud_name %] = Gantry::Plugins::CRUD->new(
    add_action      => \&[% crud_name %]_add,
    edit_action     => \&[% crud_name %]_edit,
    delete_action   => \&[% crud_name %]_delete,
    form            => \&[% form_method_name %],
    redirect        => \&[% crud_name %]_redirect,
    text_descr      => '[% text_descr %]',
    use_clean_dates => 1,
);

#-----------------------------------------------------------------
# $self->[% crud_name %]_redirect( $data )
# The generated version mimics the default behavior, feel free
# to delete the redirect key from the constructor call for $crud
# and this sub.
#-----------------------------------------------------------------
sub [% crud_name %]_redirect {
    my ( $self, $data ) = @_;
    return $self->location;
}

#-------------------------------------------------
# $self->do_add( )
#-------------------------------------------------
sub do_add {
    my $self = shift;

    $[% crud_name %]->add( $self, { data => \@_ } );
}

#-------------------------------------------------
# $self->[% crud_name %]_add( $params, $data )
#-------------------------------------------------
sub [% crud_name %]_add {
    my ( $self, $params, $data ) = @_;

    my $row = $[% model_alias %]->create( $params );
    $row->dbi_commit();
}

#-------------------------------------------------
# $self->do_delete( $doomed_id, $confirm )
#-------------------------------------------------
sub do_delete {
    my ( $self, $doomed_id, $confirm ) = @_;
    $[% crud_name %]->delete( $self, $confirm, { id => $doomed_id } );
}

#-------------------------------------------------
# $self->[% crud_name %]_delete( $data )
#-------------------------------------------------
sub [% crud_name %]_delete {
    my ( $self, $data ) = @_;

    my $doomed = $[% model_alias %]->retrieve( $data->{id} );
    $doomed->delete;
    $[% model_alias %]->dbi_commit;
}

#-------------------------------------------------
# $self->do_edit( $id )
#-------------------------------------------------
sub do_edit {
    my ( $self, $id ) = @_;

    my $row = $[% model_alias %]->retrieve( $id );

    $[% crud_name %]->edit( $self, { row => $row } );
}

#-------------------------------------------------
# $self->[% crud_name %]_edit( $param, $data )
#-------------------------------------------------
sub [% crud_name %]_edit {
    my( $self, $params, $data ) = @_;

    my %param = %{ $params };

    my $row = $data->{row};

    # Make update
    $row->set( %param );
    $row->update;
    $row->dbi_commit;
}
[% END %]
EO_TT_blocks

#-----------------------------------------------------------------
#   Methods in the B::C::Gantry package
#-----------------------------------------------------------------

sub what_do_you_make {
    return [
        [ 'lib/AppName.pm'       => 'Base module stub [safe to change]'    ],
        [ 'lib/AppName/*.pm'     => 'Controller stubs [safe to change]'    ],
        [ 'lib/AppName/GEN/*.pm' => 'Generated code [please, do not edit]' ],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },

        { keyword => 'full_use',
          label   => 'Full Use Statement',
          descr   => 'use Gantry qw( -engine=... ); [defaults to true]',
          type    => 'boolean',
          default => 'true' },
    ];
}

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

sub gen_Control {
    my $class       = shift;
    my $build_dir   = shift;
    my $bigtop_tree = shift;

    my $app_name            = $bigtop_tree->get_appname();
    my $lookup              = $bigtop_tree->{application}{lookup};
    my $app_stmnts          = $lookup->{app_statements};
    my $authors             = $app_stmnts->{authors};
    my $email               = $app_stmnts->{email}[0];
    my @external_modules;
    my $copyright_holder;
    my $license_text;

    @external_modules    = @{ $app_stmnts->{uses} }
            if defined ( $app_stmnts->{uses} );

    if ( defined $app_stmnts->{copyright_holder} ) {
        $copyright_holder   = $app_stmnts->{copyright_holder}[0];
    }
    else {
        $copyright_holder   = $authors->[0];
    }

    if ( defined $app_stmnts->{license_text} ) {
        $license_text = $app_stmnts->{license_text}[0];
    }

    my $year                = ( localtime )[5];
    $year                  += 1900;

    my $author_str          = join ', ', @{ $authors };

    my ( $module_dir, @sub_dirs )
                    = Bigtop::make_module_path( $build_dir, $app_name );

    # First, make one controller for each controller block in the bigtop_file
    # collect the names of all the controllers and their models.
    my $sub_modules = $bigtop_tree->walk_postorder(
        'output_controller',
        {
            module_dir       => $module_dir,
            app_name         => $app_name,
            lookup           => $lookup,
            tree             => $bigtop_tree,
            author_str       => $author_str,
            email            => $email,
            copyright_holder => $copyright_holder,
            license_text     => $license_text,
            year             => $year,
        },
    );

    # Second, make the main module.
    my $config            = $bigtop_tree->get_config();

    my $base_module_name  = pop @sub_dirs;
    my $base_module_file  = File::Spec->catfile(
            $build_dir, 'lib', @sub_dirs, "$base_module_name.pm"
    );

    my $app_configs       = $bigtop_tree->{application}{lookup}{configs};
    my ( $all_configs, $accessor_configs )
                          = build_config_lists( $app_configs );

    my $init_sub          = build_init_sub( $accessor_configs );
    my $config_accessors  = Bigtop::Backend::Control::Gantry::config_accessors(
        { configs => $accessor_configs, }
    );

    # remember the pod
    my @pod_methods       = ( 'init', @{ $accessor_configs } );
    my $pod               = Bigtop::Backend::Control::Gantry::pod(
        {
            package_name     => $app_name,
            methods          => \@pod_methods,
            other_module_text=> 'SEE ALSO',
            used_modules     => [ 'Gantry', @{ $sub_modules } ],
            author           => $author_str,
            email            => $email,
            copyright_holder => $copyright_holder,
            license_text     => $license_text,
            sub_module       => 0,
            year             => $year,
        }
    );

    my $full_use_statement = 1;
    my $config_block = $config->{Control};
    if ( defined $config_block->{full_use} and not $config_block->{full_use} ) {
        $full_use_statement = 0;
    }

    my $base_module_content = Bigtop::Backend::Control::Gantry::base_module(
        {
            app_name           => $app_name,
            external_modules   => \@external_modules,
            sub_modules        => $sub_modules,
            init_sub           => $init_sub,
            config_accessors   => $config_accessors,
            pod                => $pod,
            full_use_statement => $full_use_statement,
            %{ $config },                # Go fish!
        }
    );

    eval {
        no warnings qw( Bigtop );
        Bigtop::write_file(
            $base_module_file, $base_module_content, 'no_overwrite'
        );
    };
    warn $@ if ( $@ );

    # finally, make the test
    my $test_dir  = File::Spec->catdir( $build_dir, 't' );
    my $test_file = File::Spec->catfile( $test_dir, '01_use.t' );

    mkdir $test_dir;

    unshift @{ $sub_modules }, $app_name;

    my $module_count = @{ $sub_modules };

    my $test_file_content = Bigtop::Backend::Control::Gantry::test_file(
        {
            modules      => $sub_modules,
            module_count => $module_count,
        }
    );

    eval { Bigtop::write_file( $test_file, $test_file_content ); };
    warn $@ if ( $@ );
}

sub build_init_sub {
    my $configs     = shift;

    my $arg_capture =
        Bigtop::Backend::Control::Gantry::arg_capture_st_nick_style(
            { args => [ qw( $self $r ) ] }
        );

    my $body = Bigtop::Backend::Control::Gantry::init_method_body(
        {
            arg_capture => $arg_capture,
            configs     => $configs,
        }
    );

    my $method = Bigtop::Backend::Control::Gantry::gen_controller_method(
        {
            method_name  => 'init',
            child_output => {
                body     => $body,
                doc_args => [ '$r' ],
            },
        }
    );

    $method =~ s/^\s+//;
    $method =~ s/^/#/gm if ( @{ $configs } == 0 ); # no configs, comment it out

    return "$method\n";
}

sub build_config_lists {
    my $configs    = shift;

    my @accessor_configs;
    my @all_configs;

    SET_VAR:
    foreach my $config ( keys %{ $configs } ) {

        push @all_configs, $config;

        my $item = $configs->{$config}[0];

        if ( ref( $item ) =~ /HASH/ ) {

            my ( $value, $condition ) = %{ $item };

            next SET_VAR if $condition eq 'no_accessor';
        }

        push @accessor_configs, $config;
    }

    return \@all_configs, \@accessor_configs;
}

#-----------------------------------------------------------------
#   Packages named in the grammar
#-----------------------------------------------------------------

package sql_block;
use strict; use warnings;

sub output_field_names {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return unless $self->{__TYPE__} eq 'tables';

    return unless $self->{__NAME__} eq $data->{table_of_interest};

    return $child_output;
}

package table_element_block;
use strict; use warnings;

sub output_field_names {
    my $self = shift;

    return unless $self->{__TYPE__} eq 'field';

    return [ $self->{__NAME__} ];
}

package controller_block;
use strict; use warnings;

use Bigtop;

my %magical_uses = (
    CRUD     => 'Gantry::Plugins::CRUD',
    AutoCRUD => 'Gantry::Plugins::AutoCRUD',
    stub     => '',
);

sub get_package_name {
    my $self = shift;
    my $data = shift;

    return $data->{app_name} . '::' . $self->get_name();
}

sub get_gen_package_name {
    my $self = shift;
    my $data = shift;

    return $data->{app_name} . '::GEN::' . $self->get_name();
}

sub get_controller_type {
    my $self = shift;

    return $self->{__TYPE__}[0] || 'stub';
}

sub output_extra_use {
    my $self   = shift;
    my $type   = $self->get_controller_type;
    my $module = $magical_uses{ $type } || return;

    my $poser  = {
        __ARGS__ => [ $module ]
    };
    bless $poser, 'controller_statement';

    my %extra_use = @{ $poser->uses };

    my $output    = $extra_use{ output };

    return ( $output, $module );
}

sub output_controller {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    # generate the content of the controller and its GEN module
    my $short_name            = $self->get_name();
    my $package_name          = $self->get_package_name( $data );
    my $gen_package_name      = $self->get_gen_package_name( $data );

    # skip it if we can
    my $statements = $data->{lookup}{controllers}{$short_name}{statements};

    return if ( defined $statements->{no_gen} and $statements->{no_gen}[0] );

    # Begin by inserting magical things based on controller type
    my ( $extra_use, $extra_module )
            = $self->output_extra_use( $self->get_controller_type() );

    #############################################
    # Deal with what the children made for us.  #
    #############################################
    my ( $output_str, $class_access, $gen_output_str, $output_hash )
            = _extract_output_from( $child_output );

    my $stub_method_names = $output_hash->{stub_method_name};
    my $gen_method_names  = $output_hash->{gen_method_name};
    # gen_method_names is an array ref of names or undef if there are none

    # build beginning of dependencies section (the base app and the GEN
    # if it has methods)
    my @depend_head = ( $data->{app_name} );
    push @depend_head, $gen_package_name if defined $gen_method_names;

    unshift @{ $output_hash->{used_modules} }, \@depend_head;

    my $used_modules      = _flatten( $output_hash->{used_modules} );

    if ( $extra_use ) {
        push @{ $used_modules }, $extra_module;
        chomp $extra_use;
        $output_str       = "\n$extra_use" . $output_str;
    }

    # make doc stubs for standard controller accessor methods
    if ( defined $statements->{controls_table} ) {
        push @{ $stub_method_names }, qw( get_model_name text_descr );
    }

    # make the gen use statement if it has methods
    my $gen_use_statement;
    if ( defined $gen_method_names ) {
        $gen_use_statement = Bigtop::Backend::Control::Gantry::use_stub(
            { module => $gen_package_name, imports => $gen_method_names }
        );
    }

    my $export_array          = Bigtop::Backend::Control::Gantry::export_array(
            { exported_subs => $gen_method_names }
    );

    my $loc_configs = $data->{lookup}{controllers}{$short_name}{configs};
    my ( $all_configs, $accessor_configs ) =
            Bigtop::Backend::Control::Gantry::build_config_lists(
                $loc_configs
            );

    my $init_sub;
    if ( @{ $accessor_configs } ) {
        $init_sub = Bigtop::Backend::Control::Gantry::build_init_sub(
            $accessor_configs
        );
    }

    my $config_accessors;
    if ( @{ $accessor_configs } ) {
        $config_accessors = Bigtop::Backend::Control::Gantry::config_accessors(
            { configs => $accessor_configs, }
        );
    }

    my $pod                 = Bigtop::Backend::Control::Gantry::pod(
        {
            app_name         => $data->{app_name}, 
            accessors        => $accessor_configs,
            package_name     => $package_name,
            methods          => $stub_method_names,
            gen_package_name =>
                ( defined $gen_method_names ) ? $gen_package_name : undef,
            mixins           => $gen_method_names,
            other_module_text=> 'DEPENDENCIES',
            used_modules     => $used_modules,
            author           => $data->{author_str},
            email            => $data->{email},
            copyright_holder => $data->{copyright_holder},
            license_text     => $data->{license_text},
            sub_module       => 1,
            year             => $data->{year},
        }
    );

    my $output       = Bigtop::Backend::Control::Gantry::controller_block(
        {
            app_name          => $data->{app_name},
            package_name      => $package_name,
            gen_use_statement => $gen_use_statement,
            child_output      => $output_str,
            class_accessors   => $class_access,
            pod               => $pod,
            init_sub          => $init_sub,
            config_accessors  => $config_accessors,
        }
    );

    my $gen_output = Bigtop::Backend::Control::Gantry::gen_controller_block(
        {
            app_name         => $data->{app_name},
            gen_package_name => $gen_package_name,
            child_output     => $gen_output_str,
            export_array     => $export_array,
        }
    );

    # put the content onto the disk
    my @pack_pieces  = split /::/, $short_name;
    my $base_name    = pop @pack_pieces;
    $base_name      .= '.pm';

    # ... first make sure the directories exist for this piece
    my $module_home  = File::Spec->catdir( $data->{module_dir} );
    foreach my $subdir ( @pack_pieces ) {
        $module_home = File::Spec->catdir( $module_home, $subdir );
        mkdir $module_home;
    }

    # ... then make sure GEN directories exist (similar plan)
    my $gen_home = File::Spec->catdir( $data->{module_dir}, 'GEN' );

    if ( defined $gen_method_names ) {
        mkdir $gen_home;

        foreach my $subdir ( @pack_pieces ) {
            $gen_home = File::Spec->catdir( $gen_home, $subdir );
            mkdir $gen_home;
        }
    }

    my $pm_file     = File::Spec->catfile( $module_home, $base_name);
    my $gen_pm_file = File::Spec->catfile( $gen_home,    $base_name);

    # ... then write them
    eval {
        # Is the stub already present? Then skip it.
        no warnings qw( Bigtop );
        Bigtop::write_file( $pm_file,     $output,    'no overwrite' );
        if ( defined $gen_method_names ) {
            Bigtop::write_file( $gen_pm_file, $gen_output );
        }
    };
    return if ( $@ );

    # tell postorder walker what we just built
    return [ $package_name ];
}

sub _flatten {
    my $input = shift;

    my @output;

    foreach my $element ( @{ $input } ) {
        push @output, @{ $element };
    }

    return \@output;
}

sub _extract_output_from {
    my $child_output = shift;

    my %all_output;

    # extract from the individual child output lists
    foreach my $output_list ( @{ $child_output } ) {
        my $output_hash = { @{ $output_list } };

        foreach my $type ( keys %{ $output_hash } ) {
            next unless defined $output_hash->{ $type };
            push @{ $all_output{ $type } }, $output_hash->{ $type };
        }
    }

    # join the results
    my ( $output, $class_access, $gen_output );

    if ( defined $all_output{output} ) {
        $output       = join '', @{ $all_output{output}       };
    }

    if ( defined $all_output{gen_output} ) {
        $gen_output   = join '', @{ $all_output{gen_output}   };
    }

    if ( defined $all_output{class_access} ) {
        $class_access = join '', @{ $all_output{class_access} };
    }

    return (
        $output,
        $class_access,
        $gen_output,
        \%all_output,
    );
}

package controller_statement;
use strict; use warnings;

sub output_controller {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $keyword      = $self->{__KEYWORD__};

    return unless Bigtop::Backend::Control->is_controller_keyword( $keyword );

    return [ $self->$keyword( $child_output, $data ) ];
}

sub uses {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my @output;
    my @used_modules;

    foreach my $module ( @{ $self->{__ARGS__} } ) {

        if ( ref( $module ) eq 'HASH' ) {
            my ( $used, $import ) = %{ $module };
            my $use_statement =
                    Bigtop::Backend::Control::Gantry::explicit_use_stub(
                        {
                            module      => $used,
                            import_list => $import,
                        }
                    );
            chomp $use_statement;
            push @output, $use_statement;
            $module = $used;
        }

        else {
            my @exported;
            eval {
                my $module_path = $module;
                $module_path    =~ s{::}{/}g;
                require "$module_path.pm";
            };

            if ( $@ ) {
                push @output, Bigtop::Backend::Control::Gantry::use_stub(
                        { module => $module, }
                );
            }
            else {
                {
                    no strict 'refs';
                    @exported = @{"$module\::EXPORT"};
                }
                if ( @exported ) {
                    push @output, Bigtop::Backend::Control::Gantry::use_stub(
                            { module => $module, imports => \@exported }
                    );
                }
                else {
                    push @output, Bigtop::Backend::Control::Gantry::use_stub(
                            { module => $module }
                    );
                }
            }
        }

        push @used_modules, $module;
    }

    my $output = join "\n", @output;
    $output   .= "\n\n";

    return [
        output       => $output,
        used_modules => \@used_modules,
    ];
}

sub is_crud {
    my $self = shift;
    my $data = shift;

    my $controller_name  = $self->{__PARENT__}{__PARENT__}{__NAME__};
    my $controller_type  = $data->{lookup}
                                  {controllers}
                                  {$controller_name}
                                  {type}
                         || 'stub';

    return ( $controller_type eq 'CRUD' );
}

sub controls_table {
    my $self             = shift;
    my $child_output     = shift;
    my $data             = shift;
    my $table            = $self->{__ARGS__}[0];

    my $model            = "$data->{app_name}\::Model::$table";

    my $model_alias      = uc $table;
    $data->{model_alias} = $model_alias;

    my $output           = Bigtop::Backend::Control::Gantry::use_stub(
        { module => $model, imports => "\$$model_alias" }
    );

    my $class_access;
    unless ( $self->is_crud( $data ) ) {
        $class_access     = Bigtop::Backend::Control::Gantry::class_access(
            { model_alias => $model_alias }
        );
    }

    # This use statement goes in both stub and gen output.
    return [
        output       => $output,
        gen_output   => $output,
        class_access => $class_access,
        used_modules => [ $model ],
    ];
}

sub text_description {
    my $self             = shift;
    my $child_output     = shift;
    my $data             = shift;
    my $description      = $self->{__ARGS__}[0];

    if ( $self->is_crud( $data ) ) {
        return;
    }
    else {
        my $output       = Bigtop::Backend::Control::Gantry::text_description(
            { description => $description }
        );

        return [
            class_access => $output,
        ];
    }
}

package controller_method;
use strict; use warnings;

sub output_controller {
    my $self = shift;
               shift;  # There's no child output, we're in the recursion base.
    my $data = shift;

    my $gen_package_name
            = $self->{__PARENT__}{__PARENT__}->get_gen_package_name( $data );

    my $base_name = $gen_package_name;
    $base_name    =~ s/.*:://;

    my $method_name  = $self->{__NAME__};
    my $type         = $self->{__TYPE__};
    my $method_body  = $self->{__BODY__};

    my $controller_statements
                     = $data->{lookup}
                              {controllers}
                              {$base_name}
                              {statements};

    my $statements   = $data->{lookup}
                              {controllers}
                              {$base_name}
                              {methods}
                              {$method_name}
                              {statements};

    if ( $statements->{no_gen} ) {
        return;
    }

    # restart recursion based on method type
    unless ( $method_body->can( "output_$type" ) ) {
        die "Error: bad type '$type' for method '$method_name'\n"
            . "in controller '$base_name'\n";
    }

    my $child_output = $method_body->walk_postorder( "output_$type", $data );

    if ( $child_output ) {
        $child_output = { @{ $child_output } };
    }

    my $stub_method_name;
    if ( $type eq 'stub' ) {
        $stub_method_name = $self->{__NAME__};
    }

    my $gen_method_name;
    if ( defined $child_output->{gen_output}
            and
        $child_output->{gen_output}{body} )
    {
        $gen_method_name = $self->{__NAME__};
    }

    my ( $output, $gen_output );

    if ( $child_output->{gen_output} ) {
        $gen_output = Bigtop::Backend::Control::Gantry::gen_controller_method(
            {
                method_name  => $self->{__NAME__},
                child_output => $child_output->{gen_output},
            }
        );
    }

    if ( $child_output->{comment_output} ) {
        $output = Bigtop::Backend::Control::Gantry::controller_method(
            {
                method_name      => $self->{__NAME__},
                child_output     => $child_output->{comment_output},
                gen_package_name => $gen_package_name,
            }
        );
    }

    if ( $child_output->{stub_output} ) {
        $output = Bigtop::Backend::Control::Gantry::gen_controller_method(
            {
                method_name  => $self->{__NAME__},
                child_output => $child_output->{stub_output},
            }
        );
    }

    if ( $child_output->{crud_output} ) {
        my $crud_name    = $self->{__NAME__};
        $crud_name       =~ s/_form//;
        $crud_name     ||= 'crud';

        my $text_descr   = $controller_statements->{text_description}[0];
        my $model_alias  = $data->{model_alias};

        unless ( defined $model_alias and $model_alias ) {
            die "Error: controller $base_name is type CRUD but is missing\n"
                . "    it's controls table statement.\n";
        }

        my $crud_helpers = Bigtop::Backend::Control::Gantry::crud_helpers(
            {
                form_method_name => $self->{__NAME__},
                crud_name        => $crud_name,
                text_descr       => $text_descr || 'missing text descr',
                model_alias      => $model_alias,
            }
        );

        my $form_method =
            Bigtop::Backend::Control::Gantry::gen_controller_method(
                {
                    method_name  => $self->{__NAME__},
                    child_output => $child_output->{crud_output},
                }
            );

        $output = $crud_helpers . $form_method;
    }

    return [
        [
            gen_output       => $gen_output,
            output           => $output,
            stub_method_name => $stub_method_name,
            gen_method_name  => $gen_method_name,
        ]
    ];
}

package method_body;
use strict; use warnings;

sub get_table_name_for {
    my $self        = shift;
    my $lookup      = shift;
    my $name_of     = shift;

    my $table_name  = $self->get_table_name( $lookup );

    unless ( $table_name ) {
        die "Error: I can't generate main_listing in $name_of->{method} "
            . "of controller $name_of->{controller}.\n"
            . "  The controller did not have a 'controls_table' statement.\n";
    }

    $name_of->{table} = $table_name;
}

sub get_fields_from {
    my $self    = shift;
    my $lookup  = shift;
    my $name_of = shift;

    my $fields = $lookup->{tables}{ $name_of->{table} }{fields};

    unless ( $fields ) {
        die "Error: I can't generate main_listing for $name_of->{method} "
        .   "of controller $name_of->{controller}.\n"
        .   "  I can't seem to find the fields in the table for "
        .   "this controller.\n"
        .   "  I was looking for them in the table named '$name_of->{table}'.\n"
        .   "  Maybe that name is misspelled.\n";
    }

    return $fields;
}

sub get_field_for {
    my $col     = shift;
    my $fields  = shift;
    my $name_of = shift;

    my $field = $fields->{$col};

    # make sure there really is a field
    unless ( $field ) {
        die "Error: I couldn't find a field called '$col' in "
            .   "$name_of->{table}\'s field list.\n"
            .   "  Perhaps you misspelled '$col' in the definition of\n"
            .   "  method $name_of->{method} for controller "
            .   "$name_of->{controller}.\n";
    }

    return $field;
}

sub output_stub {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $choices      = { @{ $child_output } };

    # set up args
    my ( $arg_capture, @doc_args )
            = _build_arg_capture( @{ $choices->{extra_args} } );

    return [
        stub_output => {
            body     => $arg_capture,
            doc_args => \@doc_args,
        }
     ];
}

sub output_main_listing {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $choices      = { @{ $child_output } };

    # set up args
    my ( $arg_capture, @doc_args )
            = _build_arg_capture( @{ $choices->{extra_args} } );

    # provide defaults
    my $title         = $choices->{title}[0]          || 'Main Listing';
    my $template      = $choices->{html_template}[0]  || 'results.tt';

    # set self vars for title/template etc.
    my $self_setup = Bigtop::Backend::Control::Gantry::self_setup(
        { title => $title, template => $template }
    );

    # set up headings
    my @col_labels;
    my @cols;
    my %name_of;

    $name_of{method}     = $self->get_method_name();
    $name_of{controller} = $self->get_controller_name();

    $self->get_table_name_for(           $data->{lookup}, \%name_of );

    my $fields = $self->get_fields_from( $data->{lookup}, \%name_of );

    foreach my $col ( @{ $choices->{cols} } ) {
        my $field = get_field_for( $col, $fields, \%name_of );

        # get the field's label
        my $label;
        if ( defined $choices->{col_labels} and @{ $choices->{col_labels} } ) {
            my $element = shift @{ $choices->{col_labels} };
            if ( ref( $element ) =~ /HASH/ ) {
                my ( $text, $link ) = %{ $element };
                push @col_labels, { href => { text => $text, link => $link } };
            }
            else {
                push @col_labels, { simple => $element };
            }
        }
        else {
            $label = $fields->{$col}{label}{args}[0];
            unless ( $label ) {
                warn "Warning: I couldn't find the label for "
                    . "'$col' in $name_of{table}\'s fields.\n"
                    . "  Using '$col' as the label in method $name_of{method}"
                    . " of\n"
                    . "  controller $name_of{controller}.\n";

                $label = $col;
            }
            push @col_labels, { simple => $label };
        }

        # see if it's foreigner
        if ( defined $fields->{$col}{refers_to} ) {
            push @cols, ${col} . '->foreign_display()';
        }
        else {
            push @cols, ${col};
        }
    }

    # put options in the heading bar
    my $header_options = [];
    if ( $choices->{header_options} ) {
        $header_options = _build_options( $choices->{header_options} );
    }

    my $heading = Bigtop::Backend::Control::Gantry::main_heading(
        { headings => \@col_labels, header_options => $header_options }
    );

    # generate database retrieval
    my $row_options = [];
    if ( $choices->{row_options} ) {
        $row_options = _build_options( $choices->{row_options}, '/$id' );
    }

    my $main_table = Bigtop::Backend::Control::Gantry::main_table(
        {
            model       => $data->{model_alias},
            data_cols   => \@cols,
            row_options => $row_options,
        }
    );

    # return the result
    # We must call the templates separately,  Inline::TT does not support
    # including one block inside another.  (Since each block is logically
    # a file and you can never call a block in another file with TT.
    # In reality the reason is a bit more subtle.  To call a block, with
    # Inline::TT, you need to call it as a function in the Bigtop::* class.
    # But inside the templates, you cannot call a Perl function without
    # enabling Perl code, which we don't want to do.)
    return [
        gen_output => {
            body     => "$arg_capture\n$self_setup\n$heading\n$main_table",
            doc_args => \@doc_args,
        },
        comment_output => {
            doc_args => \@doc_args,
        }
    ];
} # END output_main_listing

# Given
#   [ Label => url, Label2 => url2, Label_no_url; ]
# Returns
#   [
#       { text => 'Label',       link => 'url'  },
#       { text => 'Label2',      link => 'url2' },
#       { text => 'Plain_Label', link => '$$self{location}/plain_label' },
#   ]
sub _build_options {
    my $bigtop_args = shift;
    my $url_suffix  = shift || '';

    my @options;
    foreach my $option ( @{ $bigtop_args } ) {
        my $label;
        my $location;

        if ( ref( $option ) =~ /HASH/ ) {
            ( $label, $location ) = %{ $option };
        }
        else {
            $label    = $option;
            my $type  = lc $option;
            $type     =~ s/ /_/g;
            $location = '$self->location() . "/' . $type . $url_suffix . '"';
        }

        push @options, {
            text     => $label,
            location => $location,
        };
    }

    return \@options;
}

sub _build_arg_capture {
    my @extras   = @_;

    my @args     = ( '$self', @extras );
    my $arg_capture =
            Bigtop::Backend::Control::Gantry::arg_capture_st_nick_style(
                { args => \@args }
            );

    return ( $arg_capture, @extras );
}

sub _crud_form_outputer {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;
    shift;                      # parent. not needed.
    my $auto_crud    = shift || 0;

    # set up args
    my $choices      = { @{ $child_output } };

    my $default_arg  = ( $auto_crud ) ? '$row' : '$data';

    my ( $arg_capture, @doc_args )
            = _build_arg_capture( $default_arg, @{ $choices->{extra_args} } );

    # get the fields
    my %name_of;
    $name_of{method}     = $self->get_method_name();
    $name_of{controller} = $self->get_controller_name();

    $self->get_table_name_for( $data->{lookup}, \%name_of );

    my $fields = $self->get_fields_from( $data->{lookup}, \%name_of );

    unless ( defined $choices->{fields}
                or
             defined $choices->{all_fields_but} )
    {
        die "Error: I can't generate AutoCRUD_form for $name_of{method} "
            .   "of controller $name_of{controller}.\n"
            .   "  No fields (or all_fields_but) were given.\n"; 
    }

    my $requested_fields;

    if ( defined $choices->{all_fields_but} ) {
        $requested_fields = _find_all_fields_but(
            $choices->{all_fields_but},
            $data,
            $name_of{table}
        );
    }
    else {
        $requested_fields = $choices->{fields};
    }

    my @field_lookups;
    foreach my $field_name ( @{ $requested_fields } ) {
        my $field = get_field_for( $field_name, $fields, \%name_of );

        my %clean_field;

        $clean_field{name} = $field_name;

        foreach my $key ( keys %{ $field } ) {
            my $clean_key              = $key;
            $clean_key                 =~ s/html_form_//;

            my $clean_value            = $field->{$key}{args}[0];

            # translate foreign key into select list
            if ( $clean_key eq 'refers_to' ) {
                $clean_key   = 'options_string';
                $clean_value = '$selections->{' . $clean_value . '}';
            }
            # pull out all pairs
            elsif ( $clean_key eq 'options' ) {
                my @option_pairs;
                foreach my $pair ( @{ $field->{$key}{args} } ) {
                    push @option_pairs, $pair;
                }
                $clean_value           = \@option_pairs;
            }
            else {
                $clean_value           = $field->{$key}{args}[0];
            }

            $clean_field{ $clean_key } = $clean_value;
        }

        push @field_lookups, \%clean_field;
    }

    my %extra_keys;
    if ( $choices->{extra_keys} ) {
        foreach my $pair ( @{ $choices->{extra_keys} } ) {
            my ( $key, $value ) = %{ $pair };
            $extra_keys{ $key } = $value;
        }
    }

    # build body
    my $form_body = Bigtop::Backend::Control::Gantry::form_body(
        {
            model      => $data->{model_alias},
            form_name  => $choices->{form_name}[0],
            fields     => \@field_lookups,
            extra_keys => \%extra_keys,
            raw_row    => $auto_crud,
        }
    );

    my $output_type = ( $auto_crud ) ? 'gen_output' : 'crud_output';

    return [
        $output_type => {
            body     => "$arg_capture\n$form_body",
            doc_args => \@doc_args,
        },
        comment_output => {
            doc_args => \@doc_args,
        }
    ];
}

sub output_AutoCRUD_form {
    return _crud_form_outputer( @_, 1 );
}

sub output_CRUD_form {
    my ( $self, undef, $data )    = @_;

    return _crud_form_outputer( @_, 0 );
}

sub _find_all_fields_but {
    my $excluded_fields = shift;
    my $data            = shift;
    my $table_name      = shift;

    my $bigtop_tree     = $data->{tree};

    # ask the corresponding table for its fields
    my $fields = $bigtop_tree->walk_postorder(
        'output_field_names', { table_of_interest => $table_name }
    );

    my @retval;

    # now build the return list
    my %exclude_this;
    @exclude_this{ @{ $excluded_fields } } = @{ $excluded_fields };

    foreach my $field ( @{ $fields } ) {
        push @retval, $field unless $exclude_this{ $field };
    }

    return \@retval;
}

package method_statement;
use strict; use warnings;

sub walker_output {
    my $self = shift;

    return [ $self->{__KEY__} => $self->{__ARGS__} ];
}

sub output_stub          { goto &walker_output; }

sub output_main_listing  { goto &walker_output; }

sub output_AutoCRUD_form { goto &walker_output; }

sub output_CRUD_form     { goto &walker_output; }

1;

