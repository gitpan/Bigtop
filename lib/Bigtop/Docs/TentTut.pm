package Bigtop::Docs::TentTut;

=head1 NAME

Bigtop::Docs::TentTut - tentmaker Tutorial (best viewed in html)

=head1 INTRO

If you don't know what Bigtop is, you might want to start by reading
Bigtop::Docs::About.

Bigtop is a language of simple structure, but with many keywords.  In an
effort to make it easier to use, I have written tentmaker, which amounts
to a wizard for building web apps.  Yet, tentmaker is not as simple as the
wizards so frequently presented by desktop OSes, hence this document.

Here I will walk you through using tentmaker to generate a bigtop file.
Then I will show how to use bigtop to turn that into a web app.  Then
I will return to expand the example in a second iteration of feature
additions.  There a plenty of screen shots here, so it is best to view
this document with a browser.  If you are viewing it with perldoc, you
may want to consult the screen shots with another program.  You can
find them in the docs directory of the Bigtop distribution and on the
web at http://www.usegantry.org/images/tenttut.

The example app I will build here is a contact database.  It will initially
store names and phone numbers.  In the second iteration we will expand it.

=head1 STARTING

When I start tentmaker, I give it a file name and a port number.  The
file is a skeleton with paths set up properly for my development machine.
Since you weren't born with a bigtop skeleton, tentmaker provides one for you.
You will benefit from modifying it to suit your personal setup, then
saving it as your reusable skeleton.  This can save a few minutes on
each app.  Here I will start with the default skeleton to show you what
needs to change.

Before using tentmaker, you must install Gantry (and the Template Toolkit).
Then you must install Bigtop, answering yes when asked if you want to
install tentmaker's templates (you must also provide a directory in
which to place them).

Once Bigtop installation is complete, you may start tentmaker at any time
by typing:

    tentmaker

If I provide a file name as a command line argument, tentmaker loads it
(provided Bigtop can parse it).

By default, it listens to port 8080.  If you want (or need) it to use
a different port supply it like so:

    tentmaker --port=8081

tentmaker is very quiet, but when it starts it will tell you
C<HTTP::Server::Simple: You can connect to your server at
http://localhost:8080/>.  This is testament to my laziness as the line
reveals HTTP::Server::Simple as that actual server.  But you don't need
to think about tentmaker as a server (but realize it is listening on
a port, so becareful of who is allowed to talk to it, think firewall).
You need to know how to use it as an app, read on.

=head1 BUILDING AN APP

Start a web browser and point it to the server.  (The browser needs to
understand the Javascript DOM1 standard or a good approximation of it, like
Firefox does.  If your browser should understand that standard, but can't
handle tentmaker, please send me a bug report.  IE users need not write.)
You should see something like this:

=for html <img src='http://www.usegantry.org/tenttut/tentopening.png' alt='tentmaker opening screen />

    http://www.usegantry.org/tenttut/tentopening.png

At the bottom of the window is a section called 'Current bigtop file'.
It shows the text of the bigtop file you are editing.  I include it
mostly for debugging, but enquiring minds might want to look at it from
time to time as we move through our example.

Immediately above the bigtop file dump is a 'Save As:' button and
its file name box.  I will say more about it when we have something worth
saving.

From this you can see that there are five tabbed panes in tentmaker:

=over 4

=item Bigtop Config

Controls only three things: the app name, what engine will serve it,
and what type of templates it will use.

=item Backends

Controls what will be generated by bigtop.  For example, do you want Postgres
or SQLite SQL for building your database.

=item App Level Statements

Allows input of general information about the app, like the app's license,
who wrote it, and how to contact them.

=item App Config

Allows input of configuration information about the app.  This usually
includes things like database name, user, and password, but can include
any configuration your app needs.

=item App Body

The heart of the matter.  This pane allows you to define your tables and
controllers.

=back

We will now walk through these panes in order from left to right as
they appear on the screen.

=head1 Bigtop Config

If it is not already selected, click on the 'Bigtop Config' tab.

Begin by changing the default app name from C<Sample> to something more
meaningful.  I'll choose C<Contact>.  Simply click into the App Name box and
replace Sample with Contact.  Then click somewhere else.

If you wanted, you could change the engine or template engine.  I'll stick
with CGI (since it is easy to deploy) and Template Toolkit (since I
like Gantry and it supports only TT or manual html production).

This is the least interesting pane.  Let's move along.

=head1 Backends

Click on the 'Backends' tab.

When I wrote this, there were already 10 backends and the number is likely
growing.  Each backend represents a generator that bigtop uses to make
some part of your app.  For example, backends of type SQL make schema
files ready to create your database tables, etc. via your database's
command line tool.  Backends of type Model build code for your
Object-Relational Mapper (like the classic Class::DBI).

This pane overflows, so you will need to use the scroll bar to see all
of your options.  This figure shows the top of the pane:

=for html <img src='http://www.usegantry.org/images/tenttut/backends.png' alt='Backends Pane' />

    http://www.usegantry.org/images/tenttut/backends.png

There are four columns here:

=over 4

=item Type

This describes the category of the backend in general.  For instance,
CGI backends build cgi scripts, SQL backends build SQL files to create
tables, etc.

=item Backend

This is the name of a specific backend within a type.  For instance, CGI
Gantry makes cgi scripts that work with the Gantry framework.

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

But, let's start with an explanation of the default selections in the
default skeleton.

=over 4

=item CGI Gantry

This will build a cgi script to drive our app.  Since 'Build Server' in
the far right column is selected, it will also build a stand alone
server to deliver the app during testing.  If we wanted to change that
server's default port from 8080 to something else, we could enter a
new default port in the 'Server Port' box.

=item Control Gantry

This builds the controller modules (think C in MVC) suitable for use with
Gantry.  Note that 'Full Use Statement' is selected by default.  This
means that the generated base module will explicitly specify the
engine (cgi or mod_perl) and the template engine when it uses Gantry.
If you want to do that in your httpd.conf, you should uncheck the box.

=item Init Std

This is really useful only when you first build an app.  It is responsible
for building the directories and default distribution files (like Changes
and README).  When we revise the app in the last section we will turn this
backend off, so that it can't overwrite Change, README, etc.

=item Model GantryCDBI

We first used Gantry with Class::DBI, so it is the default ORM.  This backend
builds the Class::DBI subclasses for our tables.

=item SiteLook GantryDefault

This takes the 'Gantry Wrapper', whose name is in the far right column,
using it produce a template toolkit wrapper for our application.
This will give us a styled look and default navigation links.

=item SQL Postgres

This produces a file of SQL statements, describing your database, ready
for use with Postgres.

=back

Here's what the other backends do:

=over 4

=item Conf General

This makes a Config::General file of your configuration information,
which is especially useful if you are using Gantry::Conf.

=item HttpdConf Gantry

This makes a file ready for direct inclusion in your httpd.conf file assuming
you are using mod_perl.

=item Model Gantry

This makes the modules you need to use Gantry's native ORM scheme.
It responds to a subset of the Class::DBI API.

=item SQL SQLite

Generates a file of SQL statements, describing your database, ready for 
use with SQLite.

=item ???

Other backends may have appeared since this was written.

=back

We only need to make one change on this pane.  For the SiteLook GantryDefault
'Gantry Wrapper', make sure the value is a valid path to ther
sampler_wrapper.tt that ships in the C<root> directory of the Gantry
distribution.

=head1 App Level Statements

Next, click on the 'App Level Statements' tab.

Here you will see a table of statements which describe the app that
looks like this:

=for html <img src='http://www.usegantry.org/images/tenttut/appstat.png' alt='App Level Statements' />

    http://www.usegantry.org/images/tenttut/appstat.png

The most important statement is colored red.  It is the list of authors.
Module::Build requires at least one author in order to build a distribution.

Change 'A. U. Thor' to your name.  Add the names of anyone who will be
assisting you.  Then put a real email address in the C<Email> box.  This
could be the address of the lead author or a mailing list address.

If you need to note a copyright holder (such as your employer) do so.
If the copyright holder does not like the standard Perl license,
enter their prefered license text (such as 'All rights reserved.').

=head1 App Config

Click on the 'App Config' tab.

This shows a table of configuration information for the application like
this:

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
box so bigtop does not make a duplicate accessor for the keyword in your
app's base perl module.

=item Delete Buttons

If you don't need one of the config params, simple click this button to
remove it.

=back

Under the current config parameters is a 'New Config Statement' button
and an input box to type the name of a new parameter.  For instance, you
might want to add dbpass for the database password which corresponds
to your dbuser.

Even if you don't need addtional config parameters, you should correct
the ones supplied by default.  For instance, you should change the name
of the database in the 'dbconn' Value box.  I'll choose C<contact>.  If
you don't use Postgres, change the DBI connection string as well.  Remember
to change the database user name unless you happen to have a user named apache.

The hardest thing to get right is the root.  This is the Template Toolkit
root Gantry will use when looking for templates.  In my setup there
are two directories in this list (separated by a colon).  The first is
the template directory of the app we are building, the second is the
root directory of the Gantry distribution (which I've installed in my
home directory under srcgantry/root).  When I'm done, my root has these
two directories:

    /home/pcrow/bigapps/build/Contact/html
    /home/pcrow/srcgantry/root

Choose the appropriate local equivalents for your setup.  Don't fret about
these paths at this point.  Even if you get them wrong, the app will
complain, but with helpful information upon start up.  In particular, it
will tell you what file it was looking for and what root path it traversed.
From this you'll be able to correct the path quickly (I hope).

If you need other config information, feel free to add it now.

=head1 App Body

Finally, we are ready to describe the details of the app.  Click on the
'App Body' link.  When you first do this on the default skeleton all you
see is this invitation to make something:

=for html <img src='http://www.usegantry.org/images/tenttut/appbody.png' alt='App Body' />

    http://www.usegantry.org/images/tenttut/appbody.png

You may make any of these things in the app body:

=over 4

=item Sequence

This is an SQL sequence.  Only make these if your database understands them.

=item Table

An SQL table, these are the heart of an app.

=item Controller

A code module for managing a table (usually showing rows from it on screen,
allowing updates to those rows).

=item Literal

Literal text intended for one of the backends.  These allow you to augment
what bigtop knows how to generate.  With careful use of them, you can
usually continue to regenerate the app, without fear, even after it is in
production (regenerating on a dev box and testing before release is usually
a good idea).  I won't say more about these here.

=back

In our shop, we have traditionally made a sequence for each table that
generates the primary keys, which we always call C<id>.  So begin by
choosing sequence (which might already be selected), typing a name
like C<contact_seq> into the box, and pressing 'Create Block'.
The new block should appear below the 'Create Block' button.

Sequences are not very interesting, especially since bigtop knows nothing
about attributes of sequences like min or max values.  Let's move on to
a table.

Choose type 'Table'.  Then enter a name like C<contact> and
press 'Create Block'.  Note that the new table appears below the sequence.
This is important, because the sequence creation statement must come
before the creation statement for the table which uses it, otherwise your
database will be unhappy.  Now the screen should look like this:

=for html <img src='http://www.usegantry.org/images/tenttut/seqtab.png' alt='App Body showing a sequence and a table' />

    http://www.usegantry.org/images/tenttut/seqtab.png

Click on the blue 'Body:' link.  Scroll until you see something more like this:

=for html <img src='http://www.usegantry.org/images/tenttut/newtable.png' alt='App Body a table body' />

    http://www.usegantry.org/images/tenttut/newtable.png

As with the App Level Statements, there are table level statements which
describe the table as a whole.  Again, these are color coded (remember
that the authors input boxes were red).  Yellow means probably needed,
green means usually needed, blue means frequently used.

In this case, we need to fill in the sequence with the name of the
sequence we made above.  Mine was called C<contact_seq>.

If this table were on the receiving end of a foreign key, it should have
a foreign_display to tell other tables which fields they should
show to summarize its rows in their own output.  Even though our rows are
not the object of foriegn attention, we still need a foreign_disply,
because it also controls the sort order for the main listing.  Ours should
be C<%name>.

Note that one field has already been made for us.  In our shop, we religiously
make the first column in any table the id and have the database generate a
sequential value for it.  This saves difficulties when everything else in
the row is subject to change.  The tentmaker makes this C<id> field for us.
Feel free to click on the id field's 'Body:' to see what it did.

The other fields are more interesting.  For our first crack at the Contact
app, there will be just two: name and number.  Create these by entering their
names into the new field 'Name:' box (one at a time) and pressing
'Create Field'.

These fields will be stored and displayed in the same way.  First, click
on the 'Body:' link for C<name>.  Enter C<varchar> in the red box next to
the 'is' keyword.  Then enter a label for the field: C<Name>.  Finally,
choose text for the html_form_type.

Repeat the above for the 'number' field (but pick a different label).

With the data structure complete, we need only make a controller to finish
our app.  Go back up to New Block (at the top of the 'App Body' pane).
Choose 'Type:' C<Controller>.  Enter a name for the contact controller
table.  I'll call it 'Family', because I'm thinking ahead to a full
address book.

Once you create the block (which will appear below the sequence and table
we made earlier), go to it and change its type to AutoCRUD.  While this
is mostly documentation, it does tell bigtop to use the Gantry AutoCRUD
plugin.

In the Family 'Body:' we need to choose either a location or a rel_location.
A location must be absolute on the install server; a rel_location will
be relative to the app's base location.  In this case they amount to the
same thing (except that location must start with a slash).  I'll set
rel_location to 'contact'.

In order for the AutoCRUD to work, I must enter C<contact> as the
'controls_table' value.  I also want a 'text_description' of 'Contact Item'.
When the user chooses 'Delete', this will fill in the blank in
"Delete ____?", so I don't want something like 'Family' or 'Person' as
"Delete Person?" sounds a bit too fatal.

If there were more pages in the app, I would probably pick a 'page_link_label'
for this controller, so it would appear among the site navigation links.

Now that we have described the controller attributes, we need to make a couple
of methods.  Under the 'Add Method' heading, type C<do_main> in the 'Name:'
box.  Then choose 'Method Type:' C<main_listing> and press 'Create Method'.
The name 'do_main' is special.  All methods tied to urls by Gantry start
with do_.  The one named do_main is called by default, sort of like
index.html is loaded by default by many web servers.

The only other method we need is the entry form.  Enter C<form> in the
name box.  Then choose type C<AutoCRUD_form> and press 'Create Method'.
This method must be called 'form' so that the AutoCRUD plugin can call it.

Click on the 'Body:' link of the do_main method.  You'll see something like
this:

=for html <img src='http://www.usegantry.org/images/tenttut/do_mainbody.png' alt='main_listing method body' />

    http://www.usegantry.org/images/tenttut/do_mainbody.png

As with other keyword/value entry tables, this one has 'Keyword',
'Values', and 'Description' columns.  But, it also has 'Applies to'.
This tells you what method type understands the keyword.  Make sure that
the 'Applies to' column is either your method's type or 'All'.

It will be easier to understand the other items if we see an example, so
here is a sample of the main listing presented to users of the app:

=for html <img src='http://www.usegantry.org/images/tenttut/main_listingout.png' alt='example main listing' />

    http://www.usegantry.org/images/tenttut/main_listingout.png

The title of the listing box comes directly from the 'title' value.
This also appears in the browser window's title bar.

A main_listing shows some columns from each row in the underlying database
table.  Here we want to show both the name and the number for each
person.  So, we enter C<name> and C<number> in separate cols boxes.
Note that as you add values, more empty boxes appear.  Enter as many
cols as you like, but keep in mind that screen space will eventually
run out.

To the right of the column labels, in the picture above, is a link labeled
'Add'.  This is a header_option.  Let's include 'Add' and 'CSV' (in case
someone wants to dump the contents in an exportable way).  Put these into
boxes next to 'header_options'.  We can enter any number of these (including
zero).  We need to define a do_ method for each one of the options.
The name of the do_ method will be the value of the label in all lowercase,
so 'Add' will be implemented in 'do_add'.  AutoCRUD will supply do_add for
us, but we must write do_csv.

Finally, to the right of each row of data, there are two links: one
for editing the current row and the other for deleting it.
Enter C<Edit> and C<Delete> in row_options boxes to get these.
As with header_options, row_options can be anything you like.  Simply
implement a do_ method for each one, where the name is again the lowercase
of the label.  AutoCRUD supplies do_edit and do_delete for us.

Now go to the form method body.  We need to tell this method what fields
to show the user.  We want all the fields except the id.  So enter C<id>
into the first all_fields_but input box.  When we add new fields later,
we won't even need to change this (but we will need bigtop to regenerate the
form for us).

Finally, we could add a new method called do_csv (though we don't need to).
If you choose to do that, choose type stub for it.  Open its body and enter
C<$id> into one of the extra_args input boxes.  This will only generate a
few lines of code, but it will save a little typing.

=head1 Saving

Now choose a file name for the bigtop file and enter it in the box next
to 'Save As:' just above the 'Current bigtop file' dump.  If you supply
a relative path, it will be relative to where you started tentmaker.

Once you press the 'Save As:' button, a message should appear immediately
below it.  It will either confirm that the file was saved, or report the
error that resulted when tentmaker attempted to save it.

=head1 Building with Bigtop

Assuming that tentmaker saved the file successfully, go to a command line
window and change to the directory where that bigtop file lives.  Then
type:

    bigtop --create contact.bigtop all

(Of course, you must replace contact.bigtop with the actual name you gave your
file.)

The C<--create> flag tells bigtop that this is an initial build, so it should
make directories.  Choosing C<all> builds everything.  We could have listed
the individual things to build, but that is usually tedious.

Now change directories into Contact (or whatever you called you app).
Look around, you should see these things:

    app.cgi     Build.PL  docs  lib       MANIFEST.SKIP  t
    app.server  Changes   html  MANIFEST  README

=head1 Creating the Database

Now create your database.  If you are using SQLite, that is as simple as:

    sqlite contact < docs/schema.sqlite

For Postgres it might look more like this:

    createdb contact -U postgres
    psql contact -U regular_user < docs/schema.postgres

supplying passwords as needed.

=head1 Starting the app

Now type:

    ./app.server [ 8081 ]

The port number is optional and defaults to 8080.  When it is ready to
serve you, this script will print the base url to which you should point
your browser.  Remember to add number (or whatever you chose for your
rel_location, or location) to the end of that url.

The only thing that doesn't work is do_csv.  Let's add that now.  From
the build directory (where app.server lives) edit this file with your
favorite editor:

    lib/Contact/Number.pm

This is the stub for our one controller.  If you added a stub method
called do_csv, it will look like this:

    #-----------------------------------------------------------------
    # $self->do_csv( $id )
    #-----------------------------------------------------------------
    sub do_csv {
        my ( $self, $id ) = @_;
    } # END do_csv

If you don't already have this method, add the above to the controller.
Here is my finished version.  This is a rough draft only.  I want to
make it so the browser will naturally open the result with a spreadsheet
program like, Open Office Calc, or save to disk with a reasonable name.
For now I will be content with the data.

    sub do_csv {
        my ( $self, $id ) = @_;

        # get the data
        my @rows = $NUMBER->retrieve_all( order_by => 'name' );

        # generate the csv
        $self->template_disable( 1 );

        my @output;
        push @output, "id, name, number\n";
        foreach my $row ( @rows ) {
            push @output, $row->id     . ', '
                        . $row->name   . ', '
                        . $row->number . "\n";
        }


        $self->content_type( 'text/csv' );
        $self->stash->controller->data( join '', @output );
    } # END do_csv

=head1 Iteration Number Two

Now that we have built the app, the inevitable change requests have arrived
from our users.  They want to add mailing and email addresses to the the
main table.  They also want to add birthdays.  Let's see what we can give
them.

From the build directory (where you ran app.server in the last section),
restart the tentmaker like so:

    tentmaker docs/contact.bigtop

Provide a port if you need it (with --port).

First -- and this is always a good first step when you've already created
the app -- go to the 'Backends' tab and check the 'No Gen' box for Init Std.
We don't need it any more and it tends to overwrite things we need (like
our Changes file).  Alternatively, you could check the boxes next to
the things you don't want updated.  For example, this could allow Bigtop
to keep the MANIFEST up to date.

By checking 'No Gen' instead of deselecting the backend, you allow it to
keep registering its keywords, so you don't have alter the rest of the
file.  This doesn't really matter for Init Std, since all the keywords
it registers are also regiestered by others.  It is a real issue
for the other backends.

With that bit of housekeeping out of the way, we can begin to make additions
to the app.  Click on the 'App Body' tab.  Then click on the C<number>
table 'Body:'.  Add these new fields:

    street
    city
    state
    zip
    country
    email

Each of these can be just like name and number.  That is, their type is
varchar, their label is their name with first letter capitalized, and
their input type is text.

Now press 'Save As:' (the name should already be correct).
Then, at a command line in the build directory (the one with Build.PL) type:

    bigtop docs/contact.bigtop all

Now we have a bit of work to do on the actual database.  We have two choices:
(1) destroy the original database or (2) alter the original database
to match the new model.  In this case, I'll opt for number 1 since we
haven't put any real data into the database yet.  This is convenient, since
Bigtop does not really support table alterations.

These are the steps for sqlite:

    rm contact
    sqlite contact < docs/schema.sqlite

For Postgres it takes a bit more work:

    dropdb contact -U postgres
    createdb contact -U postgres
    psql contact -U regular_user < docs/schema.postgres

Once the database is ready, you can restart the server:

    ./app.server

Click on 'Add' and see that the new fields are on the form.

The only thing we need to change is do_csv.  Though you can probably
imagine that, here is mine:

    sub do_csv {
        my ( $self, $id ) = @_;

        # get the data
        my @rows = $NUMBER->retrieve_all( order_by => 'name' );

        # generate the csv
        $self->template_disable( 1 );

        my @output;
        push @output, "id, name, number\n";
        foreach my $row ( @rows ) {
            push @output, join( ', ',
                            $row->id,
                            $row->name,
                            $row->number,
                            $row->street,
                            $row->city,
                            $row->state,
                            $row->zip,
                            $row->country,
                            $row->email,
                          ) . "\n";
        }


        $self->content_type( 'text/csv' );
        $self->stash->controller->data( join '', @output );
    } # END do_csv

You can continue to develop and regenerate as the model changes.  The
only piece that is difficult to manage is the database once it is built.

=head1 Further Reading

See Bigtop::Docs::Cookbook for small problems and answers,
Bigtop::Docs::Tutorial for a more complete example, with discussion,
Bigtop::Docs::Keywords for a list of valid keywords and their meanings,
and Bigtop::Docs::Sytnax for full details.  If you need to write your
own backends, see Bigtop::Docs::Modules.

All of the doc modules are described briefly in Bigtop::Docs::TOC.

=head1 AUTHOR

Phil Crow

=cut
