package Bigtop::Docs::Tutorial;

=head1 Name

Bigtop::Docs::Tutorial - a simple case study of building a web app with bigtop

=head1 Note on What to Read

This document explains how to build an app of moderate complexity by typing
in a bigtop file.  Since it was written, tentmaker has come along.  It
is a browser delivered editor for bigtop files, see Bigtop::Docs::TentTut
for details.

If you need a simpler example than the one shown here, consider
the one table address book example in Gantry::Docs::Tutorial.

=head1 Driving Idea

Many (not all) applications are mostly data managers.  That is, they are
really intermediaries between users and various tables in a database.
A bigtop file is meant to be a single place to describe all (or practically
all) facits of the data in an application.  This includes at least:

=over 4

=item *

The name and special features of each controller.

=item *

The name of each table in the database.

=item *

A description of each column (field) in each table in the database.
This includes at least:

=over 4

=item *

its name and SQL type

=item *

the label the user sees for it when it appears on the screen

=item *

what type of html form element the user uses to enter or update it

=item *

how the data is validated and filtered on its way into and out of the database
(filtering not yet supported)

=item *

which table the field refers to if it is a foreign key

=item *

etc.

=back

=back

All of these things, and more, are described in a Bigtop file.  That file
can be given to bigtop to build the application.  Once it is built, it
can be safely rebuilt so that only the generated bits are changed (this is
accomplished by maintaining a clean separation between generated and hand
edited files, and by config options in the bigtop file).

Notice that nothing in the above has committed you or me to any particular
web application framework, data modeling scheme, templating system,
or web server.  Bigtop is neutral (think big tent), at least for
Perl apps delivered via the web.

=head1 A Working Example

Here I will present a small, but useable application.  It's purpose is
to teach you the syntax of the bigtop.

=head2 The Assumptions I'm About to Make

In order to explain the bigtop syntax, I'm going to exhibit a
particular example.  It will use the following:

=over 4

=item *

the Apache web server running mod_perl 1.3

=item *

the Postgres database

=item *

the DBIx::Class data modeler

=item *

the Template Toolkit templating system

=item *

the Gantry web application framework

=back

I made these choices just for concreteness.  Bigtop already supports CGI,
Gantry's hand written data modeler, and Class::DBI::Sweet.  Eventually, I
hope to make the scheme work with other choices like Catalyst, Mason, etc.
Whether that happens or not depends on my spare time or (more likely) on
people interested in using Bigtop with those modules.

=head2 The Example

Just to have an example, suppose you've taken up free-lancing (consulting,
writing, etc.).  You've chosen to represent yourself under a business
name or two.  The customers are lining up for your services, so its time
to tame your billing process.

In what follows, I will present a bigtop file a few lines at a time
with comments interspersed.  The full file is examples/billing.bigtop
in the Bigtop distribution.  Please consult it when you need to
see how all the pieces look together.

Caveat: I made some of design decisions for this app just to showcase
Bigtop and how it interacts with Gantry.  But, a colleague actually uses
a very similar app for his side consulting business.  Reality is just
around the corner.

=head2 The Data Model

There are five tables in my version of the billing app:

=over 4

=item customers

people paying me

=item my_companies

the names I use when doing business

=item invoices

bills I email to the customers

=item line_items

the tasks that are listed on the invoices

=item status

a code for whether the invoice is under construction, mailed, or payed

=back

There is a nice picture of the data model in billing_model.png in the
distribution's examples directory.  If you're viewing with a browser this
might help:

=for html <img src='http://www.usegantry.org/images/billing_model.png' alt='Billing Data Model' />

We've actually done the hardest part by constructing the data model.  The
rest is really just typing it in.

=head2 Initial Creation

When starting an app from scratch one might use a tool like h2xs to build
diretory structures and standard files (like Changes).  This is a good
idea with bigtop too.  We could just run bigtop to make a default app:

    bigtop --new Billing

Instead we can make it do a lot of initial work for us if we give some
information about our data model.  That could be as simple as listing the
tables:

    bigtop -n Billing customers my_companies \
            invoices line_items status

Or, we could go further and tell it about the foreign key relationships
between the tables:

    bigtop -n Billing 'customers<-invoices
    invoices->status invoices->my_companies
    line_items->customers line_items->invoices'

Pick one of the above versions to start following the discussion below.

Since this document started before the -n flag to arguments, the
billing.bigtop file it describes will differ from yours if you use
either of the -n versions above.  But, the differences are mainly in the
order in which things appear.  For instance, when I typed in the file
I chose to keep all the tables together and they come first.  Then
the controllers follow as a group.  With -n each table/controller
pair will appear in the order of first appearance of the table name
on the command line.  There are other similar differences, but all of
them are only cosmetic.  All the commands are the same and have the
same effect, even if the order differs slightly.

Any of the bigtop -n options above will make the Billing subdirectory of
the current directory.  In it you will find many files including: Build.PL,
Changes, MANIFEST, MANIFEST.SKIP, README plus directories: docs, html, lib,
and t.  The directories will have lots of goodies, including:
docs/schema.sqlite for building a quick test database with sqlite,
html/genwrapper.tt a template toolkit wrapper providing a tan theme for the
app, a set of models for the tables, and a set of controllers for those
tables.  Finally, the docs directory will have billing.bigtop, which will
edit until it describes our app more correctly.

All the tables will have the same default columns: id, ident, description,
created, and modified.  The ones on the tail end of a foreign key
will also have a column for that foreign key.

At this point, we could create the database and start the app.  But since
the tables don't store our actual data, it is better to wait.

We will now begin editing docs/billing.bigtop.  After we edit it,
we will regenerate the app.  When you run bigtop to do that, you should
be in the directory where the Changes file lives.  (If you aren't, it will
not build for you without strong insistence.)

Before looking at the generated bigtop file (which is a little over
200 lines), let's consider the basic structure of bigtop files.  They all
look like this:

    config {
        engine CGI;
        template_engine TT;
        # ...
    }
    app Billing {
        # ...
    }

Note that there are two top level blocks: config and app.  Let's consider
these in separate sections.  First, note that any line whose first
non-whitespace character is a pound sign is ignored as a comment.

=head2 Configuration

At the top of each bigtop file is a config section.  In it, we list a few
properties of the app and what pieces bigtop should generate for us.

With the --new option to bigtop the config section looks like this:

 config {
     engine          CGI;
     template_engine TT;

     Init      Std             {}
     SQL       SQLite          {}
     SQL       Postgres        {}
     SQL       MySQL           {}
     CGI       Gantry          { with_server 1; gen_root 1; flex_db 1; }
     Control   Gantry          { dbix 1; }
     Model     GantryDBIxClass {}
     SiteLook  GantryDefault   {}
 }

First there are two statements.  They request the engine and template
engine which will service the app.  This one will run under CGI (for
the time being) and will rely on Template Toolkit for output formatting.
When we are ready to move to mod_perl, we can simply change the engine,
add a backend (HttpdConf Gantry), regenerate, and be ready to go.

After the statements is a list of the backends which built things for us.
Take this line for example:

        Init            Std             {}

This specifies that the Bigtop::Backend::Init::Std module should be loaded
whenever bigtop runs.  We could load the backend, but ask it not to do
anything by changing this statement to:

        Init            Std             { no_gen 1; }

Initially (as it were) Init Std builds lots of things, like Changes, README,
and Build.PL.  After that, all it ever does is update MANIFST.  By setting
no_gen, you ask it not to do that; presumably because you have a more
manual scheme in mind for MANIFEST maintenance.  Every backend can be turned
off in this way.  Turning off a backend, instead of removing it, allows
it to register its keywords.  If your source file uses keywords specific
to a backend, failing to include that backend will lead to parse errors.
Turning off the backend lets people know you used it in the past and lets
the Parser know you want it to recognize the backend's keywords.

In addition to Init, bigtop put seven other backends to work for us.
Three of these build schema files for databases, making it easier to
move between them.  For instance, it is often convenient to start work
on an app with a sqlite database, then migrate to one of the others
for deployment.

The other four backends each do a different thing (as indicated by their
different types).  CGI Gantry makes a CGI script ready for immediate
deployment to our cgi-bin directory.  Since with_server has a true
value, it also makes a handy stand alone server we can use during initial
development.  The gen_root statement adds a config param called root
pointing to the html subdirectory (more on root and other config params
later).

Control Gantry makes the controllers in the lib subdirectory.
Model GantryDBIxClass makes models for use with the DBIx::Class ORM.
Finally, SiteLook GantryDefault makes a TT wrapper.

So, from these examples, we've learned that the name of the backend has
a type and an implementation name.  These can be anything, so long as
there is a Bigtop::Backend::Type::ImplName in the C<@INC> path.  So, we
have asked for Bigtop::Backend::Init::Std, Bigtop::Backend::SQL::SQLite,
etc.  There is some advice on building your own backend in
Bigtop::Docs::Modules.

=head3 Order is (somewhat) important

Note that generation usually happens in the order listed.  So, if you type:

    bigtop billing.bigtop all

The generation order will be Init, SQL, ...

This seldom matters much, except that Init has to come first during
creation, since it builds the directories.

This principle is true for the other sections of the bigtop file.  So, if
order is important in the output, use that order in the bigtop file.

=head2 app section

The app section has this form:

 app Billing {
     #...
 }

Everything shown below is inside the app block, but we will update
things according to our billing app spec.  The name is the package
name of the base controller and is also a prefix for all other modules.

    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
    }

You can include any config parameters you like in the app level config block.
The backends will move them into the proper place for app configuration.
For example, the CGI Gantry backend will put them into a hash in the
CGI script (and stand alone server).  The HttpdConf Gantry backend would
instead make them PerlSetVars.  Later we will see how to use Gantry::Conf,
then the Config General backend will put them into a flat file readable
by Config::General.

Normally, an accessor will be generated for each one in the base controller
module.  But, if you mark them no_accessor, as bigtop did above,
that accessor will not be generated.  Presumbably your framework will provide
accessors for them in that case, as Gantry does for the ones shown.

These config variables are of two types: database and app navigation.

Within Gantry, database connection is handled with dbconn, dbuser, and
dbpass.  dbconn is a full DBI connection string.  (SQLite doesn't use
dbuser or dbpass, so bigtop doesn't generate them.)  Note that if dbuser
or dbpass include any characters Perl wouldn't like in a variable name,
you must backquote the string, as in:

    dbpass `s!m0n` => no_accessor;

The other parameter is the name of the generated TT wrapper.  It lives
in the html directory.

=head3 Encoding the data model

After the environmental setup is described, there are two remaining
pieces: the data model and the controllers which manage it.

We'll start with the data model.

For this app there is one basic block that describe that model: table.

Table blocks take this form:

    table name { ... }

Inside the braces, you can include either statements or field blocks.  There
are three legal statements.  One of them was supplied for us: foreign_display.
It comes after the gernated fields.

    table my_companies {
        # ... generated fields
        foriegn_display `%ident`;

We want to change this from C<`%ident`> to C<`%name`>.

This controls what is displayed when other tables refer to this one.  In
this case, they will see the name of the company.  If there were people
in a table, foreign_display might be C<`%last, %first`>.  So, percent followed
by a column name will be replaced with the value of that column for each
row.  Note that the percent sign in the value requires us to surround
all foreign_display values with backquotes.

We'll use the data statement in the status table below.  The third statement
is useful only if you want to use Postgres sequences.

The rest of the customers table is a set of field blocks.  Like other blocks,
field blocks have this form:

    field name { ... }

Inside is a list of statements.  Some of those shown below
are specific to Gantry, in particular, many depend on its default
templates.

        field id {
            is int4, primary_key, auto;
        }

All fields must have an C<is> statement.  This fully specifies their
SQL properties.  Mostly, you want to list a valid SQL type (where valid
means your database understands it).  You can provide a single keyword,
a list of keywords, a backquoted string, or a comma separated combination
of those.  Back quoted strings are taken literally.

You may use the C<int4> type even if your database doesn't understand
it.  Then the backend for your database will convert it into a reasonable
integer type.  You may always choose to be explicit instead of relying
on that magic.

You should use the bare C<primary_key> as one attribute of the id column.
This not only generates 'PRIMARY KEY' in the SQL output, but
marks the column as primary for the ORM.

There is a special keyword you may use to fill in the primary key by
default: C<auto>.  The SQL for this request varies by database, but
all three supported databases work properly.

Note that primary_key and auto must be bare (not inside
quotes).  Remember: backquoted strings are taken literally.

Since ids rarely appear on screen, they usually only have an is statement.
Other fields are shown to the user and thus have other statements.
When bigtop makes a new app from a list of tables, it puts five columns in
each table: id, ident, description, created, and modified.  If you included
ASCII art table relationships, other fields will be generated to represent
them.  We talked about id above, and we don't need to change it.  The other
fields are too generic for our billing app.  So, we finally have a bit of
work to do (other than changing the foreign_display).

Here is what the generated ident field block looks like:

        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }

The description field looks just like it with the name changed.  The created
and modified fields are more like this:

        field created {
            is date;
        }

These are meant to be managed internally, not to be shown to the user.
For now, we'll keep the created and modified fields (even though they
aren't in the model as we originally drew it).  But, we won't do anything
with them, so if you don't like them, delete them.

We need to change the name of the ident field to name and its label
to Name.  We wanted a description field, so we'll keep it.  But we don't want
to require it, so add an html_form_optional statement:

        field name {
            is             varchar;
            label          Name;
            html_form_type text;
        }
        field description {
            is                 varchar;
            label              Description;
            html_form_type     text;
            html_form_optional 1;
        }

I've also added some whitespace to make things look a little better.  Any
whitespace between the tokens is ignored by bigtop.  In fact, if you
use tentmaker, all whitespace is normalized.  So, my extra internal
spacing would be removed on any trip through tentmaker.

To finish the my_companies table, we need to add the rest of the contact
information to it.  Simply copy the address field, paste it six times
and change the field names and labels, until your customers table has these:

        field city {
            is             varchar;
            label          City;
            html_form_type text;
        }
        field state {
            is             varchar;
            label          State;
            html_form_type text;
        }
        field zip {
            is             varchar;
            label          Zip;
            html_form_type text;
        }
        field contact_name  {
            is                 varchar;
            label              `Contact Name`;
            html_form_type     text;
        }
        field contact_email {
            is                 varchar;
            label              `Contact Email`;
            html_form_type     text;
        }
        field contact_phone {
            is                 varchar;
            label              `Contact Phone`;
            html_form_type     text;
        }
    }

While there are many other statements you could use, the four shown
here are the most common.

=over 4

=item is

SQL type information

=item label

what the user sees on the screen as the column label in HTML tables where
the field appears and next to the entry elements where values for it are
entered.

=item html_form_type

the input type for this field when it appears in an HTML form.
Current Gantry templates only understand select, text, textarea, and
display.

=item html_form_optional

the field is not required even when it appears on a user input/update form.
This is not the same as C<non_essential 1;> which indicates that the
data modeler should not retrieve the value until you call an accessor for the
field.

=back

The other tables are similar.

    table    customers         {
        foreign_display `%name`;

        field id { is int4, primary_key, assign_by_sequence; }
        field name {
            is             varchar;
            label          Name;
            html_form_type text;
        }
        field address {
            is             varchar;
            label          Address;
            html_form_type text;
        }
        field city {
            is             varchar;
            label          City;
            html_form_type text;
        }
        field state {
            is             varchar;
            label          State;
            html_form_type text;
        }
        field zip {
            is             varchar;
            label          Zip;
            html_form_type text;
        }
        field description {
            is                 varchar;
            label              Description;
            html_form_type     text;
            html_form_optional 1;
        }
        field contact_name  {
            is                 varchar;
            label              `Contact Name`;
            html_form_type     text;
            html_form_optional 1;
        }
        field contact_email {
            is                 varchar;
            label              `Contact Email`;
            html_form_type     text;
            html_form_optional 1;
        }
        field contact_phone {
            is                 varchar;
            label              `Contact Phone`;
            html_form_type     text;
            html_form_optional 1;
        }
    }

Easy date handling is a key feature of Bigtop and Gantry.  The line item
table has a due date for the task it describes:

    sequence line_items_seq    {}
    table    line_items        {
        sequence line_items_seq;
        foreign_display `%name`;

        field id { is int4, primary_key, assign_by_sequence; }
        field due_date {
            is               date;
            label            `Due Date`;
            date_select_text Select;
            html_form_type   text;
        }

The date_select_text will appear as an HTML href link next to the entry
field for the date.  If the user clicks the link, a popup will display
an intuitive calendar.  If the user clicks a date on the popup calendar,
the text input box will be populated with that date.

Of course, this behavior is driven by the controller.
For example, see the LineItem controller below.

        field name {
            is               varchar;
            label            Name;
            html_form_type   text;
        }
        field my_companies {
            is                 int4;
            label              `My Company`;
            refers_to          my_companies;
            html_form_type     select;
        }

Because we used the -> notation when running bigtop originally, the
foreign key fields are already present.  But here is how to add one
manually: use the refers_to statement to say which table it points to.
Note that it must point to the primary key of the other table and we
generally assume that the key will be the unique id column.
Bigtop::Backend::SQL::Postgres does not currently (nor is it ever likely
to) generate genuine SQL foreign keys.  If you want foreign
keys, and your database supports them, consider implementing your own SQL
backend to generate the SQL code for them.

Note that when we used bigtop, it chose the foreign key column names
to match the foreign table names exactly.  Our original data model
diagram used slightly different names.  If you want the bigtop file
to match the picture, change the names of the foreign key fields.

The Gantry html_form_type for foreign key columns is C<select> which
allows the user to pick one item from a pull down list.

        field customers {
            is                 int;
            label              Customer;
            refers_to          customers;
            html_form_type     select;
        }
        field invoices {
            is                 int;
            label              `Invoice Number`;
            refers_to          invoices;
            html_form_type     select;
        }
        field hours {
            is                 int;
            label              Hours;
            html_form_type     text;
        }
        field charge_per_hour {
            is                 int;
            label              Rate;
            html_form_type     text;
        }
        field notes {
            is                 text;
            label              `Notes to Customer`;
            html_form_type     textarea;
            html_form_optional 1;
            html_form_rows     4;
            html_form_cols     50;
        }

You can affect the eventual appearance of the field on HTML forms with
various statements.  Here are two that affect textareas: html_form_rows
and html_form_cols; take a wild guess at what they do.  There is one
gotcha for text input boxes.  Since Template Toolkit uses a lot of magic
while dereferencing, to set the size of a text input box use
html_form_display_size.

        field description {
            is                 text;
            label              `Notes to Self`;
            html_form_type     textarea;
            html_form_optional 1;
            html_form_rows     4;
            html_form_cols     50;
        }
    }
    sequence invoices_seq      {}
    table    invoices          {
        sequence invoices_seq;
        foreign_display `%number`;

        field id { is int4, primary_key, assign_by_sequence; }
        field number {
            is                 int;
            label              Number;
            html_form_type     text;
        }
        field status {
            is                 int;
            label              Status;
            refers_to          status;
            html_form_type     select;
        }
        field sent {
            is                 date;
            label              `Sent On`;
            date_select_text   `Popup Calendar`;
            html_form_type     text;
            html_form_optional 1;
        }
        field paid {
            is                 date;
            label              `Paid On`;
            date_select_text   `Popup Calendar`;
            html_form_type     text;
            html_form_optional 1;
        }
        field company_id {
            is                 int;
            label              `My Company`;
            refers_to          my_companies;
            html_form_type     select;
        }
        field customer_id {
            is                 int;
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
        field description {
            is                 text;
            label              `Notes to Self`;
            html_form_type     textarea;
            html_form_optional 1;
            html_form_rows     4;
            html_form_cols     50;
        }
    }
    table    status            {
        foreign_display `%name: %description`;

        field id { is int4, primary_key, assign_by_sequence; }
        field name {
            is             varchar;
            label          Name;
            html_form_type text;
        }
        field description {
            is             varchar;
            label          Description;
            html_form_type text;
        }

        data name => `Working`, description => `Work in Progress, not billed`;
        data name => `Sent`,    description => `Mailed to Customer`;
        data name => `Paid`,    description => `Payment Received`;
    }

Here we see another legal simple statement in a table block: data.
Use it as many times as you need to make rows in the table.  In this case,
we want statuses which the user could edit.  But, we want some good
initial values.

Each data statement will translate directly to an C<INSERT INTO> statement
for the table.  This allows you to populate static tables whenever you
build a new version of the database from the generated SQL.  So, you shouldn't
directly set the id, if your table has a sequence.  Other than that, you
can pick any columns you want.  Only the ones you list will be included
in the insertion.

=head2 The Controllers

Now that we have seen the data model and how to tell bigtop about it,
we are ready for the controllers.

As with tables, controllers are defined with a block:

    controller Name { ... }

There is usually a controller for each table and that is the case in
this sample.  The order is not usually important.  If you have a URL
heirarchy under mod_perl, it will matter, since the httpd.conf must
list higher elements first.

    controller Status is AutoCRUD {
        controls_table   status;
        rel_location     status;
        text_description status;
        page_link_label  Status;
        ...
    }

Here are some of the simple statements you can use in a controller block:

=over 4

=item controls_table

This makes the fundamental association between the controller module and
the table it manages.  The value must be a table defined somewhere in
the bigtop file.

=item rel_location

This will be the Apache Location (relative to the app level location) for this
controller.  (You could also specify the location absolutely by replacing
rel_location with location.)

=item uses

This is a comma separated list of modules which should be used by the
generated modules.  Basically, this amounts to adding the following to
the controller's stub and GEN modules:

    use SomeModule;

[ except that both use statements will list all
of the default exports explicitly. ]

Remember that stubs are never regenerated (unless you delete or rename
them), so adding a use statement to your controller will not work for the
stub once it is built.

=item gen_uses

Just like uses, except that the modules are only used in the GEN module.

=item stub_uses

Just like uses, except that the modules are only used in the stub module.
This still won't alter an existing stub module.

=item text_description

This is the phrase which will appear in questions like, 'Should I really
delete this status?'

=item page_link_label

This is the text of any href link which points to this page in site
navigation.

=back

When you supply tables to bigtop during initial app creation, or with
the --add flag, most of these statements are used and given good
default values based purely on the name of the table.  But, machine
generated names often leave something to be desired, so you'll want to
look them over to make sure they read well.

The real joy of using bigtop is the ease of generating running code
that you might never have to manually edit.  This is the result of
each method block in the controller block.  They take this form:

    controller Name is type {
        ...
        method name is type { ... }
    }

The name can be anything, but for Gantry handlers, it must start with do_.
The type is governed by the backend.  Bigtop::Backend::Control::Gantry
recognizes four types: main_listing, AutoCRUD_form, CRUD_form, and stub.

    controller Status is AutoCRUD {
        ...
        method do_main is main_listing {
            title            `Status`;
            cols             name;
            header_options   Add;
            row_options      Edit, Delete;
        }

A main listing is an HTML table listing of rows in the underlying
table sorted by the columns that appear in the foreign_display.  This
is not suitable for complex controllers.  But, for all the tables
in this app, it is good enough (at least until there are too many rows
in the table).  To control the number of rows on each page of listing
output add this:

            rows 20;

Alternatively, you could add:

            paged_conf listing_rows

where listing_rows is the name of an accessor on your site object (usually
that accessor is generated by defining a conf variable of the same name
in the app level config block:

    config {
        #...
        listing_rows 15;
    }

The simple statements in a main_listing method block are:

=over 4

=item title

what appears in the browser window title bar.

=item cols

which columns to show in the output.

=item header_options

links which appear at the far right of the title bar.  Here we allow
the user to add new statuses.

=item row_options

links which appear at the far right of each row in the table.  Here
we allow users to edit the row and to delete it.

=back

        method form is AutoCRUD_form {
            form_name        status;
            fields           name, description;
            extra_keys
                legend => `$self->path_info =~ /edit/i ? 'Edit'
                                                       : 'Add'`;
        }
    }

One of my favorite features of gantry (probably because I wrote it) is
its automated Create, Retrieve, Update, and Delete.  All you have to
do to get it is use Gantry::Plugins::AutoCRUD and implement a method
called form, which returns a specially crafted hash describing the
the appearance of the input form along with populating its fields as
appropriate.  Bigtop::Backend::Control::Gantry can generate the proper
form method as shown here.

There are three statements in an AutoCRUD_form method block:

=over 4

=item form_name

the name of the html form element.  This doesn't usually matter.
It does matter when you use the date popups (see later tables that
have dates).  Note that XHTML does not allow form elements to have names,
but until we fix our date scheme, we'll have to be in violation.

=item fields

a comma separated list of fields that should be included on the form.

=item extra_keys

any extra keys that should be included in the hash form returns and their
values.  The values will not be modified in any way, simply include valid
Perl code in backquotes.  Gantry's form.tt surrounds the entry elements
with a fieldset.  The legend shown here is the legend of that fieldset.

=back

    controller Company is AutoCRUD {
        controls_table   my_companies;
        rel_location     company;
        text_description company;
        page_link_label  Companies;
        method do_main is main_listing {
            title            `My Companies`;
            cols             name, contact_phone;
            header_options   Add;
            row_options      Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name        company;
            all_fields_but   id;
            extra_keys
                legend     => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }

While we can list the fields we want in an AutoCRUD_form, we can also
use all_fields_but and list the fields we don't want.

    controller Customer is AutoCRUD {
        controls_table   customers;
        rel_location     customer;
        text_description customer;
        page_link_label  Customers;
        method do_main is main_listing {
            title            `Customers`;
            cols             name, contact_name, contact_phone;
            header_options   Add;
            row_options      Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name        customer;
            all_fields_but   id;
            extra_keys
                legend     => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }
    controller LineItem is AutoCRUD {
        controls_table   line_items;
        rel_location     lineitem;
        uses             Gantry::Plugins::Calendar;
        text_description `line item`;
        page_link_label  `Line Items`;
        method do_main is main_listing {
            title            `Line Items`;
            cols             name, due_date, customer_id;
            header_options   Add;
            row_options      Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name        line_item;
            all_fields_but   id;
            extra_keys
                legend     => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`,
                javascript => `$self->calendar_month_js( 'line_item' )`;
        }
    }

When we discussed the line_items table, I explained breifly how the
user may chose dates.  There are really three steps in the process:

=over 4

=item 1.

Add a date_select_text statement to the field's block in the table.
The text can be anything (but remember to use backquotes if you want
spaces, or other funny characters, in it).  The user will see it as
the html href link text.

=item 2.

Put C<Gantry::Plugins::Calendar> in the C<uses> list for the controller.

=item 3.

Include javascript in C<extra_keys> in the C<AutoCRUD_form> method block.
Use the value as shown here, but change C<line_item> to match your
C<form_name>.

=back

    controller Invoice is AutoCRUD {
        controls_table   invoices;
        rel_location     invoice;
        uses             Gantry::Plugins::Calendar;
        text_description invoice;
        page_link_label  Invoices;
        method do_tasks is stub {
            extra_args   `$id`;
        }
        method do_pdf   is stub {
            extra_args   `$id`;
        }
        method do_main is main_listing {
            title            `Invoices`;
            cols             number, status_id;
            header_options   Add;
            row_options      Tasks, PDF, Edit, Delete;
        }

Row options can be anything.  Usually they are Edit and Delete.  Here we
add Tasks and PDF.  While Add, Edit, and Delete are supported by
Gantry::Plugins::AutoCRUD, any others you name will require code you hand
write.

Here we want to be able to view the tasks associated with an invoice
and to generate a PDF of the invoice which we can email to the client.

Bigtop can help you by generating stubs for these methods.  Simply include
method blocks of type stub.  For gantry dispatching, the name of the
method must be do_ followed by the lowercase name of the row option.  In
order for the methods to operate properly, they must know the id of the
row they will work on.  Include this in an extra_args statement.

        method form is AutoCRUD_form {
            form_name        invoice;
            all_fields_but   id;
            extra_keys
                legend     => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`,
                javascript => `$self->calendar_month_js( 'invoice' )`;
        }
    }
 }

This concludes our walk through the bigtop description of the billing
application.  Now it's time to build it.

=head2 Generation and Installation

Once you have a bigtop description of your application, you are ready
to build it.

If you began following along by using

    bigtop --new Apps::Billing [...]

You can just move into the Apps-Billing directory and type

    bigtop docs/app-billing.bigtop all

Otherwise, if you typed in the file (or are using billing.bigtop from
the examples directory of the bigtop distribution) do this instead:

    bigtop --create billing.bigtop all

After a few seconds, all the files needed for your app will be built in
the app_dir.  In my case that is /home/pcrow/Billing.  Running ls
on that directory shows:

 Build.PL      MANIFEST.SKIP app.db        html
 Changes       README        app.server    lib
 MANIFEST      app.cgi       docs          t

Of course, the README is meaningless and must be changed.  As should the
pod sections of the generated code in lib.  Further, the tests are minimal.
The check for broken or missing POD, whether the controller modules compile
(think C<use_ok>), and whether each controllers default page returns status
200.

But here is what you really get.  In docs there is a file schema.sqlite, which
defines your database.  To build the clean database do this:

    sqlite app.db < docs/schema.sqlite

This builds the database, including populating the status table.
Note that bigtop tried to do this during initial building, so you won't
have to do this unless you don't have sqlite installed (go install it,
it's worth it) or it has a different name.

The app is useable at this point, but it doesn't generate PDF invoices.
To start it, type:

    ./app.server [ port ]

By default app.server runs on port 8080, type an alternate port number
if that isn't suitable.

If you prefer to use Postgres or MySQL at this point, look in the docs
directory for the schema file for your database.  If it isn't there,
you need to add:

    SQL Postgres {}
    SQL MySQL    {}

to your config block and re-run bigtop:

    bigtop docs/billing.bigtop all

Then build your database as you normally would and check app.server's
POD for the proper command line flags to control database connectivity.

=head2 What Was Generated

The above section listed the files in the app directory and showed
how to use the docs directory files to install the app.  Here, we'll see
all the other pieces that were made by bigtop.

=head3 Templates and Styling

In the html subdirectory, lives genwrapper.tt.  This is the skin of
your application.  The default includes a pleasant style sheet and
navigation links for all your controllers.

=head3 Code

In the lib subdirectory is Apps/Billing where the code for the app was
built.  There you will find:

=over 4

=item Company.pm Customer.pm LineItem.pm and Status.pm

controllers for their tables.  These are only stubs. They have no code except
uses and two generic methods: get_model_name and text_descr.  The
later should probably have been called get_text_descr.

=item Invoice.pm

controller for invoice table.  Stubs only, like the other controllers, but
including stubs for do_tasks and do_pdf.  You have to fill those in
to finish the app.

=item GEN

a subdirectory which includes a mate for each of the above controllers.
Each mate has the code for do_main and _form.  This allows you to work on
the actual controller and still regenerate the mate should the data model
change.  GEN includes Company.pm, Customer.pm, Invoice.pm, LineItem.pm,
and Status.pm

=item Model

a subdirectory with a module for each table:

=over 4

=item *

customers.pm

=item *

invoices.pm

=item *

line_items.pm

=item *

my_companies.pm

=item *

status.pm

=back

Note that the names of these modules exactly match their table names.
Each one exports a scalar containing its fully qualified package name as
the table name in all caps.  For example customers.pm exports:

    $CUSTOMERS = 'Apps::Billing::Model::customers';

Controllers import this and use it to save reading and typing.

Each one of these modules inherits from Gantry::Utils::DBIxClass, which
is a DBIx::Class subclass.

=back

This concludes the tutorial.  Feel free to add the PDF and task management
pieces to the app.

=head1 Further Reading

If you long to learn more, try these:

=over 4

=item Bigtop::Docs::About

a brief litany of features plus some history of the project

=item Bigtop::Docs::Keywords

a short description of most of Bigtop syntax

=item Bigtop::Docs::QuickRef

an even shorter description of Bigtop syntax in an html table format

=item Bigtop::Docs::Syntax

a fairly complete picture of bigtop syntax

=item Bigtop::Docs::Cookbook

examples of what to type and what you get as a result

=back

=head1 Author

Phil Crow, E<lt>philcrow2000@yahoo.comE<gt>

=head1 Copyright and License

Copyright (C) 2005-6, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
