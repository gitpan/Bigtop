# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::Checkbook::GEN::SOAP;

use strict;
use warnings;

use Apps::Checkbook qw(
    -PluginNamespace=Apps::Checkbook::SOAP
    SOAP::RPC
);

our @ISA = qw( Apps::Checkbook );


#-----------------------------------------------------------------
# $self->namespace(  )
#-----------------------------------------------------------------
sub namespace {
    return 'Apps::Checkbook::SOAP';
} # END namespace

#-----------------------------------------------------------------
# $self->get_soap_ops
#-----------------------------------------------------------------
sub get_soap_ops {
    my $self = shift;

    return {
        soap_name      => 'Checkbook',
        location       => $self->location,
        namespace_base => 'www.example.com/wsdl',
        operations     => [
            {
                name => 'greet',
                expects => [
                    { name => 'name', type => 'xsd:string' },
                ],
                returns => [
                    { name => 'greeting', type => 'xsd:string' },
                ],
            },
            {
                name => 'cube_root',
                expects => [
                    { name => 'target', type => 'xsd:double' },
                    { name => 'tolerance', type => 'xsd:double' },
                ],
                returns => [
                    { name => 'answer', type => 'xsd:double' },
                ],
            },
        ],
    };
} # END get_soap_ops

1;

=head1 NAME

Apps::Checkbook::GEN::SOAP - generated support module for Apps::Checkbook::SOAP

=head1 SYNOPSIS

In Apps::Checkbook::SOAP:

    use base 'Apps::Checkbook::GEN::SOAP';

=head1 DESCRIPTION

This module was generated by bigtop and IS subject to regeneration.
Use it in Apps::Checkbook::SOAP to provide the methods below.
Feel free to override them.

=head1 METHODS

=over 4

=item namespace

=item get_soap_ops


=back

=head1 AUTHOR

Generated by bigtop and subject to regeneration.

=cut

