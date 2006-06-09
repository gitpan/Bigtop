package Bigtop::TentMaker;
use strict; use warnings;

use base 'Gantry';
use Bigtop::Parser;
use Bigtop::Deparser;
use File::Find;

# Parsing takes time, I'm caching these.  I blow out the cached values
# when $file changes.
my $file;
my $input;
my $tree;
my $deparsed;
my %backends;
my $statements;

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    return if $AUTOLOAD =~ /DESTROY$/;

    warn "$self was asked to $AUTOLOAD\n";
}

# preambles

sub take_performance_hit {
    my $class = shift;
    $file     = shift;   # this one is global, sorry Damian

    build_backend_list();

    $class->read_file();

    # deparse the tree
    Bigtop::Parser->set_gen_mode( 0 );
    $tree      = Bigtop::Parser->parse_string( $class->input );
    $class->deparsed( Bigtop::Deparser->deparse( $tree ) );

    $class->update_backends( $tree );

    $statements = Bigtop::Parser->get_keyword_docs();
}

sub build_backend_list {

    %backends = (); # in testing we call this repeatedly

    my $filter = sub {
        my $module = $File::Find::name;
        return unless $module =~ /Bigtop.*Backend.*\.pm$/;

        $module =~ s{.*Bigtop.Backend}{Bigtop/Backend}; # could use look ahead

        require "$module";

        # Load in its what_do_you_make info
        my $package = $module;
        $package    =~ s{/}{::}g;
        $package    =~ s{.pm$}{};

        my ( undef, undef, $type, $name ) = split /::/, $package;

        if ( defined $name ) {

            if ( $package->can( 'what_do_you_make' ) ) {
                my $package_output = $package->what_do_you_make();
                $backends{ $type }{ $name }{ output } = $package_output;
            }

            if ( $package->can( 'backend_block_keywords' ) ) {
                my $block_keywords = $package->backend_block_keywords();
                $backends{ $type }{ $name }{ keywords } = $block_keywords;
            }

            $backends{ $type }{ $name }{ in_use     } = 0;
            $backends{ $type }{ $name }{ statements } = {};
        }
    };

    my @real_inc;
    foreach my $entry ( @INC ) {
        push @real_inc, $entry if ( -d $entry );
    }

    find( { wanted => $filter, chdir => 0 }, @real_inc );
}

sub init {
    my $self = shift;
    my $r    = shift;

    $self->SUPER::init( $r );

    $self->set_file( $self->fish_config( 'file' ) );
}

# for testing only, usually objects are constructed in the Gantry handler
sub new {
    my $class = shift;

    return bless {}, $class;
}

# initial end user page handler

sub do_main {
    my $self   = shift;

    if ( not defined $tree ) {
        $self->read_file();

        # deparse the tree
        Bigtop::Parser->set_gen_mode( 0 );
        $tree      = Bigtop::Parser->parse_string( $self->input );
        $self->deparsed( Bigtop::Deparser->deparse( $tree ) );

        $self->update_backends( $tree );
    }

    $self->stash->view->template( 'tenter.tt' );
    $self->stash->view->title( 'TentMaker Home' );
    $self->stash->view->data(
        {
            input                 => $self->deparsed,
            engine                => $tree->get_engine,
            template_engine       => $tree->get_template_engine,
            app                   => $tree->get_app,
            app_blocks            => $tree->get_app_blocks,
            backends              => \%backends,
            statements            => $statements,
            app_config_statements => compile_app_configs(),
            file_name             => $file,
        }
    );
}

sub compile_app_configs {
    my %app_config_statements = @{ $tree->get_app()->get_config() };
    my @app_config_statements;

    foreach my $config_statement ( sort keys %app_config_statements ) {
        my $arg = $app_config_statements{ $config_statement }->get_first_arg;

        my $no_accessor;
        my $value;

        if ( ref( $arg ) eq 'HASH' ) {
            ( $value, $no_accessor ) = %{ $arg };
            $no_accessor = ( $no_accessor eq 'no_accessor' ) ? 1 : 0;
        }
        else {
            ( $value, $no_accessor ) = ( $arg, 0 );
        }

        my $statement_hash = {
            keyword     => $config_statement,
            value       => $value,
            no_accessor => $no_accessor,
        };

        push @app_config_statements, $statement_hash;
    }

    return \@app_config_statements;
}

sub do_save {
    my $self          = shift;
    my $new_file_name = unescape( shift );

    if ( open my $BIGTOP_UPDATE, '>', $new_file_name ) {
        # XXX Assume it will work if we opened it (not always good, I know).
        print $BIGTOP_UPDATE $self->deparsed;
        close $BIGTOP_UPDATE;

        $self->template_disable( 1 );
        $self->stash->controller->data( "Saved $new_file_name" );
    }
    else {
        warn "Couldn't open file $new_file_name: $!\n";

        $self->template_disable( 1 );
        $self->stash->controller->data( "Couldn't write $new_file_name: $!" );
    }
}

# for use by all do_update_* methods
sub complete_update {
    my $self = shift;

    $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
    $self->update_backends( $tree );

    $self->template_disable( 1 );
    $self->stash->controller->data( $self->deparsed );
}

sub unescape {
    my $input = shift;

    return unless defined $input;

    $input    =~ s/\+/ /g;
    $input    =~ s/%([0-9a-fA-F]{2})/chr( hex( $1 ) )/ge;

    return $input;
}

# AJAX handlers MISC.

sub do_update_std {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    my $method    = "set_$parameter";

    eval {
        $tree->$method( $new_value );
    };
    if ( $@ ) {
        warn "error: $@\n";
        return;
    }

    $self->complete_update();
}

sub do_update_backend {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    if ( $parameter =~ /(.*)::(.*)/ ) {
        my ( $type, $backend ) = ( $1, $2 );

        if ( $new_value eq 'false' ) {
            drop_backend( $tree, $type, $backend );
        }
        else {
            add_backend(  $tree, $type, $backend );
        }
    }
    else {
        warn "error: mal-formed update_backend request\n";
        return;
    }

    $self->complete_update();
}

# AJAX hanlers for Bigtop config block

sub do_update_conf_text {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    if ( $parameter =~ /(.*)::(.*)::(.*)/ ) {
        my ( $type, $backend, $keyword ) = ( $1, $2, $3 );

        my $value = ( $new_value ) ? $new_value : 'undef';

        change_conf( $tree, $type, $backend, $keyword, $value );
    }
    else {
        warn "error: mal-formed update_conf_bool request\n";
        return;
    }

    $self->complete_update();
}

sub do_update_conf_bool {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    if ( $parameter =~ /(.*)::(.*)::(.*)/ ) {
        my ( $type, $backend, $keyword ) = ( $1, $2, $3 );

        my $value = ( $new_value eq 'false' ) ? 0 : 1;

        change_conf( $tree, $type, $backend, $keyword, $value );
    }
    else {
        warn "error: mal-formed update_conf_bool request\n";
        return;
    }

    $self->complete_update();
}

sub do_update_conf_bool_controlled {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );
    my $false     = shift;
    my $true      = shift;

    if ( $parameter =~ /(.*)::(.*)::(.*)/ ) {
        my ( $type, $backend, $keyword ) = ( $1, $2, $3 );

        my $value = ( $new_value eq 'false' ) ? $false : $true;

        change_conf( $tree, $type, $backend, $keyword, $value );
    }
    else {
        warn "error: mal-formed update_conf_bool_backward request\n";
        return;
    }

    $self->complete_update();
}

# AJAX handlers for Bigtop app block statements

sub do_update_app_statement_text {
    my $self      = shift;
    my $keyword   = shift;
    my $new_value = unescape( shift );

    $new_value    = 'undefined' unless defined $new_value;

    $new_value    =~ s/\s+\Z//m; # strip trailing whitespace from last line

    if ( $new_value ne 'undefined' ) {
        eval {
            $tree->get_app->set_app_statement( $keyword, $new_value );
        };
        if ( $@ ) {
            warn "error: $@\n";
            return;
        }
    }
    else {
        eval {
            $tree->get_app->remove_app_statement( $keyword );
        };
        if ( $@ ) {
            warn "error: $@\n";
            return;
        }
    }

    $self->complete_update();
}

sub do_update_app_statement_bool {
    my $self      = shift;
    my $keyword   = shift;
    my $new_value = unescape( shift );

    my $actual_value = ( $new_value eq 'false' ) ? 0 : 1;

    eval {
        $tree->get_app->set_app_statement( $keyword, $actual_value );
    };
    if ( $@ ) {
        warn "error: $@\n";
    }

    $self->complete_update();
}

sub do_update_app_statement_pair {
    my $self      = shift;
    my $keyword   = shift;
    my %params    = $self->get_param_hash();

    if ( defined $params{keys} and $params{keys} ) {
        eval {
            $tree->get_app->set_app_statement_pairs(
                {
                    keyword   => $keyword,
                    new_value => \%params,
                }
            );
        };
        if ( $@ ) {
            warn "error: $@\n";
        }
    }
    else {
        eval {
            $tree->get_app->remove_app_statement( $keyword );
        };
        if ( $@ ) {
            warn "error: $@\n";
        }
    }

    return $self->complete_update();
}

# AJAX handlers for managing app level blocks (including literals)

sub do_create_app_block {
    my $self           = shift;
    my $new_block_name = shift;
    my $block_type     = shift || 'stub';

    my $new_block;

    if ( $new_block_name =~ /(.*?)::(.*)/ ) {
        my ( $type, $name ) = ( $1, $2 );

        $new_block = $tree->create_block( $type, $name, $block_type );
    }
    else {
        warn "error: mal-formed create_app_block request\n";
        return;
    }

    # now fill in the new app_body element
    my $block_hashes = $new_block->walk_postorder( 'app_block_hashes' );

    $self->stash->view->template( 'new_app_body_div.tt' );
    $self->stash->view->data(
        {
            block      => $block_hashes->[0],
            statements => $statements,
        }
    );

    delete $self->{__TEMPLATE_WRAPPER__}; # just in case
    my $new_div = '';
    eval {
        $new_div = $self->do_process( ) || '';
    };
    if ( $@ ) {
        warn "error: $@\n";
    }

    $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
    $self->update_backends( $tree );

    $self->template_disable( 1 );

    $self->stash->controller->data( $new_div . $self->deparsed );
}

sub do_delete_block {
    my $self         = shift;
    my $doomed_ident = shift;

    eval {
        $tree->delete_block( $doomed_ident );
    };
    if ( $@ ) {
        warn "Error: $@\n";
    }

    $self->complete_update();
}

sub do_move_block_after {
    my $self  = shift;
    my $mover = shift;
    my $pivot = shift;

    $tree->move_block( { mover => $mover, pivot => $pivot, after => 1 } );

    $self->complete_update();
}

# log_warn is for use during testing with Test::Warn::warns_ok which eats
# all output on STDERR.
#sub log_warn {
#    open my $LOG, '>>', 'warn.log' or die "Couldn't write warn.log: $!\n";
#
#    print $LOG @_;
#
#    close $LOG;
#}

sub do_create_subblock {
    my $self           = shift;
    my $new_block_name = shift;
    my $block_type     = shift || 'stub';

    my $new_block;

    my ( $parent_type, $parent_ident, $type, $name );
    if ( $new_block_name =~ /(.*)::(.*)::(.*)::(.*)/ ) {
        ( $parent_type, $parent_ident, $type, $name ) = ( $1, $2, $3, $4 );

        eval {
            $new_block = $tree->create_subblock(
                {
                    parent    => {
                        type => $parent_type, ident => $parent_ident
                    },
                    new_child => {
                        type     => $type,
                        name     => $name,
                        sub_type => $block_type,
                    },
                }
            );
        };
        if ( $@ ) {
            warn "Error creating subblock: $@\n";
            return;
        }
    }
    else {
        warn "error: mal-formed create_field_block request\n";
        return;
    }

    my $field_hashes = $new_block->walk_postorder( 'app_block_hashes' );

    my $template     = ( $type eq 'field' )
                     ? 'new_field_div.tt'
                     : 'new_method_div.tt';

    $self->stash->view->template( $template );
    $self->stash->view->data(
        {
            item       => $field_hashes->[0],
            block      => { ident => $parent_ident },
            statements => $statements,
        }
    );

    delete $self->{__TEMPLATE_WRAPPER__}; # just in case
    my $new_div;
    eval {
        $new_div = $self->do_process( );
    };
    if ( $@ ) {
        warn "error: $@\n";
        return;
    }

    $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
    $self->update_backends( $tree );

    $self->template_disable( 1 );

    $self->stash->controller->data( $new_div . $self->deparsed );
}

sub do_update_statement {
    my $self      = shift;
    my $type      = shift;
    my $ancestors = shift;
    my $keyword   = shift;
    my $new_value = unescape( shift );

    eval {
        if ( not defined $new_value
                    or
             $new_value eq 'undef'
                    or
             $new_value eq 'undefined'
        ) {
            $tree->remove_statement(
                {
                    type    => $type,
                    ident   => $ancestors,
                    keyword => $keyword,
                }
            );
        }
        else {
            $tree->change_statement(
                {
                    type      => $type,
                    ident     => $ancestors,
                    keyword   => $keyword,
                    new_value => $new_value,
                }
            );
        }
    };
    if ( $@ ) {
        warn "Error changing statement: $@\n";
    }

    $self->complete_update();
}

sub do_update_block_statement_text {
    my $self      = shift;
    my $type      = shift;
    my $parameter = shift;
    my $new_value = shift;

    if ( $parameter =~ /(.*)::(.*)/ ) {
        my ( $ident, $keyword ) = ( $1, $2 );

        return $self->do_update_statement(
            $type, $ident, $keyword, $new_value
        );
    }
    else {
        warn "error: mal-formed update_block_statement_text request\n";
        return;
    }
}

sub do_update_subblock_statement_text {
    my $self      = shift;
    my $type      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    if ( $parameter =~ /(.*)::(.*)/ ) {
        my ( $parent, $keyword ) = ( $1, $2 );

        return $self->do_update_statement(
            $type, $parent, $keyword, $new_value
        );
    }
    else {
        warn "error: mal-formed update_subblock_statement_text request\n";
        return;
    }

    $self->complete_update();
}

    # This one takes its args from the query string.
sub do_update_subblock_statement_pair {
    my $self      = shift;
    my $type      = shift;
    my $parameter = shift;
    my %params    = $self->get_param_hash();

    if ( $parameter =~ /(.*)::(.*)/ ) {
        my ( $ident, $statement ) = ( $1, $2 );

        eval {
            if ( $params{ keys } ) {
                $tree->change_statement(
                    {
                        type      => $type,
                        ident     => $ident,
                        keyword   => $statement,
                        new_value => \%params,
                    }
                );
            }
            else {
                $tree->remove_statement(
                    {
                        type    => $type,
                        ident   => $ident,
                        keyword => $statement,
                    }
                );
            }
        };
        if ( $@ ) {
            warn "Error changing paired statement: $@\n";
        }
    }
    else {
        warn "error: mal-formed do_update_*_statement_pair request\n";
        return;
    }

    $self->complete_update();
}
# AJAX handlers for table blocks (inside the app block)

sub do_update_table_statement_text {
    my $self = shift;

    $self->do_update_block_statement_text( 'table', @_ );
}

sub do_update_name {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    if ( my ( $type, $ident ) = split /::/, $parameter ) {

        eval {
            if ( $new_value eq 'undef' or $new_value eq 'undefined' ) {
                warn 'Error: To delete an item use its Delete button, '
                        .   "don't blank the name.\n";
            }
            else {
                $tree->change_name(
                    {
                        ident        => $ident,
                        type         => $type,
                        new_value    => $new_value,
                    }
                );
            }
        };
        if ( $@ ) {
            warn "Error changing statement: $@\n";
        }
    }
    else {
        warn "error: mal-formed update_table_statement_text request\n";
        return;
    }

    $self->complete_update();
}

sub do_update_field_statement_bool {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    my ( $real_value ) = ( $new_value eq 'true' ) ? 1 : 0;

    return $self->do_update_subblock_statement_text(
        'field', $parameter, $real_value
    );
}

sub do_update_field_statement_text {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    return $self->do_update_subblock_statement_text(
        'field', $parameter, $new_value
    );
}

    # This one takes its args from the query string.
sub do_update_field_statement_pair {
    my $self = shift;
    return $self->do_update_subblock_statement_pair( 'field', @_ )
}

# AJAX handlers for controller blocks (inside the app block)

sub do_update_controller_statement_text {
    my $self = shift;

    $self->do_update_block_statement_text( 'controller', @_ );
}

sub do_update_controller_statement_bool {
    my $self      = shift;
    my $parameter = shift;
    my $value     = shift;
    my $extra     = shift;

    $value = ( $value eq 'true' ) ? 1 : 0;

    return $self->do_update_block_statement_text(
        'controller',
        $parameter,
        $value,
        $extra,
    );
}

sub do_update_method_statement_text {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    return $self->do_update_subblock_statement_text(
        'method',
        $parameter,
        $new_value,
    );
}

sub do_update_method_statement_bool {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    $new_value = ( $new_value eq 'true' ) ? 1 : 0;

    return $self->do_update_subblock_statement_text(
        'method',
        $parameter,
        $new_value,
    );
}

    # This one takes its args from the query string.
sub do_update_method_statement_pair {
    my $self = shift;
    return $self->do_update_subblock_statement_pair( 'method', @_ )
}

sub do_type_change {
    my $self       = shift;
    my $ident      = shift;
    my $new_type   = shift;

    eval {
        $tree->type_change(
            {
                ident    => $ident,
                new_type => $new_type,
            }
        );
    };
    if ( $@ ) {
        warn "Error in type_change: $@\n";
    }

    $self->complete_update();
}

sub do_update_literal {
    my $self      = shift;
    my $ident     = shift;
    my $new_value = unescape( shift );

    eval {
        $tree->walk_postorder(
            'change_literal', { ident => $ident, new_value => $new_value }
        );
    };
    if ( $@ ) {
        warn "Error in literal change:$@\n";
    }

    $self->complete_update();
}

# AJAX handlers for the config block inside the app block

sub do_update_app_conf_statement {
    my $self    = shift;
    my $keyword = shift;
    my $value   = unescape( shift );
    my $checked = shift;

    if ( $value eq 'undefined' or $value eq 'undef' ) {
        $value = '';
    }

    if ( defined $checked ) {
        $checked = ( $checked eq 'undefined' ) ? undef :
                   ( $checked eq 'false'     ) ? 0     : 1;
    }

    $tree->get_app->set_config_statement( $keyword, $value, $checked );

    $self->complete_update();
}

sub do_update_app_conf_accessor {
    my $self    = shift;
    my $keyword = shift;
    my $value   = unescape( shift );

    my $actual_value = ( $value eq 'false' ) ? 0 : 1;

    $tree->get_app->set_config_statement_status( $keyword, $actual_value );

    $self->complete_update();
}

sub do_delete_app_config {
    my $self    = shift;
    my $keyword = shift;

    $tree->get_app->delete_config_statement( $keyword );

    $self->complete_update();
}

# AJAX handler helpers

sub change_conf {
    my $tree      = shift;
    my $type      = shift;
    my $backend   = shift;
    my $keyword   = shift;
    my $value     = shift;
    my $config    = $tree->get_config();

    STATEMENT:
    for( my $i = 0; $i <= $#{ @{ $config->{__STATEMENTS__} } }; $i++ ) {
        next STATEMENT unless (
                ref( $config->{__STATEMENTS__}[$i][1] ) eq 'HASH'
        );  # find backends, skip simple statements

        if ( $config->{__STATEMENTS__}[$i][0] eq $type
                    and
            $config->{__STATEMENTS__}[$i][1]{__NAME__} eq $backend
        ) {
            if ( $value eq 'undef' or $value eq 'undefined' ) {
                delete $config->{__STATEMENTS__}[$i][1]{ $keyword };
            }
            else {
                $config->{__STATEMENTS__}[$i][1]{ $keyword } = $value;
            }
            last STATEMENT;
        }
    }
}

sub drop_backend {
    my $tree      = shift;
    my $type      = shift;
    my $backend   = shift;
    my $config    = $tree->get_config();

    # remove the item from the __STATEMENTS__ list
    my $doomed_element = -1;

    STATEMENT:
    for( my $i = 0; $i <= $#{ @{ $config->{__STATEMENTS__} } }; $i++ ) {

        next STATEMENT unless (
                ref( $config->{__STATEMENTS__}[$i][1] ) eq 'HASH'
        );  # find backends, skip simple statements

        if ( $config->{__STATEMENTS__}[$i][0] eq $type
                    and
            $config->{__STATEMENTS__}[$i][1]{__NAME__} eq $backend
        ) {
                $doomed_element = $i;
                last STATEMENT;
        }
    }
    if ( $doomed_element >= 0 ) {
        splice @{ $config->{__STATEMENTS__} }, $doomed_element, 1;
    }
}

sub add_backend {
    my $tree      = shift;
    my $type      = shift;
    my $backend   = shift;
    my $config    = $tree->get_config();

    if ( $type eq 'Init' ) { # put it at the top
        unshift @{ $config->{__STATEMENTS__} },
                [ 'Init', { __NAME__ => $backend } ];
    }
    else {
        push @{ $config->{__STATEMENTS__} },
             [ $type, { __NAME__ => $backend } ];
    }

    $config->{ $type } = { __NAME__ => $backend };
}

sub update_backends {
    my $self   = shift;
    my $tree   = shift;
    my $config = $tree->get_config();

    # remove old values
    foreach my $type ( keys %backends ) {
        foreach my $backend ( keys %{ $backends{ $type } } ) {
            $backends{ $type }{ $backend }{ in_use     } = 0;
            $backends{ $type }{ $backend }{ statements } = {};
        }
    }

    # set current values
    CONFIG_ITEM:
    foreach my $block ( @{ $config->{__STATEMENTS__} } ) {

        my ( $type, $backend ) = @{ $block };

        next CONFIG_ITEM unless ( ref( $backend ) eq 'HASH' ); # blocks only

        my $name       = $backend->{__NAME__};
        my $statements = _get_backend_block_statements( $backend );

        $backends{ $type }{ $name }{ in_use     } = 1;
        $backends{ $type }{ $name }{ statements } = $statements;
    }
}

sub _get_backend_block_statements {
    my $backend = shift;

    my %retval;

    STATEMENT:
    foreach my $statement ( keys %{ $backend } ) {
        next STATEMENT if $statement eq '__NAME__';

        $retval{ $statement } = [ $backend->{ $statement } ];
    }

    return \%retval;
}

# Accessors and global helpers

sub read_file {
    my $self = shift;

    my $BIGTOP_FILE;
    my $file_name = $self->get_file;

    my $retval;

    if ( $file_name ) {
        unless ( open $BIGTOP_FILE, '<', $file_name ) {
            warn 'Couldn\'t read ' . $file_name . "\n";

            return '';
        }

        $retval = join '', <$BIGTOP_FILE>;

        close $BIGTOP_FILE;
    }
    else {
        $retval = join '', <DATA>;
    }

    $self->input( $retval );

    return $retval;
}

sub set_file {
    my $self     = shift;
    my $new_file = shift;

    if ( not defined $file or defined $new_file and $new_file ne $file ) {
        $file = $new_file;
        undef $input;
        undef $tree;
    }
}

sub get_file {
    my $self = shift;

    return $file;
}

sub get_tree {
    return $tree;
}

sub input {
    my $self      = shift;
    my $new_input = shift;

    if ( defined $new_input ) {
        $input = $new_input;
    }

    return $input
}

sub deparsed {
    my $self     = shift;
    my $deparsed = shift;

    if ( defined $deparsed ) {
        $input = $deparsed;
    }

    return $input
}

1;

=head1 NAME

Bigtop::TentMaker - A Gantry App to Help You Code Bigtop Files

=head1 SYNOPSIS

Start the tentmaker:

    tentmaker [ --port=8192 ] [ file ]

Point your browser to the address it prints.

=head1 DESCRIPTION

Bigtop is a language for describing web applications.  The Bigtop language
is fairly complete, in that it lets you describe complex apps,
but that means it is not so small.  This module (and the tentmaker
script which drives it) helps you get the syntax right through your
browser.

=head1 HANDLERS

There are three types of methods in this module: handlers called by browser
action, methods called by the driving script during launch, and methods
which help the others.  This section discusses the handlers.  See below
for details on the other types.

=head2 do_main

This is the main handler users hit to initially load the page.  It sends
them the tenter.tt template populated with data from the file given on
the command line.  If no file is given, it gives them an empty stub [not
yet implemented].

Expects: nothing

The remaining handlers are all AJAX handlers.  They are triggered by GUI
user events and send back a plain text representation of the updated
abstract syntax tree being edited.  Eventually a method will allow the
user to save that output back to the disk, but it's not here yet.

Each routine is given a parameter (think keyword) and a new value.
Some of them also receive additional data, see below.

=head2 do_update_std

The parameter is the suffix of the name of a method the tree responds to.
The full name is "set_$parameter" (see Bigtop::Parser for details of
these methods, if I ever get around to writing about them).  

The new_value is merely passed to the set_ method, which is responsible
for updating the tree properly.  Errors are trapped.

=head2 do_update_backend

While this is probably not wise, the parameter has the form 'type::backend'
referring to a module in the Bigtop::Backend:: namespace.  The
new value is a string (repeat: it is a string).  If the string eq 'false',
the backend is dropped from the config block of the file.  Otherwise,
it is added to the list.

When a config is dropped, all of the statements in its config block are
LOST.  This creates a disappointing end user reality.  If you uncheck
a backend box by mistake, after you recheck it, you must go focus and
defocus on all text backend statements and check and uncheck all checkboxes.
This is bad.

=head2 do_update_conf_bool

Again, the parameter form is bad: 'type::backend::keyword'.  If needed,
this creates the keyword as a statement in the backend's config block.
In any case, it sets the value to the new value passed in (except that
it converts 'false' to 0 and anything else to 1).

It uses change_conf to do the actual work.

=head2 do_update_conf_bool_controlled

This is just like do_update_conf_bool, but accepts two additional url
parameters.  These are the values for false and true, in that order.

If the new value eq 'false', the false value is assigned, otherwise
the true value is used.  This facilitates statements like the Init::Std
'Changes no_gen'.

If one of the values is the string 'undefined' the statement will be
deleted from the backend.

=head2 do_update_conf_text

This is like do_update_conf_bool, except that the new value is used
as the statement value.  If the value is false, the statement is
removed from the backend's config block.

=head2 do_update_app_statement

If the new value eq 'undefined' the statement is removed from the app
block.  Otherwise the statement has its value changed to the new value
(the statement is created if needed).  Mulitple values should be
separated by a comma and a space (yes this prevents Kip Worthington, III.
from couting as an author name).

=head1 LAUNCH METHODS

=head2 take_performance_hit

This method allows the server to take the hit of compiling Bigtop::Parser
and initially parsing the input file with it, before declaring that the
server is up and available.  I no longer think this is a good idea,
but for now it is reality.

It builds a list of all the backends available on the system (by walking
@INC looking for things in the Bigtop::Backend:: namespace).  It also
reads the file given to it and parses that into a bigtop AST.  Then
it deparses that to produce the initial presented in the browser.
Think of this as canonicallizing the input file for presentation.  Finally,
it builds the statements hash, filling it with docs from all the
keywords that all of the backends register.

This method takes at least 5 seconds, even though I haven't profiled it,
I believe most of that is spent compiling the grammar.  Subsequent operations
on the tree are subsecond.

=head2 build_backend_list

The backends hash is used internally to know which backends are available,
whether they are in use, and what statements they support.

=head2 read_file

Guess what this does.  Eventually there will be a way to avoid this step,
but for now only file input is acceptable.

=head1 HELPER METHODS

=head2 init

This is a gantry init method.  It fishes the file name from the site object.

=head2 compile_app_configs

Builds an array whose elements are hashes describing each config statement
in the app level config block.

=head2 complete_update

Used by all AJAX handlers to deparse the updated tree and return it to the
client.

=head2 unescape

Typical routine to turn %.. into a proper character.

=head2 change_conf

Used by all the do_update_conf_* methods to actually change the config
portion of the AST.

=head2 drop_backend

Used by do_update_backend to remove a backend from the AST.

=head2 add_backend

Used by do_update_backend to add a backend from the AST.

=head2 update_backends

Keeps the backends hash up to date.

=head2 _get_backend_block_statements

Helps update_backends.

=head2 file

Accessor to get/set the name of the input file.  Setting it blows the
cache of other accessible values.

=head2 input

Accessor to get/set the input file text in memory.

=head2 deparsed

Accessor to get/set the deparsed (canonicalized) text of the file.

=head1 AUTHOR

Phil Crow, E<lt>philcrow2000@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
config {
    engine          CGI;
    template_engine TT;
    Init Std {}
    CGI Gantry { with_server 1; }
    Control Gantry {}
    SQL Postgres {}
    Model GantryCDBI {}
    SiteLook GantryDefault { gantry_wrapper `/home/athor/srcgantry/root/sample_wrapper.tt`; }
}
app Sample {
    config {
        dbconn `dbi:Pg:dbname=sample` => no_accessor;
        dbuser apache => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        root `/home/athor/bigtop/html:/home/athor/srcgantry/root` => no_accessor;
    }
    authors `A. U. Thor` => `author@example.com`;
}
