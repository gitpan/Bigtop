package Bigtop::Docs::TentRef;

=head1 Name

Bigtop::Docs::TentRef - tentmaker reference (best viewed in html)

=head1 Intro

If you haven't used tentmaker before, you probably want to start with
its tutorial: Bigtop::Docs::TentTut.  If you don't know what bigtop is,
read Bigtop::Docs::About.

Unlike the tutorial, this document assumes you have started looking
around tentmaker, but are wondering what all it can do.  Here
we will walk through it in detail.  Consider this an encyclopedia
of tentmaker (and don't complain too loudly if it is verbose and
pedantic).

After a short section on the various ways to start tentmaker, we will
turn to the tabs it offers and what they allow you to control.  There
you will find many screen shots to aid the discussion.  If you can't
see them with your current pod viewer, look them up here:
http://www.usegantry.org/images/tenttut or in the docs directory of
the Bigtop distribution.

=head1 Starting Tentmaker

There three ways to start tentmaker:

=over 4

=item --new (or -n)

If you want to start an app from scratch, you should use the --new flag.
It will give the best defaults.  Supply at least an app name:

    tentmaker -n AppName some tables here

But, for greater effect use L<ASCII Art>.

=item --add (or -a)

If you have a bigtop file, but want to augment it with additional tables,
use the --add flag.  Supply the bigtop file name and a list of tables or
L<ASCII Art>:

    tentmaker -a docs/appname.bigtop more tables

If you previously built your databse, you will have to manually alter (or
replace) it.

=item normal mode

If you just need to work with the tables and controllers which are already
in the bigtop file, start in normal mode:

    tentmaker docs/appname.bigtop

=back

No matter how you start tentmaker, remember that it is an insecure socket
server, so you need to be somewhat careful of what user runs it (never
use root) and where the server sits in your network topography (behind
a firewall is a good place).

=head2 ASCII Art

When in new or add modes, you can specify more than just table names.  You
can show their relationships.  There are three relationships you can show:
one-to-one, one-to-many, and many-to-many.  Each relationship is shown with
a binary operator between two table names.  Here's the notation:

=over 4

=item a-b one-to-one

Both tables receive a foreign key pointing to each other.

=item a->b or b<-a one-to-many

The table on the tail of the arrow receives a foreign key to the table on
the point.  The only difference is that tables are created in their overall
order of appearance.

=item <-> many-to-many

A joining table will be created with two foreign keys, one for each named
table.  The named tables each receive a many-to-many relationship through
the joining table.  (This only works if your backend and ORM understand
how to handle many-to-many relationships.  Only Model GantryDBIxClass does.)

=back

Note Well:  Your shell might want to aggressively steal the table relationship
operators shown above.  Therefore, you should put all ASCII art in single
quotes.

Any tables that don't already exist will be created in the order of their
appearance in the list of tables or ASCII art.  The relationships will
be applied to all tables, including the existing ones.  Keep in mind that
the system is not all that smart.  If you list the same relationship
repeatedly, don't be surprised if you end up with multiple foreign keys
from one table to another.  But, it won't recreate whole tables.

=head1 The Tabs in Detail

In total, there are five tabs in tentmaker:

=over 4

=item Bigtop Config

Controls only three things: the app name, what engine will serve it, and
what type of templates it will use.  But it also provides a snapshot of
the bigtop file and a way to save it.

=item App Body

The heart of the matter.  Allows you to define your tables and
controllers.

=item Backends

Controls what will be generated by bigtop.  For example, do you want SQLite,
MySQL, or Postges SQL syntax for building your database.

=item App Level Statements

Allows input of general information about the app, like the app's license,
who wrote it, and how to contact them.

=item App Config

Allows input of configuration information about the app.  This usually
includes things like database name, user, and password, but can include
any configuration your app needs.

=back

The following sections walk through these in detail with pictures.

=head1 Bigtop Config

When you start tentmaker, this is the default tab.  It looks something
like this:

=for html <img src='http://www.usegantry.org/images/tenttut/tentopening.png' alt='tentmaker opening screen' />

    http://www.usegantry.org/images/tenttut/tentopening.png

This is where you give your app a name.  But, keep in mind that names are
very sticky once you assign them.  After you build an app, it is very
painful to change the name, even with bigtop helping.

Changing your engine or template engine is much easier.  Simply select the
new one from the pull down.  Regeneration should be enough to move you.
This is not always the case, since some choices make your code
dependent on an engine.  Some of those choices are in controller code
you wrote by hand, but others are in the backend statements (see below).

That's really all there is to see here (aside from seeing the raw
bigtop source and the saving box and button).

=head1 App Body

The heart of tentmaker is the App Body tab.  If you have a single table
called address and a controller to go with it, should look like this:

=for html <img src='http://www.usegantry.org/images/tenttut/appbody.png' alt='tentmaker app body screen' />

    http://www.usegantry.org/images/tenttut/appbody.png

The tutorial shows off some of the features on the tab.  Here we will
take a more systematic approach.

In addition to having tentmaker create or augment the bigtop file during
startup, you can create things within the app body tab.  You may make any
of these things in the app body: a table (which also makes its controller),
a controller, a literal, a join table, and a sequence (which also makes
its table and controller).

Once you have the App Body elements, tentmaker makes it easy to customize
them.  Here's how.

=over 4

=item Table

An SQL table, these are the heart of an app.  If you make one, tentmaker
will make a controller to go with it.  Once you have a table, click
'edit' next to the Table label.  It will expand to look something like this:

=for html <img src='http://www.usegantry.org/images/tenttut/tableedit.png' alt='tentmaker table expanded for editing' />

    http://www.usegantry.org/images/tenttut/tableedit.png

There are four statements which affect a whole table:

=over 4

=item not_for

Should you need to hide this table from your Model or SQL backend (or both),
select from the pull down.  Indicated backends will pass over this table
as if it were not in the bigtop file.

We use this occasionally when we want to build models for our auth tables
within the app, but actually point to an external database for the data.
Then, we select not_for SQL.

=item sequence

If you use sequences to generate your primary keys in Postgres, fill in
the sequence name here.  You should get a good value by default, if you
created the sequence with tentmaker.

=item foreign_display

This controls two things: the sort order of items from this table in its
controller's do_main method and the appearance of rows from this table when
other tables' controllers refer to them.  Suppose your table stores data
about people and you want foreign tables to summarize rows with the names
of the people.  You could use this foreign_display: C<%last, %first>.
Anything abutted to the left of a percent sign must be a column in the
table.  Anything else is taken literally.

=item model_base_class

Most table models inherit from the default base class prefered by their
backend.  In the backend block, you can change that default for all the
tables in the app.  Sometimes one table needs a special parent.  This
statement allows you to pick such a parent on a table by table basis.

=back

Below the statements which apply to the whole table is the Field Quick Edit
table which was featured so heavily in the tutorial.  It looks like this:

=for html <img src='http://www.usegantry.org/images/tenttut/quickedit.png' alt='tentmaker quick edit field' />

    http://www.usegantry.org/images/tenttut/quickedit.png

There are five columns in the quick edit table:

=over 4

=item Column Name

The name of the column in the database table, but also the name of the input
element when the field appears on an add/edit form.

Changing the name of the field will change all references to it in other
parts of the bigtop file.

=item SQL Type

The type of the column in SQL.  In the quick edit box you may only supply
one type phrase.  In the full edit table, you may include as many phrases
as you like.

If you change the type to date, tentmaker will do all the needed work to
make a popup calendar for easy date selection.

=item Label

What the user sees as a label for this field when it is on the screen.

=item Optional

Indicates that this field should be optional during add/edit form validation.

=item Constraint

Any valid Data::FormValidator constraint.  Usually this is a regex, but it
could be call to a sub which returns a regex.  See the POD for
Data::FormValidator for details.  Note that if you use the exported
subs provided by Data::FormValidator modules, you must add those modules
to the uses list of the controller which will display the form for this
table.

=item Default

A literal string (or number) to use as the form element's default value.  This
will be overriden by prior user input or a good value from the database row.

=back

All of the things which appear in the quick edit table appear in the more
detailed edit tables for each field.

If you need to edit other features of your fields, you need to choose
your field in the 'Edit Field' selection box immediately under the
Create Field(s) box.  As soon as you select a field from the pull down
list, it will open for editing like this:

=for html <img src='http://www.usegantry.org/images/tenttut/fieldedit.png' alt='tentmaker field expanded for editing' />

    http://www.usegantry.org/images/tenttut/fieldedit.png

Here are the statements which apply to fields:

=over 4

=item not_for

Just as some tables confuse some backends, some fields do also.  If you need
to hide a troubling field from a backend or two, pick those backends here.

=item is

A list of items which will become phrases in the column definition in
your SQL.  Some of these are also used by AutoCRUD to sanitize the form
parameter hash prior to database changes.

You can use multiple entries for is.  That is why there are extra input boxes.
If you fill up the last box, a new one will appear as if by magic.

Normally, the first item must be a valid SQL type, where valid means anything
your database understands.  If your database is Postgres and you are using
auto-incrementing without sequences, you can just put auto in the list,
the backend will assign SERIAL as the type for you.

There are a few special bits of magic bigtop uses to keep all SQL engines
happy.  For instance, if you use int4 as the type, it will be converted by
the backend into something your database will like (it might even be
discarded, for example if you use Postgres without sequences and request
auto).

The word auto is also special.  It will instruct backends to produce SQL
so the column's value will be generated sequentially.  That will involve
actual SQL sequences only if you created a sequence for the table and
included a sequence statement.  Otherwise, the backend will tell the
databse to auto-increment without sequences.

If the column is the unique primary key, put primary_key in the list.
The Model backends also honor that.

If you use varchar, it will be converted into a suitable string even
if your database does not allow bare varchars.

Otherwise, you can put anything your database understands in a column
definition.

=item refers_to

Indicates that this column is a foreign key to another table.  The value
is the name of the other table.  Not that SQL backends do not currently
indicate that the column is a foreign key.  The foreign key concept is
managed by the ORM.

You must choose html_form_type select for these fields.  This will allow
users to select rows from the foreign table based on their foreign_display
output.

=item non_essential

Some ORMs only fetch columns selectively, if yours does, this is how
you tell it to skip this column.

=item label

What the user sees when the field is on screen.

=item html_form_type

This is the input type of the field on html forms.  All statements
which begin html_form_ are passed directly to the template hash with
html_form_ stripped from the key prefix.

=item html_form_optional

By default, all fields on a form are required.  Check this box to make
this one optional.

=item html_form_constraint

A Data::FormValidator constraint.  See its docs for all the clever options.

=item html_form_default_value

What the form.tt template will put in the HTML input element if it can't
think of anything better to use.  Better values come from prior user
input (when the user submitted a page with errors) or from the database
row object (during edit only, obviously).

=item html_form_cols and html_form_rows

These apply only to html_form_type textarea.  They specify the cols and rows
attributes of the textarea element in HTML.

=item html_form_display_size

Applies only to html_form_type text.  Specifies the size attribute of the
input text element in HTML.  (The name is not size, because TT has a
virtual method by that name.)

=item html_form_options

Applies only to html_form_type select, and then only if the field is not
a foreign_key.  Allows you to specify the pull down labels and values
for the select menu.

To enter your options, there are two input columns that look like this:

=for html <img src='http://www.usegantry.org/images/tenttut/optionsedit.png' alt='editing html form options' />

    http://www.usegantry.org/images/tenttut/optionsedit.png

Under Label, enter what you want the user to see in the pull down list.
Under Database Value, enter what you want the database to store.  Each time
you add an option, a new pair of boxes will appear.

=item date_select_text

Gantry provides a mechanism for user date entry via a popup calendar.
Enter the link text, which will trigger the popup, here.  If you set a
value here, several other changes will happen throughout the bigtop file,
so that the user can easily pick dates.  This will be set automatically
when any field's type becomes date.

=back

=item Controller

A code module for managing a table (usually showing rows from it on screen,
allowing updates to those rows).  You only need to make one of these if you
need one that doesn't control a table.  Otherwise, when you make the table,
tentmaker will make one for you.

A controller expanded for editing looks like this:

=for html <img src='http://www.usegantry.org/images/tenttut/controledit.png' alt='tentmaker controller expanded for editing' />

    http://www.usegantry.org/images/tenttut/controledit.png

As for tables, there are a number of statements which affect the whole
controller.  They are:

=over 4

=item no_gen

Check this box, if you no longer want to regenerate for this controller.
No new GEN files will be written for it.  Everything else here will be
ignored.

=item location

Specify an absolute location from the document root for the web server
for this page.

You must specify either a location or a rel_location for each controller.

=item rel_location

Specify a location for this page relative to the app's base location.
You may control the app's base location on the App Level Staatements tab,
see below.

You must specify either a location or a rel_location for each controller.

=item controls_table

The name of the table controlled by this controller.

=item uses

List any modules you want to use in your controller here.  Keep in mind
that stub modules are not regenerated, so adding to this list after
generation will not add use statements to the stub.  But, items in the
uses list are also used in the GEN modules, which will incorporate new
ones.

=item text_description

What fills in the blank in questions like 'Delete this ____?'

=item page_link_label

Supply this, if you want the page to appear in site navigation.  The value
is the link the user will have to click to come to it.

=item autocrud_helper

Most of the time bigtop supplies the proper ORM helper for Gantry's AutoCRUD
scheme without intervention (providing you check the For use with DBIx::Class
on the Control Gantry backend as appropriate).  If you want to use
a different helper, supply it here.  See
Gantry::Plugins::AutoCRUDHelper::DBIxClass for an example of what to do.

=back

In addition to the statements that affect the whole controller, there
are methods in it.  Methods come in four types, shown below.
There are two statements they all understand: no_gen (take a guess)
and extra_args.  Any extra_args -- and you can have as many as you like --
are added to the argument list in the generated routine.  Be sure to
include full perl variables, including sigils:

    $id
    @variadic

If you include an array, put it at the end, remember that they are greedy.

Here are the method types and what's unique about them:

=over 4

=item stub

This makes an uninteresting sub, which can save some typing.

=item main_listing

Makes a do_main style method which displays the rows from the controlled
table something like this:

=for html <img src='http://www.usegantry.org/images/tenttut/mainlist.png' alt='sample main listing' />

    http://www.usegantry.org/images/tenttut/main_listingout.png

Most statements apply to either main_listings or forms, not to both.
When you expand a method for editing, you see something like this:

=for html <img src='http://www.usegantry.org/images/tenttut/stubmethodedit.png' alt='editing a method' />

    http://www.usegantry.org/images/tenttut/stubmethodedit.png

Note that there is a column labeled 'Applies to.'  It tells you which
method types understand statement.  For stubs, only the first two are
available.  For main_listings we can set these extras:

=over 4

=item cols

These are the fields you want to display to the user.  Refer to them by their
field name in the controlled table.  List as many as you want.  Extra boxes
will appear when you fill up the ones intially shown.

=item col_labels

By default each column is labeled with its field's label.  If you want
something different just for the main listing, specify that here.  Labels
are used in the order given (blank boxes are ignored) until they run out.
At that point labels are taken from field definitions again.

=item header_options

The most common header option is add, allowing for new row creation.
These appear at the far right of the main listing box.  Normally, the
Label of the option is mapped to the do_* method which handles the click.
The mapping is C<'do_' . lc label>.

If you want the user to go somewhere else for the action, specify that
in the optional Location box.  Whatever you put in a Location box must
be valid Perl code which will generate a URL (usually a relative one).

Use as many header_options as you like.  Locations are always optional,
using one for an option does not force you to use one for all options.

=item row_options

These are like header options, except that they apply to each row and that
the default URL includes the row id.  If you use Locations for these,
you probably want to end the URL with C<$id>.

=item title

This is the browser window title while the main listing is on display.

=item html_template

This overrides the default results.tt with a template of your choice.
Note that generation may be somewhat less than useful if your template
expects data incompatable with results.tt.

=back

=item AutoCRUD_form

The statements which apply just to form methods are shown here:

=for html <img src='http://www.usegantry.org/images/tenttut/formedit.png' alt='editing a form' />

    http://www.usegantry.org/images/tenttut/formedit.png

=over 4

=item all_fields_but

List the fields you don't want users to enter -- think of fields like id,
created or modified dates, etc.

This is not compatible with the fields statement.

=item fields

List fields you want users to see here.

This is not compatible with the all_fields_but statement.

=item extra_keys

Form methods return hashes as expected by their templates.  This allows
you to pump extra keys into that hash.  The value must be perl code.

=item form_name

Becomes the name attribute of the form HTML element.  tentmaker will set this
when a field's SQL type becomes date or you set date_select_text for it.

See How can I let my users pick dates easily? in Gantry::Docs::FAQ for
an explanation of all the pieces needed to make date popups work.
Then be glad tentmaker already knows all that.

=back

=item CRUD_form

The statements are exactly the same as for AutoCRUD_forms, they differ only
internally so they can respond to the slightly different APIs of AutoCRUD
and CRUD.

=back

=item Literal

Literal text intended for one of the backends.  These allow you to augment
what bigtop knows how to generate.  With careful use of them, you can
usually continue to regenerate the app, without fear, even after it is in
production (regenerating on a dev box and testing before release is usually
a good idea).

It is usually better not to give the Literal a name.  If you do give
it a name, it must be one of those shown below (or it will be ignored):

Once the literal block is created, you may easily change the type from
the pull down menu.  See Bigtop::Docs::Syntax or Bigtop::Docs::Keywords
for more details of where these literals put their output.

The literal types are:

=over 4

=item SQL

Output goes directly into all docs/schema.* files.  Together with tables
(and sequences) these appear in the output in the order of their appearance.

=item Location

Output goes into the httpd.conf base level location block.

=item PerlTop

Output goes into the <Perl> block in httpd.conf immediately below the shebang
line.

=item PerlBlock

Output goes into the <Perl> block in httpd.conf after the use module
statements.

=item HttpdConf

Output goes into the httpd.conf.  Together with controller's location
these appear in the output in the order of their appearance.

=item Conf

Output goes into app.config at the top level.  This only applies when
Conf::Gantry or Conf::General is in use.

=back

=item Join Table

If you have a many-to-many relationship between two of your tables, express
that by creating a Join Table (but keep in mind that the only Model which
understands it is GantryDBIxClass).  Usually, the join table name has the
names of the other tables in it, but the choice is yours.  Here's one: 

=for html <img src='http://www.usegantry.org/images/tenttut/joiner.png' alt='editing a join table' />

    http://www.usegantry.org/images/tenttut/joiner.png

There are two statements, the first one is required:

=over 4

=item joins

List the tables which share the many-to-many relationship.  This is a
symmetric relationship, so the order makes no difference.

=item names

Normally, the names of the many-to-many relationships are formed by adding
a trailing 's' to the table names.  If you want to control the names,
enter yours here.  If you supply one, you must supply the other, even
if you don't mind the original default.  Keep the tables in the same
order, to protect everyones sanity.

=back

=item Sequence

This is an SQL sequence.  If your database understands them, and you
like them, make them.  But you never need to.  If you do make a sequence,
do it first.  That will also make a table and a controller to go with it.

=back

=head1 Backends

When I originally wrote this, there were already 10 backends and the number
is likely still growing.  Each backend represents a generator that bigtop
uses to make some part of your app.  For example, backends of type SQL make
schema files ready to create your database tables, etc. via your database's
command line tool.  Backends of type Model build code for your
Object-Relational Mapper -- ORM -- (like the classic Class::DBI or the
newer DBIx::Class).

This pane overflows, so you will need to use the scroll bar to see all
of your options.  This figure shows the top of the pane:

=for html <img src='http://www.usegantry.org/images/tenttut/backends.png' alt='Backends Pane' />

    http://www.usegantry.org/images/tenttut/backends.png

There are four columns here:

=over 4

=item Type

This describes the category of the backend in general.  For instance,
CGI backends build cgi scripts, SQL backends build SQL files to create
tables, etc.  Normally, you may only have one backend of each type
selected.  The SQL backends are an exception, you can use all of those
together.  This makes it easier to use sqlite during initial development,
then migrate to Postgres or MySQL for deployment.  You can even ship them
with your app, allowing eventual users to pick their favorite.

=item Backend

This is the name of a specific backend within a type.  For instance, CGI
Gantry makes CGI scripts that work with the Gantry framework.

=item What Does It Make?

Gives a brief summary of what this backend builds.

=item Config Statements

A list of things you can change about the backend.  All of them have No Gen,
which means that the backend will be skipped (in which case it won't build
anything).  The other statements are specific to the backend.  For instance,
checking 'Build Server' for the CGI Gantry backend results in a stand alone
server for use during testing.

=back

To change selections, check or uncheck the box in the 'Backend' column.
After you select a backend, fill in any statement values you need.

Note that if you deselect a backend, then reselect it, the statements
from the right column are not re-read.  You'll have to respecify them.
Just click in and out of the input boxes.  Fixing this is a TODO item.

Now, I will walk through all of the backend choices in alphabetical
order.

=over 4

=item CGI Gantry

Selected by default.

This will build a cgi script to drive our app.  It can also make
a stand alone server, which is highly useful for initial development.
Here are the statements it understands:

=over 4

=item No Gen

Check this if you built the app with this in mind, but no longer want
to regenerate the scripts.

=item FastCGI

If you will deploy your CGI to a FastCGI environment instead of regular
CGI, check this box.  The generated code in app.cgi will be slightly different.

=item Use Gantry::Conf

If you use Gantry::Conf, check this box.  Then remember to use the Conf
Gantry backend (see below).

=item Build Server

Selected by default.

Check this if you want a stand alone server called app.server.

=item Server Port

If you want an app.server, but the default port (8080) is not good for
you, specify an alternate port here.  Users of app.server can still
override that at the command line.

=item Generate Root Path

Selected by default.

This adds 'html' to the Template Toolkit root path, which is useful during
app.server development.  It does so by adding a root => 'html' entry
to the config section of the hash passed to the CGI engine constructor
in both app.server and app.cgi.  When you need to move to a different
directory -- say for deployment -- simply remove this statement from
the CGI Gantry backend block in the config section and add a root
parameter, with the proper path to the installed location of your templates,
to the app level config block.

Note that this will be ignored if you are using Gantry::Conf.  But the
Conf Gantry backend has the same flag.

=item Database Flexibility

Selected by default.

This only applies to app.server (so you must check Build Server for it
to have any effect).  It adds command line handling to app.server, so
the user can change database connection information at the command line.
The POD of the generated app.server explains the flags.

=item Alternate Template

Allows you to supply your own template, which controls the generation.

=back

=item Conf Gantry

Produces docs/AppName.gantry.conf suitable for immediate use in the
/etc/gantry.d directory of most Gantry::Conf deployments.  It uses all
of the information from the app and controller level config blocks.
The output is in Config::General format, which is wrapped in instance
tags.

=over 4

=item No Gen

Just as for CGI Gantry.

=item Conf Instance

The name of the conf instance for this app.  Gantry::Conf uses this to
locate the config for the app.  It must be unique among instances on the
box.

=item Conf File

By default Gantry::Conf expects to begin conf searching in /etc/gantry.conf.
If your master conf file is somewhere else, supply the absolute path here.

=item Generate Root Path

Check this if you want the backend to manufacture a 'root' config variable
giving it the value 'html.'  This works great for initial development with
the stand alone server.  You put all your templates in the html subdirectory
of the build directory, the backend tells TT where to find them.  But, the
approach breaks down for deployment.  Then you need to uncheck this box,
and add a proper root variable to the conf.  Its value should be an
absolute path to the TT templates.

=item Alternate Template

Just as for CGI Gantry.

=back

=item Conf General

This backend is not used much any more.  It is mostly surpassed by Conf Gantry.
It writes the information from your app and controller level
config blocks into docs/appname.conf in Config::General format, suitable
for use with Gantry::Conf, if you are using ConfigureVia statements.

=over 4

=item No Gen

Just as for CGI Gantry.

=item Generate Root Path

Just as for CGI Gantry, except that the root variable is put into the
Config::General file at the top level.

=item Alternate Template

Just as for CGI Gantry.

=back

=item Control Gantry

This builds the controller modules (think C in MVC) suitable for use with
Gantry.  There are two modules for every project, plus the others
listed under the App Body tab.  The app level stub module -- where
you should put your app level custom code -- is the 'Application Name'
from the Bigtop Config tab.  The generated module begins with the
prefix GEN and ends with the application name.

=over 4

=item No Gen

Just as for CGI Gantry.

=item Full Use Statement

Somewhere, you must tell Gantry to load your engine and template engine.
We prefer to do that in httpd.conf or in the CGI or stand alone server
script.  The alternative is to check this box.  Then the engine
information will be put into the base module of the application.  We
don't like that, because it informs the code of how it will be deployed.
This would require a code change to move from one engine to another,
which is inconvenient since we usually start development on the stand
alone server and move to mod_perl for final testing and deployment.
So, we prefer to control that via config information.  If you want it in
the code, go ahead, check this box.

=item Run Tests

By default, the backend makes t/10_run.t.  It sets up a little test server
which hits the default action (do_main) of each controller.  You need
an SQLite database called app.db in the build directory for the tests to
work.

If the tests work for you, great.  Add your own run tests in separate files
so bigtop can keep t/10_run.t up to date.

If the tests don't work for you (e.g. you don't use SQLite), allow bigtop
to make t/10_run.t initially, then uncheck this box and edit the generated
tests.

=item For use with DBIx::Class

Selected by default.

DBIx::Class normally works in a unique manner among ORMs.  Namely, it
uses the schema and resultset concepts.  To get these properly incorporated,
you should check this box.

=item Alternate Template

Just as for CGI Gantry.

=back

=item HttpdConf Gantry

This builds docs/httpd.conf which is suitable for use in an Include statement
in your system's httpd.conf.  We usually put that Include statement into
a virtual host for the app.

=over 4

=item Use Gantry::Conf

Just as for CGI Gantry.

=item Skip Config

Does not write any PerlSetVars into the generated output.  This is useful
if you use the old Conf General backend.  In that case, you need to add
some literals to set the GantryConfInstance and GantryConfFile.  The
later is only needed if your master conf file is not /etc/gantry.conf.

=item Full Use Statement

The flip side of the same statement in Control Gantry.  We religiously
choose the one here when we are using or planning to use mod_perl.

=item Generate Root Path

Just as for CGI Gantry.  Remember that if you choose to Use Gantry::Conf,
you should use its 'Generate Root Path' instead of the one here.

=item Alternate Template

Just as for CGI Gantry.

=back

=item Init Std

This is really useful, but mostly when you first build an app.  It is
responsible for building the directories and default distribution files
(like Changes and README).  Once the app is built, you probably want to
check the No Gen box for this one.  Alternatively, you can pick and
choose what gets overwritten, see below.

=over 4

=item No Gen

Just as for CGI Gantry.

=item Skip Build.PL, Changes, README, MANIFEST, MANIFEST.SKIP

Checking any of these will keep Init Std from overwritting that single
file.  Usually we just use No Gen on the whole backend.

=item Alternate Template

Just as for CGI Gantry.

=back

=item Model Gantry

Gantry has a native ORM scheme, select this backend if you want to use it.
I wrote it to focus my frustrations with other ORM schemes.  Then we
moved to DBIx::Class, and I've been thinking of removing this native model
scheme ever since.

=over 4

=item No Gen

Just as for CGI Gantry.

=item Models Inherit From

Gantry models usually inherit from Gantry::Utils::Model::Regular,
this lets you change their lineage.

=item Alternate Template

Just as for CGI Gantry.

=back

=item Model GantryCDBI

This backend builds Class::DBI subclasses for each table.

=over 4

=item No Gen

Just as for CGI Gantry.

=item Models Inherit From

CDBI models usually inherit from Gantry::Utils::CDBI,
this lets you change their lineage.

=item Alternate Template

Just as for CGI Gantry.

=back

=item Model GantryDBIxClass

Selected by default.

This backend builds DBIx::Class subclasses for each table and a pair of
schema modules to load them.  The schema modules are unforunately called
App::Model and App::GENModel.  Think of them as model controllers.  The
first one is for you to modify.  The second one just lists the current
tables and is regenerated with the app.

=over 4

=item No Gen

Just as for CGI Gantry.

=item Models Inherit From

CDBI models usually inherit from Gantry::Utils::DBIxClass,
this lets you change their lineage.

=item Alternate Template

Just as for CGI Gantry.

=back

=item SiteLook GantryDefault

Selected by default.

This backend copies the sample_wrapper.tt from the Gantry distribution
(or actually from its installed templates location) into html/genwrapper.tt.
Feel free to completely replace it.  If you change the file name, change
it on the App Config tab and regenerate.

=over 4

=item No Gen

Just as for CGI Gantry.

=item  Gantry Wrapper Path

Normally, this copies the sample_wrapper.tt which is installed with
your Gantry templates.  To use a different default wrapper, give a full
path to it here.

=back

=item SQL MySQL

This produces docs/schema.mysql with the SQL statements you need to
build your app's database with MySQL.

=over 4

=item No Gen

Just as for CGI Gantry.

=item Alternate Template

Just as for CGI Gantry.

=back

=item SQL Postgres

This produces docs/schema.postgres with the SQL statements you need to
build your app's database with Postgres.

=over 4

=item No Gen

Just as for CGI Gantry.

=item Alternate Template

Just as for CGI Gantry.

=back

=item SQL SQLite

Selected by default.

This produces docs/schema.sqlite with the SQL statements you need to
build your app's database with SQLite.

=over 4

=item No Gen

Just as for CGI Gantry.

=item Alternate Template

Just as for CGI Gantry.

=back

=item ???

Other backends may have appeared since this was written.

=back

=head1 App Level Statements

On this tab you will see a table of statements which describe the app that
looks like this:

=for html <img src='http://www.usegantry.org/images/tenttut/appstat.png' alt='App Level Statements' />

    http://www.usegantry.org/images/tenttut/appstat.png

Note that almost all the statements (all except base location) will only
work during initial generation.  After that, the app's base stub module
will not be regenerated.  Luckily for you, there are good defaults
if you skip this at the outset.  Then you can merely change the generated
result when you need to adjust the copyright to suit you PHB.

Here's a complete list of the statements you can control on this tab:

=over 4

=item Base Location

This is the root HTTP location for the app.  Note that you should not
set this if you are using Gantry's stand alone server.  It has no notion of
document roots and will become confused if you use this.

=item Authors

List those who should receive credit or blame for the app here.  Email
addresses are optional.

=item Contact Us

A blurb about how to send in bug reports and/or join the project.

=item Copyright Holder

Defaults to the first author.  Use this if something funny is going on,
like your company is the owner of your code.

=item License Text

Defaults to the Perl 5.8.6 license text generated by h2xs.  Use this
to be meaner.  Some might even make it 'All rights reserved.'

=item Modules Used

These will be used in the base module for the app (but remember that they
will be ignored after your initial bigtop build).

=back

=head1 App Config

This is where you configure your app.  Here is the table you need to fill
with your info:

=for html <img src='http://www.usegantry.org/images/tenttut/appconfig.png' alt='App Config' />

    http://www.usegantry.org/images/tenttut/appconfig.png

There is a row for each config parameter.  Each row has four columns:

=over 4

=item Keyword

The name of the parameter.

=item Value

The value to use for it.

=item Skip Accessor?

If your framework already knows about the keyword, it probably provides
a built-in accessor for it.  For instance, Gantry already provides accessors
for dbconn, dbuser, dbpass, root, template_wrapper, and several others.
If your frameword provides the accessor, you should check the 'Skip Accessor?'
box, so bigtop does not make a duplicate accessor for the keyword in your
app's base module.

=item Delete Buttons

If you don't need one of the config params, simple click this button to
remove it.

=back

Under the current config parameters is a 'New Config Statement' button
and an input box to type the name of a new parameter.  For instance, you
might want to add dbpass for the database password which corresponds
to your dbuser.

This concludes our exhaustive tour of tentmaker.  I hope you are more
excited than exhausted.

Consult Building and Starting in Bigtop::Docs::TentTut for instructions
on how to build your app once you have saved the above.

=head1 Further Reading

See Bigtop::Docs::Cookbook for small problems and answers,
Bigtop::Docs::Tutorial for a more complete example, with discussion,
Bigtop::Docs::Keywords for a list of valid keywords and their meanings,
and Bigtop::Docs::Sytnax for full details.  If you need to write your
own backends, see Bigtop::Docs::Modules.

All of the doc modules are described briefly in Bigtop::Docs::TOC.

=head1 Author

Phil Crow

=cut
