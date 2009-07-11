package Kids::Model;
use strict; use warnings;

use base 'DBIx::Class::Schema';

use Kids::GENModel;

sub get_db_options {
    return { AutoCommit => 1 };
}

1;

=head1 NAME

Kids::Model - schema class for Kids

=head1 SYNOPSIS

In your base module:

    use Kids::Model;
    sub schema_base_class { return 'Kids::Model'; }
    use Gantry::Plugins::DBIxClassConn qw( get_schema );
    use Kids::Model::child qw( $CHILD );

=head1 DESCRIPTION

This module was generated by Bigtop.  But, feel free to edit it.  You
might even want to update these docs.

=over 4

=item get_db_options

The generated version sets AutoCommit to 1, this assumes that you will
do all transaction work via the DBIx::Class API.

=back

=head1 DEPENDENCIES

    Gantry::Utils::DBIxClass
    Kids::GENModel

=head1 AUTHOR

Phil Crow, E<lt>phil@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
