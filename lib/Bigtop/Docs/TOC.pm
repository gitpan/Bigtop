package Bigtop::Docs::TOC;

=head1 NAME

Bigtop::Docs::TOC - Table of Contents for Bigtop::Docs::* documentation modules

=head1 What Should I Read?

This document is a brief annotated list of each Bigtop::Docs::* module.

=over 4

=item Bigtop::Docs::About

Describes the features and motivations of Bigtop.

=item Bigtop::Docs::Cookbook

Modeled after the Perl Cookbook, this provides a list of things you might
want to do, the syntax needed to make Bigtop do them for you, and the
output produced by them.

=item Bigtop::Docs::Keywords

A (fairly) complete list of keywords Bigtop understands in a compact text
file.  See Bigtop::Docs::QuickRef for most of the same information in
html tabular formatting.

=item Bigtop::Docs::Modules

Documents many of the modules in the bigtop distribution including at least:
Bigtop.pm, Bigtop::Parser.  This includes a description of the grammar
of the Bigtop language and how to work with it.  (Note that the grammar
is now in its own file called bigtop.grammar, but this has no effect on
the docs in Bigtop::Docs::Modules.  It may be out of date, but the extraction
of the grammar is not the reason.)

=item Bigtop::Docs::QuickRef

This provides a somewhat complete list of all the keywords Bigtop understands
along with some examples in html form.  The depth of the tables involved
makes it somewhat difficult to use.  For a more compact version in plain
text, see Bigtop::Docs::Keywords.

=item Bigtop::Docs::Syntax

This is meant to fully describe all of the syntax (including deprecations)
in the Bigtop language.  It is the encyclopedic version of
Bigtop::Docs::Keywords.

=item Bigtop::Docs::TentTut

The tentmaker tutorial.  Explains in detail how to use tentmaker to edit
Bigtop files.  Filled with beautiful screen shots.

=item Bigtop::Docs::Tutorial

If you don't like tentmaker, this is where you should start.  It walks
through building a moderately complex application from scratch using
a text editor to enter the proper Bigtop syntax.

=item Bigtop::Docs::Vim

Explains how to install vim syntax highlighting for Bigtop source files.

=back

=head1 AUTHOR

Phil Crow

=cut
