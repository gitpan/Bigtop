package Bigtop::Docs::Modules;

=head1 NAME

Bigtop::Docs::Modules - An annotated list of modules in the Bigtop distribution

=head1 Intro

This document goes into some depth on each piece of of the Bigtop distribution.
Some of the details are left for the POD of the pieces themselves.

If you want to know exactly what's legal in a bigtop file, look in
Bigtop::Docs::Syntax or the more concise (and less complete)
Bigtop::Docs::Keywords.  Or, you could look where tentmaker looks:
Bigtop::Keywords.

=head2 Bigtop.pm

Bigtop.pm is primarily a documentation module.  It does provide two
useful functions for backend authors.  One writes files on the disk
the other makes directory paths.  See its docs for details.

=head2 Bigtop::Parser

This is the real workhorse of Bigtop.  It is a grammar driven parser for
Bigtop files.  Interactions with this parser are usually indirect.
End users use the bigtop script, which in turn uses the parser to first build
an abstract syntax tree (AST) and then to generate output by passing the AST
to the backends.  Developers should write backends which receive the AST
in methods named for what they should produce (see L<Backends> below).

=head3 Parsing Bigtop specifications

If you have a file on the disk and want to parse it into an abstract
syntax tree (AST), call Bigtop::Parser->parse_file( $file_name ).
This returns the AST.

The bigtop script is quite simple.  (It relies on Bigtop::ScriptHelp
when it needs to manufacture or modify bigtop source files.)  Mostly,
it handles command line options, then directly passes the rest of its
command line arguments to gen_from_file in Bigtop::Parser.  gen_from_file
reads the file into memory and passes it and the other command line
arguments to gen_from_string.

gen_from_string first parses the config section of the Bigtop file to
find the backends.  It requires each of those (using Bigtop::Parser->import),
then calls gen_YourType on each one that is not marked no_gen.

The backend's gen_YourType is called as a class method.  It receives the 
base directory of the build (where the user wants files to end up),
the AST, and the input file name (if one is available).

Once you have an AST, you can call methods on it.  Most of these
will return lists (whose element are most often strings).

The most useful method provided is walk_postorder.  It takes care
of walking the tree.  For each element, it calls walk_postorder for
all of the children, pushing their output lists into a meta-list.  Then it
passes that result to the action in the current class.  This is a depth
first traversal.  (If there is no action for the current class, walk_postorder
returns the collection of child output unmodified; except that if the
array of such output is empty, it returns undef and not an empty array.)

You can pass a single item of data (one scalar) to walk_postorder.  That
item (which is usually a hash reference or object) is in turn passed to all
walk_postorder methods in the descendents as they are called.  All of the
walk_postorder methods pass this item on to the action methods when they
call them.

To make this concrete, consider what the Bigtop::Backend::Control::Gantry
does in its gen_Control method:

    my $sub_modules = $bigtop_tree->walk_postorder(
        'output_controller',
        {
            module_dir => $module_dir,
            app_name   => $app_name,
            lookup     => $wadl_tree->{application}{lookup},
            #... more hash keys
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
contains module_dir, app_name, lookup, etc.).  Keep in mind that this
is a post order (depth first) traversal, so children finish making
their output before parents are called on to make output.  In particular,
this means you can't feed your children, or prune off their behavior
(though you could discard their output).  The initial caller must pre-feed
all the children.  Children must prune for themselves.

[footnote: If you do want to avoid child behavior in a parent, you can
change the name of the action method in the child classes.  This makes
the parent the end of the first recursion, allowing it to decide whether
or not to start a new recursion on its subtree.  Upon deciding to initiate
a new recursion, it can feed the children whatever they need.  This technique
is less useful in generators, where the child output is usually
straightforward (like a set of column definitions for the body of a CREATE
TABLE statement in SQL).  Where it shines is in the methods of Bigtop::Parser
which manipulate already parsed trees on behalf of tentmaker.]

The output_controller action methods live in packages named for rules in
the grammar.  See directly below for the package names and how to
implement them.

=head3 The AST

The AST lives in a hash.  This section explains the anatomy of that hash.
It is presented as a nested list so you can see the tree structure by
indentation.  The top level element is blessed into the bigtop_file package.

It responds to these methods: get_config (returns the config subtree) and
get_appname (among others).

It has two children.  The first is configuration (available through
get_config) which is a hash reference representing the config section of
the Bigtop file.  The configuration child is not part of the AST you
walk when generating output, but its info can be essential to your backend.

Since this description was written, the tree has grown.  I decided to
leave this section as is, rather than increase its already somewhat
daunting complexity.  Mainly this reflects my laziness, but I think
it will aid your laziness as well.  You can gain an initial understanding
without as much detail.  Further, most of the new things the tree node classes
do support the tentmaker, which I hope you don't need to work on.

The tree continues with the other child.  First I will show a simple outline
of the whole tree as generated by outliner a script in the lib/Bigtop/Docs
directory of the distribution.  I've compressed the output of outliner
to compress the tree vertically.  This means that attributes which are
not themselves AST nodes are listed in line with their parent.

Below the summary, I will show it again with discussion.  Note that in
both the summary and the full discussion, nodes appear in logical order
as they normally would in a Bigtop source file (modulo placing rare nodes
near the bottom).  This is not the same order as the productions in the
grammar.

In summary:

    application __NAME__ __BODY__:
        block(s?):
            app_config_block __BODY__:
                app_config_statement __KEYWORD__ __ARGS__
            app_statement __KEYWORD__ __ARGS__
            table_block __IDENT__ __NAME__ __TYPE__ __BODY__:
                __IDENT__ __NAME__ __ARGS__ __TYPE__ __BODY__:
                    field_statement __KEYWORD__ __DEF__:
                        field_statement_def __ARGS__
            controller_block __IDENT__ __NAME__ __TYPE__ __BODY__:
                controller_method __IDENT__ __NAME__ __TYPE__ __BODY__:
                    method_body:
                        __KEYWORD__
                        __ARGS__
                controller_config_block __BODY__:
                    controller_config_statement __KEYWORD__ __ARGS__
                controller_literal_block __IDENT__ __BACKEND__ __BODY__
                controller_statement __KEYWORD__ __ARGS__
            join_table __IDENT__ __NAME__ __BODY__:
                join_table_statement
                    __KEYWORD__
                    __DEF__
            literal_block __IDENT__ __BACKEND__ __BODY__
            seq_block __IDENT__ __NAME__ __TYPE__ __BODY__

=over 4

=item application

Responds to thes method:

get_name returns the app name.

show_idents dumps out the name, type, and ident of every ident bearing node.
Useful when building tests of tree manipulations.

There are many other methods, most support tentmaker.

Has these children:

=over 4

=item __NAME__

A string with the app name in it.  This is available through get_appname
on the whole tree or through get_name on the application subtree.

=item __BODY__

Created by Parse::RecDescent's autotree scheme.  Has one child:

=over 4

=item block(s?)

This child is an array (ref) of objects, each blessed into the block class.
Since autotree builds this for us, there is some litter.  We are
only concerned with children whose package names end with _block or
_statement.  These children are:

=over 4

=item app_statement

Represents a simple statement at the app level.  Has two keys:

=over 4

=item __KEYWORD__

The statement's keyword (like authors).

=item __ARGS__

An arg_list (see below).

=back

=item app_config_block

Represents an app level config block.  Has one child:

=over 4

=item __BODY__

An array (possibly undef) of objects blessed into:

=over 4

=item app_config_statement

Has two attributes:

=over 4

=item __KEYWORD__

The name of the set var.

=item __ARGS__

An arg_list (see below).

=back

=back

=back

=item table_block

Responds to get_name which returns the name of the block's table.
The attributes of a table node are:

=over 4

=item __IDENT__

The internal and unchanging name of the node.

=item __NAME__

The name of the constructed sequence or table.

=item __TYPE__

As string, either sequences or tables.

=item __BODY__

The body of the block.  This is an array (ref) of nodes blessed into:

=over 4

=item table_element_block

There are two types of these: statements and field blocks.
Both are blessed into the table_element_block class.  They have the following
keys:

=over 4

=item __IDENT__

For field blocks only.  The internal and unchanging name of the node.

=item __NAME__

For field blocks only.  The name of the field (and its SQL column).

=item __ARGS__

For statements only, the arguments of the statement.  This is an arg_list,
see below.

=item __TYPE__

Either 'field' for field blocks or the statement keyword for statements.

=item __BODY__

Either the statement keyword for statements, or an array (ref) of nodes
blessed into:

=over 4

=item field_statement

The class for field blocks.  These nodes have the following keys:

=over 4

=item __KEYWORD__

The keyword of the statement.

=item __DEF__

A node blessed into the field_statement_def package, which has a single
key:

=over 4

=item __ARGS__

An arg list, see below.

=back

=back

=back

=back

=back

=back

=item controller_block

Responds to get_name which returns the name of the controller.

Has these children:

=over 4

=item __IDENT__

The internal and unchanging name of the node.

=item __NAME__

The name of the controller relative to the app name, available through
get_name.

=item __TYPE__

Controllers are specified as:

    controller Name is type {...}

This attribute is the controller's type.

Note that if the type is base_controller, the controller cannot have
an explicit name, but must be written as:

    controller is base_controller {...}

=item __BODY__

This is an array (ref) of nodes blessed into one of these classes:
controller_method, controller_statement, controller_config_block,
controller_literal_block.  The first two are the most common.

Controller config blocks are quite rare.  They specify controller level
adjustments to the apps top level config block.  These are either new
variables only this controller wants, or replacement values this controller
needs in place of global values.

Controller literal blocks allow placement of literal text into the httpd.conf
Location for this controller.

All of these types are described further below:

=over 4

=item controller_method

Represents a method.  Responds to get_name which returns the method's name.
Has these children:

=over 4

=item __IDENT__

Unique and unchanging internal name.

=item __NAME__

A string attribute.  The name of the method available through get_name.

=item __TYPE__

A string attribute.  As with controllers, methods have types:

    method name is type { ... }

This is the type name.  There should probably be an accessor for this.

=item __BODY__

The body of the method, including all of its statements.  Responds to
these methods: get_method_name, get_controller_name, and get_table_name
(which works if the controller has a controls_table statement).

Blessed into:

=over 4

=item method_body

An array (ref) of nodes blessed into the method_statement class, whose
keys are:

=over 4

=item __KEYWORD__

The statement's keyword.

=item __ARGS__

An arg_list (see below).

=back

=back

=back

=item controller_config_block

Has a single key:

=over 4

=item __BODY__

An array (ref) of nodes blessed into:

=over 4

=item controller_config_statement

Each of these is a leaf with two attributes:

=over 4

=item __KEYWORD__

The config variable's name.

=item __ARGS__

An arg_list (see below).

=back

=back

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

=item __IDENT__

Internal and unchanging name.

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

=item join_table

Represents a many-to-many relationship between two tables and the implicit
table which goes between them.  Has three keys:

=over 4

=item __IDENT__

The internal invariant name of the block.  These are used by tentmaker
to make updates to the existing tree and may vary from parse to parse.

=item __NAME__

The name of the implicit table.  The SQL backend will make SQL statements
to generate this table in the schema.

=item __BODY__

An array (ref) of statements in the block.  There must be a joins statement.
There may be an optional names statement.  Each array element blessed
into:

=over 4

=item join_table_statement

These are somewhat like field_statements, but they are simpler since both
legal statements expect exactly one pair.

=over 4

=item __KEYWORD__

The statement keyword, must be either joins or names.  Exactly one joins
statement must be present (if the parse is valid).  At most one names statement
may be present.  These rules are enforced by the backend.

=item __DEF__

An arg_list containing a single pair.

=back

=back

=back

=item literal_block

This is a leaf node.  It responds to one highly useful method: make_output.
Backends call it on the current subtree (remember it's a leaf) passing in
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
both handled by Bigtop::Backend::Gantry::HttpdConf.  It needs the hash form
to know where to put the literal output.

literal_blocks have three attributes:

=over 4

=item __IDENT__

Internal unchanging name.

=item __BACKEND__

The name of the backend this literal is intended for.

=item __BODY__

The literal text for the backend.

Usually it is easier to call make_output than to fish for these.

=back

=item seq_block

Responds to get_name.  Represents a sequence block.  Only the Postgres SQL
backend understands sequence blocks.  All other backends ignore them
completely, even if a table includes a sequence statement.
Has the following keys:

=over 4

=item __IDENT__

The internal and unchanging name of the node.

=item __NAME__

The name of the sequence.

=item __TYPE__

Hold over from when sequences were blessed into the same package as tables.
Deprecated and may be removed.

=item __BODY__

If there were any legal sequence statements (which there aren't), this
would be an array ref holding the statements in the sequence block.
As it is, you can't use this.

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

While the items in an arg_list are not blessed, the whole list is.
The arg_list pacakge in Bigtop::Parser provides many convenience methods
for getting and setting data in the list.  Here are some highlights:

=over 4

=item get_first_arg

When you know that your statement only uses one arg, call this to get
it.  It saves you having to fish in the array for the first arg.  If
the first arg is a pair, you will receive a hash with one key.

=item get_args

Returns all of the args as valid Bigtop input.  The above example would
come back as:

    value1, key, value2, value3

This is useful when you don't want quoted values and you don't expect
pairs.

=item get_quoted_args

Primarily useful when deparsing.  Returns the arg list as a string which
is valid bigtop input.  This adds all needed backquotes (but none
that aren't required).

=item get_unquoted_args

Returns an array of the args, but with pairs converted to strings like so:

    key => value2

Only occasionally useful by backends.

=back

Most backend either use get_first_arg, or walk the list themselves.

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
and test the generated files (say with Test::Files) as the Bigtop test
suite tends to do.

To know what a particular backend will do, see Bigtop::Docs::Keywords
or Bigtop::Docs::Syntax.  That is also where you will see a list of the
keywords they understand and what values those keywords take.

To write a backend, you need to write the gen_* method and have one package
for each AST element type you care about.  It is easiset to see this by
example.  A good example is Bigtop::Backend::SQL::SQLite.  I'll show it
here so you can see how it goes with commentary interspersed amongst the
code.  To see the whole of it, look for lib/Bigtop/Backend/SQL/SQLite.pm
in the Bigtop distribution.  (Note that I have removed some details to make
this presentation easier, and the real version may have been updated
more recently than this discussion.)

=head3 Preamble

There is nothing really fancy about the start of a backend:

 package Bigtop::Backend::SQL::SQLite;
 use strict; use warnings;

 use Bigtop::Backend::SQL;
 use Inline;

Note that the package name must begin with Bigtop::Backend:: in order
for the bigtop and tentmaker scripts to find it.

I use Bigtop::Backend::SQL, which registers the SQL keywords with the
Bigtop parser.  Actually, Bigtop::Backend::SQL uses Bigtop::Keywords
which is a central repository of all keywords any backend could want.
It is really best to add the keywords there.  Among other things it
makes maintenance easier.  But this is not a requirement (even for
proper tentmaker functioning).

In all of my backends I use Inline::TT to aid in generating
the output.  It needs Inline loaded.  (See setup_template below for how
templates are installed for use.)

=head3 TentMaker requirements

 sub what_do_you_make {
     return [
         [ 'docs/schema.sqlite' => 'SQLite database schema' ],
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

           { keyword => 'template',
             label   => 'Alternate Template',
             descr   => 'A custom TT template.',
             type    => 'text' },
           ];
 }

backend_block_keywords is similar to what_do_you_make.  It lists all
the valid keywords which can go in the backend's block in the config
section at the top of the Bigtop file.  These appear in order in the
far right column of the Backends tab of tentmaker.  The above keys are
required, if you need a default use the C<default> key.  If the type is
boolean, spell out C<true> or C<false> as the default value (these
are going to HTML and/or Javascript as strings).  If you don't specify a
default, you get false (unchecked) for booleans and blank for strings.

=head3 The generating sub

 sub gen_SQL {
     shift;
     my $base_dir = shift;
     my $tree     = shift;

The bigtop script will call gen_SQL (via gen_from_sting) when the
user has this backend in their config section and invokes bigtop with
SQL or all in the list of build items.

The class name is not needed, so I shifted it into the ether.

The $base_dir is where the output goes.

The $tree is the full AST (see above for details).

     # walk tree generating sql
     my $lookup       = $tree->{application}{lookup};
     my $sql          = $tree->walk_postorder( 'output_sql_lite', $lookup );
     my $sql_output   = join '', @{ $sql };

The lookup subtree of the application subtree provides easier access to
the data in the tree (though it doesn't have all the connectors the AST
has for parsing use, in particular it uses hashes exclusively, so it never
intentionally preserves order).

I let Bigtop::Parser's walk_postorder do the visiting of tree nodes
for me.  It will call 'output_sql_lite' on each of them.  I implement that
on the packages my SQL generator cares about below.  I pass the lookup
hash to walk_postorder so it will be available to the callbacks.

Note that the name of the walk_postorder action needs to be unique among
all Bigtop::Backend::* modules.  This prevents subroutine redefinitions
(and their warnings) when multiple SQL backends are in use.  It also
makes tentmaker run more quietly in all cases.  Choose names with some
tag relating to your backend to avoid namespace collisions.

The output of walk_postorder is always an array reference.  I join it
together and store it in $sql_output.

     # write the schema.postgres
     my $docs_dir     = File::Spec->catdir( $base_dir, 'docs' );
     mkdir $docs_dir;

By the convention of our shop, the schema.sqlite file lives in the docs
directory of the generated distribution.  Here, I make that directory
(if that fails we'll hear loud screaming shortly).

All that remains is to put the output into the file:

     my $sql_file     = File::Spec->catfile( $docs_dir, 'schema.sqlite' );

     open my $SQL, '>', $sql_file or die "Couldn't write $sql_file: $!\n";

     print $SQL $sql_output;

     close $SQL or die "Couldn't close $sql_file: $!\n";
 }

So, the whole generation method is only 22 lines.  Except for the specific
use of 'sqlite' or 'lite', this method is the same for the other SQL backends.
Of course, there is still a lot left for me to do.

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
   
   [% BLOCK three_way %]
   CREATE TABLE [% table_name %] (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
   [% FOREACH foreign_key IN foreign_keys %]
       [% foreign_key %] INTEGER[% UNLESS loop.last %],[% END +%]
   [% END %]
   );
   [% END %]
   EO_TT_blocks

There are six blocks -- whose names usually correspond to grammar rules --
each of which may be used repeatedly while generating output:

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

=item three_way

Makes the CREATE TABLE block for implicit tables which join other tables.
These come from join_table blocks in the Bigtop file which in turn
come from a<->b in ASCII art passed to bigtop or tentmaker at the command line.

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

=head4 table_block

 package # table_block
     table_block;
 use strict; use warnings;

 sub output_sql_lite {
     my $self         = shift;
     my $child_output = shift;
  
     return if ( $self->_skip_this_block );
  
     my %output;
     foreach my $statement ( @{ $child_output } ) {
         my ( $type, $output ) = @{ $statement };
         push @{ $output{ $type } }, $output;
     }
  
     my $child_out_str = Bigtop::Backend::SQL::SQLite::table_body(
         { child_output => $output{table_body} }
     );
  
     if ( defined $output{insert_statements} ) {
         $child_out_str .= "\n" . join "\n", @{ $output{insert_statements} };
     }
  
     my $output = Bigtop::Backend::SQL::SQLite::sql_block(
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

The child output comes from the walk_postorder method of this package.
It is always an array reference.  In this case, that array has one or more
subarrays.  Each of those has two elements: type and text.  The types
are: table_body and insert_statements.  The table_body elements must
go inside the body of the CREATE TABLE statement.  The insert_statements
must be placed after the CREATE TABLE statement.  There is one of those
for each data statement in the table block of the Bigtop file.

While the child output is always an array reference, its contents are up
to you.  We'll see how I formed the child output for this package below,
when we walk into the child packages.  Usually I only put arrays in it,
to avoid confusion.

Once the child output is divided into two pieces, I first call the
table_body template BLOCK.  Then I join the insert statements together
as strings.  Finally, I call the sql_block template BLOCK.  I've used
the get_name provided by the sql_block package in Bigtop::Parser.
The get_create_keyword sub is defined in Bigtop::Backend::SQL.  The same
method (with different output) is defined there for the seq_block package
used by Bigtop::Backend::SQL::Postgres to build sequence statements.

Note that I am careful to give my output back in an array, even though
I have only one item.  This is required by all walk_postorder
actions.

=head4 table_element_block

 package # table_element_block
     table_element_block;
 use strict; use warnings;

 sub output_sql_lite {
     my $self         = shift;
     my $child_output = shift;
 
     if ( defined $child_output) {

         my $child_out_str = join "\n", @{ $child_output };

         my $output = Bigtop::Backend::SQL::SQLite::table_element_block(
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

Note that I always return arrays, even if I want to return a hash.  This
avoids rare but nasty bugs when the returned values pass through packages
which aren't responding to the current action.

     else {
         return unless ( $self->{__TYPE__} eq 'data' );
  
         my @columns;
         my @values;
         foreach my $insertion ( @{ $self->{__ARGS__} } ) {
             my ( $column, $value ) = %{ $insertion };
  
             $value = "'$value'" unless $value =~ /^\d+$/;
  
             push @columns, $column;
             push @values,  $value;
         }
  
         my $output = Bigtop::Backend::SQL::SQLite::insert_statement(
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

The __ARGS__ for the node is an arg_list (which is a blessed array).  The
foreach walks that array hashifying each entry, since the user provided
these as pairs.  The value is quoted to keep SQL happy, unless it is an
integer.  Both key and value are pushed into arrays for easy use by the
insert_statement TT BLOCK.  The result is returned with a note that the
output is for the insert_statements list.

=head4 field_statement

Now we are arriving at the most intricate piece.  It handles the only
statement in the field block we care about: is.

 package # field_statement
     field_statement;
 use strict; use warnings;
 
 my %expansion_for = (
     int4               => 'INTEGER',
     primary_key        => 'PRIMARY KEY',
     assign_by_sequence => 'AUTOINCREMENT',
     auto               => 'AUTOINCREMENT',
 );
 
 sub output_sql_lite {
     my $self   = shift;
     shift;  # there is no child output
     my $lookup = shift;
 
     return unless $self->get_name() eq 'is';
 
     my @keywords;
     foreach my $arg ( @{ $self->{__DEF__}{__ARGS__} } ) {
         my $expanded_form = $expansion_for{$arg};
 
         if ( defined $expanded_form ) {
             push @keywords, $expanded_form;
         }
         else {
             push @keywords, $arg;
         }
     }
     my $output = Bigtop::Backend::SQL::SQLite::field_statement(
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

For each of those, output_sql looks in the expansion_for hash to see if
there is alternate text for the input word.  If it finds alternate text,
it uses it.  Otherwise, it merely uses the arg directly.  The input order
is preserved in the output.  This is the mechanism that allows all
Bigtop input files to use int4, primary_key, and auto.  Each backend
uses a scheme like this one (though Postgres' is more complex) to generate
the SQL for its database engine.

Once the proper clauses have all been pushed into the keywords array,
it is passed to the field_statement TT BLOCK.

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
literal statements of all sorts.  Simply tell it what backend type you are
interested in.  If the node you're working on is of that type, it makes
meaningful output (giving back an array reference with one element containing
the full literal string from the user's statement).  Otherwise, it returns
undef which is discarded by the proper walk_postorder method.

=head4 join_table

Join tables are manufactured tables whose only purpose is to embody a
many-to-many relationship between other tables.

 sub output_sql {
     my $self         = shift;
     my $child_output = shift;

     my $three_way    = Bigtop::Backend::SQL::SQLite::three_way(
         {
             table_name   => $self->{__NAME__},
             foreign_keys => $child_output,
         }
     );

     return [ $three_way ];
 }

This method just passes the buck to the three_way TT block.

=head4 join_table_statement

 sub output_sql {
     my $self         = shift;
     my $child_output = shift;

     return unless $self->{__KEYWORD__} eq 'joins';

     my @tables = %{ $self->{__DEF__}->get_first_arg() };

     return \@tables;
 }

 1;

The __DEF__ key stores the joins or names statement pair, it is an
arg_list object.  These respond to get_first_arg and other methods.
Since there is only ever one pair allowed for either of these statements,
we just want that one pair.  It comes back as a hash, but we must once
again make it an array to comply with walk_postorder's return value API.

The rest of the module is all POD.

=head3 The lookup hash

The lookup hash is stored inside the AST.  You can get it out like so:

    my $lookup = $tree->{application}{lookup};

as shown in the gen_SQL method shown above.

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

=item join_tables

This subhash represents all join_tables in the Bigtop file, but each one
appears twice -- once for each table involved in the many-to-many
relationship.  The keys of the hash are the names of the tables on either
side of the many-to-many.  The values are hashes, which are slightly
complex.  Here is an example:

    join_tables => {
        skill => { joins => { job   => 'job_skill' } },
        job   => { joins => { skill => 'job_skill' } },
        fox   => { joins => { sock  => 'fox_sock'  },
                   name  => 'socks' },
        sock  => { joins => { fox   => 'fox_sock'  },
                   name  => 'foxes' },
    }

which corresponds to these join_table blocks:

    join_table job_skill { joins job => skill; }
    join_table fox_sock  { joins fox => sock; names foxes => socks; }

=back

Note that I said that the lookup hash is easier to use than direct
AST walking.  But I never said it was trivial or even well designed.
It was easy to build.

Here is the gist of the lookup hash in summary (as generated by outliner):

    app_statements
    controllers
        methods
            statements
            type
        configs
        statements
        type
    configs
    tables
        data
        fields
        foreign_display
        sequence
    join_tables

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=cut
