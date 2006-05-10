package Bigtop::Backend::Control;
use strict; use warnings;

use Bigtop::Keywords;

#-----------------------------------------------------------------
#   Register keywords in the grammar
#-----------------------------------------------------------------

my %controller_keywords;

BEGIN {
    my @controller_keywords = qw( controls_table uses text_description );

    @controller_keywords{ @controller_keywords } = @controller_keywords;
    
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'controller',
            qw( controls_table uses text_description )
        )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'app',
            qw( authors email copyright_holder license_text uses )
        )
    );
}

sub is_controller_keyword {
    shift;
    my $candidate = shift;

    return $controller_keywords{ $candidate };
}

1;

=head1 NAME

Bigtop::Backend::Control - defines legal keywords in control blocks

=head1 SYNOPSIS

If you are making a control generating backend:

    use Bigtop::Backend::Control;

This specifies the valid keywords for the controller.

If you need additional keywords which are generally useful, add them
here (and send in a patch).  If you need backend specific keywords, register
them within your backend module.

=head1 DESCRIPTION

If you are using a Bigtop backend which generates controllers, you should read
this document to find out what the valid keywords inside controller blocks
are and what affect they have.

If you are writing a Bigtop backend which generates controllers, you should
use this module.  That will register the standard controller keywords with
the Bigtop parser.

=head1 BASIC STRUCTURE

A controller block looks like this:

    controller name { }

Inside the braces, you can include simple statements or method blocks.
Each method block looks like this:

    method name is type { }

The type must be supported by your backend.  Look in its pod for
SUPPORTED TYPES.

=head1 KEYWORDS in app blocks

This module registers these keywords in app blocks:

=over 4

=item authors

These are the authors' names which Control backends will put in the pod
stub for each generated module.  The first author will also be used as
the copyright holder (at least until further notice).

=item copyright_holder

This string will come at the end of the phrase Copyright...
in the pod.  By default, it will be the first person in the authors list.

=item email

This will be presented by the Control backend as the author's email
in the AUTHOR section of the pod block at the bottom of each module.

=item license_text

The exact text of the paragraph that comes directly after the copyright
statement in the all files that have that.  Controllers should pick
a default that h2xs would have generated for Perl version 5.8 or later.

Example:

    copyright_holder `Your Company Inc.`;
    license_text     `All rights reserved.`;

Example output:

    Copyright (c) 2005 Your Company Inc.

    All rights reserved.

=back

=head1 KEYWORDS in controller blocks

The simple statement keywords available in controller blocks are
(all of these are optional):

=over 4

=item controls_table

This is the name of the table which this controller controls.  It must
be defined in a table block somewhere in the bigtop file.

=item uses

A comma separated list of modules which the controller should include with
Perl use statements.  There is not currently a way to limit what these
modules export, except by editing the generated stub.

=item text_description

This is a short phrase that describes the rows of the table.  It will
usually become the return value of get_text_description (a class accessor).
For example, Gantry's AutoCRUD uses this in user messages.

=back

Note that some other backend types also look for information in controller
blocks.  Pay particular attention to HttpdConf backends.  They typically
expect a location or rel_location keyword which becomes the Apache Location
for the controller.

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
