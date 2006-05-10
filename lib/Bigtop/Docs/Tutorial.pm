package Bigtop::Docs::Tutorial;

=head1 Name

Bigtop::Docs::Tutorial - a simple case study of building a web app with bigtop

=head1 Note on What to Read

This document explains how to build an app of moderate complexity by typing
in a bigtop file.  Since it was written, tentmaker has come along.  It
is a browser delivered editor for bigtop files, see Bigtop::Docs::TentMaker
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
(filtering yet supported)

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

the Class::DBI::Sweet data modeler

=item *

the Template Toolkit templating system

=item *

the Gantry web application framework

=back

Partly, I made these choices because they are the ones we use in my shop.
But, truth be told, they were all that Bigtop supported when I wrote this.
It already supports CGI and Gantry's hand written data modeler.
Eventually, I hope to make the scheme work with other choices like
DBIx::NameAModule, Catalyst, Mason, etc.  Whether that happens or not
depends on my spare time or (more likely) on people interested in using
Bigtop with those modules.

=head2 The Example

Just to have an example, suppose you've taken up free-lancing (consulting,
writing, etc.).  You've chosen to represent yourself under a business
name or two.  The customers are lining up for your services, so its time
to tame your billing process.

In what follows, I will present a bigtop file a few lines at a time
with comments interspersed.  The full file is examples/billing.bigtop
in the Bigtop distribution.  Please consult it when you need to
see how all the pieces look together.

Warning: I made some of design decisions for this app just to showcase
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
distribution's examples directory.

We've actually done the hardest part by constructing the data model.  The
rest is really just typing it in.

=head2 Initial Creation

When starting an app from scratch one might use a tool like h2xs to build
diretory structures and standard files (like Changes).  This is a good
idea with bigtop too.  Simply type:

    bigtop --new Apps::Billing

This will make the Apps-Billing subdirectory of the current directory.
In it you will find Build.PL, Changes, MANIFEST, MANIFEST.SKIP, README
and directories docs, lib, and t.  Only the docs directory will have
anything in it.  It will contain apps-billing.bigtop.

You can edit that file to match the discussion that follows.  When you
run bigtop, you should be in the directory where the Changes file lives.
(If you aren't it will not build for you without strong insistence.)

The generated Bigtop file has the structure of all Bigtop files.

    config {
        Init Std { no_gen 1; }
    }
    app Apps::Billing {
    }

Note that there are two top level blocks: config and app.  Let's consider
these in separate sections.

=head2 Configuration

At the top of each bigtop file is a config section.  In it, we list a few
properties of the app and what pieces bigtop should generate for us.

The stub made with the --new option to bigtop has one block in it:

    config {
        Init Std { no_gen 1; }
    }

This specifies that the Bigtop::Init::Std module should be loaded whenever
bigtop runs.  But, the no_gen statement tells it not to do anything.  Since
Init builds Changes, README, etc. from useless stubs, you don't want it to
make them again.  Every backend can be turned off in this way.

Init Std is still listed for two reasons.  First, it shows people which
module did the Init building.  Second, it allows Bigtop::Init::Std to
register any keywords it understands.  This keeps you from having parse
errors for statements that Init Std would have understood, but the other
modules don't use.  All of this is more important for the other backends.

In addition to Init, we want a file of sql statements ready for Postgres,
an httpd.conf suitable for use with Gantry in mod_perl mode, a set
of gantry controllers, a set of gantry style Class::DBI::Sweet subclasses,
and a Template Toolkit wrapper for site navigation.  Let's add these:

 config {
     Init            Std           { no_gen 1; }
     SQL             Postgres      {}
     HttpdConf       Gantry        {}
     Control         Gantry        {}
     Model           GantryCDBI    {}
     SiteLook        GantryDefault {
         gantry_wrapper `/home/pcrow/srcgantry/root/sample_wrapper.tt`;
     }
 }

The name of the backend has a type and an implementation name.  These
can be anything, so long as there is a Bigtop::Type::ImplName in the
C<@INC> path.  So, we have asked for Bigtop::Init::Std, Bigtop::SQL::Postgres,
etc.

The last backend, Bigtop::SiteLook::GantryDefault, needs a statement in
its block to specify the location of the sample_wrapper.tt that came
with Gantry.  Some of the other backends have statements they understand.
If so, their documentation will have details.

Running bigtop at this point would make some additional files, but
they wouldn't really do anything.  Let's wait.

We should also include statements in the config block.  Statements in
Bigtop are a keyword and its value, separated by some whitespace.
The value for any config keyword is either a valid Perl identifier or
a literal string surrounded by backquotes (the ones usually found on
the tilde key).  Using backquotes for Bigtop leaves the other quotes
available for literal use in raw Perl values.

    config {
        engine          MP13;
        template_engine TT;
        #... as before
    }

In our config block there are two statements.

=over 4

=item engine

Our engine is mod_perl 1.3.x.  I picked this because we had not yet
upgraded our productions servers at work when I wrote this.

Other reasonable choices include CGI and MP20 for mod_perl 2.0.

=item template_engine

Our template engine is the Template Toolkit.  The only other choice at
present is Default which sends back content of type text/plain.

=back

=head3 Order is (somewhat) important

Note that generation usually happens in the order listed.  So, if you type:

    bigtop apps-billing.bigtop all

The generation order will be Init, SQL, ...

This seldom matters much, except that Init has to come first during
creation, since it builds the directories.

This principle is true for the other sections of the bigtop file.  So, if
order is important in the output, use that order in the bigtop file.

p.s. If you typed bigtop apps-billing.bigtop all, you need to remove
the lib/Apps subdiretory for the rest of the tutorial to go well.
Bigtop does not overwrite files it thinks you will modify.

=head2 app section

The app section has this form:

    app Apps::Billing {
        #...
    }

Everything shown below goes inside the app block.  The name is
the package name of the base controller and is also a prefix for all
other modules.  To keep your sanity, this should be the same name you
used with the --new flag to bigtop.

Our app section begins with simple statements and a config block (note that
the order probably doesn't matter).

    location `/billing`;
    authors `Phil Crow`;

The location is the base Apache Location for the application (or its
moral equivalent for cgi/fast cgi).

Authors is a comma separated list of people who should be blamed for the
app in its docs.  Note that Module::Build will not build an app with no
authors, so include at least one.

By default the first person in the authors list is the copyright holder
listed in the README and in all the module POD sections which have a
notice.  If it should be someone else, include a copyright_holder
statement with the proper name.  Use backquotes around it, if it
contains spaces or anything else that couldn't be in a Perl variable
name.

    config {
        dbconn           `dbi:Pg:dbname=billing`   => no_accessor;
        dbuser           apache;
        template_wrapper `wrapper.tt`              => no_accessor;

        root
          `/home/pcrow/Apps-Billing/html:/path/to/gantry/template/root`
                                                   => no_accessor;
        css_root  `/home/pcrow/srcgantry/root/css` => no_accessor;
        css_rootp `/css`                           => no_accessor;
        app_rootp `/billing`                       => no_accessor;
    }

You can include any PerlSetVars you like here.  They will be
copied into the root location for the app in the Apache conf
(or into the config hash of the cgi dispatch script).
Normally, an accessor will be generated for each one in the base controller
module.  But, if you mark them no_accessor, as I have above, that
accessor will not be generated.  Presumbably your framework will provide
accessors for them in that case, as gantry does for the ones shown.

My config variables are of two types: database and app navigation.

Within Gantry, database connection is handled with dbconn, dbuser, and
dbpass.  dbconn is a full DBI connection string.  (I omitted dbpass on
purpose.)  Note that if dbuser or dbpass include any characters Perl
wouldn't like in a variable name, you must backquote the string, as in:

    dbpass `s!m0n`;

The other set vars are file system paths or http locations.  Generally,
we use a suffix of p to indicate a location path and omit p for disk paths.
Of course, both of them are paths, but our location paths get the p.
Again, these paths are meaningful to gantry.

=head3 Encoding the data model

After the environmental setup is described, there are two remaining
pieces: the data model and the controllers which manage it.

We'll start with the data model.

There are two basic blocks that describe that model: sequence and table.
sequence defines a sequence and must come before the table that uses
it (since the generated SQL is in the same order as the blocks in the
bigtop file).

Currently, sequence blocks must be empty.  Some day you may be
able to control max and min values, etc. with statements in the blocks.

    sequence mycomp_seq        {}

Table blocks take this form:

    table name { ... }

Inside the braces, you can include either statements or field blocks.

    table mycompanies {
        sequence        mycomp_seq;
        foreign_display `%name`;
        ...

There are three legal statements.  We see two of them in the
my_companies table (we'll see the third in the status table below).
They are sequence and foreign_display.

sequence associates a table with a sequence.  (We could just make the type
of the id serial, but using a sequence increases flexibility.  For example,
you could share a sequence between tables.)

foreign_display controls how data from rows in the table will be abbreviated
when they are shown by controllers of other tables.  The syntax is
simple.  Inside backquotes, put a string of whatever literals you like,
combined with %column_names of your choice.  For example, if a table
should show full name based on last_name and first_name columns, you
could say:

    foreign_display `%last_name, %first_name`;

Which would generate names like

    Wonka, Willy

None of the foreign_display values in this app are that intersting.

Like other blocks, field blocks have this form:

    field name { ... }

Inside, it is a list of statements.  Some of those shown below
are specific to Gantry, in particular, many depend on its default
templates.

        field id { is int4, primary_key, assign_by_sequence; }

All fields must have an C<is> statement.  This fully specifies their
SQL properties.  Mostly, you want to list a valid SQL type (where valid
means your database understands it).  You can provide a single keyword,
a list of keywords, a backquoted string, or a comma separated combination
of those.  Back quoted strings are taken literally.

You should use the bare C<primary_key> as one attribute of the id column.
This not only generates 'PRIMARY KEY' in the SQL output, but
marks the column as primary for the Class::DBI model, etc.

There is a special keyword you may use to fill in the sequence
default: assign_by_sequence, which you may abbreviate as auto.  So the
above is equivalent to:

    field id { is int4, primary_key, `DEFAULT NEXTVAL( 'mycomp_seq' )`; }

Both of them generate this SQL:

    id int4 PRIMARY KEY DEFAULT NEXTVAL( 'mycomp_seq' ),

and they both mark id as the primary key for data modelers like Class::DBI.

Note that primary_key, assign_by_key, and auto must be bare (not inside
quotes).  Remember: backquoted strings are taken literally.

Since ids rarely appear on screen, they usually only have an is statement.
Other fields are shown to the user and thus have other statements.

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
        field descr {
            is                 varchar;
            label              Description;
            html_form_type     text;
            html_form_optional 1;
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

While there are many other statements you could use, the three shown
here are the most common.

=over 4

=item label

what the user sees on the screen as the column label in html tables where
the field appears and next to the entry elements where values for it are
entered.

=item html_form_type

the input type for this field when it appears in an html_form.
Current Gantry templates only understand select, text, and textarea.

=item html_form_optional

the field is not required even when it appears on a user input/update form.
This is not the same as C<non_essential 1;> which indicates that the
data modeler should not retrieve the value until you call an accessor for the
field.

=back

The other tables are similar.

    sequence customers_seq     {}
    table    customers         {
        sequence invoices_seq;
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
        field descr {
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

The date_select_text will appear as an html href link next to the entry
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
        field company_id {
            is                 int;
            label              `My Company`;
            refers_to          my_companies;
            html_form_type     select;
        }

If a column is a foreign key, use the refers_to statement to say which
table it points to.  Note that it must point to the primary key of the
other table and we generally assume that the key will be the unique
id column.  Bigtop::SQL::Postgres does not currently (nor is it ever likely
to) generate genuine SQL foreign keys.  If you want foreign
keys, and your database supports them, consider implementing your own SQL
backend to generate the SQL code for them.

The Gantry html_form_type for foreign key columns is C<select> which
allows the user to pick one item from a pull down list.

        field customer_id {
            is                 int;
            label              Customer;
            refers_to          customers;
            html_form_type     select;
        }
        field invoice_id {
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

You can affect the eventual appearance of the field on html forms with
various statements.  Here are two that affect textareas: html_form_rows
and html_form_cols; take a wild guess at what they do.  There is one
gotcha for text input boxes.  Since Template Toolkit uses a lot of magic
while dereferencing, to set the size of a text input box use
html_form_display_size.

        field descr {
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
        field status_id {
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
        field descr {
            is                 text;
            label              `Notes to Self`;
            html_form_type     textarea;
            html_form_optional 1;
            html_form_rows     4;
            html_form_cols     50;
        }
    }
    sequence status_seq        {}
    table    status            {
        sequence status_seq;
        foreign_display `%name: %descr`;

        field id { is int4, primary_key, assign_by_sequence; }
        field name {
            is             varchar;
            label          Name;
            html_form_type text;
        }
        field descr {
            is             varchar;
            label          Description;
            html_form_type text;
        }

        data name => `Working`, descr => `Work is in Progress, not billed`;
        data name => `Sent`,    descr => `Mailed to Customer`;
        data name => `Paid`,    descr => `Payment Received`;
    }

Here we see the final legal simple statement in a table block: data.
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
this sample.  The order is not usually important.  If you have a url
heirarchy under mod_perl, it will matter, since the httpd.conf must
list higher elements first.

    controller Status {
        controls_table   status;
        rel_location     status;
        uses             Gantry::Plugins::AutoCRUD;
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
generated module.  Basically, this amounts to adding the following to
the module's .pm file:

    use Gantry::Plugins::AutoCRUD;

[ except that there are two generated modules and both will list all
of the default exports explicitly. ]

=item text_description

This is the phrase which will appear in questions like, 'Should I really
delete this status?'

=item page_link_label

This is the text of any href link which points to this page in site
navigation.

=back

Some of these could be assumed, but they are not.  One of our principles
is explicit is better than implicit.

The real joy of using bigtop is the ease of generating running code
that you might never have to manually edit.  This is the result of
each method block in the controller block.  They take this form:

    controller Name {
        ...
        method name is type { ... }
    }

The name can be anything, but for gantry handlers, it must start with do_.
The type is governed by the backend.  Bigtop::Control::Gantry recognizes
four types: main_listing, AutoCRUD_form, CRUD_form, and stub.

    controller Status {
        ...
        method do_main is main_listing {
            title            `Status`;
            cols             name;
            header_options   Add;
            row_options      Edit, Delete;
        }

A main listing is an html table listing all the rows in the underlying
table sorted by the columns that appear in the foreign_display.  This
is not suitable for complex controllers.  But, for all the tables
in this app, it is good enough (at least until there are too many rows
in the table).

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

        method _form is AutoCRUD_form {
            form_name        status;
            fields           name, descr;
            extra_keys
                legend => `$self->path_info =~ /edit/i ? 'Edit'
                                                       : 'Add'`;
        }
    }

One of my favorite features of gantry (probably because I wrote it) is
its automated Create, Retrieve, Update, and Delete.  All you have to
do to get it is use Gantry::Plugins::AutoCRUD and implement a method
called _form, which returns a specially crafted hash describing the
the appearance of the input form along with populating its fields as
appropriate.  Bigtop::Control::Gantry can generate the proper _form method
as show here.

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

any extra keys that should be included in the hash _form returns and their
values.  The values will not be modified in any way, simply include valid
Perl code in backquotes.  Gantry's form.tt surrounds the entry elements
with a fieldset.  The legend shown here is the legend of that fieldset.

=back

    controller Company {
        controls_table   my_companies;
        rel_location     company;
        uses             Gantry::Plugins::AutoCRUD;
        text_description company;
        page_link_label  Companies;
        method do_main is main_listing {
            title            `My Companies`;
            cols             name, contact_phone;
            header_options   Add;
            row_options      Edit, Delete;
        }
        method _form is AutoCRUD_form {
            form_name        company;
            all_fields_but   id;
            extra_keys
                legend     => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }

While we can list the fields we want in an AutoCRUD_form, we can also
use all_fields_but and list the fields we don't want.

    controller Customer {
        controls_table   customers;
        rel_location     customer;
        uses             Gantry::Plugins::AutoCRUD;
        text_description customer;
        page_link_label  Customers;
        method do_main is main_listing {
            title            `Customers`;
            cols             name, contact_name, contact_phone;
            header_options   Add;
            row_options      Edit, Delete;
        }
        method _form is AutoCRUD_form {
            form_name        customer;
            all_fields_but   id;
            extra_keys
                legend     => `$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }
    controller LineItem {
        controls_table   line_items;
        rel_location     lineitem;
        uses             Gantry::Plugins::AutoCRUD, Gantry::Plugins::Calendar;
        text_description `line item`;
        page_link_label  `Line Items`;
        method do_main is main_listing {
            title            `Line Items`;
            cols             name, due_date, customer_id;
            header_options   Add;
            row_options      Edit, Delete;
        }
        method _form is AutoCRUD_form {
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

Add C<Gantry::Plugins::Calendar> to the uses list for the controller.

=item 3.

Include javascript in extra_keys in the AutoCRUD_form method block.
Use the value as shown here, but change C<line_item> to match your form_name.

=back

    controller Invoice {
        controls_table   invoices;
        rel_location     invoice;
        uses             Gantry::Plugins::AutoCRUD, Gantry::Plugins::Calendar;
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

        method _form is AutoCRUD_form {
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

    bigtop --new Apps::Billing

You can just move into the Apps-Billing directory and type

    bigtop docs/app-billing.bigtop all

Otherwise, if you typed in the file (or are using billing.bigtop from
the examples directory of the bigtop distribution) do this instead:

    bigtop --create billing.bigtop all

After a few seconds (ok, so bigtop is not speedy), all the files needed
for your app will be built in the app_dir.  In my case that is
/home/pcrow/Apps-Billing.  Running ls on that directory shows:

 Build.PL  Changes  docs  html  lib  MANIFEST  MANIFEST.SKIP  README  t

Of course, the README is meaningless and must be changed.  As should the
pod sections of the generated code in lib.  Further, the tests are only
for whether the modules compile (think C<use_ok>).

But here is what you do get.  In docs there is a file schema.postgres, which
defines your database.  To build the clean database do this (remember:
we are using postgres and you will have to supply passwords and change
user names as needed):

    createdb billing -U postgres
    psql billing -U apache < docs/schema.postgres

This builds the database, including populating the status table.

Also in docs is httpd.conf.  Depending on your setup, you may be able
to simply add

    <Perl>
        #!/usr/bin/perl
        use Apache::DBI;

        use lib '/home/pcrow/Apps-Billing/lib';
    </Perl>
    Include /home/pcrow/Apps-Billing/docs/httpd.conf

to your system httpd.conf.  For our development systems we create
virtual hosts for each app so our modification to the system conf looks more
like this:

    <VirtualHost billing.example.com>
        ServerName    billing.example.com
        DocumentRoot  /path/to/gantry/template/root
        CustomLog     /home/pcrow/logs/combined.log combined
        ErrorLog      /home/pcrow/logs/billing.err

        <Perl>
             #!/usr/bin/perl
             use Apache::DBI;  # must be at the top of the first
                               # perl block in httpd.conf

             use lib '/home/pcrow/Apps-Billing/lib';
        </Perl>

        Include       /home/pcrow/Apps-Billing/docs/httpd.conf
    </VirtualHost>

Make sure that gantry is installed on your system and that its
root directory (which is the root of its templates) is the DocumentRoot
of your virtual host (or copy the files from its root dir to the
docoument root, if you copy be sure to include the css directory).
Gantry's ./Build install will take of this for you in most cases.

Then, restart Apache and point your browser to:

    http://billing.example.com/billing/company

The app is useable at this point, but it doesn't generate pdf.

=head2 What Was Generated

The above section listed the files in the app directory and showed
how to use the docs directory files to install the app.  Here, we'll see
all the other pieces that were made by bigtop.

=head3 Templates and Styling

In the html subdirectory, lives wrapper.tt.  This is the skin of
your application.  The default includes a pleasant style sheet and
navigation links for all your controllers.  If everything is installed
correctly, and your config root variable includes the html directory
in its path, your app will be styled.  If not, you will have to adjust
PerlSetVars and file locations until Apache can find these things:

=over 4

=item wrapper.tt

include a path to its directory in your root config variable

=item gantry's templates

include a path to their directory in your root config variable

=item css directory

include a path to this in your css_root config variable

=item css location

the config variable should be /css

=back
    
Finally C<css/default.css> must live in the document root for the server.

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

Each one of these modules inherits from Gantry::Utils::CDBI, which
is a Class::DBI::Sweet subclass.  It correctly handles database connections
in a mod_perl environment for them (provided you use C<Apache::DBI> at the
TOP of your first <Perl> block, as shown in the confs above).

=back

This concludes the tutorial.  Feel free to add the pdf and task management
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
