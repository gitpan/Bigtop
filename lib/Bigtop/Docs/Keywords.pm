package Bigtop::Docs::Keywords;

=head1 Name

Bigtop::Docs::Keywords - a bigtop keyword quick reference in monospace font

=head1 The Keywords in Bigtop

For those who like compact quick references with too much information crammed
on them (designed to print on a few of pages, if you cut everthing above):

 config {}
    base_dir        - in create mode, the directory under which all things live
    app_dir         - in create mode, the subdirectory of base_dir where
                      Build.PL and company reside
    engine          - mod_perl or cgi choose from MP13, MP20, or CGI
    template_engine - the templating system to use choose from TT or TT.

    Init      Std           {}
        Makes: Build.PL, Changes, README, lib/, t/, docs/file.bigtop
    Conf      General
        Makes: docs/AppName.conf a Config::General formatted conf file
               for use with Gantry::Conf
        gen_root - makes a root config param for you with value `html`
    Control   Gantry        {}
        Makes: modules in lib (including GEN modules, but not models)
        full_use - defaults to false, make it true to to get use with engines
        dbix     - defaults to false, make it true if you want to use
                   DBIx::Class
    CGI       Gantry        {}
        Makes: ./app.cgi and possibly ./app.server
        confile     - replacement for /etc/gantry.conf (used with instance)
        gen_root    - makes a root config hash key for you with value `html`
        instance    - set this to your Gantry::Conf instance name
                      the CGI script's config will have only GantryConfInstance
                      in its config hash (see Conf General)
        with_server - makes app.server a stand alone server for the app
        server_port - if with_server is set, this controls its binding port
    HttpdConf Gantry        {}
        Makes: docs/httpd.conf
        confile       - replacement for /etc/gantry.conf (used with instance)
        full_use      - defaults to true, make it false to get a simple use
                        Gantry...  with TemplateEngine, Engine, and Conf.
        gen_root      - makes a root PerlSetVar you with value `html`
        instance      - set this to your Gantry::Conf instance name the CGI
                        script's config will have only GantryConfInstance
                        in its config hash (see Conf General)
        skip_config   - make this true to omit PerlSetVar statments
    Model     GantryDBIxClass {}
    Model     Gantry          {}
    Model     GantryCDBI      {}
        Make: lib/Model modules (including GEN modules)
        model_base_class - changes the default base class for models can still
                           be overridden by model_base_class on a table
    SQL       Postgres      {}
        Makes: docs/schema.postgres
    SiteLook  GantryDefault {}
        Makes: html/wrapper.html
        gantry_wrapper - file name of gantry's sample_wrapper.tt

    [Note: All config backend blocks can have a no_gen statement, which if true
    will cause the parser to skip the whole backend. ]
    [Note: Most config backend blocks can have a template statement to
    change their generation TT template to one of your choice.]

 app name {}
    authors          - comma separated list of authors or author => email pairs
    contact_us       - blurb about how to contact project members
    copyright_holder - defaults to first author
    license_text     - defaults to text from h2xs for Perl 5.8.0
    location         - root Apache Location for the app
    uses             - comma separated list of modules the base modules uses

    config {}
        any_keyword its_value;    - creates:
            (1) a PerlSetVar at the base location in httpd.conf,
                or its moral equivalent
            (2) a statement to retrieve the set var in the base init method,
            (3) an accessor in the base module
        OR
        key value => no_accessor; - same as above, but makes no accessor

    literal Location `...`; - a literal string to include in the base
                              Location directive for the app

    literal SQL `...`;      - a literal string to include in schema.*

    literal PerlTop `...`;  - a literal string to include immediately
                              after the shebang line in the <Perl> block
                              of httpd.conf (for backends of type HttpdConf)
                              or in the CGI dispatching script (for backends
                              type CGI)

    literal PerlBlock `...`;- a literal string to include in the <Perl> block
                              of httpd.conf (appears in the order it appears
                              in the bigtop file relative to controllers)

    literal HttpdConf `...`;- a literal string to include between location
                              directives in httpd.conf.

    literal Conf `...`;     - a literal string to include at the top
                              level of Config::General conf file

    literal GantryLocation `...`; - a literal string to include at a controller
                                    level of Config::General conf file

    sequence name {}
        (none of these work yet:)
        starting_value
        maximum_value
        increment

    table name {}
        field name {}
            is        - valid sql modifiers like int4, primary_key, etc.
            label     - what the user will see when this field appears on
                        screen or in reports
            refers_to - table to which this field points as a foreign key
            html_form...
                _type         - text, textarea, select
                _optional     - unvalidated during form submission, if true
                _rows         - how long a textarea appears
                _cols         - how wide a textarea appears
                _display_size - how wide a text field appears
                _options      - comma separated list of option hashes for
                                select lists (don't use this if field is
                                a foreign key)
                _constraint   - backquoted perl code which returns a regex
                                which must match this field's value
                _default_value- becomes the default if nothing else will do
            non_essential - excludes field from greedy retrieval, if true

        data      - a comma separated list of key value pairs which become
                    a literal INSERT INTO for this table

        sequence  - what sequence the table will use (must refer to a
                    sequence defined by an earlier sequence block)

        not_for   - tells a back end to skip this table valid choices:
                    SQL or Model or both (separate with commas)

        model_base_class - allows you to change the base class for this
                           table's model, for instance if you need to
                           use Gantry::Utils::AuthCDBI instead of plain CDBI.

        foreign_display  - how other table see rows from this one.  Example:
                           foreign_display `%last, $first`;

    join_table name {}
        joins - a pair of tables this table joins in many-to-many bliss.
                You must have exactly one joins statement in the block.
                Ex: joins a => b;
        names - pair of names of the many-to-many relationship in each table

    controller name is type {}
        [ is type is optional an defaults to is stub,
          see below for valid types ]
        controls_table  - name of one table which this controller works on
        location        - absolute Apache Location
        rel_location    - location relative to the site's base location
        text_description- used only by AutoCRUD to fill in Delete this ___?
        uses            - places use statement(s) at the top of the stub
                          and gen modules
        page_link_label - Indicates that this controller should be in the
                          site's nav menu.  The value is the text to use
                          for the nav link.
        config {}
            name value - works like app level config, but at the controller's
                         location
        literal Location `...` - copied directly into Apache Location
                                 for this controller

        There are three types with meaning (saying 'is stub' does nothing):
            AutoCRUD - adds Gantry::Plugins::AutoCRUD to your uses list (even
                       if you don't have one)
            CRUD     - adds Gantry::Plugins::CRUD to your uses list (even if
                       you don't have one) and generates various helper code
                       for using CRUD.
            base_controller - governs the app's main module (and its GEN
                              partner)

        method name is type {}
        All types use:
            extra_args - a comma separated list of literal perl variables
                         (complete with sigils) to add at the end of this
                         methods arg list.  Example: extra_args `$id`, `@junk`;
        Types:
            stub         - empty except for arg capture
            main_listing - call this do_main
                rows       - number of rows per main listing page, no default
                             omit this to get all rows
                paged_conf - call this accessor to get the number of rows
                cols       - list of columns for the main listing table
                col_labels - list of columns labels (optional). By
                             default the label is taken from the field in
                             its table or from its name there if no label was
                             given (the later results in a warning).
                             Items in this list can be label => href pairs.
                             Then, the href must be valid Perl
                             code which will be executed to obtain the href
                             of the link.
                header_options - These appear in the order given as links
                                 at the right side of the label bar over the
                                 table.  Use either strings or text => link
                                 pairs.
                html_template  - a template to use for output display
                row_options    - Like header_options, but appear at the end
                                 of each row.  If you specify text => link
                                 pairs, remember to include $id.
                title          - browser window title for page made by do_main
                limit_by       - limit results to a single foreign key value
                                 this is the name of the foriegn key's column
            AutoCRUD_form - call this _form, for use with Gantry AutoCRUD
                fields         - which fields to include on the form
                all_fields_but - which fields to exclude, all others appear in
                                 the order they appear in their table's
                                 definition
                form_name      - (not xhtml compliant) the name of the form
                                 element (needed for calendar popups)
                extra_keys     - Things to include in generated method's
                                 returned hash.  These are taken literally.
            CRUD_form - Just like AutoCRUD_form, but result works with
                        Gantry::Plugins::CRUD instead.
            base_links - a do_main with nav links for the base module
            links      - a site_links method (usually in the base_controller)
                         providing a method for templates to get nav links from

=head1 Author

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 Copyright and License

Copyright (C) 2005-6, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
