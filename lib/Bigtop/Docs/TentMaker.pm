package Bigtop::Docs::TentMaker;

=head1 Name

Bigtop::Docs::TentMaker - An introduction the browser delivered bigtop editor

=head1 Intro

Bigtop is a little language with a simple structure, but it has a lot of
keywords.  Remembering which ones are legal where, and spelling them
correctly is a chore that flies in the face of impatience.  So tentmaker
came along to make the task of making and editing bigtop files easier.
For most applications you can use it exclusively (see
L<What tentmaker can't do> for a list of bigtop features the tentmaker
does not understand).

=head1 Installing and Starting

When you install Bigtop, its Build.PL asks you if you want to install
the tentmaker templates.  You must say yes in order to use tentmaker.

If you did choose a location for the templates (or take the /usr/local/share
default), you will be ready to use tentmaker as soon as you ./Build install.

To start the tentmaker type:

    tentmaker --port=8081 [ file.bigtop ]

If you don't supply a port, tentmaker will bind to 8080.  If you don't supply
a bigtop file (like one from the examples directory of the distribution),
tentmaker will use its default skeleton, which you will need to modify
(unless your name is A. U. Thor).

=head1 Using tentmaker

Once tentmaker starts, you can point your browser to it.  It presents
something like this:

=for html <img src'/images/tentmaker.png' alt='tentmaker default appearance'>

XXX This document is not finished.

=head1 What tentmaker can't do

data statements in tables

alternate locations for header_options and row_options for main_listing
methods

literal blocks

=head1 Further Reading

See Bigtop::Docs::Cookbook for small problems and answers,
Bigtop::Docs::Tutorial for a more complete example, with discussion,
Bigtop::Docs::Keywords for a list of valid keywords and their meanings,
and Bigtop::Docs::Sytnax for full details.  If you need to write your
own backends, see Bigtop::Docs::Modules.

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=cut
