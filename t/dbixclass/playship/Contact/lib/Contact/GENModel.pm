package Contact::Model;
use strict; use warnings;

__PACKAGE__->load_classes( qw/
    number
    bday
    tshirt
    color
    tshirt_color
    tshirt_author
    author
    book
    author_book
    sch_name
/ );

1;

=head1 NAME

Contact::GENModel - regenerating schema for Contact

=head1 SYNOPSIS

In your base schema:

    use base 'DBIx::Class::Schema';
    use Contact::GENModel;

=head1 DESCRIPTION

This module was generated by Bigtop (and IS subject to regeneration).

=head1 DEPENDENCIES

    Gantry::Utils::DBIxClass

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
