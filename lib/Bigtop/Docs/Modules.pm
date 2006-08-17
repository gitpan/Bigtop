package Bigtop::Docs::Modules;

=head1 NAME

Bigtop::Docs::Modules - An annotated list of modules in the Bigtop distribution

=head1 Intro

This document goes into some depth on each piece of of the Bigtop distribution.
Some of the details are left for the POD of the pieces themselves.

If you want to know exactly what's legal in a bigtop file, look in
Bigtop::Docs::Syntax or the more concise (and less complete)
Bigtop::Docs::Keywords.

=head2 Bigtop.pm

Bigtop.pm is primarily a documentation module.  It does provide two
useful functions for backend authors.  One writes files on the disk
the other makes directory paths.  See its docs for details.

=head2 Bigtop::Parser

This is the real workhorse of Bigtop.  It is a grammar driven parser for
Bigtop files.  Interactions with this parser are usually indirect.
End users use the bigtop script which in turn uses the parser to first build
an abstract syntax tree (AST) and then to generate output by passing the AST
to the backends.  Developers should write backends which receive the AST
in methods named for what they should produce.

=head3 Parsing Bigtop specifications

If you have a file on the disk and want to parse it into an abstract
syntax tree (AST), call Bigtop::Parser->parse_file( $file_name ).
This returns the AST.

The bigtop script is quite simple (I can almost see it as a bash script).
It handles command line options, then directly passes the rest of its
command line arguments to gen_from_file in Bigtop::Parser.  gen_from_file
reads the file into memory and passes it and the other command line
arguments to gen_from_string.

gen_from_string first parses the config section of the Bigtop file to
find the backends.  It requires each of those (using its own import method),
then calls gen_YourType on each one that is not marked no_gen.

The backend's gen_YourType is called as a class method.  It receives the 
base directory of the build (where the user wants files to end up)
and the AST.

Once you have an AST, you can call methods on it.  Most of these
will return lists (whose element are most often strings).

The most useful method provided is walk_postorder.  It takes care
of walking the tree.  For each element, it calls walk_postorder for
all of the children, pushing their output lists into a meta-list.  Then it
passes that result to the action in the current class.  This is a depth
first traversal.  (If there is no action for the current class, walk_postorder
returns the collection of child output unmodified; except that if the
array of such output is empty, it returns undef and not an empty array.)

You can pass a single item of data to walk_postorder.  That item (which
is usually a hash or object) is in turn passed to all walk_postorder
methods in the descendents as they are called.  All of the walk_postorder
methods pass this item on to the action methods when they call them.

To make this concrete, consider what the Bigtop::Control::Gantry does in
its gen_Control method:

    my $sub_modules = $wadl_tree->walk_postorder(
        'output_controller',
        {
            module_dir => $module_dir,
            app_name   => $app_name,
            lookup     => $wadl_tree->{application}{lookup}
        }
    );

This specifies the callback action as output_controller.  Each
output_controller has a definition like this:

    sub output_controller {
        my $self         = shift;
        my $child_output = shift;
        my $data         = shift;

        # ...
    }

Where $self is the current tree element, $child_output is the result
returned from all of this element's children (as an array reference),
and the data hash originally passed to walk_postorder (the one that
contains module_dir, app_name, and lookup).

These output_controller methods live in packages named for rules in
the grammar.  See directly below for the package names and how to
implement them.

=head3 The AST

The AST lives in a hash.  This section explains the anatomy of that hash.
It is presented as a nested list so you can see the tree structure by
indentation.  The top level element is blessed into the bigtop_file package.

It responds to these methods: get_config (returns the config subtree) and
get_appname.

It has two children.  The first is configuration (available through
get_config) which is a hash reference representing the config section of
the Bigtop file.  The configuration child is not part of the AST you
walk when generating output, but its info can be essential to your backend.

The tree continues with the other child:

=over 4

=item application

Responds to this method: get_name.

Has these children:

=over 4

=item __NAME__

A string with the app name in it.  This is available through get_appname
on the whole tree or through get_name on the app subtree.

=item app_body

Created by Parse::RecDescent's autotree scheme.  Has one child:

=over 4

=item block(s?)

This child is list of objects, each blessed into the block class.
Since autotree builds this for us, there is some litter.  We are
only concerned with children whose package names end with _block or
_statement.  These children are:

=over 4

=item literal_block

This is a leaf node.  It responds to one highly useful method: make_output.
Backends call it on the current subtree (which is a leaf) passing in
their backend type.  If the current literal block has the same type, the
text of the backquoted string in the Bigtop file is returned.  (A trailing
new line is added to the user's input unless that input already had
trailing whitespace.)  If the current node is of a different type, undef
is returned.

There is an optional additional parameter: want_hash.  Pass a true
value if you need the output as

    [ { $backend_type => $output } ]

instead of the default:

    [ $output ]

This is useful if your backend handles multiple literal blocks in
different ways.  For example, PerlTop and PerlBlock literals are
both handled by Bigtop::Gantry::HttpdConf.  It needs the hash form
to know where to put the literal output.

literal_blocks have two attributes:

=over 4

=item __BACKEND__

The name of the backend this literal is intended for.

=item __BODY__

The literal text for the backend.

Usually it is easier to call make_output than to fish for these.

=back

=item controller_block

Responds to get_name which returns the name of the controller.

Has these children:

=over 4

=item __NAME__

The name of the controller relative to the app name, available through
get_name.

=item __TYPE__

Controllers are specified as:

    controller Name is type {...}

This attribute is the controller's type.

=item controller_body

An autotree supplied package with one useful child:

=over 4

=item controller_statement(s?)

This is an array of nodes blessed into the controller_statement class.
Controller statements come in several types (some of which are really blocks):

=over 4

=item controller_method

Represents a method.  Responds to get_name which returns the method's name.
Has these children:

=over 4

=item __NAME__

A string attribute.  The name of the method available through get_name.

=item __TYPE__

A string attribute.  As with controllers, methods have types:

    method name is type { ... }

This is the type name.  There should probably be an accessor for this.

=item __BODY__ (blessed into method_body)

The body of the method, including all of its statements.  Responds to
these methods: get_method_name, get_controller_name, and get_table_name
(which works if the controller has a controls_table statement).

Has only one child:

=over 4

=item method_statement(s?)

An array of objects blessed into the method_statement class.  Each
method_statement has two attributes:

=over 4

=item __KEY__

The statement's keyword.

=item __ARGS__

An arg_list (see below).

=back

=back

=back

=item controller_config_block

A leaf with two attributes:

=over 4

=item __KEY__

The config variable's name.

=item __ARGS__

An arg_list (see below).

=back

=item controller_literal_block

This is really a statement, not a block (the name stuck before I decided
statements would be easier to work with).

Responds to make_output which is similar to the method of that name in
the literal_block package.  The key difference is that this one does
not handle multiple backend types gracefully.  If the backend type you
ask for matches, you get the output.  No hash keyed by backend type
is available.  (Trailing new lines are supplied exactly as for make_output
in the literal_block package.)

A leaf with two attributes:

=over 4

=item __BACKEND__

The backend which the user wants to handle the literal.

=item __BODY__

A string to put literally in the __BACKEND__'s output.

=back

It's easier to call make_output than to fish in these manually.

=item controller_statement

These are the simple statements in the controller block (like controls_table).
They have two keys:

=over 4

=item __KEYWORD__

The statement name.

=item __ARGS__

An arg list (see below).  This is optional and may therefore be undef.

=back

=back

=back

=back

=item sql_block

Responds to get_name which returns the name of whatever the block makes
(a table or a sequence).  These can be of two varieties.  They have
the same attributes:

=over 4

=item __NAME__

The name of the constructed sequence or table.

=item __TYPE__

As string, either sequences or tables.

=item __BODY__

The body of the block.  These come in two types:

=over 4

=item sequence_body

Has one child:

=over 4

=item sequence_statement(s?)

Unused by any current backend, so generally undef.

An array of objects blessed into the sequence_statement class.  Each of
these has two attributes:

=over 4

=item __NAME__

The statement's keyword.

=item __ARGS__

An arg list (see below).

=back

=back

=item table_body

Has one useful child:

=over 4

=item table_element_blocks(s)

An array of objects blessed into the table_element_block class.  These
come in two types, governed by their __TYPE__ attribute:

=over 4

=item __TYPE__ eq 'field'

=over 4

=item __NAME__

The name of the field.

=item __BODY__

The field_body child object, which has one child:

=over 4

=item field_statement(s)

An array of objects blessed into the field_statement class.  Each of these
has children:

=over 4

=item __NAME__

The keyword of the field statement.

=item __DEF__

An object of type:

=over 4

=item field_statement_def

This is the value for the field statement.  It has one optional child:

=over 4

=item __ARGS__

An arg_list (see below).

=back

=back

=back

=back

=back

=item __TYPE__ some statement keyword

=over 4

=item __VALUE__

The arg_list (see below) of the statement.

=item __BODY__

The keyword of the statement (same as the __TYPE__).

=back

=back

=back

=back

=back

=item app_config_block

Represents an app level config block.  Has one child:

=over 4

=item app_config_statements

An array (possibly undef) of objects blessed into:

=over 4

=item app_config_statement

Has two attributes:

=over 4

=item __KEY__

The name of the set var.

=item __ARGS__

An arg_list (see below).

=back

=back

=back

=item app_statement

Represents a simple statement at the app level.  Has two keys:

=over 4

=item __KEYWORD__

The statement's keyword (like authors).

=item __ARGS__

An arg_list (see below).

=back

=back

=back

=back

=back

In addtion to those packages, there is one which is a frequent leaf:

=over 4

=item arg_list

An arg_list is an array whose elements are either single strings or
pairs.  There is no help in Bigtop::Parser for these.  They look like
this:

    [
        'value1',
        { key => 'value2' },
        'value3',
    ]

None of the items in arg_lists are blessed, hence the absence of help
from above.

=back

=head2 Backends

To see what the current backends do, consult Bigtop::Docs::Syntax.  To
write your own, keep reading.

Each backend should have a generation method called gen_BackendType
(where BackendType is part of the package name:
Bigtop::Backend::BackendType::Backend).  These are called as class methods
with the build directory, the AST generated in Bigtop::Parser, and the
source file name (if one is available).

In addition to the generation methods, if your backend wants to work
with the TentMaker, you must also implement what_do_you_make and
backend_block_keywords.  See the example below for what these should
do.

The gen_* methods produce output on the disk.  For testing, you can
call the methods that the gen_* methods call.  Usually these are prefixed
with output_, but that is not enforced.  Or you can call the gen_* method
and test the generated files (say with Test::Files).

To know what a particular backend will do, see Bigtop::Docs::Keywords
or Bigtop::Docs::Syntax.  That is also where you will see a list of the
keywords they understand and what values those keywords take.

To write a backend, you need to write the gen_* method and have one package
for each AST element type you care about.  It is easiset to see this by
example.  A good example is Bigtop::Backend::SQL::Postgres.  I'll show it
here so you can see how it goes with commentary interspersed amongst the
code.  To see the whole of it, look for lib/Bigtop/Backend/SQL/Postgres.pm
in the Bigtop distribution.  (Note that I have removed some details to make
this presentation easier, and the real version may have been updated
more recently than this discussion.)

=head3 Preamble

There is nothing really fancy about the start of a backend:

    package Bigtop::Backend::SQL::Postgres;
    use strict; use warnings;

    use Bigtop::Backend::SQL;
    use Inline;

I use Bigtop::Backend::SQL, which registers the SQL keywords with the
Bigtop parser.  In all of my backends I use Inline::TT to aid in generating
the output.  It needs Inline loaded.  (See setup_template to see how
templates are installed for use.)

=head3 TentMaker requirements

    sub what_do_you_make {
        return [
            [ 'docs/schema.postgres' => 'Postgres database schema' ],
        ];
    }

what_do_you_make should return an array reference describing the things
your backend writes on the disk.  Each array element is also an array
reference with two entries.  First is the name of something made by
the module, second is a brief description of what that piece has in it.
These appear as documentation in the tentmaker application.

    sub backend_block_keywords {
        return [
              { keyword => 'no_gen',
                label   => 'No Gen',
                descr   => 'Skip everything for this backend',
                type    => 'boolean' },
        ];
    }

backend_block_keywords is similar to what_do_you_make.  It lists all
the valid keywords which can go in the backend's block in the config
section at the top of the bigtop file.  These appear in order in the
far right column of the Backends tab.  The above keys are required,
if you need a default use the default key.  If the type is boolean,
spell out true or false as the default value.  If you don't specify
a default, you get false (unchecked) for booleans and blank for strings.

=head3 The generating sub

    sub gen_SQL {
        shift;
        my $base_dir = shift;
        my $tree     = shift;

The bigtop script will call gen_SQL (via gen_from_file) when the
user has this backend in their config section and invokes bigtop with
SQL or all in the list of build items.

The class name is not needed, so I shifted it into the ether.

The $base_dir is where the output goes.

The $tree is the full AST (see above for details).

        # walk tree generating sql
        my $lookup       = $tree->{application}{lookup};
        my $sql          = $tree->walk_postorder( 'output_sql', $lookup );
        my $sql_output   = join '', @{ $sql };

The lookup subtree of the application subtree provides easier access to
the data in the tree (though it doesn't have all the connectors the AST
has for parsing use, in particular it uses hashes exclusively, so it never
intentionally preserves order).

I let Bigtop::Parser's walk_postorder do the visiting of tree nodes
for me.  It will call 'output_sql' on each of them.  I implement that
on the packages my SQL generator cares about below.  I pass the lookup
has to walk_postorder so it will be available to the callbacks.

The output of walk_postorder is always an array reference.  I join it
together and store it in $sql_output.

        # write the schema.postgres
        my $docs_dir     = File::Spec->catdir( $base_dir, 'docs' );
        mkdir $docs_dir;

By the convention of our shop, the schema.postgres file lives in the docs
directory of the generated distribution.  Here, I make that directory
(if that fails we'll hear loud screaming shortly).

All that remains is to put the output into the file:

        my $sql_file     = File::Spec->catfile( $docs_dir, 'schema.postgres' );

        open my $SQL, '>', $sql_file or die "Couldn't write $sql_file: $!\n";

        print $SQL $sql_output;

        close $SQL or die "Couldn't close $sql_file: $!\n";
    }

So, the whole generation method is only 22 lines.  Of course, there
is still a lot left for me to do.

=head3 Output appearance control

Like most backends, this one uses Inline::TT to control the appearance
of the output.  If users don't like the appearance, they have only
to copy the template into another file, edit it to suit them, and
tell the module by including a template statement in the config block for
the backend:

    config {
        SQL Postgres { template `my.tt`; }
        # ...
    }

Here is my default template:

    our $template_is_setup = 0;
    our $default_template_text = <<'EO_TT_blocks';
    [% BLOCK sql_block %]
    CREATE [% keyword %] [% name %][% child_output %]

    [% END %]

    [% BLOCK table_body %]
     (
    [% FOREACH child_element IN child_output %]
    [% child_element +%][% UNLESS loop.last %],[% END %]

    [% END %]
    );
    [% END %]

    [% BLOCK table_element_block %]    [% name %] [% child_output %][% END %]

    [% BLOCK field_statement %]
    [% keywords.join( ' ' ) %]
    [% END %]

    [% BLOCK insert_statement %]
    INSERT INTO [% table %] ( [% columns.join( ', ' ) %] )
        VALUES ( [% values.join( ', ' ) %] );
    [% END %]
    EO_TT_blocks

There are five blocks, each of which may be used repeatedly while
generating output:

=over 4

=item sql_block

Wraps the body of an SQL CREATE statement with 'CREATE name'.

=item table_body

Wraps all of the column definitions in each CREATE TABLE statement with
parentheses.

=item table_element_block

Makes the column definition statements for CREATE TABLE bodies.

=item field_statement

Concatenates the individual definition clauses for a column definition
statement.

=item insert_statement

Makes the INSERT statements which correspond to data statements in the
Bigtop file.

=back

To make the template operative, requires implementing setup_template:

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

The parser calls this (if the package can respond to it) prior to
calling gen_SQL.  If the user has supplied an alernate template, it
is passed to setup_template.

To avoid bad template binding, $template_is_setup keeps track of whether
we've been here before.

Inline's bind method creates subs in the current name space for callbacks
to use.  Note that if $template_text is a file name, that file will be
bound correctly.

I've tried to abstract out this code so all backends can share it, but
the nature of Inline bindings makes that difficult, so I gave up.

=head3 Real work

All that remains is the real work.  We need to implement output_sql in
about half a dozen packages.

=head4 sql_block

    sub output_sql {
        my $self         = shift;
        my $child_output = shift;

        my $child_out_str = join "\n", @{ $child_output };

        my $output = Bigtop::SQL::Postgres::sql_block(
            {
                keyword      => $self->get_create_keyword(),
                child_output => $child_out_str,
                name         => $self->get_name(),
            }
        );

        return [ $output ];
    }

As all callbacks do, this one receives the current tree node as its
invocant and the output of its children as parameters.  (It also
receives the data passed to walk_postorder, but this method doesn't need it.)

The child output is an array reference of strings which I join with
newlines.  Then I call the sql_block template BLOCK.  I've used
the get_name provided by the sql_block package in Bigtop::Parser.
The get_create_keyword sub is below.

Note that I am careful to give my output back in an array, even though
I have only one item.  This is required by all walk_postorder
visitors.

    sub get_create_keyword {
        my $self = shift;

        return $self->{__BODY__}->create_keyword();
    }

As you can see in the Bigtop::Parser section above, sql_block objects
have a __BODY__ key.  In this module, their packages implement create_keyword
(see below).  It returns 'SEQUENCE' or 'TABLE' as appropriate.

=head4 sequence_body

Here is the whole sequence_body pacakge:

    package sequence_body;
    use strict; use warnings;

    sub create_keyword { return 'SEQUENCE' }

    sub output_sql {
        # XXX for now, just end the line.
        # Watch this space for something more interesting.
        return [ ';' ];
    }

It implements create_keyword as required by sql_block's get_create_keyword
shown above.

It also implements output_sql, which returns a mere semi-colon.  I have
yet to implement min, max, or any of the other sequence control SQL statements.
So that is all I can do.

=head4 table_body

The table_body package is only slightly more interesting:

    package table_body;
    use strict; use warnings;

    sub create_keyword { return 'TABLE' }

    sub output_sql {
        my $self         = shift;
        my $child_output = shift;

        my %output;
        foreach my $statement ( @{ $child_output } ) {
            my ( $type, $output ) = @{ $statement };
            push @{ $output{ $type } }, $output;
        }

        my $output = Bigtop::SQL::Postgres::table_body(
                { child_output => $output{table_body} }
        );

        if ( defined $output{insert_statements} ) {
            $output .= "\n" . join "\n", @{ $output{insert_statements} };
        }

        return [ $output ]
    }

Here we see one example of why children report arrays for output instead
of simple strings.  The children of table_body return hashes keyed
by type.  There are two types: table_body (for column definitions)
and insert_statements (which must come after the table's CREATE
statement).

So, the loop at the top walks through the child output separating
the different types into two arrays.  The body statements are sent
to the table_body TT block.  The insert statements are ready for
immediate use, after the table_body.

=head4 table_element_block

    package table_element_block;
    use strict; use warnings;

    sub output_sql {
        my $self         = shift;
        my $child_output = shift;

        if ( defined $child_output) {

            my $child_out_str = join "\n", @{ $child_output };

            my $output = Bigtop::SQL::Postgres::table_element_block(
                { name => $self->get_name(), child_output => $child_out_str }
            );

            return [ [ table_body => $output ] ];
        }

There are two kinds of children for the table_element_block: fields
(which are themselves blocks) and statements (where are leaves in the AST).
So, if there is child output, we can safely assume that this node is a field
block.  In which case, we join the child output, send it to the
table_element_block TT BLOCK and return the output, being careful
to note that it belongs in the table_body.

Note that even if we want to return a hash, we must return an array of
strings.  All the walk_postorder methods must return only arrays or arrays
of arrays.  This is because the walk_postorder method is neutral (or
ignorant if you prefer) regarding what will happen to the output.

        else {
            return unless ( $self->{__TYPE__} eq 'data' );

            my @columns;
            my @values;
            foreach my $insertion ( @{ $self->{__VALUE__} } ) {
                my ( $column, $value ) = %{ $insertion };

                $value = "'$value'" unless $value =~ /^\d+$/;

                push @columns, $column;
                push @values,  $value;
            }

            my $output = Bigtop::SQL::Postgres::insert_statement(
                {
                    table   => $self->get_table_name,
                    columns => \@columns,
                    values  => \@values,
                }
            );
            return [ [ insert_statements => $output ] ];
        }
    }

If there is no child output, we must be working on a statement.  But,
in this backend, the only statements I care about are data statements.
So, I return unless this is one of those, which I know by checking the
__TYPE__ key of the node's hash.

Recall that data statements look like this:

    data f_name => Phil, l_name => Crow;

The __VALUE__ of the node is an arg_list (which is a blessed array).  The
foreach walks that array hashifying each entry, since the user provided
these as pairs.  The value is quoted to keep SQL happy, unless it is an
integer.  Both key and value are pushed into arrays for easy use by the
insert_statement TT BLOCK.  The result is returned with a note that the
output is for the insert_statements list.

=head4 field_statement

Now we are arriving at the most intricate piece.  It handles the only
statement in the field block we care about: is.

    package field_statement;
    use strict; use warnings;

    my %code_for = (
        primary_key        => sub { 'PRIMARY KEY' },
        assign_by_sequence => \&gen_seq_text,
        auto               => \&gen_seq_text,
    );

    sub output_sql {
        my $self   = shift;
        shift; # discard child output (there isn't any)
        my $lookup = shift;

        return unless $self->get_name() eq 'is';

        my @keywords;
        foreach my $arg ( @{ $self->{__DEF__}{__ARGS__} } ) {
            my $code = $code_for{$arg};

            if ( defined $code ) {
                push @keywords, $code->( $self, $lookup );
            }
            else {
                push @keywords, $arg;
            }
        }
        my $output = Bigtop::SQL::Postgres::field_statement(
                { keywords => \@keywords }
        );

        return [ $output ];
    }

Now we see $lookup coming into the sub.  I gave it to the original
call to walk_postorder, which has been dutifully passing it to all
the output_sql subs it calls.  It's finally come to the place that
needs it (see below).

If the statement's keyword is not 'is', output_sql returns undef.

For 'is' statements, it loops through the __DEF__ __ARGS__.  Each of those
is one of the comma separated clauses or clause abbreviations in the
'is' statement.  For example:

    is int4, primary_key, auto;

has three items in its list: int4, primary_key, and auto.

For each of those, output_sql looks in the code_for hash to see if
there is a sub it should call to convert the text into something else.
If it finds a sub, it calls it and uses the result.  Otherwise, it
merely uses the arg directly.  The input order is preserved in the output.
When calling the converter, it passes the current AST node and $lookup.

Once the proper clauses have all been pushed into the keywords array,
it is passed to the field_statement TT BLOCK.

Note that assign_by_sequence can be abbreviated as auto.  Both of these
point to the gen_seq_text sub:

    sub gen_seq_text {
        my $self       = shift;
        my $lookup     = shift;

        my $table      = $self->get_table_name();

        my $sequence   = $lookup->{tables}{$table}{sequence}{__ARGS__}[0];

        unless ( defined $sequence ) {
            die "I can't assign_by_sequence for table $table.\n"
                .  "You didn't define a sequence for it.\n";
        }

        return "DEFAULT NEXTVAL( '$sequence' )";
    }

The field_statement package in Bigtop::Parser supplied get_table_name
which (not surprisingly) returns the name of the table in which this
field will have its column.  I use that name to fish the table's sequence
name from the lookup hash.  There is a section below, L<The lookup hash>
which has details on what goes into this hash.

One of the top level keys in the lookup hash is 'tables'.  The value
there is a hash keyed by table name.  The values are hashes.  If the
table has a sequence defined, that hash will include a sequence key.
The __ARGS__ of that key is really a single element array holding the
sequence name.

Using the lookup hash is much easier than walking the AST to find things.
But it doesn't have everything.  In particular, it is all hashes, so it
never preserves order.

If there is no sequence, the user receives an error message.  Note that
die is used with trailing newlines, since the bigtop invoker never
wants to hear about line numbers in the bigtop script or in any of the
Bigtop modules.

=head4 literal_block

To allow you to put additional SQL statements into the schema.* file,
Bigtop provides the literal SQL statement.  This package handles it:

    package literal_block;
    use strict; use warnings;

    sub output_sql {
        my $self = shift;

        return $self->make_output( 'SQL' );
    }

Bigtop::Parser provides make_output in its literal_block package to facilitate
literal statements of all sorts.  Simply tell it what sort you are
interested in.  If the node you're working on is of that type, it makes
meaningful output (giving back an array reference with one element containing
the full literal string from the user's statement).  Otherwise, it returns
undef which is discarded by the proper walk_postorder method.

=head3 The lookup hash

The lookup hash is stored inside the AST.  You can get it out like so:

    my $lookup = $tree->{application}{lookup};

as shown in the gen_SQL method of Bigtop::SQL::Postgres shown above.

The keys in the lookup hash are (these are optional, so only some of them
might appear in your hash):

=over 4

=item app_statements

This subhash represents all the simple statements at the app level.  Its
keys are the statement keywords.  The values are arg_lists of the values
for the statement.  arg_lists are the only arrays in the lookup hash.

=item controllers

This subhash represents all the controllers in the Bigtop app section.
Its keys are the controller names.  Each value is a hash with these
keys (some of which are optional):

=over 4

=item methods

This subhash represents all the methods defined for the controller.  It
is keyed by method name.  The value is a hash with two keys:

=over 4

=item statements

Just like the app_statements subhash at the top level.

=item type

(Always present and defined.)

A string with the type supplied in the Bigtop file.

=back

=item configs

Just like the configs subhash at the top level (see below).

=item statements

Just like the app_statements subhash at the top level.  These are the
simple statements of the controller.

=item type

(Always present, but could be undef.)

This is the controller's type.  It will be a string storing the type from
the Bigtop file for this controller or undef if no type was given by the user.

=back

=item configs

The keys are config names.  The values are arg_lists with a single element.
If the config is marked no_accessor, that element will be a hash keyed
by the value storing no_accessor.  Otherwise, that element will be a simple
string.

=item tables

This subhash represents all the tables in the Bigtop file.  It is keyed
by table name and has these subkeys (which are optional):

=over 4

=item data

(Useless.)

This has a single key __ARGS__ which stores the arg_list for the last
data statement in the table.

=item fields

This is a subhash keyed by the name of the field storing subhashes
of simple statements keyed by the statement keyword and storing a
hash with a single key 'args' whose value is an arg_list.

=item foreign_display

This has a single key __ARGS__ which is an arg_list whose single element
is the text of the foreign_display template for this table.

=item sequence

This has a single key __ARGS__ which is an arg_list whose single element
is the sequence name for this table.

=back

=back

Note that I said that the lookup hash is easier to use than direct
AST walking.  But I never said it was trivial or even well designed.
It was easy to build.

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=cut
