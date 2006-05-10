package Bigtop::Docs::Cookbook;

=head1 Name

Bigtop::Docs::Cookbook - Bigtop syntax by example

=head1 Intro

This document is meant to be like the Perl Cookbook with short wishes
you might long for, together with syntax to type in your bigtop file
and what that produces.  In addition, many sections start
with a simple question about what gets built by the backend in question.

For quick syntax reference consult Bigtop::Docs::Keywords for more
complete information consult Bigtop::Docs::Syntax.

The questions are in sections.  Here is a complete list of sections and
questions:

=over 4

=item *

Init

=over 4

=item *

L<What does Init::Std build?>

=item *

L<How can I regenerate some of those files but not others?>

=back

=item *

Stand Alone Server

=over 4

=item *

L<How do I make a stand alone server for my app?>

=back

=item *

SQL

=over 4

=item *

L<What do SQL backends make?>

=item *

L<How do I make a sequence (and why should I)?>

=item *

L<How do I make a table?>

=item *

L<How do I make a primary key column?>

=item *

L<What all can I put in a table block?>

=item *

L<How can I include data for initial population into a table?>

=item *

L<How do I put extra things into schema.*?>

=back

CGI

=over 4

=item *

L<What do CGI backends make?>

=item *

L<How do I specify configuration values?>

=item *

L<How do I specify Gantry::Conf configuration values?>

=item *

L<How do I control CGI locations?>

=back

=item *

httpd.conf

=over 4

=item *

L<What do HttpdConf backends make?>

=item *

L<How do I specify PerlSetVar values for mod_perl?>

=item *

L<How do I use Gantry::Conf for mod_perl?>

=item *

L<How do I put extra statements into my Apache Perl block?>

=item *

L<How do I put extra directives into httpd.conf?>

=back

=item *

Gantry conrollers

=over 4

=item *

L<What does the Gantry Control backend make?>

=item *

L<How do I associate a controller with a table?>

=item *

L<How do I get a stub method in my controller?>

=item *

L<How do I use Gantry's AutoCRUD?>

=item *

L<How do I use Gantry's CRUD?>

=back

=item *

Gantry's Class::DBI models

=over 4

=item *

L<What does the GantryCDBI Model backend make?>

=item *

L<How do I specify a primary key for my model?>

=item *

L<How can I make my model inherit from a class of my choice?>

=item *

L<How can I alter the generated models behavior?>

=back

=item *

Gantry's home made models

=over 4

=item *

L<What does the Gantry Model backend make?>

=item *

L<How do I specify a primary key for my model?>

=item *

L<How can I make my model inherit from a class of my choice?>

=item *

L<How can I alter the generated models behavior?>

=back

=back

=head1 Init

=head2 What does Init::Std build?

If your config includes:

    config {
        Init Std {}
    }

bigtop will generate the following regular files:

    Build.PL
    Changes
    MANIFEST
    MANIFEST.SKIP
    README

It also makes the following directories:
    
    docs
    lib
    t

It will try to put the bigtop file into the docs directory (but it
won't overwrite it, if its already there).  Note that Init doesn't put
things into the lib or t directories.

=head2 How can I regenerate some of those files but not others?

As with all backends, you can prevent regeneration of all of the above:

    Init Std { no_gen 1; }

If you use C<bigtop --new AppName>, it do this for you.

But this backend has more fine tuned control:

    Init Std {
        Changes no_gen;
        README  no_gen;
    }

This will not build Changes or README, but will make Build.PL,
MANIFEST, and MANIFEST.SKIP.  List as many of the regular files as you
like with no_gen as the value.  The others will be rebuilt.
This is convenient for keeping the MANIFEST up to date while leaving
the Changes file safe for hand editing.

=head1 Stand Alone Server

There is no special backend for making stand alone servers, but there
is a way to generate them for Gantry (see below).

=head2 How do I make a stand alone server for my app?

To get a stand alone server, do just what you would for a CGI app,
but add the with_server statement to the CGI backend block in the config
section:

    config {
        engine    CGI;
        Init      Std    {}
        CGI       Gantry { with_server 1; }
    }
    app Name {
        config {
            variable_1 value;
            variable_2 `multi-word value`;
            overriden  global;
        }
        controller SubPage {
            rel_location subpage;
        }
    }

This yields a CGI script as normal and app.server which can be executed
directly (it requires HTTP::Server::Simple).

    #!/usr/bin/perl
    use strict;


    use CGI::Carp qw( fatalsToBrowser );

    use Name qw{ -Engine=CGI -TemplateEngine= };

    use Gantry::Server;

    use Gantry::Engine::CGI;

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            variable_1 => 'value',
            variable_2 => 'multi-word value',
            overriden => 'global',
        },
        locations => {
            '/' => 'Name',
            '/subpage' => 'Name::SubPage',
        },
    } );

    my $server = Gantry::Server->new();
    $server->set_engine_object( $cgi );
    $server->run();

This server binds to port 8080.  To change the port, add the server_port
statement:

    
        CGI       Gantry { with_server 1;
                           server_port 8090; }

This will change the script in only one place:

    my $server = Gantry::Server->new( 8090 );

You could change the port manually after generation as well.

=head1 SQL

=head2 What do SQL backends make?

SQL backends make docs/schema.* (where * becomes your database engine,
like postgres) in the build directory.  It should
be ready for direct use to create your database.

=head2 How do I make a sequence (and why should I)?

Use a sequence block:

    sequence name_seq {}

This will generate:

    CREATE SEQUENCE name_seq;

in schema.*.  Note that blocks for sequences must currently be empty.
Eventually they should support min and max values, etc.

You should make a sequence for each table and make it the primary
key of your table.  This facilitates Class::DBI and other similar
object relational mappers as they manage the table.

=head2 How do I make a table?

Tables are made with blocks:

    table name {
        #...
    }

Inside the braces you need to specify the table's sequence and
its fields:

    table name {
        sequence name_seq;
        field id   { is int4, primary_key, auto; }
        field name { is varchar; }
    }

=head2 How do I make a primary key column?

Include C<primary_key> as one of the attributes of the is statement for the
field (see above or below).  This will add C<PRIMARY KEY> in the schema.*,
but will also show Model backends that the field is primary.

=head2 What all can I put in a table block?

Here is a table with several types of fields:

    table invoices {
        sequence        invoices_seq;
        foreign_display `%number`;

        field id { is int4, primary_key, assign_by_sequence; }
        field number {
            is int4;
            label                `Number (example: COM-12)`;
            html_form_type       text;
            html_form_constraint `qr{^\w\w\w-\d+$}`;
        }
        field status_id {
            is                 int4;
            label              Status;
            refers_to          status;
            html_form_type     select;
        }
        field paid {
            is                 date;
            label              `Paid On`;
            date_select_text   `Popup Calendar`;
            html_form_type     text;
            html_form_optional 1;
        }
        field customer_id {
            is                 int4;
            label              Customer;
            refers_to          customers;
            html_form_type     select;
        }
        field notes {
            is                 text;
            label              `Notes to Customer`;
            html_form_type     textarea;
            html_form_optional 1;
            html_form_rows     4;
            html_form_cols     50;
        }
    }
    
The foreign_display statement controls how rows from this table
appear when other tables refer to them.  This is available through
the model's foreign_display method:

    my $show_to_user = $invoice_row_object->foreign_display();

Each field that might appear on the screen should have a label which
the user will see above or next to the values.  It becomes the column
label when the field appears in a table.  It appears next to the entry
field when the user is entering or updating it.

Including the refers_to statement implies that the field is a foreign
key.  Whether this generates SQL indicating that is up to the backend.
Bigtop::SQL::Postgres does not generate foreign key SQL.  But,
using refers_to always affects the model.  For instance,
Bigtop::Model::CDBI generates a has_a for each field with a refers_to
statement.

The date_select_text is shown by Gantry templates as the text for
a popup calendar link.  See the discussion of the LineItem controller in
Bigtop::Docs::Tutorial for details.  You might also want to check 'How can I
let my users pick dates easily?' in Gantry::Docs::FAQ to see
what bigtop generates.

All of the statements which begin with html_form_ are passed through
to the template (with html_form_ stripped).  Consult your template
for details.  The gantry template is form.tt.  Note that html_form_constraint
is actually used by Gantry plugins which rely on Gantry::Utils::CRUDHelp.
This includes at least Gantry::Plugins::AutoCRUD and Gantry::Plugins::CRUD.

=head2 How can I include initial data in a table?

Sometimes it's useful to put some data into the database during creation.
Two types that spring to mind are test data and standard constants.
To include such data add data statements to the table block:

    table status_code {
        #...
        data name => `Begun`,  descr => `work in progress`;
        data name => `Billed`, descr => `invoice sent to customer`;
        data name => `Paid`,   descr => `payment received`;
    }

Notes: (1) you should not set the id if your table has a sequence (and it
should). (2) remember to surround the values with backquotes if they
have any characters Perl wouldn't like in a variable name (it's always
safe to have backquotes around values, even if they aren't strictly needed,
think of them like the comma after the last item in a Perl list). (3) you
can use as many data statments as you like each one makes an SQL statement:

    INSERT INTO status_code ( name, descr )
        VALUES ( 'begun', 'work in progress' );

=head2 How do I put extra things into schema.*?

At any point in the app section, you may include a literal SQL statement:

    literl SQL `CREATE INDEX name_ind ON some_table ( some_field );`;

There are a couple of things to notice here.  First, enclose all of your
literal content in backquotes.  It will only be modified in one way.  If
it doesn't end in whitespace, one new line will be added to it.  Otherwise,
you are on your own.

Second, there are two semi-colons here.  The one inside the backquotes is
for SQL, the one outside is for Bigtop.  The later semi-colon is always
required.  It's up to you to make sure the syntax of your literal SQL code
is correct (including determining whether it needs a semi-colon).

If you want a trailing empty line, do this:

    literl SQL `CREATE INDEX name_ind ON some_table ( some_field );
    
    `;

All trailing whitespace is taken literally.  If you include any, no extra
new line will be added.

The order of SQL generation is the same as the order in your Bigtop file.
For example, since the index creation above must come after some_table
is defined, put the literal statement after some_table's block.

=head1 CGI

=head2 What do CGI backends make?

CGI backends make a single CGI based dispatching script called app.cgi
directly in the build directory.  You will have to copy it to your
cgi-bin directory and make sure the copy there is executable.

=head2 How do I specify configuration values?

If you want to use Gantry::Conf, see the next question.

Specify CGI configuration values with config blocks as you would for
mod_perl apps:

    app SomeApp {
        config {
            dbconn `dbi:Pg:dbname=appdb` => no_accessor;
            dbuser `someone`             => no_accessor;
            dbpass `not_tellin`          => no_accessor;
            page_size 15;
        }
    }

These become config hash members:

    my $cgi = Gantry::Engine::CGI->new(
        config => {
            dbconn => 'dbi:Pg:dbname=appdb',
            dbuser => 'someone',
            dbpass => 'not_tellin',
            page_size => 15,
        }
    );

Note: if you don't use Gantry::Conf, all config parameters for your
CGI script must be at the app level and they will only appear in the
config hash of the Gantry::Engine::CGI object.

=head2 How do I specify Gantry::Conf configuration values?

Bigtop does not currently generate CGI scripts which use Gantry::Conf.
I hope to change this soon.

=head2 How do I control CGI locations?

The locations your CGI script can manage will come from your controllers.
Each controller should have either a location or a rel_location directive.
locations are used as is, rel_locations have the location for the app
prepended.  Note that the app location is optional and defaults to '/'.
Do not start or end locations or rel_locations with / (except that the
app level location can be '/').

    app MyAppName {
        location `/mysubsite`;
        #... table definitions here
        controller SomeTable {
            rel_location `sometable`;
        }
        controller Odd {
            location `/pretends/to_be/part_of/other/app/odd`;
        }
    }

For the Gantry CGI backend, this leads to the following excerpt in app.cgi:

    my $cgi = Gantry::Endgin::CGI->new(
        locations => {
            '/mysubsite' => 'MyAppName',
            '/mysubsite/sometable' => 'MyAppName::SomeTable',
            '/pretends/to_be/part_of/other/app/odd' => 'MyAppName::Odd',
        },
    );

=head1 httpd.conf

=head2 What do HttpdConf backends make?

HttpdConf backends make docs/httpd.conf suitable for use in a mod_perl
apache conf file or as the value of an Include statement there.

=head2 How do I specify PerlSetVar values for mod_perl?

Use config blocks to specify PerlSetVars:

    config {
        engine MP13;
        # You could use MP20 instead of MP13.
        Init      Std    {}
        HttpdConf Gantry {}
    }
    app Name {
        config {
            variable_1 value;
            variable_2 `multi-word value`;
            overriden  global;
        }
        controller SubPage {
            rel_location subpage;
            config {
                overriden subpage;
            }
        }
    }

Note that the SubPage controller includes its own value for the overriden
variable.  This results in a PerlSetVar statement in the location block
for this controller.  The app level config block results in three
PerlSetVars appearing in the root location block.  Output in docs/httpd.conf:

    <Perl>
        #!/usr/bin/perl

        use Name;
        use Name::SubPage;
    </Perl>

    <Location />
        PerlSetVar variable_1 value
        PerlSetVar variable_2 multi-word value
        PerlSetVar overriden global
    </Location>

    <Location /subpage>
        SetHandler  perl-script
        PerlHandler Name::SubPage
        PerlSetVar overriden subpage

    </Location>

The Control backend is responsible for including these in site object
initialization (in its init method) and for making accessors for them.
Marking them no_accessor prevents both of those things
(see Controllers below).

=head2 How do I use Gantry::Conf for mod_perl?

Gantry::Conf allows for all sorts of applications to be configured in
all sorts of ways in one place.  It allows multiple apps to share
configuration information, even if they run on different servers.
It allows multiple instances of the same app to use different configuration
information, even if they run in the same apache server.  See the docs on
Gantry::Conf for details on its use.

    config {
        engine MP13;
        Init      Std     {}
        Conf      General {}
        HttpdConf Gantry  { skip_config 1; }
    }
    app Name {
        literal Location `PerlSetVar GantryConfInstance example`;
        config {
            variable_1 value;
            variable_2 `multi-word value`;
            overriden  global;
        }
        controller SubPage {
            rel_location subpage;
            config {
                overriden subpage;
            }
        }
    }

The process is very similar for Gantry::Conf as for PerlSetVars.  There
are a couple of key differences.  First, you should add the Conf General
backend.  Second, you should mark the HttpdConf Gantry backend with
skip_config, so it won't write PerlSetVars.  Finally, you must still
supply one PerlSetVar: GantryConfInstance, which Gantry uses to retrieve
the proper configuration.  Since you are skipping the config block during
httpd.conf generation, you must include a literal HttpdConf statement for it.

This yields two output files: a shorter httpd.conf and a new Name.conf.
Here's docs/httpd.conf:

    <Perl>
        #!/usr/bin/perl

        use Name;
        use Name::SubPage;
    </Perl>

    <Location />
        PerlSetVar GantryConfInstance example
    </Location>

    <Location /subpage>
        SetHandler  perl-script
        PerlHandler Name::SubPage
    </Location>

Here's docs/Name.conf:

    variable_1 value
    variable_2 multi-word value
    overriden global

    <GantryLocation /subpage>
        overriden subpage
    </GantryLocation>

=head2 How do I put extra statements into my Apache Perl block?

There are two ways to put extra things into the generated Perl block,
depending on where things should appear.  If you need something to come
immediately after the #!/usr/bin/perl line (like a use lib), do this:

    literal PerlTop `    use lib '/home/myuser/src/lib';`;

As with all literals, you must enclose your content in backquotes and mind
your own syntax inside those quotes.  You are responsible for whitespace
management, except that one new line will be added at the end if your literal
text does NOT have trailing whitespace.  So the above will get one new
line added to it.

PerlTop blocks always appear in the generated httpd.conf in the order
they appear in the Bigtop file and start immediately after the shebang line.

Note that PerlTop may not be soon enough, for statments like
C<use Apache::DBI>, if your httpd.conf has an earlier Perl block.
In that case, you must work manually.

If you don't care where the statements fall, you can use a literal PerlBlock
statement:

    literal PerlBlock `use SomeModule;`;

These and your controller blocks produce output in the order they appear
in the bigtop file.

=head2 How do I put extra directives into httpd.conf?

You may include arbitrary things outside of the generated blocks like this:

    literal HttpdConf `Include /some/file.conf`;

These appear intermixed with location blocks in the same order as in the
bigtop file.  All of these come after the <Perl> block.

You may include additional directives in the base location for the app with
literal Location statements:

    literal Location
    `    AuthType Basic
        AuthName "Your Realm"
        PerlAuthenHandler Gantry::Control::C::Authen
        PerlAuthzHandler  Gantry::Control::C::Authz
        require valid-user`;

These appear literally immediately below the PerlSetVar statements.

You may include directives in other location blocks by putting literal
Location statments inside your controller's block:

    controller SecureSubLocation {
        # ...
        literal Location `    require group SecretAgent`;
    }

=head1 Gantry conrollers

=head2 What does the Gantry Control backend make?

Gantry controllers usually make two pieces: a stub and a GEN module
(but the GEN module will not be made if there are no methods to put in
it).  The GEN module is designed to be regenerated as changes to the
app arise.  For this reason, you should not edit the GEN module.
Rather, put your code in the stub.

    app Apps::Name {
        #...
        controller SomeModule {
            #...
        }
    }

This will make Apps/Name/SomeModule.pm and Apps/Name/GEN/SomeModule.pm.
You shouldn't need to edit the GEN module.  If it is wrong, update your
Bigtop file and regenerate.

=head2 How do I associate a controller with a table?

Use a controls_table statment to associate your controller with a table:

    controller SomeTableController {
        controls_table sometable;
    }

This has one basic effect: it includes a use statement for the
table's model module in your stub and GEN modules.  That use statement
will import the abbreviated model name.  In the example the table has
a name like:

    package Apps::Name::Model::sometable;

But, it exports C<$SOMETABLE> as an abbreviation for that package name.
So, the generated statement (repeated in the stub and GEN modules) is:

    use Apps::Name::Model::sometable qw( $SOMETABLE );

In addition to the basic effect of controls_table, it is also used
by methods of type AutoCRUD_form and CRUD_form to make sure the
requested fields are available in the controlled table.

Note, that a controller will only control one table as generated.
If you need to work with other tables, you'll have to write some code.

=head2 How do I get a stub method in my controller?

If you need a method stubbed in without useful code, you can say:

    controller Name {
        method empty is stub {
            extra_args `$id`;
        }
    }

This will make:

    #-------------------------------------------------
    # $self->empty( $id )
    #-------------------------------------------------
    sub empty {
        my ( $self, $id ) = @_;
    }

(Note that extra_args is optional.)

You then fill in the operative bits.

Note that adding stub methods to your Bigtop file once your stub module
exists will have no effect, since regeneration never alters existing stubs.
To force generation rename or delete the stub module.

=head2 How do I use Gantry's AutoCRUD?

Gantry's AutoCRUD supplies do_add, do_edit, and do_delete for simple
tables.  To use it say

    controller Simple is AutoCRUD {
        method form is AutoCRUD_form {
            form_name simple
            fields    name, address;
            extra_keys
                legend => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }

This makes the following stub:

    package Apps::AppName::Simple;

    use strict;

    use base 'Apps::AppName';
    use Apps::AppName::GEN::Simple qw(
        form
    );

    use Gantry::Plugins::AutoCRUD qw(
        do_add
        do_edit
        do_delete
        form_name
    );

    #-----------------------------------------------------------------
    # $self->form( $row )
    #-----------------------------------------------------------------
    # This method supplied by Apps::Checkbook::GEN::Trans

Bigtop makes a note in the stub for each method it is mixing in from
the GEN module.

Note that both the GEN module and Gantry::Plugins::AutoCRUD are mixins (they
export methods).  If you don't want their standard methods, don't include
them in the import lists.  But, if you don't want the ones from
Gantry::Plugins::AutoCRUD, you probably want real CRUD (see below).

=head2 How do I use Gantry's CRUD?

Gantry's AutoCRUD has quite a bit of flexibility (it has pre and post
callbacks for add, edit, and delete), but sometimes it isn't enough.
Even when it is enough, some people prefer explicit schemes to implicit
ones.  CRUD is more explicit.  To use it do this:

    controller NotSoSimple is CRUD {
        text_description `Not So Simple Item`;
        method my_crud_form is CRUD_form {
            form_name simple
            fields    name, address;
            extra_keys
                legend => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }

There are only a couple of differences from the AutoCRUD version above.  The
controller type is just CRUD; the form method is called my_crud_form and
has type CRUD_form.

Note that it is important to use a method name that ends in _form, but
don't use just _form.  The backend says:

    my ( $crud_name = $method_name ) =~ s/_form$//;

So using _form as the name (which is required for AutoCRUD) will make
Bad Things happen for CRUD.

The above produces a lot of code.  I'll show it a piece at a time with
running commentary interspersed.  It makes a CRUD object:

    my $my_crud = Gantry::Plugins::CRUD->new(
        add_action      => \&my_crud_add,
        edit_action     => \&my_crud_edit,
        delete_action   => \&my_crud_delete,
        form            => \&my_crud_form,
        redirect        => \&my_crud_redirect,
        text_descr      => 'Not So Simple Item',
        use_clean_dates => 1,
    );

It makes do_add, do_edit, and do_delete.  For example:

    #-------------------------------------------------
    # $self->do_add( )
    #-------------------------------------------------
    sub do_add {
        my $self = shift;

        $my_crud->add( $self, { data => \@_ } );
    }

(do_edit and do_delete are similar.)

Finally, it provides the callbacks.  For example:

    #-------------------------------------------------
    # $self->my_crud_add( $id )
    #-------------------------------------------------
    sub my_crud_add {
        my ( $self, $params, $data ) = @_;

        my $row = $YOUR_MODEL->create( $param );
        $row->dbi_commit();
    }

It also makes my_crud_edit, my_crud_delete, and my_crud_redirect.

Note that if you have more than one method of type CRUD_form, the bigtop
backend will make multiple crud objects (each named for its form)
and the callbacks for those objects.  But it will also make multiple
do_add, do_edit, and do_delete methods.  They will make their calls through
the proper crud object, but their names will be duplicated.  In that
case, you are on your own to change them to reasonable (i.e. non-clashing)
names.

=head1 Gantry's Class::DBI models

=head2 What does the GantryCDBI Model backend make?

The Model GantryCDBI backend makes a pair of modules for each table.
One is the stub module, the other is the GEN module.  Once made, the
stub is never regenerated, so put your code in it.  The GEN module
will be regenerated when you run bigtop.

    config {
        #...
        Model GantryCDBI {}
    }
    app Apps::Name {
        table some_table {
            #...
        }
    }

The above makes Apps::Name::Model::some_table (the stub) and
Apps::Name::Model::GEN::some_table (the GEN module).  Note that the
.pm files have exactly the same name as the table.  If you want capital
letters, use them to name the table.

Due to the way that Class::DBI binds the methods it makes on the fly, the GEN
module mixes in to the stub by using this to start its file:

    package Apps::Name::Model::some_table;

So, the disk file is named Apps/Name/Model/GEN/some_table.pm, but
the package statement is the same as the one in the stub.  This will cause
sub redefinition warnings if you put a sub in the stub with the same
name as one in the GEN module.  Models generated by Model Gantry inherit
from Gantry::Utils::Model instead of from Class::DBI.  They use inheritence
instead of mixing in.

=head2 How do I specify a primary key for my model?

Each table should have a single column primary key:

    table name {
        sequence name_seq;
        field id { is int4, primary_key, auto; }
    }

This will put PRIMARY KEY in the sql for the column and tell the
Model backend to make the column primary.  This generates:

    Apps::Name::Model::name->columns( Primary => qw/id/ );

(except that I've removed some whitespace for brevity).

=head2 How can I make my model inherit from a class of my choice?

Normally Model GantryCDBI modules inherit from Gantry::Utils::CDBI
(which inherits from Class::DBI).  You can change that with the
model_base_class statement:

    table name {
        model_base_class Gantry::Utils::AuthCDBI;
    }

The generated output will be the same, except for the base class.

=head2 How can I alter the generated model's behavior?

To change the behavior of the generated model, put code in the stub
or use model_base_class to change what it inherits from.

=head1 Gantry's home made models

=head2 What does the Gantry Model backend make?

The Gantry Model backend is simlar to the GantryCDBI Model backend.
It makes two modules for each table.  For example:

    table name {
        #...
    }

will yield App::Name::Model::name and App::Name::Model::GEN::name.
Since these inherit from Gantry::Utils::Model instead of from Class::DBI,
they don't have problems with binding run time generated methods to the
proper package.  This leaves them free to use inheritence instead of mixing
in.  The stub inherits from the GEN module which inherits from
Gantry::Utils::Model, so the GEN module begins:

    package Apps::Name::Model::GEN::name;

    use base 'Gantry::Utils::Model;

while the stub begins:

    package Apps::Name::Model::name;

    use base 'Apps::Name::Model::GEN::name';

(actually the stub is also an exporter so it can provide an abbreviated name).

This means that you can safely override methods in the GEN module by
simply writing a sub of the same name in the stub.

Summary of inheritence

    Gantry::Utils::Model
        Apps::Name::Model::GEN::name
            Apps::Name::Model::name

=head2 How do I specify a primary key for my model?

As for the other Model backends, include primary_key in the is statement
for the primary column:

    table name {
        sequence name_seq;
        field id { is int4, primary_key, auto; }
    }

You should use a sequence with the table, because Gantry::Utils::Model
relies on it.

=head2 How can I make my model inherit from a class of my choice?

To change what the GEN model inherits from use the model_base_class statement:

    table name {
        model_base_class Gantry::Utils::Model::Auth;
        #...
    }

The base class you specify should respond to the same api as
Gantry::Utils::Model (which is a subset of Class::DBI).

=head2 How can I alter the generated models behavior?

To alter the generated behavior, override the offending method in your
stub.

=cut
