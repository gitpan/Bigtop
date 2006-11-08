package Bigtop::Docs::QuickRef;

=head1 NAME

Bigtop::Docs::QuickRef - a quick reference guide to bigtop syntax

=head1 An HTML Table

This file is html only.  If you want a text version see Bigtop::Docs::Keywords.
Note that this file is note complete.  Running tentmaker should give
you complete and accurate information, since its docs come from the code.
See Bigtop::Docs::TentTut for a tutorial on tentmaker use and
Bigtop::Docs::TentRef or Bigtop::Docs::Syntax for full details.

Below you should see a pretty table in your browser.

=begin html

<h1>Bigtop Quick Reference</h1>
<p>
This page is meant to show what's possible with the Bigtop web app
description language.  It's main feature is a <a href='#quickreftab'>table</a>
summarizing the syntax of the Bigtop language.
</p>
<p>
Each Bigtop file has the following basic structure:
<pre>
    config {
    }
    app App::Name {
    }
</pre>
</p>
<p>
Inside those blocks you can have simple statements and other blocks.
Simple statements are a keyword followed by a number, a valid Perl identifier,
or a backquoted string and terminated with a semi-colon.  Sometimes the
values can also be lists of single values separated by commas.  In rarer
cases, the values can themselves be key/value pairs.  As in Perl, the keys
and values are separated with the fat comma =&gt;.  See below for details.
</p>
<h2>The Key Strangeness</h2>
<p>
One syntax feature that strikes people funny is that Bigtop uses backquotes
around strings.  The reason is simple.  Bigtop never shells out,
but it often needs to store Perl's favorite quotes in strings.  Using
backquotes makes it easy to embed either single or double quotes in
its strings.
</p>
<h2>A Bigger Example</h2>
<p>
Before going into the <a href='#quickreftab'>table of descriptions</a>, it
might help to see a bigger example:
<pre>
config {
    engine          MP13;
    template_engine TT;
    Init            Std      {}
    SQL             Postgres {}
}
app Simple::Sample {
    authors               `Phil Crow`;
    config                { dbconn `dbi:Pg:dbname=simple` =&gt; no_accessor; }
    sequence contacts_seq {}
    table contacts        {
        sequence contacts_seq;
        field id   { is int4, primary_key, assign_by_sequence; }
        field name {
            is              varchar;
            label          `Contact Person`;
            html_form_type text;
        }
    }
    controller Names {
        controls_table   names;
        uses             Gantry::Plugins::AutoCRUD;
        text_description `contact name`;
        method do_main is main_listing {
            title           `Contact Names`;
            cols            name;
            header_options  Add;
            row_options     Edit, Delete;
        }
        method _form is AutoCRUD_form {
            fields          name;
            extra_keys
               legend     =&gt; `$self-&gt;>path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }
}
</pre>
<a name='quickreftab' />
<h2>The Quick Reference Table</h2>
<p>
The following table tries to cover all the statements and blocks available,
but keep in mind that backends can add simple statements of their own.
So, the table may be incomplete.  Running tentmaker will show all the
available possibilities.  It asks all the backends on your system what
they understand.
</p>
<table border>
<tr>
    <td valign='top'>
        config&nbsp;{...}
    </td>
    <td>
      <table border='1'>
        <tr>
            <td valign='top'>
                engine
            </td>
            <td>
                Your framework's engine module.  Try MP13 for mod_perl 1.3.x or
                MP20 for mod_perl 2.0.  CGI for cgi or FastCGI.
            </td>
        </tr>
        <tr>
            <td valign='top'>
                template_engine
            </td>
            <td>
                Your framework's template engine.  Try TT.
            </td>
        </tr>
        <tr>
            <td valign='top'>
                base_dir
            </td>
            <td>
                [ DEPRECATED ]<br />
                In create mode, the directory under which the app will be
                built.  (Defaults to the current directory.)  Ignored,
                with a warning, outside of create mode.
            </td>
        </tr>
        <tr>
            <td valign='top'>
                app_dir
            </td>
            <td>
                [ DEPRECATED ]<br />
                In create mode, the sub directory of base_dir where the
                app will be built.  (Defaults in the manner of h2xs.)
                Ignored, with a warning, outside of create mode.
            </td>
        </tr>

      <tr>
        <td valign='top'>
            LEGAL BLOCKS
        </td>
        <td>
            In the config section, blocks represent backend generators.
            Each generator has a type and a name.  These translate directly
            to the name of the module which will do the generating.  So,
           <pre>    SQL Postgres {}</pre>
            means use Bigtop::Backend::SQL::Postgres.  Further,
            it means that the user of bigtop at the command line can request
            generation of postgres SQL by saying
            <pre>    bigtop app.bigtop SQL</pre>
            Finally, if the user of bigtop at the command line types:
            <pre>    bigtop app.bigtop all</pre>
            each generator will be called on to make its files in
            the order it is listed in the config section.
            <br/>
            All blocks accept no_gen.  Use this statement when you no longer
            want the generator to do anything.  But, don't omit the generator
            entirely.  That will likely cause parse errors, since it won't be
            able to register it's keywords.
            <br/>
            Most blocks accept template.  Use this statement to specify
            an alternate template for the backend.  It will be used instead
            of the Inline::TT template hard coded in the backend.
            Templates define a set of BLOCKS.
            To see what blocks you must define and what parameters they
            have to work with, examine the templates hard coded in the
            backend(s) of interest to you.  Example:
            <br/>
            SQL Postgres { template `my_postgres.tt`; }
        </td>
        </tr>
        <tr>
        <td colspan='2'><table border='1'>
            <tr>
                <th>
                    Backend Type
                </th>
                <th>
                    Available Backends
                </th>
                <th>
                    Description
                </th>
            <tr>
                <td valign='top'>
                        Init
                </td>
                <td>
                    Std
                </td>
                <td>
                    Generates the things h2xs would if it used Build.PL
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    SQL
                </td>
                <td valign='top'>
                    SQLite
                </td>
                <td>
                    Generates docs/schema.sqlite using SQLite syntax.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    SQL
                </td>
                <td valign='top'>
                    Postgres
                </td>
                <td>
                    Generates docs/schema.postgres using Postgres syntax.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    SQL
                </td>
                <td valign='top'>
                    MySQL
                </td>
                <td>
                    Generates docs/schema.mysql using MySQL syntax.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    Conf
                </td>
                <td valign='top'>
                    General
                </td>
                <td>
                    Makes docs/app.conf from app and controller level
                    config blocks in Config::General format, usually
                    for use with Gantry::Conf.  Use the instance statement
                    in your HttpdConf or CGI backend block for Gantry::Conf.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    HttpdConf
                </td>
                <td valign='top'>
                    Gantry
                </td>
                <td>
                    Makes the docs/httpd.conf needed for Gantry's default
                    scheme (for mod_perl).
                    Allows skip_config and full_use statements.
                    See Bigtop::Docs::Syntax.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    Control
                </td>
                <td valign='top'>
                    Gantry
                </td>
                <td>
                    Makes the Controllers needed for use with Gantry.
                    Allows full_use statement (which defaults to true).
                    See Bigtop::Docs::Syntax.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    Model
                </td>
                <td valign='top'>
                    GantryDBIxClass
                </td>
                <td>
                    Makes DBIx::Class Models for use with Gantry.
                    Remember to use <pre>  dbix 1;</pre> in your Control
                    Gantry backend block.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    Model
                </td>
                <td valign='top'>
                    Gantry
                </td>
                <td>
                    Makes native Models for use with Gantry.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    Model
                </td>
                <td valign='top'>
                    GantryCDBI
                </td>
                <td>
                    Makes Class::DBI Models for use with Gantry.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    SiteLook
                </td>
                <td valign='top'>
                    GantryDefault
                </td>
                <td>
                    Makes the wrapper.tt Gantry uses for default site look.<br/>
                    Accepts a gantry_wrapper statement with a proper path
                    to a sample_wrapper.tt (like the one provided with gantry
                    which is the default).
                </td>
            </tr>
        </table></td>
      </tr>
      </table>
    </td>
</tr>
<tr>
    <td valign='top'>
        app&nbsp;<span class='yourident'>App::Name</span>&nbsp;{...}
    </td>
    <td>
        <table border='1'>
            <tr>
                <td valign='top'>
                    authors
                </td>
                <td>
                    A comma separated list of the authors
                    for the AUTHORS section in generated POD.
                    Elements in the list can be strings or pairs.
                    If they are pairs the name is on the left of the =>
                    and that author's email address is on the right.
                    The first author is the default copyright holder.
                    <br />
                    Defaults to the gcos name of the current logged in user.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    copyright_holder
                </td>
                <td>
                    The exact text which fills in this following blank
                    in generated POD
                    Copyright (c) 200x, _____
                    <br/>Defaults to the first author.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    contact_us
                </td>
                <td>
                    The contact information for the project, used in generated
                    POD.  Say what you like here.  You might include a
                    mailing list address or project web site.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    license_text
                </td>
                <td>
                    The exact license text which follows the copyright
                    claim in generated POD.
                    <br/>Defaults to the language of h2xs for Perl 5.8.0,
                    but your company might prefer `All rights reserved`.
                </td>
            </tr>
            <tr>
                <td valign='top'>
                    location
                </td>
                <td>
                    The Apache Location of the base module of the app (or
                    its moral equivalent for cgi/fast cgi).  Defaults to '/'.
                </td>
            </tr>
            <tr>
                <td valign='top' colspan='2'>
                    LEGAL BLOCKS
                </td>
            </tr>
            <tr>
                <td colspan='2'><table border='1'>
                    <tr>
                        <td valign='top'>
                            config&nbsp;{...}
                        </td>
                        <td>
                            Each statement has a PerlSetVar name, its value,
                            and (optionally) =&gt; no_accessor.  Usually
                            the value must be backquoted.
                            <br/>
                            If you end the statement with =&gt; no_accessor,
                            no accessor will be made for this set var by
                            the controller (in which case your framework
                            should catch it).
                        </td>
                    </tr>
                    <tr>
                        <td valign='top'>
                            sequence&nbsp;<span class='yourident'>name</span>&nbsp;{}
                        </td>
                        <td>
                            Defines an sql sequence.  There are no
                            legal statements, leave the block empty.
                        </td>
                    </tr>
                    <tr>
                        <td valign='top'>
                            table&nbsp;<span class='yourident'>name</span>&nbsp;{...}
                        </td>
                        <td><table border='1'>
                            <tr>
                                <td colspan='2'>
                                    Defines an sql table.  This might lead to
                                    generation of sql schema and/or a model.
                                    Controllers also depend on tables (usually).
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    data
                                </td>
                                <td>
                                    Each data statement becomes an INSERT
                                    INTO statement in the generated SQL.
                                    This allows you to populate your tables
                                    with test data or with data known in
                                    advance.
                                    <br/>
                                    Each data statement has a list of pairs
                                    where the key is a column name and
                                    the value is its value.
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    foreign_display
                                </td>
                                <td>
                                    What outsiders will see when they call
                                    foreign_display on a row object from this
                                    table.  Like this:
                                    <br/>`%last_name, %first_name`
                                    <br/>The %field_names are replaced with
                                    values from the row object.
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    model_base_class
                                </td>
                                <td>
                                    Replaces the default parent class for
                                    this table's model class.
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    not_for
                                </td>
                                <td>
                                    The value must be either SQL or Model or
                                    both in a comma separated list.
                                    It instructs those backends to skip this
                                    table.  For instance, you may want models
                                    for authentication tables, but they might
                                    live in a different database.
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    sequence
                                </td>
                                <td>
                                    The name of a previously defined sequence
                                    for use when auto generating primary keys.
                                </td>
                            </tr>
                            <tr>
                                <td valign='top' colspan='2'>
                                    LEGAL BLOCK: field&nbsp;<span class='yourident'>name</span>&nbsp;{...}
                                </td>
                            </tr>
                            <tr>
                            <td colspan='2'><table border='1'>
                                <tr>
                                    <td valign='top'>
                                        is
                                    </td>
                                    <td>
                                        The SQL type.  The keywords
                                        int4, primary_key and assign_by_key
                                        are special.  int4 becomes a
                                        reasonable int for your database.
                                        primary_key marks the field as
                                        a primary key in the generated
                                        SQL and Model.  assign_by_key (a.k.a.
                                        auto) yields auto-incrementing
                                        possibly based on a sequence.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        label
                                    </td>
                                    <td>
                                        What the user sees as a label whenever
                                        this field appears on screen.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        html_form_cols
                                    </td>
                                    <td>
                                        The number of columns for fields
                                        whose html_form_type is textarea.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        html_form_constraint
                                    </td>
                                    <td>
                                        The regex (or sub which will
                                        immediately return one) which must
                                        match the value entered by the
                                        user.  See Data::FormValidator.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        html_form_default_value
                                    </td>
                                    <td>
                                        A literal to use when the user and
                                        the database have provided a value.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        html_form_display_size
                                    </td>
                                    <td>
                                        The width of the text input box
                                        for fields whose html_form_type is
                                        text.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        html_form_optional
                                    </td>
                                    <td>
                                        If true, the controller will
                                        not validate the field.  (Not the
                                        same as non_essential.)
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        html_form_options
                                    </td>
                                    <td>
                                        A comma separated list of pairs whose
                                        keys are user visible labels for
                                        drop down choice lists.  The values
                                        are the form values.  The first item
                                        is the default.
                                        Example:
                                        <br/>
                                        html_form_options Yes =&gt; t, No =&gt; f;
                                        <br/>
                                        Required for fields of html_form_type
                                        select, unless the field refers_to
                                        another table.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        html_form_rows
                                    </td>
                                    <td>
                                        The number of rows for fields whose
                                        html_form_type is textarea.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        html_form_type
                                    </td>
                                    <td>
                                        The html element type used when this
                                        field appears in an html form.  Choose
                                        from: text, textarea, select, or
                                        display.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        html_form_foreign
                                    </td>
                                    <td>
                                        For fields of type 'display,' indicates
                                        field is a foreign key and the
                                        foreign_display of its row should
                                        be shown instead of the row id.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        non_essential
                                    </td>
                                    <td>
                                        If true, this field will not be
                                        included in the Model's essential
                                        field list.  Not all models honor this.
                                        (Not the same as html_form_optional.)
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        not_for
                                    </td>
                                    <td>
                                        The value may only be Model at the
                                        present time.  It means that the model
                                        should completely ignore this field.
                                    </td>
                                </tr>
                                <tr>
                                    <td valign='top'>
                                        refers_to
                                    </td>
                                    <td>
                                        Indicates that this field is a
                                        foriegn key.  The value is the name
                                        of the table whose primary_key it
                                        stores.
                                    </td>
                                </tr>
                            </table></td>
                            </tr>
                </table></td>
            </tr>
            <tr>
                <td valign='top'>
                    controller&nbsp;<span class='yourident'>name</span>&nbsp;{...}
                </td>
                <td><table border='1'>
                    <tr>
                        <td valign='top'>
                            controls_table
                        </td>
                        <td>
                            The name of the table this module will control.
                        </td>
                    </tr>
                    <tr>
                        <td valign='top'>
                            location
                        </td>
                        <td>
                            The absolute path of the Apache Location for
                            this controller or its moral equivalent.
                        </td>
                    </tr>
                    <tr>
                        <td valign='top'>
                            page_link_label
                        </td>
                        <td>
                            Implies that this page should appear in the
                            site navigation menu.  This is the text to
                            use in the menu (think of the small links
                            at the bottom of the page generated by 
                            sample_wrapper.tt that comes with Gantry).
                        </td>
                    </tr>
                    <tr>
                        <td valign='top'>
                            rel_location
                        </td>
                        <td>
                            This controller's Apache Location path, relative
                            to the app level location.
                        </td>
                    </tr>
                    <tr>
                        <td valign='top'>
                            text_description
                        </td>
                        <td>
                            Used only by AutoCRUD.
                            <br/>
                            Fills in the blank in page titles
                            Add ___, Edit ___, Delete ___, and the confirmation
                            question Delete this ____?
                        </td>
                    </tr>
                    <tr>
                        <td valign='top'>
                            gen_uses
                        </td>
                        <td>
                            A comma separated list of modules that the
                            generated module will use.
                        </td>
                    </tr>
                    <tr>
                        <td valign='top'>
                            stub_uses
                        </td>
                        <td>
                            A comma separated list of modules that the
                            stub module will use.
                        </td>
                    </tr>
                    <tr>
                        <td valign='top'>
                            uses
                        </td>
                        <td>
                            A comma separated list of modules that both the
                            generated and the stub modules will use.
                        </td>
                    </tr>
                    <tr>
                        <td valign='top' colspan='2'>
                            LEGAL BLOCK: method <span class='yourident'>name</span> is <span class='yourident'>type</span>
                            <br/>
                            Type must be one of these: main_listing,\
                            AutoCRUD_form, CRUD_form, or stub
                        </td>
                    </tr>
                    <tr>
                        <td colspan='2'><table border='1'>
                            <tr>
                                <th colspan='2' align='left'>
                                    Legal statement for all method types:
                                </th>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    extra_args
                                </td>
                                <td valign='top'>
                                    A comma separated list of extra parameters
                                    the method should accept.  These will
                                    appear exactly as you type them in the
                                    comment above the sub and in the argument
                                    retrieval inside it.  Remember to include
                                    the sigil.  Example:
                                    <br/>
                                    extra_args  `$id`, `$some_name`, `@greedy`;
                                </td>
                            </tr>
                            <tr>
                                <th colspan='2' align='left'>
                                    Legal statements for main_listing methods:
                                </th>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    rows
                                </td>
                                <td valign='top'>
                                    number of rows to include in each main
                                    listing page
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    paged_conf
                                </td>
                                <td valign='top'>
                                    name of conf parameter which hold number
                                    of rows to include in each main listing
                                    page (the value is really the name of
                                    any accessor on the gantry site object)
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    cols
                                </td>
                                <td valign='top'>
                                    Comma separated list of columns for the
                                    main listing table, must match field
                                    names for the controlled table.  The
                                    column label will be taken from
                                    col_labels list, if you have one,
                                    from the label attribute
                                    of the field block in the table,
                                    or from the fields name if no label was
                                    given there.
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    header_options
                                </td>
                                <td valign='top'>
                                    These appear as links in the title bar
                                    above the table.
                                    Supply a comma separate list of labels or
                                    label =&gt; value pairs.  The values
                                    must be literal perl code for the href.
                                    Options appear in the order you give here.
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    row_options
                                </td>
                                <td valign='top'>
                                    Like header_options, but appearing at
                                    the right end of each row in the listing.
                                    If you supply the url, use Perl code
                                    and remember to include $id.
                                    Options appear in the order you give here.
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    title
                                </td>
                                <td valign='top'>
                                    The browser window title.
                                </td>
                            </tr>
                            <tr>
                                <th colspan='2' align='left'>
                                    Legal statements for AutoCRUD_form methods:
                                </th>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    all_fields_but
                                </td>
                                <td valign='top'>
                                    A comma separated list of field names
                                    which should not appear on the form.
                                    All other fields in the controlled
                                    table will appear in the order they
                                    were defined in that table.
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    extra_keys
                                </td>
                                <td valign='top'>
                                    AutoCRUD_form methods return a hash.
                                    You can add keys to that hash with this
                                    statement.  Give a comma separated list
                                    of pairs you want added to the hash.
                                    Backquote the values and make them
                                    EXACTLY like you want them to appear in
                                    the generated output, no alterations
                                    are made.  Example:
                                    <br/>
                                    extra_keys legend =&gt;
                                    <br/>
                                    `$self-&gt;path_info =~ /edit/i ? 'Edit' : 'Add'`;
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    fields
                                </td>
                                <td valign='top'>
                                    A comma separated list of field names
                                    from the controlled table in the order
                                    they will appear on the form.
                                </td>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    form_name
                                </td>
                                <td valign='top'>
                                    The name attribute of the html form
                                    element (note that form names are not
                                    allowed in xhtml 1.0 strict).
                                </td>
                            </tr>
                            <tr>
                                <th colspan='2' align='left'>
                                    Legal statements for CRUD_form methods:
                                </th>
                            </tr>
                            <tr>
                                <td valign='top'>
                                    Same as for AutoCRUD_form.
                                </td>
                            </tr>
                        </table></td>
                </table></td>
            </tr>
        </table>
    </td>
</tr>
</table>

=end html

=head1 Author

Phil Crow, E<lt>philcrow2000@yahoo.comE<gt>

=head1 Copyright and License

Copyright (C) 2005-6, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
