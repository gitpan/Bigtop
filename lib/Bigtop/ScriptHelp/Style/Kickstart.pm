package Bigtop::ScriptHelp::Style::Kickstart;
use strict; use warnings;

use base 'Bigtop::ScriptHelp::Style';

use Text::Balanced qw( extract_multiple extract_bracketed );

use Bigtop::ScriptHelp qw( valid_ident );

my $default_columns = 'ident,description';

sub get_db_layout {
    my $self   = shift;
    my $art    = shift || '';
    my $tables = shift || {};

    {
        no warnings;  # don't tell me about unsuccessful stats on $art

        if ( -f $art ) { # take art from file

            open my $ART, '<', $art;
            my $actual_art = join '', <$ART>;
            close $ART;

            $art = $actual_art;
        }
    }

    my @new_tables;
    my @joiners;
    my %foreign_key_for;
    my %columns;

    $art =~ s/^\s+//;
    $art =~ s/\s+$//;

    foreach my $art_element ( split /\s+/, $art ) {
        if ( $art_element =~ /<|-|>/ ) {
            # split tables from operator
            my ( $table1, $op, $table2 ) =
                    split /(<->|->|<-|\*>|<\*|-)/, $art_element;

            # now pull column descriptions, if present
            my ( $cols1, $cols2 );

            ( $table1, $cols1 ) = _get_columns( $table1 );
            ( $table2, $cols2 ) = _get_columns( $table2 );

            unless ( defined $table1 and valid_ident( $table1 )
                        and
                     defined $table2 and valid_ident( $table2 )
                        and
                     defined $op
            ) {
                die "Invalid ASCII art (1): $art_element\n";
            }

            # make sure tables are in the list of all tables
            unless ( defined $tables->{ $table1 } ) {
                push @new_tables, $table1;
                $tables->{ $table1 }++;
            }
            $columns{ $table1 } = $cols1 if defined $cols1;

            unless ( defined $tables->{ $table2 } ) {
                push @new_tables, $table2;
                $tables->{ $table2 }++;
            }
            $columns{ $table2 } = $cols2 if defined $cols2;

            # process based on operator
            if ( $op eq '<-' or $op eq '*>' ) {
                push @{ $foreign_key_for{ $table2 } },
                     { table => $table1, col => 1};
            }
            elsif ( $op eq '->' or $op eq '<*' ) {
                push @{ $foreign_key_for{ $table1 } },
                     { table => $table2, col => 1};
            }
            elsif ( $op eq '-' ) {
                push @{ $foreign_key_for{ $table2 } },
                     { table => $table1, col => 1 };
                push @{ $foreign_key_for{ $table1 } },
                     { table => $table2, col => 1 };
            }
            elsif ( $op eq '<->' ) {
                push @joiners, [ $table1, $table2 ];
            }
            else {
                die "Invalid ASCII art (2): $art_element\n";
            }
        }
        elsif ( valid_ident( $art_element ) ) {
            unless ( defined $tables->{ $art_element } ) {
                push @new_tables, $art_element;
                $tables->{ $art_element }++;
                $columns{ $art_element } = _parse_columns( $default_columns )
                    unless $columns{ $art_element };
            }
        }
        else {
            my ( $table, $cols ) = _get_columns( $art_element );

            unless ( valid_ident( $table ) ) {
                die "Invalid ASCII art (3): $art_element\n";
            }

            unless ( defined $tables->{ $table } ) {
                push @new_tables, $table;
                $tables->{ $table }++;
            }
            $columns{ $table } = $cols if defined $cols;
        }
    }

    my $parsed_defaults = _parse_columns( $default_columns );
    NEW_TABLE:
    foreach my $new_table ( @new_tables ) { # add default cols as needed
        next NEW_TABLE if defined $columns{ $new_table };
        $columns{ $new_table } = $parsed_defaults;
    }

    return {
        all_tables => $tables,
        new_tables => \@new_tables,
        joiners    => \@joiners,
        foreigners => \%foreign_key_for,
        columns    => \%columns,
    }
}

sub _get_columns {
    my $table = shift;

    my ( $name, $raw ) = extract_multiple(
        $table, [
            qr/([^(]*)/, sub { extract_bracketed( $_[0], '()' ) }
        ]
    );

    if ( defined $raw ) {

        $raw =~ s/^\(//;
        $raw =~ s/\)$//;

        return ( $name, _parse_columns( $raw ) );
    }
    else {
        return ( $name );
    }
}

sub _parse_columns {
    my $raw = shift;

    my @pieces = split /,/, $raw;

    my $you_dont_want_em  = 0;
    my %is_normal_default = (
        id       => 1,
        created  => 1,
        modified => 1,
    );

    my @columns;
    foreach my $piece ( @pieces ) {
        my ( $name_type, $default ) = split /=/, $piece;
        my ( $name, @types ) = split /:/, $name_type;

        # pull optional plus from name
        my $optional;
        $optional = 1 if ( $name =~ s/^\+// );

        @types = ( 'varchar' ) unless ( @types > 0 );

        # begin building columns sub hash with required keys
        my %col_hash = ( name => $name, types => \@types );

        # fill in other keys if we need them
        $col_hash{ default  } = $default  if $default;
        $col_hash{ optional } = $optional if $optional;

        push @columns, \%col_hash;

        $you_dont_want_em++ if defined $is_normal_default{ $name };
    }

    unless ( $you_dont_want_em ) {
        unshift @columns, {
                    name  => 'id',
                    types => [ 'int4', 'primary_key', 'auto' ]
                };

        push @columns,
             { name => 'created',  types => [ 'datetime' ] },
             { name => 'modified', types => [ 'datetime' ] };
    }

    return \@columns;
}

1;

=head1 NAME

Bigtop::ScriptHelp::Style::Kickstart - handles kickstart syntax for scripts

=head1 SYNOPSIS

Most users use this module as the default style for the bigtop and
tentmaker scripts:

    bigtop -n AppName [kickstart]

See L<KICKSTART SYNTAX> below for details, but note that kickstart could
be a file whose contents are in kickstart syntax.

If you are writing a script that want to leverage styles do this:

    use Bigtop::ScriptHelp::Style;

    my $style = Bigtop::ScriptHelp::Style->get_style( 'Kickstart' );

    # then pass $style to methods of Bigtop::ScriptHelp

=head1 DESCRIPTION

See C<Bigtop::ScriptHelp::Style> for a description of what this module
must do in general.

=head1 METHODS

=over 4

=item get_db_layout

This method does not use standard in.  Instead, it expects
kickstart syntax.  See L<KICKSTART SYNTAX> below.

=back

=head1 KICKSTART SYNTAX

Bigtop's kickstart syntax allows you to describe your tables, their columns,
and how they are related to other tables in a compressed text style.

Note well: Since the descriptions use punctuation that your shell probably
loves, you must surround them with single quotes on the command line.  But,
there's no need to do that if you put the kickstart description in a file.
To use the file method, put your kickstart in a file and give that
file's name as in:

    tentmaker -a docs/app.bigtop kickstart_file

It is easiest to understand kickstart syntax is by seeing an example.  So,
suppose we have a four table data model describing a bit of our personnel
process:

    +-----------+       +----------+
    |    job    |<------| position |
    +-----------+       +----------+
          ^
          |
    +-----------+       +----------+
    | job_skill |------>|  skill   |
    +-----------+       +----------+

What this data model shows is that each position refers to a job,
each job could require many skills, and each skill could be associated with
many jobs.  The last two mean that job and skill share a many-to-many
relationship.

Here's how to specify this data model with bigtop kickstart syntax:

    bigtop --new HR 'job<-position job<->skill'

This indicates a foreign key from position to job and an implied
table, called job_skill, to hold the many-to-many relationship between
job and skill.

The same kickstart can be used with --new and --add for both bigtop
and tentmaker scripts.

There are four kickstart table relationship operators:

=over 4

=item <->

Many-to-many.  A new table will be made with foreign keys to each operand
table.  Each operand table will have a has_many relationship.  Note
that your Model backend may not understand these relationships.  At the
time of this writing only Model GantryDBIxClass did, by luck it happens
to be the default.

=item <- or *>

The second table has a foreign key pointing to the first.

The *> form is useful if you want to read the relationship with the phrase
'has-many' as in

    book*>chapter

Each book has many chapters.  Instead of

    book<-chapter

Each chapter belongs to a book.  But, both forms are equivalent.

=item -> or <*

The first table has a foreign key pointing to the second.  This is really
a convenience synonymn for <-.

Note that tables will appear in the generated SQL so that foreign keys
appear after the tables they refer to (at least that is the goal).  Hence
the order of your tables in the kickstart has no bearing on
their order in the bigtop file.

=item -

The two tables have a one-to-one relationship.  Each of them will have
a foreign key pointing to the other.  Note that this will create SQL which
is unlikely to load well due to foreign key forward references.

=back

=head2 COLUMN DEFINITIONS

As of Bigtop 0.23, you may use the syntax below to specify information
about the columns in your tables, in addition to the table relationships
above.

Note Well:  When following the instructions below, never be tempted to
use spaces inside column definitions.  If you need spaces, colons might
work.  If not, you'll need to edit the generated bigtop file, just like
old times.

Column definitions must be placed inside parnetheses immediately after the
table name and immediately before any table relationship operator.  Separate
columns with commas.  Specify type definitions with colons.  Use equals
for defaults and leading plus signs for optional fields.  For example:

    bigtop -n App 'family(name,+phone)<-child(name,birth_day:date)'

By default all columns will have type varchar (but note that SQL backends
translate that into some other string type for all supported databases,
if a bare varchar wouldn't work).  If you need some other type, use a colon,
as I did for birth_day.  If your type definition needs multiple words, use
colons instead of spaces.

Do not include foreign key columns in the list.  They will be generated
based on the relationship punctuation between the tables.

The phone column in the family table has a leading plus sign, and will
therefore be optional on the HTML form.

You can still augment the bigtop file later.  Existing tables in the bigtop
file will have foreign keys added as specified by relation operators, but
parenthetical column lists will be used only for new tables.  For example:

    bigtop -a docs/app.bigtop '
        anniversary(anniversary:date,gift_pref=money)<-family'

This will add a new table called anniversary with anniversary (a date) and
gift_pref columns.  The later will have a default value in the database
and on HTML forms of 'money.'  Finally, a new foreign key will be added
to the existing family table pointing to the anniversary table.

You may find it easier to supply the kickstart text by first specifying the
relationships without including the columns, then defining the columns later:

    tentmaker -n App \
    'child->family anniversary->family
        child(name,birth_day:date)
        family(name,+phone)
        anniversary(anniversary:date,gift_pref=money)'

You may mention a table as many times as you like, but only define its
columns once.

Finally, as mentioned in the L<SYNOPSIS>, and described in more detail below
(see L<KICKSTART FILES>, you may put the kickstart in
a file and supply the file name on the command line:

    tentmaker -n App app.kickstart

None of the syntax changes when you use the file approach, except that
you don't need the shell quotes.  In paricular, using a file does not
allow you to include spaces within a table's definition.

=head2 FORMAL SUMMARY

Here is the formal syntax for each table definition:

    name(COL_DEF[,COL_DEF...])

Where name is a valid SQL table name and COL_DEF is as follows:

    [+]col_name[:TYPE_INFO][=default]

Where plus makes the HTML form field for the column optional,
col_name is a valid SQL column name, and
all defaults are literal strings (they will be quoted in SQL).  If you need
more interesting defaults, edit the bigtop file after it is updated.
TYPE_INFO is a colon separated list of column declaration words.

Suppose you want this column definition:

    state int4 NOT NULL DEFAULT 4,

Say this:

    state:int4:NOT:NULL=4

=head2 KICKSTART FILES

Traditionally, kickstart text was specified on the command line.  Now you
can put it in a file and invoke bigtop or tentmaker like this:

    bigtop -n NewApp file.kickstart

Unfortunately, you cannot currently pipe to bigtop to tentmaker, they
do not read from standard in.

Here is an example kickstart file for a blogging application:

    blog(active:int4,ident,title,subtitle,blurb,body,gps,comments_enabled:int4,rank:int4,section,username,tag)
    author(name,address,city,state,country,gps)
    comment(active:int4,rejected:int4,name,email,url,subject,body)
    link(active:int4,location,label,posted_date,score,username,tag)
    tag(active:int4,label,rank)
    image(active:int4,label,descr,file,default_image,file_ident,file_name,file_size:int4,file_mime,file_suffix)
    attachment(active:int4,label,descr,file,default_image,file_ident,file_name,file_size:int4,file_mime,file_suffix)
    section(active:int4,label)
    blog<-image
    blog<-attachment
    blog<-author
    blog<-comment
    blog<-section

Note again that spaces are not allowed in column definition lists, since
whitespace is the separator of table and table relationship entries.

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

