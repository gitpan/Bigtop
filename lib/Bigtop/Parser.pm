package Bigtop::Parser;
use strict; use warnings;

use File::Find;
use File::Spec;
use Data::Dumper;
use Carp;

use Bigtop::Grammar;
use Bigtop::Keywords;

# $::RD_TRACE = 1;
# $::RD_HINT = 1;

my $ident_counter = 0;
my $parser;
my %valid_keywords;
my %keyword_for;

#---------------------------------------------------------------------
#   Methods which add and validate keywords in the grammar
#---------------------------------------------------------------------

sub add_valid_keywords {
    my $class    = shift;
    my $type     = shift;
    my $caller   = caller( 0 );

    my %callers;

    KEYWORD:
    foreach my $statement ( @_ ) {
        my $keyword = $statement->{keyword};

        my $seen_it = $valid_keywords{ $type }{ $keyword };

        $valid_keywords{ $type }{ $keyword }++;

        next KEYWORD if ( defined $statement->{type}
                            and   $statement->{type} eq 'deprecated' );

        push @{ $keyword_for{ $type }{ $keyword }{ callers } }, $caller;

        next KEYWORD if $seen_it;

        push @{ $keyword_for{ $type }{ statements } }, $statement;
    }
}

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'config',
            qw( engine template_engine base_dir app_dir )
        )
    );

    # register no_gen as a keyword for (almost) all block types
    # sequence and table are not included since SQL happens all at once
    foreach my $keyword_type qw( app controller method ) {
        Bigtop::Parser->add_valid_keywords(
            Bigtop::Keywords->get_docs_for(
                $keyword_type,
                'no_gen',
            )
        );
    }

    # to allow a table to be described, but to be omitted from either
    # a Model or SQL output

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for( 'table', 'not_for' )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for( 'field', 'not_for' )
    );
}

sub is_valid_keyword {
    my $class   = shift;
    my $type    = shift;
    my $keyword = shift;

    return $valid_keywords{$type}{$keyword};
}

sub get_valid_keywords {
    my $class = shift;
    my $type  = shift;

    my %trailer_for = (
        config     => 'or a valid backend block',
        app        => 'or a valid block (controller, sequence, ' .
                                        'config, or table)',
        controller => 'or a valid method block',
        table      => 'or a valid field block',
    );

    my %extras_for = (
        app => [ 'literal' ],
    );

    my @extra_expected = @{ $extras_for{ $type } }
            if ( defined $extras_for{ $type } );

    my $trailer  = $trailer_for{ $type };

    my @expected = sort @extra_expected, keys %{ $valid_keywords{ $type } };
    push( @expected, $trailer ) if $trailer;

    return @expected;
}

sub get_keyword_docs {
    return \%keyword_for;
}

#---------------------------------------------------------------------
#   The ident factory
#---------------------------------------------------------------------

sub get_ident {
    $ident_counter++;

    return "ident_$ident_counter";
}

#---------------------------------------------------------------------
#   The import method
#---------------------------------------------------------------------

sub import {
    my $class   = shift;
    my @modules = @_;

    foreach my $module ( @modules ) {
        my ( $type, $name, $template ) = split /=/, $module;

        # build full path to module and require it
        my $module_file = File::Spec->catfile(
            'Bigtop', 'Backend', $type, "$name.pm"
        );
        require $module_file;

        my $package = 'Bigtop::Backend::' . $type . '::' . $name;

        # allow caller to fill in a template file
        if ( $class->gen_mode && $package->can( 'setup_template' ) ) {
            $package->setup_template( $template );
        }
    }
}

my $gen_mode = 1;
sub gen_mode {
    my $class = shift;

    return $gen_mode;
}

sub set_gen_mode {
    my $class = shift;
    my $value = shift;

    $gen_mode = $value;

    return $gen_mode;
}

#---------------------------------------------------------------------
#   Methods which handle errors
#---------------------------------------------------------------------

sub fatal_keyword_error {
    my $class                = shift;
    my $bad_keyword          = shift;
    my $diag_text            = shift;
    my $bigtop_input_linenum = shift;
    my @expected             = @_;

    $diag_text               =~ s/\n.*//sg;  # trim to one line

    my $expected             = join ', ', @expected;

    die "Error: invalid keyword '$bad_keyword' (line $bigtop_input_linenum) "           . "near:\n"
        . "$diag_text\n"
        . "I was expecting one of these: $expected.\n";
}

sub fatal_error_two_lines {
    my $class                = shift;
    my $message              = shift;
    my $diag_text            = shift;
    my $bigtop_input_linenum = shift;

    $diag_text               = substr $diag_text, 0, 65;

    die "Error: $message\n    "
        . "on line $bigtop_input_linenum near:\n$diag_text\n";
}

#---------------------------------------------------------------------
#   The grammar has been moved to the generated Bigtop::Grammar
#---------------------------------------------------------------------

#---------------------------------------------------------------------
#   The preprocessor (comment stripper)
#---------------------------------------------------------------------
#
# A comment is a line where the first non-whitespace char is #
#
sub preprocess {
    $_[0] =~ s/^\s*#.*//mg;
}

#---------------------------------------------------------------------
#   Methods which parse input
#---------------------------------------------------------------------

sub get_parser {
    $parser = Bigtop::Grammar->new() if ( not defined $parser );

    return $parser;
}

# This is the method that bigtop uses.
sub gen_from_file {
    my $class       = shift;
    my $bigtop_file = shift;
    my $create      = shift;
    my @gen_list    = shift;

    my $BIGTOP_FILE;
    open ( $BIGTOP_FILE, '<', $bigtop_file )
            or die "Couldn't read bigtop file $bigtop_file: $!\n";

    my $bigtop_string = join '', <$BIGTOP_FILE>;

    close $BIGTOP_FILE;

    $class->gen_from_string(
        $bigtop_string, $bigtop_file, $create, @gen_list
    );
}

# This is the method that gen_from_file uses.
sub gen_from_string {
    my $class         = shift;
    my $bigtop_string = shift;
    my $bigtop_file   = shift;
    my $create        = shift;
    my @args          = @_;

    # strip comments
    preprocess( $bigtop_string );

    my $config        = $class->parse_config_string( $bigtop_string );

    my $build_types   = $class->load_backends( $bigtop_string, $config );

    # build the whole parse tree
    my $bigtop_tree   = $class->parse_string( $bigtop_string );

    # check to see if an app wide no_gen is in effect
    my $lookup = $bigtop_tree->{application}{lookup};

    if ( defined $lookup->{app_statements}{no_gen}
            and
        $lookup->{app_statements}{no_gen}
    ) {
        warn "Warning: app level is marked no_gen, skipping generation\n";
        return;
    }

    # make the build directory (if needed)
    my $build_dir = _build_app_home_dir( $bigtop_tree, $create );

    # make sure we are in the right place
    _validate_build_dir( $build_dir, $bigtop_tree, $create );

    # replace all with a list of all available backends
    my @gen_list;
    foreach my $gen_type ( @args ) {
        if ( $gen_type eq 'all' ) { push @gen_list, @{ $build_types}; }
        else                      { push @gen_list, $gen_type;        }
    }

    # generate the files
    GENERATION:
    foreach my $gen_type ( @gen_list ) {

        if ( defined $config->{$gen_type}{no_gen}
                and
             $config->{$gen_type}{no_gen} )
        {
            next GENERATION;
        }

        my $module = join '::', (
            'Bigtop', 'Backend', $gen_type, $config->{$gen_type}{__NAME__} );
        my $method = "gen_$gen_type";
                $module->$method( $build_dir, $bigtop_tree, $bigtop_file
        );
    }
}

sub load_backends {
    my $class         = shift;
    my $bigtop_string = shift;
    my $config        = shift;

    # import the moudles mentioned in the config

    my @modules_to_require;
    my @build_types;

    CONFIG_KEY:
    foreach my $key ( keys %{ $config } ) {
        next CONFIG_KEY if ( $class->is_valid_keyword( 'config', $key ) );
        next CONFIG_KEY if ( $key eq '__STATEMENTS__' );

        my $backend  = $config->{$key}{__NAME__};
        my $template = $config->{$key}{template} || '';

        my $module_str = join '=', $key, $backend, $template;

        push @modules_to_require, $module_str;
        push @build_types, $key;
    }

    $class->import( @modules_to_require );

    return \@build_types;
}

sub _build_app_home_dir {
    my $tree     = shift;
    my $create   = shift;
    my $config   = $tree->get_config();

    my $base_dir = '.';
    
    if ( $create ) {
        $base_dir = $config->{base_dir} if defined $config->{base_dir};
    }
    elsif ( defined $config->{base_dir} ) {
        warn "Warning: config's base_dir ignored, "
                . "because we're not in create mode\n";
    }

    # make sure base_dir exists
    die "You must make the base directory $base_dir\n" unless ( -d $base_dir );

    # get app name and make a directory of it
    my $build_dir = _form_build_dir( $base_dir, $tree, $config, $create );

    if ( $create ) {
        mkdir $build_dir;

        die "couldn't make directory $build_dir\n" unless ( -d $base_dir );
    }
    else {
        die "$build_dir is not a directory, perhaps you need to use --create\n"
                unless ( -d $base_dir );
    }

    $tree->{configuration}{build_dir} = $build_dir;

    return $build_dir;
}

sub _form_build_dir {
    my $base_dir = shift;
    my $tree     = shift;
    my $config   = shift;
    my $create   = shift;

    my $app_dir  = '';
    if ( $create ) {
        if ( defined $config->{app_dir} ) {
            $app_dir = $config->{app_dir};
        }
        else {
            $app_dir = $tree->get_appname();
            $app_dir    =~ s/::/-/g;
        }
    }
    else {
        if ( defined $config->{app_dir} ) {
            warn "config's app_dir ignored, because we're not in create mode\n";
        }
    }

    return File::Spec->catdir( $base_dir, $app_dir );
}

sub _validate_build_dir {
    my $build_dir  = shift;
    my $tree       = shift;
    my $create     = shift;

    my $warning_signs = 0;
    if ( -d $build_dir ) {
        unless ( $create ) {
            # see if there are familiar surroundings in the build_dir
            my $buildpl = File::Spec->catfile( $build_dir, 'Build.PL' );
            my $changes = File::Spec->catfile( $build_dir, 'Changes'  );
            my $t       = File::Spec->catdir(  $build_dir, 't'        );
            my $lib     = File::Spec->catdir(  $build_dir, 'lib'      );

            $warning_signs++ unless ( -f $buildpl );
            $warning_signs++ unless ( -f $changes );
            $warning_signs++ unless ( -d $t       );
            $warning_signs++ unless ( -d $lib     );

            # dig deep for the main module
            my $app_name   = $tree->get_appname();
            my @mod_pieces = split /::/, $app_name;
            my $main_mod   = pop @mod_pieces;
            $main_mod      .= '.pm';

            my $saw_base   = 0;
            my $wanted     = sub {
                $saw_base++ if ( $_ eq $main_mod );
            };

            find( $wanted, $build_dir );

            $warning_signs++ unless ( $saw_base );
        }
    }
    else {
        die "$build_dir does not exist, and I couldn't make it.\n";
    }

    if ( $warning_signs > 2 ) {
        my $base_dir          = $tree->{configuration}{base_dir} || '.';
        my $config_build_dir  = $base_dir;
        if ( $tree->{configuration}{app_dir} ) {
            $config_build_dir = File::Spec->catdir(
                $base_dir, $tree->{configuration}{app_dir}
            );
        }
        die "$build_dir doesn't look like a build dir (level=$warning_signs),\n"
          . "  use --create to force a build in or under $config_build_dir\n";
    }
}

sub parse_config_string {
    my $class  = shift;
    my $string = shift
        or croak "usage: Bigtop::Parser->parse_config_string(bigtop_string)";

    preprocess( $string );

    my $retval = $class->get_parser->config_only( $string );

    unless ( $retval ) {
        die "Couldn't parse config in your bigtop input.\n";
    }

    return $retval;
}

sub parse_string {
    my $class  = shift;
    my $string = shift
        or croak "usage: Bigtop::Parser->parse_string(bigtop_string)";

    preprocess( $string );

    my $build_types   = $class->load_backends(
            $string,
            $class->parse_config_string( $string )
    );

    my $retval = $class->get_parser->bigtop_file( $string );

    unless ( $retval ) {
        die "Couldn't parse your bigtop input.\n";
    }

    return $retval;
}

sub parse_file {
    my $class       = shift;
    my $bigtop_file = shift
        or croak "usage: BigtoP::Parser->parse_file(bigtop_file)";

    open my $BIGTOP_INPUT, "<", $bigtop_file
        or croak "Couldn't open $bigtop_file: $!\n";

    my $data = join '', <$BIGTOP_INPUT>;

    close $BIGTOP_INPUT;

    return $class->parse_string( $data );
}

#---------------------------------------------------------------------
#   Packages for each node type.  These can walk_postorder.
#   Start with $your_tree->walk_postorder( 'action', $data_object ).
#
#   Most of these have a useful dumpme which trims the Data::Dumper
#   output.  The closer you are to the bottom of the tree, the
#   better it looks relative to a regular dump.
#---------------------------------------------------------------------

package application_ancestor;
use strict; use warnings;

sub set_parent {
	my $self   = shift;
	my $output = shift;
	my $data   = shift;
	my $parent = shift;

	$self->{__PARENT__} = $parent;

    return;
}

sub dumpme {
    my $self = shift;

    my $parent = delete $self->{__PARENT__};

    use Data::Dumper; warn Dumper( $self );

    $self->{__PARENT__} = $parent;
}

package bigtop_file;
use strict; use warnings;

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;

    return $self->{application}->walk_postorder( $action, $data );
}

sub get_config {
    my $tree = shift;

    return $tree->{configuration};
}

sub get_app {
    my $tree = shift;

    return $tree->{application};
}

sub get_app_blocks {
    my $tree = shift;

    return $tree->get_app()->get_blocks();
}

sub get_appname {
    my $tree = shift;

    return $tree->get_app()->get_name();
}

sub set_appname {
    my $tree     = shift;
    my $new_name = shift;

    $tree->{application}->set_name( $new_name );
}

sub get_engine {
    my $tree = shift;

    return $tree->{configuration}{engine};
}

sub set_engine {
    my $tree       = shift;
    my $new_engine = shift;

    my $config = $tree->{configuration};

    # change it in the quick lookup hash...
    $config->{engine} = $new_engine;

    # ... and in the __STATEMENTS__ list
    my $we_changed_engines = 0;
    STATEMENT:
    foreach my $statement ( @{ $config->{__STATEMENTS__} } ) {
        my ( $keyword, $value ) = @{ $statement };
        if ( $keyword eq 'engine' ) {
            $statement->[1] = $new_engine;
            $we_changed_engines++;
            last STATEMENT;
        }
    }

    # add the statement at the top if it wasn't already there
    unless ( $we_changed_engines ) {
        unshift @{ $config->{__STATEMENTS__} }, [ 'engine', $new_engine ];
    }
}

sub get_template_engine {
    my $tree = shift;

    return $tree->{configuration}{template_engine};
}

sub set_template_engine {
    my $tree       = shift;
    my $new_engine = shift;

    my $config = $tree->{configuration};

    # change it in the quick lookup hash...
    $config->{template_engine} = $new_engine;

    # ... and in the __STATEMENTS__ list
    my $we_changed_engines = 0;
    STATEMENT:
    foreach my $statement ( @{ $config->{__STATEMENTS__} } ) {
        my ( $keyword, $value ) = @{ $statement };
        if ( $keyword eq 'template_engine' ) {
            $statement->[1] = $new_engine;
            $we_changed_engines++;
            last STATEMENT;
        }
    }

    # add the statement at the top if it wasn't already there
    unless ( $we_changed_engines ) {
        unshift @{ $config->{__STATEMENTS__} },
                [ 'template_engine', $new_engine ];
    }
}

sub change_statement {
    my $self   = shift;
    my $params = shift;

    my $walk_action = "change_$params->{ type }_statement";
    my $result      = $self->walk_postorder( $walk_action, $params );

    if ( @{ $result } == 0 ) {
        die "Couldn't change $params->{type} statement "
            .   "'$params->{keyword}' for '$params->{ident}'\n";
    }
}

sub remove_statement {
    my $self   = shift;
    my $params = shift;

    my $walk_action = "remove_$params->{ type }_statement";
    my $result      = $self->walk_postorder( $walk_action, $params );

    if ( @{ $result } == 0 ) {
        warn "Couldn't remove statement: couldn't find it\n";
        require Data::Dumper;
        Data::Dumper->import( 'Dumper' );
        warn Dumper( $params );
    }
}

sub change_name {
    my $self   = shift;
    my $params = shift;

    my $method            = "change_name_$params->{type}";

    $self->walk_postorder( $method, $params );
}

sub create_block {
    my $self     = shift;
    my $type     = shift;
    my $name     = shift;
    my $subtype  = shift;

    my $result   = $self->walk_postorder(
            'add_block', { type => $type, name => $name, subtype => $subtype }
    );

    return $result->[ 0 ];
}

sub delete_block {
    my $self     = shift;
    my $ident    = shift;

    my $result   = $self->walk_postorder( 'remove_block', $ident );

    return $result->[ 0 ];
}

sub move_block {
    my $self   = shift;
    my $params = shift;

    $self->walk_postorder( 'block_move', $params );
}

sub create_subblock {
    my $self   = shift;
    my $params = shift;

    my $result = $self->walk_postorder( 'add_subblock', $params );

    if ( @{ $result } == 0 ) {
        die "Couldn't add subblock '$params->{new_child}{name}' "
            .   "to $params->{parent}{type} '$params->{parent}{ident}'\n";
    }

    return $result->[0];
}

sub type_change {
    my $self   = shift;
    my $params = shift;

    $self->walk_postorder( 'change_type', $params );
}

package application;
use strict; use warnings;

sub get_blocks {
    my $self = shift;

    return $self->walk_postorder( 'app_block_hashes' );
}

sub get_name {
	my $self = shift;

	return $self->{__NAME__};
}

sub set_name {
    my $self     = shift;
    my $new_name = shift;

    $self->{__NAME__} = $new_name;
}

sub get_app_statement {
    my $self    = shift;
    my $keyword = shift;

    my $answer = $self->walk_postorder( 'get_statement', $keyword );

    return $answer;
}

sub set_app_statement {
    my $self    = shift;
    my $keyword = shift;
    my $value   = shift;

    my $success = $self->walk_postorder(
        'set_statement', { keyword => $keyword, value => $value }
    );

    unless ( defined $success->[0] ) { # no existing statement, make one
        my @keys = sort keys %{ $self };
        $self->{app_body}->add_last_statement( $keyword, $value );
    }
}

sub remove_app_statement {
    my $self    = shift;
    my $keyword = shift;

    $self->walk_postorder( 'remove_statement', $keyword );
}

sub set_config_statement {
    my $self     = shift;
    my $keyword  = shift;
    my $value    = shift;
    my $accessor = shift;

    my $success  = $self->walk_postorder(
        'update_config_statement', { keyword => $keyword, value => $value, }
    );

    unless ( defined $success->[0] ) { # no such statement
        $self->{app_body}->add_last_config_statement(
                $keyword, $value, $accessor
        );
    }
}

sub set_config_statement_status {
    my $self    = shift;
    my $keyword = shift;
    my $value   = shift;

    $self->walk_postorder(
        'config_statement_status', { keyword => $keyword, value => $value }
    );
}

sub delete_config_statement {
    my $self    = shift;
    my $keyword = shift;

    $self->walk_postorder( 'remove_config_statement', $keyword );
}

sub get_config {
    my $self = shift;

    my $statements = $self->walk_postorder( 'get_config_statements' );

    return $statements;
}

sub walk_postorder {
	my $self   = shift;
	my $action = shift;
    my $data   = shift;

	my $output = $self->{app_body}->walk_postorder( $action, $data, $self );

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, undef );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

package app_body;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
	my $self   = shift;
	my $action = shift;
	my $data   = shift;
	my $parent = shift;

	my $output = [];

	foreach my $block ( @{ $self->{'block(s?)'} } ) {
        my $child_output = $block->walk_postorder( $action, $data, $self );

        push @{ $output }, @{ $child_output } if $child_output;
	}

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub add_block {
    my $self = shift;
    shift;
    my $data = shift;

    my $new_block = block->new_block( $self, $data );

    push @{ $self->{ 'block(s?)' } }, $new_block;

    return [ $new_block ];
}

sub remove_block {
    my $self         = shift;
    shift;
    my $doomed_ident = shift;
    my $blocks       = $self->{ 'block(s?)' };
    my $doomed_index = get_block_index( $blocks, $doomed_ident );

    return if ( $doomed_index == -1 ); # must be for a subblock

    splice @{ $blocks }, $doomed_index, 1;

    return [ 1 ];
}

sub block_move {
    my $self   = shift;
    shift;
    my $data   = shift;
    my $blocks = $self->{ 'block(s?)' };

    my $mover_index  = get_block_index( $blocks, $data->{mover} );
    die "No such block: $data->{mover}\n" if ( $mover_index == -1 );
    my $moving_block = splice @{ $blocks }, $mover_index, 1;

    my $pivot_index  = get_block_index( $blocks, $data->{pivot} );

    if ( $pivot_index == -1 ) {
        splice @{ $blocks }, $mover_index, 0, $moving_block;

        die "No such pivot block: $data->{pivot}\n";
    }

    if ( defined $data->{after} and $data->{after} ) {
        splice @{ $blocks }, $pivot_index + 1, 0, $moving_block;
    }
    else {
        splice @{ $blocks }, $pivot_index, 0, $moving_block;
    }

    return [ 1 ];
}

sub get_block_index {
    my $blocks       = shift;
    my $target_ident = shift;

    my $target_index = -1;
    my $count        = 0;

    BLOCK:
    foreach my $block ( @{ $blocks } ) {
        next BLOCK if defined $block->{app_statement};

        if ( $block->matches( $target_ident ) ) {
            $target_index = $count;
            last BLOCK;
        }
    }
    continue {
        $count++;
    }

    return $target_index;
}

sub remove_statement {
    my $self    = shift;
    shift;
    my $keyword = shift;

    my $doomed_child = -1;
    my $count        = 0;

    BLOCK:
    foreach my $block ( @{ $self->{'block(s?)'} } ) {
        next BLOCK unless defined $block->{app_statement};

        my $child_keyword = $block->{app_statement}->get_keyword();
        if ( $keyword eq $child_keyword ) {
            $doomed_child = $count;
            last BLOCK;
        }
    }
    continue {
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        # This probably leaks memory because children have parent pointers.
        # But the parent is me and I'm the app_body, so maybe not.
        splice @{ $self->{'block(s?)'} }, $doomed_child, 1;
    }
    # else, nothing to see here, move along quietly

    return [ 1 ];
}

sub add_last_config_statement {
    my $self     = shift;
    my $keyword  = shift;
    my $value    = shift;
    my $accessor = shift;

    my $success  = $self->walk_postorder(
        'add_config_statement',
        {
            keyword  => $keyword,
            value    => $value,
            accessor => $accessor,
        }
    );

    # if there is not a config block, make one and try again
    unless ( defined $success->[0] ) {
        my $statement = app_config_statement->new(
            $keyword,
            $value,
            $accessor,
        );

        my $block = app_config_block->new(
            {
                parent     => $self,
                statements => [ $statement ],
            }
        );
            
        push @{ $self->{ 'block(s?)' } }, $block;
    }
}

sub add_last_statement {
    my $self          = shift;
    my $keyword       = shift;
    my $value         = shift;

    my @values        = split /\]\[/, $value;
    my $new_statement = block->new_statement( $self, $keyword, \@values );

    my $index         = $self->last_statement_index();

    if ( $index >= 0 ) {
        splice @{ $self->{ 'block(s?)' } }, $index, 0, $new_statement;
    }
    else { # We're so excited, this is our first child!!!
        $self->{ 'block(s?)' } = [ $new_statement ];
    }

    # Untested, but should update the lookup hash, in case anyone cares
    my $lookup = $self->{__PARENT__}->{lookup};

    $lookup->{app_statements}{ $keyword } = arg_list->new( \@values );
}

sub last_statement_index {
    my $self = shift;

    my $index = -1;
    my $count = 0;
    foreach my $block ( @{ $self->{ 'block(s?)' } } ) {
        $index = $count if defined $block->{app_statement};
        $count++;
    }

    return $index;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my %output;

    foreach my $element ( @{ $child_output } ) {
        my $output_type                  = $element->{__TYPE__};

        my $name                         = $element->{__DATA__}[0];

        $output{ $output_type }{ $name } = $element->{__DATA__}[1];
    }

    return [ %output ];
}

package block;
use strict; use warnings;

use base 'application_ancestor';

sub new_statement {
    my $class   = shift;
    my $parent  = shift;
    my $keyword = shift;
    my $values  = shift;

    my $self = {
        __RULE__      => 'block',
        __PARENT__    => $parent,
    };

    $self->{app_statement} = app_statement->new( $self, $keyword, $values ),

    return bless $self, $class;
}

my %block_name_for = (
    table      => 'sql_block',
    sequence   => 'sql_block',
    controller => 'controller_block',
    literal    => 'literal_block',
);

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self   = {
        __RULE__   => 'block',
        __PARENT__ => $parent,
    };

    bless $self, $class;

    my $constructing_class = $block_name_for{ $data->{type} };

    $self->{ $constructing_class } = $constructing_class->new_block(
        $self, $data
    );

    return $self;
}

sub matches {
    my $self  = shift;
    my $ident = shift;

    my @block_types = qw( controller_block sql_block literal_block );

    TYPE:
    foreach my $block_type_name ( @block_types ) {
        next TYPE unless defined $self->{ $block_type_name };
        return 1 if ( $self->{ $block_type_name }{__IDENT__} eq $ident );
    }
}

sub old_matches {
    my $self  = shift;
    my $type  = shift;
    my $ident = shift;

    my $block_type_name = $block_name_for{ $type };

    return unless defined $self->{ $block_type_name };

    return unless ( $self->{ $block_type_name }{__IDENT__} eq $ident );

    return 1;
}

sub walk_postorder {
	my $self   = shift;
	my $action = shift;
    my $data   = shift;
	my $parent = shift;

	my $output = [];

	foreach my $block_type ( keys %$self ) {
		next unless (
            $block_type =~ /_block$/
                or
            $block_type =~ /_statement$/
        );

        my $child_output = $self->{$block_type}->walk_postorder(
            $action, $data, $self
        );

        push @{ $output }, @{ $child_output } if $child_output;
	}

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return $child_output;
}

package app_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class   = shift;
    my $parent  = shift;
    my $keyword = shift;
    my $values  = shift;

    my $self    = {
        __PARENT__  => $parent,
        __KEYWORD__ => $keyword,
        __ARGS__    => arg_list->new( $values ),
    };

    return bless $self, $class;
}

sub get_keyword {
    my $self = shift;

    return $self->{__KEYWORD__};
}

sub set_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data->{keyword} eq $self->{__KEYWORD__} );

    $self->{__ARGS__}->set_args_from( $data->{value} );

    return [ 1 ];
}

sub get_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data eq $self->{__KEYWORD__} );

    return $self->{__ARGS__}->get_unquoted_args;

}

sub walk_postorder {
	my $self   = shift;
	my $action = shift;
    my $data   = shift;
	my $parent = shift;

	if ( $self->can( $action ) ) {
		return $self->$action( undef, $data, $parent );
	}
	else {
		return;
	}
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [
        {
            '__TYPE__' => 'app_statements',
            '__DATA__' => [
                $self->{__KEYWORD__} => $self->{__ARGS__}
            ]
        }
    ];
}

package literal_block;
use strict; use warnings;

use base 'application_ancestor';

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self = {
        __PARENT__      => $parent,
        __IDENT__       => Bigtop::Parser->get_ident(),
        __BACKEND__     => $data->{name} || 'None',
        __BODY__        => '',
    };

    return bless $self, $class;
}

sub set_type {
    my $self     = shift;
    my $new_type = shift;

    $self->{__BACKEND__} = $new_type;
}

sub set_value {
    my $self      = shift;
    my $new_value = shift;

    $self->{__BODY__} = $new_value;
}

sub change_type {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident eq $data->{ident} );

    $self->set_type( $data->{new_type} );

    return [ 1 ];
}

sub change_literal {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident eq $data->{ident} );

    $self->set_value( $data->{new_value} );

    return;
}

sub app_block_hashes {
    my $self         = shift;

    return [ {
        ident     => $self->get_ident,
        type      => 'literal',
        keyword   => $self->{__BACKEND__},
        value     => $self->{__BODY__},
    } ];
}

sub get_ident {
    my $self = shift;
    return $self->{__IDENT__};
}

sub get_backend {
    my $self = shift;

    return $self->{__BACKEND__};
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	if ( $self->can( $action ) ) {
		return $self->$action( undef, $data, $parent );
	}
	else {
		return;
	}
}

sub make_output {
    my $self      = shift;
    my $backend   = shift;
    my $want_hash = shift;

    if ( $backend eq $self->{__BACKEND__} ) {
        my $output = $self->{__BODY__};

        $output    =~ s/\Z/\n/ if ( $output !~ /\s\Z/ );

        return $want_hash ? [ { $backend => $output } ] : [ $output ];
    }
    else {
        return;
    }
}

package sql_block;
use strict; use warnings;

use base 'application_ancestor';

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self;

    if ( $data->{type} eq 'sequence' ) {
        my $sequence_body = {
            'sequence_statement(s?)' => [],
            '__RULE__'               => 'sequence_body',
            'sequence_statement(s)'  => [],
        };

        bless $sequence_body, 'sequence_body';

        $self = {
            __IDENT__ => Bigtop::Parser->get_ident(),
            __NAME__  => $data->{name},
            __TYPE__  => 'sequences',
            __BODY__  => $sequence_body,
        };

        $sequence_body->{__PARENT__} = $self;
    }
    elsif ( $data->{type} eq 'table' ) {
        my $table_body = table_body->new();

        $self = {
            __IDENT__ => Bigtop::Parser->get_ident(),
            __NAME__  => $data->{name},
            __TYPE__  => 'tables',
            __BODY__  => $table_body,
        };

        $table_body->{__PARENT__} = $self;

        my $id_field = table_element_block->new_field(
            $self->{__BODY__}, 'id'
        );

        $id_field->change_field_statement(
            undef,
            {
                ident     => $id_field->get_ident,
                keyword   => 'is',
                new_value => 'int4][primary_key][auto',
            },
        );

        push @{ $self->{__BODY__}{'table_element_block(s?)'} }, $id_field;
    }
    else {
        die "sql_block does not know how to make a $data->{type}\n";
    }

    $self->{__PARENT__} = $parent;

    return bless $self, $class;
}

sub add_subblock {
    my $self   = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__TYPE__}        eq 'tables'         );
    return unless ( $data->{parent}{type}    eq 'table'          );
    return unless ( $data->{parent}{ident}   eq $self->get_ident );
    return unless ( $data->{new_child}{type} eq 'field'          );

    my $new_field = table_element_block->new_field(
            $self->{__BODY__}, $data->{new_child}{name}
    );

    push @{ $self->{__BODY__}{'table_element_block(s?)'} }, $new_field;

    return [ $new_field ];
}

sub remove_block {
    my $self         = shift;
    shift;
    my $doomed_ident = shift;

    my $doomed_index = -1;
    my $count        = 0;

    my $children     = $self->{__BODY__}{'table_element_block(s?)'};

    CHILD:
    foreach my $child ( @{ $children } ) {
        my $child_ident = $child->get_ident;

        next CHILD unless defined $child_ident;

        if ( $child_ident eq $doomed_ident ) {
            $doomed_index = $count;
        }
    }
    continue {
        $count++;
    }

    return if ( $doomed_index == -1 );

    splice @{ $children }, $doomed_index, 1;

    return [ 1 ];
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    if ( $self->{__TYPE__} eq 'sequences' ) {
        return [ {
            type  => 'sequence',
            body  => undef,
            name  => $self->get_name,
            ident => $self->get_ident,
        } ];
    }
    else {
        my $body = {
            statements => {},
            fields     => [],
        };

        foreach my $child_item ( @{ $child_output } ) {
            if ( $child_item->{ type } eq 'statement' ) {
                $body->{ statements }{ $child_item->{ keyword } } =
                        $child_item->{ value };
            }
            else {
                push @{ $body->{ fields } }, $child_item;
            }
        }

        return [ {
            type  => 'table',
            body  => $body,
            name  => $self->get_name,
            ident => $self->get_ident,
        } ];
    }
}

sub change_name_table {
    my $self   = shift;
    shift;
    my $data = shift;

    return unless $self->{__TYPE__} eq 'tables';
    return unless $self->get_ident  eq $data->{ident};

    $self->set_name( $data->{new_value} );

    return [ 1 ];
}

sub change_name_sequence {
    my $self   = shift;
    shift;
    my $params = shift;

    return unless $self->{__TYPE__} eq 'sequences';
    return unless $self->get_ident  eq $params->{ident};

    $self->set_name( $params->{new_value} );

    return [ 1 ];
}

sub get_ident {
    my $self = shift;

    return $self->{__IDENT__};
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub set_name {
    my $self     = shift;
    my $new_name = shift;

    $self->{__NAME__} = $new_name;

    # update lookup hash?
}

sub walk_postorder {
	my $self   = shift;
	my $action = shift;
    my $data   = shift;
	my $parent = shift;

	my $output = $self->{__BODY__}->walk_postorder( $action, $data, $self );

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my %output;

    foreach my $element ( @{ $child_output } ) {
        my $output_type                  = $element->{__TYPE__};

        my $name                         = $element->{__DATA__}[0];

        $output{ $output_type }{ $name } = $element->{__DATA__}[1];
    }

    if ( %output ) {
        return [ 
            {
                __TYPE__ => $self->{__TYPE__},
                __DATA__ => [ $self->get_name() => \%output ],
            }
        ];
    }
    else {
        return;
    }
}

sub change_table_statement {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( $self->{__TYPE__} eq 'tables'       );
    return unless ( $self->get_ident  eq $data->{ident} );

    my $success = $self->walk_postorder( 'change_table_keyword_value', $data );

    unless ( defined $success->[0] ) { # make new statement

        my $new_statement = table_element_block->new_statement(
            $self,
            $data->{keyword},
            $data->{new_value},
        );

        my $blocks = $self->{ __BODY__ }{ 'table_element_block(s?)' };
        push @{ $blocks }, $new_statement;
    }

    return [ 1 ];
}

sub remove_table_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__TYPE__} eq 'tables'       );
    return unless ( $self->get_ident  eq $data->{ident} );

    my $doomed_child = -1;
    my $count        = 0;

    BLOCK:
    foreach my $block ( @{ $self->{__BODY__}{'table_element_block(s?)'} } ) {
        next BLOCK unless $block->{__TYPE__} eq $data->{keyword};

        $doomed_child = $count;
        last BLOCK;
    }
    continue {
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        # This probably leaks memory because children have parent pointers.
        # But the parent is me and I'm the app_body, so maybe not.
        splice @{ $self->{__BODY__}{'table_element_block(s?)'} },
                $doomed_child,
                1;
    }
    # else, nothing to see here, move along quietly

    return [ 1 ];
}

package sequence_body;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
    my $self   = shift;
	my $action = shift;
    my $data   = shift;
    my $parent = shift;

	my $output = [];
	foreach my $seq_statement ( @{ $self->{'sequence_statement(s)'} } ) {
        my $child_output = $seq_statement->walk_postorder(
            $action, $data, $self
        );

        push @{ $output }, @{ $child_output } if $child_output;
	}

	if ( $self->can( $action ) ) {
        my $real_output = ( @{ $output } ) ? $output : undef;
		$output = $self->$action( $real_output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my %output;

    if ( $child_output ) {
        foreach my $element ( @{ $child_output } ) {
            my $output_type                  = $element->{__TYPE__};

            my $name                         = $element->{__DATA__}[0];

            $output{ $output_type }{ $name } = $element->{__DATA__}[1];
        }
        return [ \%output ];
    }
    else {
        return;
    }

}

package sequence_statement;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	if ( $self->can( $action ) ) {
		return $self->$action( undef, $data, $parent );
	}
	else {
		return;
	}
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ 
        {
            '__TYPE__' => 'sequences',
            '__DATA__' => [
                $self->{__NAME__} => $self->{__ARGS__},
            ]
        }
    ];
}

package table_body;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class  = shift;

    my $self = {
        __RULE__                  => 'table_body',
        'table_element_block(s?)' => [],
    };

    return bless $self, $class;
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	my $output = [];

	foreach my $tbl_element_block ( @{ $self->{'table_element_block(s?)'} } ) {
		my $child_output = $tbl_element_block->walk_postorder(
            $action, $data, $self
        );
		push @{ $output }, @{ $child_output } if $child_output;
	}

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

package table_element_block;
use strict; use warnings;

use base 'application_ancestor';

sub new_statement {
    my $class   = shift;
    my $parent  = shift;
    my $keyword = shift;
    my $values  = shift;

    my $self    = {
        __PARENT__ => $parent,
        __BODY__   => $keyword,
        __TYPE__   => $keyword,
        __VALUE__  => arg_list->new( $values ),
    };

    return bless $self, $class;
}

sub new_field {
    my $class  = shift;
    my $parent = shift;
    my $name   = shift;

    my $self   = {
        __PARENT__ => $parent,
        __TYPE__   => 'field',
        __IDENT__  => Bigtop::Parser->get_ident(),
        __NAME__   => $name,
        __BODY__   => field_body->new(),
    };

    $self->{__BODY__}{__PARENT__} = $self;

    return bless $self, $class;
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    my %statements;

    foreach my $child_item ( @{ $child_output } ) {
        $statements{ $child_item->{ keyword } } = $child_item->{ values };
    }

    if ( $self->{__TYPE__} eq 'field' ) {
        return [ {
            type       => 'field',
            name       => $self->get_name,
            ident      => $self->get_ident,
            statements => \%statements,
        } ];
    }
    else {
        return [ {
            ident     => $self->get_ident,
            type      => 'statement',
            keyword   => $self->{__BODY__},
            value     => $self->{__VALUE__},
        } ];
    }
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub set_name {
    my $self     = shift;
    my $new_name = shift;

    $self->{__NAME__} = $new_name;
}

sub get_ident {
    my $self = shift;

    return $self->{__IDENT__};
}

sub get_table_name {
    my $self = shift;

    return $self->{__PARENT__}{__PARENT__}{__NAME__};
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	my $output;

	if ( $self->{__BODY__}->can( 'walk_postorder' ) ) {
		$output = $self->{__BODY__}->walk_postorder( $action, $data, $self );
	}

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my %output;

    if ( $child_output ) {
        my %sub_output;

        foreach my $element ( @{ $child_output } ) {
            my $output_type                      = $element->{__TYPE__};

            my $name                             = $element->{__DATA__}[0];

            $sub_output{ $output_type }{ $name } = $element->{__DATA__}[1];
        }

        %output = (
            '__TYPE__' => 'fields',
            '__DATA__' => [
                $self->{__NAME__} => \%sub_output,
            ],
        );
    }
    # for non-field statements
    else {
        %output = (
            '__TYPE__' => $self->{__BODY__},
            '__DATA__' => [
                __ARGS__ => $self->{__VALUE__},
            ],
        );
    }

    return [ \%output ];
}

sub change_table_keyword_value {
    my $self = shift;
    shift;
    my $data = shift;

    return if ( defined $self->get_name ); # only fields have names

    return unless ( $self->{__BODY__} eq $data->{keyword} );

    $self->{__VALUE__}->set_args_from( $data->{new_value} );

    return [ 1 ];
}

sub change_field_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__TYPE__}     eq 'field'        );
    return unless ( $self->get_ident      eq $data->{ident} );

    my $success = $self->walk_postorder( 'change_field_keyword_value', $data );

    unless ( defined $success->[0] ) { # make new statement

        my $new_statement = field_statement->new_statement(
            $self->{__BODY__},
            $data->{keyword},
            $data->{new_value},
        );

        my $blocks = $self->{ __BODY__ }{ 'field_statement(s?)' };
        push @{ $blocks }, $new_statement;
    }

    return [ 1 ];
}

sub remove_field_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__TYPE__}     eq 'field'        );
    return unless ( $self->get_ident      eq $data->{ident} );

    my $statements   = $self->{ __BODY__ }{ 'field_statement(s?)' };
    my $doomed_index = get_statement_index( $statements, $data->{keyword} );

    if ( $doomed_index >= 0 ) {
        splice @{ $statements }, $doomed_index, 1;
        return [ 1 ];
    }
    else {
        return [ 0 ];
    }
}

sub get_statement_index {
    my $statements   = shift;
    my $target_name  = shift;

    my $target_index = -1;
    my $count        = 0;

    STATEMENT:
    foreach my $statement ( @{ $statements } ) {
        if ( $statement->get_name eq $target_name ) {
            $target_index = $count;
            last STATEMENT;
        }
    }
    continue {
        $count++;
    }

    return $target_index;
}

sub change_name_field {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( defined $self->get_ident ); # only fields can change names

    return unless $self->get_ident eq $data->{ident};

    $self->set_name( $data->{ new_value } );

    return [ 1 ];
}

package field_body;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class  = shift;
    my $parent = shift;

    my $self  = {
        __RULE__              => 'field_body',
        __PARENT__            => $parent,
        'field_statement(s?)' => [],
    };

    return bless $self, $class;
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	my $output = [];

	foreach my $field_stmnt ( @{ $self->{'field_statement(s?)'} } ) {
        my $child_output = $field_stmnt->walk_postorder(
            $action, $data, $self
        );

		push @{ $output }, @{ $child_output } if $child_output;
	}

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

package field_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new_statement {
    my $class   = shift;
    my $parent  = shift;
    my $keyword = shift;
    my $values  = shift;

    my $self    = {
        __PARENT__ => $parent,
        __NAME__   => $keyword,
        __DEF__    => field_statement_def->new( $values ),
    };

    $self->{__DEF__}{__PARENT__} = $self;

    return bless $self, $class;
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    return [ {
        keyword => $self->get_name,
        values  => $self->get_values,
    } ];
}

sub get_table_name {
    my $self = shift;

    return $self->{__PARENT__}{__PARENT__}{__PARENT__}{__PARENT__}{__NAME__};
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub get_values {
    my $self = shift;

    return $self->{__DEF__}{__ARGS__};
}

sub change_field_keyword_value {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data->{type}         eq 'field'          );
    return unless ( $self->{__NAME__}     eq $data->{keyword} );

    $self->{__DEF__}{__ARGS__}->set_args_from( $data->{new_value} );

    return [ 1 ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	my $output;
    
    if ( $self->{__DEF__}->can( 'walk_postorder' ) ) {
        $output = $self->{__DEF__}->walk_postorder( $action, $data, $self );
    }

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ 
        {
            '__TYPE__' => $self->{__NAME__},
            '__DATA__' => [ @{ $child_output } ],
        }
    ];
}

package field_statement_def;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class  = shift;
    my $values = shift;

    my $self   = {
        __ARGS__ => arg_list->new( $values ),
    };

    return bless $self, $class;
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	if ( $self->can( $action ) ) {
		return $self->$action( undef, $data, $parent );
	}
	else {
		return;
	}
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ 'args' => $self->{__ARGS__} ];
}

package controller_block;
use strict; use warnings;

use base 'application_ancestor';

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self;

    my $controller_body = {
        'controller_statement(s?)' => [],
        '__RULE__'                 => 'controller_body',
    };

    bless $controller_body, 'controller_body';

    $self = {
        __IDENT__       => Bigtop::Parser->get_ident(),
        __NAME__        => $data->{name},
        __TYPE__        => [ $data->{subtype} ],
        controller_body => $controller_body,
    };

    $self->{controller_body}{__PARENT__} = $self;

    $self->{__PARENT__} = $parent;

    return bless $self, $class;
}

sub add_subblock {
    my $self   = shift;
    shift;
    my $params = shift;

    return unless ( $params->{parent}{type}    eq 'controller'     );
    return unless ( $params->{parent}{ident}   eq $self->get_ident );
    return unless ( $params->{new_child}{type} eq 'method'         );

    my $new_method = controller_method->new(
            $self->{controller_body}, $params
    );

    push @{ $self->{controller_body}{'controller_statement(s?)'} },
         $new_method;

    return [ $new_method ];
}

sub remove_block {
    my $self         = shift;
    shift;
    my $doomed_ident = shift;

    my $doomed_index = -1;
    my $count        = 0;

    my $children     = $self->{controller_body}
                              {'controller_statement(s?)'};

    CHILD:
    foreach my $child ( @{ $children } ) {
        next CHILD unless $child->can( 'get_ident' );

        if ( $child->get_ident eq $doomed_ident ) {
            $doomed_index = $count;
        }
    }
    continue {
        $count++;
    }

    return if ( $doomed_index == -1 );

    splice @{ $children }, $doomed_index, 1;

    return [ 1 ];
}

sub get_ident {
    my $self = shift;
    return $self->{__IDENT__};
}

sub get_name {
    my $self = shift;
    return $self->{__NAME__};
}

sub set_name {
    my $self          = shift;
    $self->{__NAME__} = shift;
}

sub set_type {
    my $self          = shift;
    $self->{__TYPE__} = [ shift ];
}

sub change_name_controller {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->get_ident  eq $data->{ident};

    $self->set_name( $data->{new_value} );

    return [ 1 ];
}

sub change_type {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident eq $data->{ident} );

    $self->set_type( $data->{new_type} );

    return [ 1 ];
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    my $body = {
        statements => {},
        methods    => [],
    };

    foreach my $child_item ( @{ $child_output } ) {
        if ( $child_item->{ type } eq 'statement' ) {
            $body->{ statements }{ $child_item->{ keyword } } =
                $child_item->{ value };
        }
        else {
            push @{ $body->{ methods } }, $child_item;
        }
    }

    my $controller_type = $self->{__TYPE__}[0] || 'stub';

    return [ {
        ident           => $self->get_ident,
        type            => 'controller',
        body            => $body,
        name            => $self->get_name,
        controller_type => $controller_type,
    } ];
}

sub change_controller_statement {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( $self->get_ident   eq $data->{ident} );

    my $success = $self->walk_postorder(
                    'change_controller_keyword_value', $data
    );

    unless ( defined $success->[0] ) { # make new statement

        my $new_statement = controller_statement->new(
            $self,
            $data->{keyword},
            $data->{new_value},
        );

        my $blocks = $self->{ controller_body }{ 'controller_statement(s?)' };
        push @{ $blocks }, $new_statement;
    }

    return [ 1 ];
}

sub remove_controller_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident   eq $data->{ident} );

    my $doomed_child = -1;
    my $count        = 0;

    my $blocks = $self->{controller_body}{'controller_statement(s?)'};

    BLOCK:
    foreach my $block ( @{ $blocks } ) {
        next BLOCK unless defined $block->{__KEYWORD__}; # skip methods
        next BLOCK unless $block->{__KEYWORD__} eq $data->{keyword};

        $doomed_child = $count;
        last BLOCK;
    }
    continue {
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        # This probably leaks memory because children have parent pointers.
        # But the parent is me and I'm the app_body, so maybe not.
        splice @{ $blocks }, $doomed_child, 1;
    }
    # else, nothing to see here, move along quietly

    return [ 1 ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	my $output = $self->{controller_body}->walk_postorder(
        $action, $data, $self
    );

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [
        {
            '__TYPE__' => 'controllers',
            '__DATA__' => [
                $self->{__NAME__} => { @{ $child_output } }
            ],
        }
    ];
}

package controller_body;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	my $output = [];

	foreach my $controller_stmnt ( @{ $self->{'controller_statement(s?)'} } ) {
		my $child_output = $controller_stmnt->walk_postorder(
            $action, $data, $self
        );
		push @{ $output }, @{ $child_output } if $child_output;
	}

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $type         = $self->{__PARENT__}{__TYPE__}[0];

    my %output       = ( type => $type );

    foreach my $element ( @{ $child_output } ) {
        my $output_type                  = $element->{__TYPE__};

        my $name                         = $element->{__DATA__}[0];

        $output{ $output_type }{ $name } = $element->{__DATA__}[1];
    }

    return [ %output ];
}

package controller_method;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class  = shift;
    my $parent = shift;
    my $params = shift;

    my $type   = $params->{new_child}{sub_type} || 'stub';

    my $self   = {
        __IDENT__  => Bigtop::Parser->get_ident(),
        __NAME__   => $params->{new_child}{name},
        __BODY__   => method_body->new(),
        __TYPE__   => $type,
    };

    $self->{__BODY__}{__PARENT__} = $self;

    return bless $self, $class;
}

sub get_ident {
    my $self = shift;

    return $self->{__IDENT__};
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub set_name {
    my $self          = shift;
    $self->{__NAME__} = shift;
}

sub set_type {
    my $self          = shift;
    $self->{__TYPE__} = shift;
}

sub get_controller_ident {
    my $self = shift;

    return $self->{__PARENT__}{__PARENT__}->get_ident();
}

sub get_controller_name {
    my $self = shift;

    return $self->{__PARENT__}{__PARENT__}->get_name();
}

sub change_name_method {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->get_ident eq $data->{ident};

    $self->set_name( $data->{ new_value } );

    return [ 1 ];
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    my %statements;

    foreach my $child_item ( @{ $child_output } ) {
        $statements{ $child_item->{ keyword } } = $child_item->{ values };
    }

    return [ {
        ident       => $self->get_ident,
        type        => 'method',
        name        => $self->get_name,
        method_type => $self->{__TYPE__},
        statements  => \%statements,
    } ];
}

sub change_method_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data->{ident} eq $self->get_ident() );

    my $success = $self->walk_postorder(
            'change_method_keyword_value', $data
    );

    unless ( defined $success->[0] ) { # make new statement

        my $new_statement = method_statement->new(
            $self->{__BODY__},
            $data->{keyword},
            $data->{new_value},
        );

        my $blocks = $self->{ __BODY__ }{ 'method_statement(s?)' };
        push @{ $blocks }, $new_statement;
    }

    return [ 1 ];
}

sub remove_method_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data->{ident} eq $self->get_ident() );

    my $doomed_child = -1;
    my $count        = 0;

    my $statements = $self->{ __BODY__ }{'method_statement(s?)'};

    STATEMENT:
    foreach my $statement ( @{ $statements } ) {
        next STATEMENT unless $statement->{__KEY__} eq $data->{keyword};

        $doomed_child = $count;
        last STATEMENT;
    }
    continue {
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        # This probably leaks memory because children have parent pointers.
        # But the parent is me and I'm the app_body, so maybe not.
        splice @{ $statements }, $doomed_child, 1;
    }
    # else, nothing to see here, move along quietly

    return [ 1 ];
}

sub change_type {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident eq $data->{ident} );

    $self->set_type( $data->{new_type} );

    return [ 1 ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = $self->{__BODY__}->walk_postorder( $action, $data, $self );

	if ( $self->can( $action ) ) {
		return $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $statements   = {};

    if ( $child_output ) {
        $statements  = { @{ $child_output } }
    }

    return [
        {
            '__TYPE__'        => 'methods',
            '__DATA__'        => [
                $self->{__NAME__} => {
                    type       => $self->{__TYPE__},
                    statements => $statements,
                },
            ],
        }
    ];
}

package method_body;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class  = shift;

    my $self  = {
        __RULE__               => 'method_body',
        'method_statement(s?)' => [],
    };

    return bless $self, $class;
}

sub get_method_name {
    my $self = shift;

    return $self->{__PARENT__}{__NAME__};
}

sub get_controller_name {
    my $self = shift;

    return $self->{__PARENT__}{__PARENT__}{__PARENT__}->get_name();
}

sub get_table_name {
    my $self   = shift;
    my $lookup = shift;

    my $controller = $self->get_controller_name();
    return $lookup->{controllers}{$controller}{statements}{controls_table}[0];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $child ( @{ $self->{'method_statement(s?)'} } ) {
        my $child_output = $child->walk_postorder( $action, $data, $self );
        push @{ $output }, @{ $child_output } if $child_output;
    }

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

package method_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class     = shift;
    my $parent    = shift;
    my $keyword   = shift;
    my $new_value = shift;

    my $self      = {
        __PARENT__ => $parent,
        __KEY__    => $keyword,
        __ARGS__   => arg_list->new( $new_value ),
    };

    return bless $self, $class;
}

sub change_method_keyword_value {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__KEY__}     eq $data->{keyword} );

    $self->{__ARGS__}->set_args_from( $data->{new_value} );

    return [ 1 ];
}

sub app_block_hashes {
    my $self         = shift;

    return [ {
        keyword     => $self->{__KEY__},
        values      => $self->{__ARGS__},
    } ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	if ( $self->can( $action ) ) {
		return $self->$action( undef, $data, $parent );
	}
	else {
		return;
	}
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ $self->{__KEY__} => $self->{__ARGS__} ];
}

package controller_literal_block;
use strict; use warnings;

use base 'application_ancestor';

sub get_backend {
    my $self = shift;

    return $self->{__BACKEND__};
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	if ( $self->can( $action ) ) {
		return $self->$action( undef, $data, $parent );
	}
	else {
		return;
	}
}

sub make_output {
    my $self    = shift;
    my $backend = shift;

    if ( $backend eq $self->{__BACKEND__} ) {
        my $output = $self->{__BODY__};

        $output    =~ s/\Z/\n/ if ( $output !~ /\s\Z/ );

        return [ $output ];
    }
    else {
        return;
    }
}

package controller_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class   = shift;
    my $parent  = shift;
    my $keyword = shift;
    my $values  = shift;

    my $self    = {
        __PARENT__  => $parent,
        __KEYWORD__ => $keyword,
        __ARGS__    => arg_list->new( $values ),
    };

    return bless $self, $class;
}

sub change_controller_keyword_value {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__KEYWORD__} eq $data->{keyword} );

    $self->{__ARGS__}->set_args_from( $data->{new_value} );

    return [ 1 ];
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    return [ {
        type    => 'statement',
        keyword => $self->{__KEYWORD__},
        value   => $self->{__ARGS__},
    } ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	if ( $self->can( $action ) ) {
		return $self->$action( undef, $data, $parent );
	}
	else {
		return;
	}
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [
        {
            '__TYPE__' => 'statements',
            '__DATA__' => [
                $self->{__KEYWORD__} => $self->{__ARGS__}
            ]
        }
    ];
}

package app_config_block;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class  = shift;
    my $params = shift;

    return bless {
        __PARENT__            => $params->{parent},
        app_config_statements => $params->{statements},
    }, $class;
}

sub add_config_statement {
    my $self = shift;
    shift;
    my $data = shift;

    my $new_statement = app_config_statement->new(
        $data->{ keyword  },
        $data->{ value    },
        $data->{ accessor },
    );

    push @{ $self->{ app_config_statements } }, $new_statement;

    return [ 1 ];
}

sub remove_config_statement {
    my $self    = shift;
    shift;
    my $keyword = shift;

    my $doomed_child = -1;
    my $count        = 0;

    STATEMENT:
    foreach my $child ( @{ $self->{ app_config_statements } } ) {
        my $child_keyword = $child->get_keyword();
        if ( $keyword eq $child_keyword ) {
            $doomed_child = $count;
            last STATEMENT;
        }
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        splice @{ $self->{ app_config_statements } }, $doomed_child, 1;
    }

    return [ 1 ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $child ( @{ $self->{'app_config_statements'} } ) {
        my $child_output = $child->walk_postorder( $action, $data, $self );
        push @{ $output }, @{ $child_output } if $child_output;
    }

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return $child_output;
}

package controller_config_block;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $child ( @{ $self->{'controller_config_statements'} } ) {
        my $child_output = $child->walk_postorder( $action, $data, $self );
        push @{ $output }, @{ $child_output } if $child_output;
    }

	if ( $self->can( $action ) ) {
		$output = $self->$action( $output, $data, $parent );
	}

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return $child_output;
}

package app_config_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class    = shift;
    my $keyword  = shift;
    my $value    = shift;
    my $accessor = shift;

    my $self;
 
    if ( $accessor ) {
        $self = {
            __KEY__  => $keyword,
            __ARGS__ => arg_list->new( [ { $value => 'no_accessor' } ] )
        };
    }
    else {
        $self = {
            __KEY__  => $keyword,
            __ARGS__ => arg_list->new( [ $value ] )
        };
    }

    return bless $self, $class;
}

sub get_keyword {
    my $self = shift;

    return $self->{__KEY__};
}

sub get_config_statements {
    my $self = shift;

    return [ $self->{__KEY__} => $self->{__ARGS__} ];
}

sub update_config_statement {
    my $self   = shift;
    shift;
    my $data   = shift;

    return [] unless ( $data->{ keyword } eq $self->{ __KEY__ } );

    my $arg = $self->{__ARGS__}->get_first_arg();

    if ( ref( $arg ) eq 'HASH' ) {
        my ( $value, $no_access ) = %{ $arg };

        $self->{__ARGS__} = arg_list->new(
            [ { $data->{value} => $no_access } ]
        );
    }
    else {
        $self->{__ARGS__} = arg_list->new(
            [ $data->{value} ]
        );
    }

    return [ 1 ];
}

sub config_statement_status {
    my $self   = shift;
    shift;
    my $data   = shift;

    return [] unless ( $data->{ keyword } eq $self->{ __KEY__ } );

    my $arg = $self->{__ARGS__}->get_args();

    if ( $data->{ value } ) { # add no_accessor flag
        $self->{__ARGS__} = arg_list->new(
            [ { $arg => 'no_accessor' } ]
        );
    }
    else { # remove flag
        $self->{__ARGS__} = arg_list->new(
            [ $arg ]
        );
    }

    return [];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	if ( $self->can( $action ) ) {
		return $self->$action( undef, $data, $parent );
	}
	else {
		return;
	}
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [
        {
            '__TYPE__' => 'configs',
            '__DATA__' => [
                $self->{__KEY__} => $self->{__ARGS__}
            ]
        }
    ];
}

package controller_config_statement;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

	if ( $self->can( $action ) ) {
		return $self->$action( undef, $data, $parent );
	}
	else {
		return;
	}
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [
        {
            '__TYPE__' => 'configs',
            '__DATA__' => [
                $self->{__KEY__} => $self->{__ARGS__}
            ]
        }
    ];
}

package arg_list;
use strict; use warnings;

sub new {
    my $class  = shift;
    my $values = shift;

    return bless build_values( $values ), $class;
}

sub build_values {
    my $values = shift;

    if ( ref( $values ) eq 'ARRAY' ) {
        return $values;
    }
    elsif ( ref( $values ) eq 'HASH' ) {
        my @keys   = split /\]\[/, $values->{ keys   };
        my @values = split /\]\[/, $values->{ values };

        my @retvals;

        for ( my $i = 0; $i < @keys; $i++ ) {
            if ( defined $values[ $i ] and $values[ $i ] ne 'undefined' ) {
                push @retvals, { $keys[ $i ] => $values[ $i ] };
            }
            else {
                push @retvals, $keys[ $i ];
            }
        }

        return \@retvals;
    }
    else {
        my @values = split /\]\[/, $values;

        return \@values;
    }
}

sub get_first_arg {
    my $self = shift;

    return $self->[0];
}

sub get_args {
    my $self = shift;

    my @args;

    foreach my $arg ( @{ $self } ) {
        if ( ref( $arg ) =~ /HASH/ ) {
            my ( $name, $condition ) = %{ $arg };
            push @args, $name;
        }
        else {
            push @args, $arg;
        }
    }

    return join ', ', @args;
}

sub get_quoted_args {
    my $self = shift;

    my @args;

    foreach my $arg ( @{ $self } ) {
        if ( ref( $arg ) =~ /HASH/ ) {
            my ( $name, $condition ) = %{ $arg };

            unless ( $name =~ /^\w[\w\d_]*$/ ) {
                $name = "`$name`";
            }

            unless ( $condition =~ /^\w[\w\d_]*$/ ) {
                $condition = "`$condition`";
            }

            push @args, "$name => $condition";
        }
        else {
            my $value = $arg;
            unless ( $value =~ /^\w[\w\d_]*$/ ) {
                $value = "`$value`";
            }

            push @args, $value;
        }
    }

    return join ', ', @args;
}

sub get_unquoted_args {
    my $self = shift;

    my @args;

    foreach my $arg ( @{ $self } ) {
        if ( ref( $arg ) =~ /HASH/ ) {
            my ( $name, $condition ) = %{ $arg };

            push @args, "$name => $condition";
        }
        else {
            push @args, $arg;
        }
    }

    return \@args;
}

sub set_args_from {
    my $self       = shift;
    my $new_values = shift;

    pop  @{ $self } while ( @{ $self } );

    my $paired_values = build_values( $new_values );

    push @{ $self }, @{ $paired_values };
}

1;

=head1 NAME

Bigtop::Parser - the Parse::RecDescent grammar driven parser for bigtop files

=head1 SYNOPSIS

Make a file like this:

    config {
        base_dir `/home/username`;
        Type1 Backend {}
        Type2 Backend {}
        Type3 Backend {}
    }
    app App::Name {
        table name { }
        controller SomeController {}
    }

Then run this command:

    bigtop my.bigtop all

=head1 DESCRIPTION

This module is really only designed to be used by bigtop.  It provides
the grammar which understands bigtop files and turns them into syntax
trees.  It provides various utility functions for bigtop (or similar
tools you might write) and for backends.

Reading further is an indication that you are interested in working on Bigtop
and not just in using it to serve your needs.

=head1 METHODS

In this section, the methods are grouped, so that similar ones appear together.

=over 4

=head2 METHODS which drive generation for scripts

=item gen_from_file

The bigtop script calls this method.

You can call this as a class method passing it the name of the bigtop
file to read and a list of things to build.

The method is actually quite simple.  It merely reads the file, then
calls gen_from_string.

=item gen_from_string

The bigtop script calls this method when --new is used.

This method orchestrates the build.  It is called internally by gen_from_file.
Call it as a class method.  Pass it the bigtop string, the name of the
file from which that string came (or undef), and the list of things to build.

The file name is used by Bigtop::Init::Std to copy the bigtop file from
its original location into the docs subdirectory of the build directory.
If the file name is not defined, it skips that step.

The list of things to build can include any backend type listed in the
config block and/or the word 'all'.  'all' will be replaced with a list
of all the backend types in the config section (in the order they appear
there), as if they had been passed in.

It is legal to mention the same backend more than once.  For instance, you
could call gen_from_string directly

    Bigtop::Parser->gen_from_string(
            $bigtop_string, 'file.bigtop', $create, 'Init', 'Control', 'Init'
    );

or equivalently, and more typically, you could call gen_from_file:

    Bigtop::Parser->gen_from_file(
        'file.bigtop', $create, 'Init', 'Control', 'Init'
    );

Either of these might be useful, if the first Init sets up directories that
the Control backend needs, but the generated output from Control should
influence the contents of file which Init finally builds.  Check your backends
for details.

=head3 gen_from_string internals

gen_from_string works like this.  First, it attempts to parse the config
section of the bigtop string.  If that works, it iterates through each
backend mentioned there building a list of modules to require.  This
includes looking in backend blocks for template statements.  Their values
must be template files relative to the directory from which bigtop
was invoked.

Once the list is built, it calls its own import method to require them.
This allows each backend to register its keywords.  If any keyword
used in the app section is not registered, a fatal parse error results.

Once the backends are all required, gen_from_string parses the whole
bigtop string into an abstract syntax tree (AST).  Then it iterates
through the build list calling gen_Type on each element's backend.
So this:

    config {
        Init Std      {}
        SQL  Postgres { template `postgres.tt`; }
    }
    app ...

    Bigtop::Parser->gen_from_string(
            $bigtop_string, 'file.bigtop', 'Init', 'SQL'
    );

Results first in the loading of Bigtop::Init::Std and Bigtop::SQL::Postgres,
then in calling gen_Init on Init::Std and gen_SQL on SQL::Postgres.  During
the loading, setup_template is called with postgres.tt on SQL::Postgres.

gen_* methods are called as class methods.  They receive the build directory,
the AST, and the name of the bigtop_file (which could be undef).
Backends can do whatever they like from there.  Typically, they put
files onto the disk.  Those files might be web server conf files,
sql to build the database, control modules, templates for viewing, models,
etc.

=head2 METHODS which invoke the grammar

=item parse_config_string

Called as a class method (usually by gen_from_string), this method receives
the bigtop input as a string.  It attempts to parse only the config section
which it returns as an AST.  Syntax errors in the config section are
fatal.  Errors in the app section are not noticed.

=item parse_file

Call this as a class method, passing it the file name to read.  It reads
the file into memory, then calls parse_string, returning whatever it
returns.

=item parse_string

Call this as a class method, passing it the bigtop string to parse.
It calls the grammar to turn the input into an AST, which it returns.

=head2 METHODS which control which simple statement keywords are legal

=item add_valid_keywords

The grammar of a bigtop file is structured, but the legal keywords in
its simple statements are defined by the backends (excepts that the config
keywords are defined by this module, see Config Keywords below for those).

If you are writing a backend, you should use the base module for your
backend type.  This will register the standard keywords for that type.
For example, suppose you are writing Bigtop::SQL::neWdB.  It should be
enough to say:

    use Bigtop::SQL;

in your module.

If you need to add additional keywords that are specific to your backend,
put them in a begin block like this:

    BEGIN {
        Bigtop::Parser->add_valid_keywords(
            $type,
            qw( your keywords here),
        );
    }

Here $type is the name of the surrounding block in which this keyword 
will make a valid statement.  For example, if $type above is 'app' then
this would be legal:

    app App::Name {
        your value;
    }

The type must be one of these levels:

=over 4

=item app

=item config

=item controller

=item field

=item method

=back

These correspond exactly to the block types in the grammar (except that
sequence blocks must currently be empty, in the future sequence will be
added to the above list).

=item is_valid_keyword

Call this as a class method, passing it a type of keyword and a word that
might be a valid keyword of that type.

Returns true if the keyword is valid, false otherwise.

=item get_valid_keywords

Call this as a class method passing it the type of keywords you want.

Returns a list of all registered keywords, of the requested type, in
string sorted order.

The two preceding methogs are really for internal use in the grammar.

=head2 METHODS which work on the AST

=item walk_postorder

Walks the AST for you, calling you back when it's time to build something.

The most common skeleton for gen_Backend is:

    use Bigtop;
    use Bigtop::Backend;

    sub gen_Backend {
        my $class     = shift;
        my $build_dir = shift;
        my $tree      = shift;

        # walk the tree
        my $something     = $tree->walk_postoder( 'output_something' );
        my $something_str = join '', @{ $something };

        # write the file
        Bigtop::write_file( $build_dir, $something_string );
    }

This walks the tree from the root.  The walking is postorder meaning that
all children are visited before the current node.  Each walk_postorder
returns an array reference (which is why we have to join the result
in the above skeleton).  After the children have been visited, the
callback (C<output_something> in the example) is called with their output
array reference.  You can also pass an additional scalar (which is usually
a hash reference) to walk_postorder.  It will be passed along to all
the child walk_postorders and to the callbacks.

With this module walking the tree, all you must do is provide the appropriate
callbacks.  Put one at each level of the tree that interests you.

For example, if you are generating SQL, you need to put callbacks in
the following packages:

    sql_block
    sequence_body
    table_body
    table_element_block
    field_body
    field_statement

This does require some knowledge of the tree.  Please consult the grammar
for the possible packages (or grep for package on this file).

The callbacks are called as methods on the current tree node.  They receive
the output array reference from their children and the data scalar that
was passed to walk_postorder (if one was passed in the top level call).
So, a typical callback method might look like this:

    sub output_something {
        my $self         = shift;
        my $child_output = shift;
        my $data         = shift;
        ...
        return [ $output ];
    }

Remember that they must return an array reference.  If you need something
fancy, you might do this:

    return [ [ type1_output => $toutput, type2_output => $other_out ] ];

Then the parent package's callback will receive that and must tease
apart the the two types.  Note that I have nested arrays here.  This prevents
two children from overwriting each other's output if you are ever tempted
to try saving the return list directly to a hash (think recursion).

(walk_postorder also passes the current node to each child after the
data scalar.  This is the child's parent, which is really only useful
during parent building inside the grammar.  The parent comes
after the data scalar in both walk_postorder and in the callback.
Most backends will just peek in $self->{__PARENT__} which is gauranteed
to have the parent once the grammar finishes with the AST.)

=item set_parent

This method is the callback used by the grammar to make sure that all nodes
know who their daddy is.  You shouldn't call it, but looking at it shows
what the simplest callback might look like.  Note that there is only one
of these and it lives in the application_ancestor package, which is not
one of the packages defined in the grammar.  But, this module makes
sure that all the grammar defined packages inherit from it.

=item build_lookup_hash

This method builds the lookup hash you can use to find data about other
parts of the tree, without walking to it.

The AST actually has three keys: configuration, application, and lookup.
The first two are built in the normal way from the input file.  They
are genuine ASTs in their own right.  The lookup key is not.  It does
not preserve order.  But it does make it easier to retrieve things.

For example, suppose that you are in the method_body package attempting
to verify that requested fields for this method are defined in the
table for this controller.  You could walk the tree, but the lookup hash
makes it easier:

    unless (
        defined $tree->{lookup}{tables}{$table_name}{fields}{$field_name}
    ) {
        die "No such column $field_name\n";
    }

The easiest way to know what is available is to dump the lookup hash.
But the pattern is basically this.  At the top level there are fixed keywords
for the app level block types: tables, sequences, controllers.  The next
level is the name of a block.  Under that, there is a fixed keyword for
each subblock type, etc.

=head2 METHODS for use in walk_postorder callbacks

=item dumpme

Use this method instead of directly calling Data::Dumper::Dump.

While you could dump $self, that's rather messy.  The problem is the parent
nodes.  Their presence means a simple dump will always show the whole app
AST.  This method carefully removes the parent, dumps the node, and restores
the parent, reducing clutter and leaving everything in tact.

=item get_appname

Call this on the full AST.  It returns the name of the application.

=item get_config

Call this on the full AST.  It returns the config subtree.

=item get_controller_name

Call this, from the method_body package, on the AST node ($self in the
callback).  Returns the name of the controller for this method.  This
is useful for error reporting.

=item get_method_name

Call this, from the method_body package, on the AST node ($self in the
callback).  Returns the name of this method.  Useful for error reporting.

=item get_name

While this should work everywhere, it doesn't.  Some packages have it.
If yours does, call it.  Otherwise peek in $self->{__NAME__}.  But,
remember that not everything has a name.

=item get_table_name

Call this, from the method_body package, on the AST node ($self in the
callback).  Returns the name of the table this controller controls.
Useful for error reporting.

=head2 METHODS used internally

=item import

You probably don't need to call this.  But, if you do, pass it a list
of backends to import like this:

    use Bigtop::Parser qw( Type=Backend=template.tt );

This will load Bigtop::Type::Backend and tell it to use template.tt.
You can accomplish the same thing by directly calling import as a class
method:

    Bigtop::Parser->import( 'Type=Backend=template.tt' );

=item fatal_error_two_lines

This method is used by the grammar to report fatal parse error in the input.
It actually gives 50 characters of trailing context, not two lines, but
the name stuck.

=item fatal_keyword_error

This method is used by the grammer to report on unregistered (often misspelled)
keywords.  It identifies the offending keyword and the line where it appeared
in the input, gives the remainder of the line on which it was seen (which
is sometimes only whitespace), and lists the legal choices (often wrapping
them in an ugly fashion).

=back

=head1 Config KEYWORDS

For simplicity, all config keywords are defined in this module.  This is
not necessarily ideal and is subject to change.

=over 4

=head1 base_dir

Used only if you supply the --create flag to bigtop (or set create to true
when calling gen_from_file or gen_from_string as class methods of this
module).

When in create mode, the build directory will be made as a subdirectory
of the base_dir.  For instance, I could use my home directory:

    base_dir `/home/username`;

Note that you need the backquotes to hide the slashes.  Also note, that
you should use a path which looks good on your development system.  In
particular, this would work on the appropriate platform:

    base_dir `C:\path\to\build`;

The default base_dir is the current directory from which bigtop is run.

=head1 app_dir

Used only if you supply the --create flag to bigtop (or set create to true
when calling gen_from_file or gen_from_string as class methods of this
module).

When in create mode, the actual generated files will be placed into
base_dir/app_dir (where the slash is correctly replaced with your OS
path separator).  If you are in create mode, but don't supply an app_dir,
a default is formed from the app name in the manner h2xs would use.
Consider:

    config {
        base_dir `/home/username`;
    }
    app App::Name {
    }

In this case the app_dir is App-Name.  So the build directory is

    /home/username/App-Name

By specifying your own app_dir statement, you have complete control
of where the app is initially built.  For example:

    config {
        base_dir `/home/username`;
        app_dir  `myappdir`;
    }
    app App::Name { }

Will build in /home/username/myappdir.

When not using create mode, all files will be built under the current
directory.  If that directory doesn't look like an app build directory,
a fatal error will result.  Either move to the proper directory, or
use create mode to avoid the error.

=head1 engine

This is passed directly to the C<use Framework;> statement of the top level
controller.

Thus,

    engine MP13;

becomes something like this:

    use Framework qw/ engine=MP13 /;

in the base level controller.  Both Catalyst and Gantry expect this
syntax.

The available engines depend on what the framework supports.  The one
in the example is mod_perl 1.3 in the syntax of Catalyst and Gantry.

=head1 template_engine

Similar to engine, this specifies the template engine.  Choices almost always
include TT, but might also include Mason or other templaters depending on
what your framework supports..

=back

=head1 Other KEYWORDS

=over 4

=item literal

This keyword applies to many backends at the app level and at some other
levels.  This keyword is special, because it expects a type keyword
immediately before its values.  For example:

    literal SQL `CREATE...`;

It always instructs someone (the backend of type SQL in the example) to
directly insert the backquoted string into its output, without so much as
adjusting whitespace.

Backend types that should obey this statement are:

    SQL      - for backends of type SQL
    Location - for backends constructing apache confs or the like

The literal Location statement may also be used at the controller level.

=item no_gen

Applies to backend blocks in the config block, app blocks, controller
blocks, and method blocks.

gen_from_string enforces the app level no_gen.  If it has a true value
only a warning is printed, nothing is generated.  None of the backends
are called.

gen_from_string also enforces no_gen on entire backends, if their config
block has a true no_gen value.

The Control backend of your choice is responsible for enforcing no_gen
at the controller and method levels.

=item not_for

Applies to tables and fields (although the latter only worked for Models
at the time of this writing).

Each backend is responsible for enforcing not_for.  It should mean
that the field or table is ignored by the named backend type.  Thus

    table skip_model {
        not_for Model;
    }

should generate as normal in SQL backends, but should be completely
ignored for Models.  The same should hold for fields marked not_for.
But my SQL backends didn't do that when I wrote this, only the Models
worked.

=back

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
