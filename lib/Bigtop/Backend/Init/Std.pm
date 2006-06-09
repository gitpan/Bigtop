package Bigtop::Backend::Init::Std;
use strict; use warnings;

use Cwd;        # for use in manifest updates
use ExtUtils::Manifest;
use File::Find;
use File::Spec;
use File::Basename;
use File::Copy;
use Inline;

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'app',
            qw(
                authors
                email
                contact_us
                copyright_holder
                license_text
            ),
        )
    );
}

sub what_do_you_make {
    return [
        [ 'Build.PL'         => 'Module::Build script'                       ],
        [ 'Changes'          => 'Almost empty Changes file'                  ],
        [ 'README'           => 'Boilerplate README'                         ],
        [ 'lib/'             => 'lib dir used by Control and Model backends' ],
        [ 't/'               => 'testing dir used by Control backend'        ],
        [ 'docs/name.bigtop' => 'Copy of your bigtop file [create mode only]'],
    ];
}

sub backend_block_keywords {
    my @trailer = ( 'backward_boolean', '', '', 'no_gen' );
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },

        { keyword => 'Build.PL',
          label   => 'Skip Build.PL',
          descr   => 'Do not regen Build.PL file',
          type    => 'controlled_boolean',
          default => undef,
          false   => undef,
          true    => 'no_gen' },

        { keyword => 'Changes',
          label   => 'Skip Changes',
          descr   => 'Do not regen Changes file',
          type    => 'controlled_boolean',
          default => undef,
          false   => undef,
          true    => 'no_gen' },

        { keyword => 'README',
          label   => 'Skip README',
          descr   => 'Do not regen README file',
          type    => 'controlled_boolean',
          default => undef,
          false   => undef,
          true    => 'no_gen' },

        { keyword => 'MANIFEST',
          label   => 'Skip MANIFEST',
          descr   => 'Do not regen MANIFEST file',
          type    => 'controlled_boolean',
          default => undef,
          false   => undef,
          true    => 'no_gen' },

        { keyword => 'MANIFEST.SKIP',
          label   => 'Skip MANIFEST.SKIP',
          descr   => 'Do not regen MANIFEST.SKIP file',
          type    => 'controlled_boolean',
          default => undef,
          false   => undef,
          true    => 'no_gen' },
    ];
}

our $template_is_setup     = 0;
our $default_template_text = <<'EO_Template';
[% BLOCK Changes %]
Revision history for Perl web application [% app_name %]

0.01  [% time_stamp %]
    - original version created with bigtop
[% END %]

[% BLOCK README %]
[% app_name %] version 0.01
===========================

Place description here.

INSTALLATION

To install this module type:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

DEPENDENCIES

This module requires these other modules and libraries:

COPYRIGHT AND LICENCE

Put the correct copyright and license info here.

Copyright (c) [% year %] by [% copyright_holder %]

[% IF license_text %]
[% license_text %]

[% ELSE %]
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.
[% END %]
[% END %]

[% BLOCK MANIFEST_SKIP %]
# Avoid version control files.
\bRCS\b
\bCVS\b
,v$
\B\.svn\b

# Avoid Makemaker generated and utility files.
\bMakefile$
\bblib
\bMakeMaker-\d
\bpm_to_blib$
\bblibdirs$
# ^MANIFEST\.SKIP$

# Avoid Module::Build generated and utility files.
\bBuild$
\b_build

# Avoid temp and backup files.
~$
\.tmp$
\.old$
\.bak$
\#$
\b\.#
\.swp$

# Avoid inline's dropings
_Inline

[% END %]

[% BLOCK Build_PL %]
[%# app_name %]
use strict;
use Module::Build;
use File::Find;

print( '*' x 80, "\n" );
print( "[% app_name %]\n" );
print( '*' x 80, "\n" );

my $subclass = Module::Build->subclass(
    class 	=> 'My::Builder',
	code 	=> &_custom_code(),
);

# collect web files 
my( %web_dirs, @web_dirs );

find( \&wanted, 'html' );
	
sub wanted {

	my $dir = $File::Find::dir;

    # XXX unix specific directory work
	$dir =~ s![^/]*/!!;  # remove extraneous leading slashes

	return if $dir =~ /\.svn/;

	++$web_dirs{ $dir };
}

foreach my $k ( sort { $a cmp $b } keys %web_dirs ) {
	print "[web dir] $k\n";

    # XXX unix specific dir separator
	push( @web_dirs, ( $k . '/*.*' ) );
}

my $build = $subclass->new(
    web_files => \@web_dirs, 
	build_web_directory => 'html',
	install_web_directories => 	{ 
        # XXX unix specific paths
		'dev' 	=> '/home/httpd/html/[% app_dash_name %]',
		'qual'	=> '/home/httpd/html/[% app_dash_name %]',
		'prod' 	=> '/home/httpd/html/[% app_dash_name %]',
	},
	create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => '[% app_name %]',
    requires           => {
        'perl'   	=> '5',
		'Gantry'	=> '3.0',
		'HTML::Prototype' => '0',
    },
    create_makefile_pl 	=> 'passthrough',

    # XXX unix specific paths
    script_files 		=> [ glob('bin/*') ],
    'recursive_test_files' => 1,

    # XXX unix specific paths
    install_path        => { script => '/usr/local/bin' },
);

$build->create_build_script;

sub _custom_code {

	return( q{

	use File::Copy::Recursive qw( dircopy );
 
	sub ACTION_code {
		my $self = shift;
		$self->SUPER::ACTION_code();

		$self->add_build_element( 'web' );
		
		$self->process_web_files( 'web' );

	}

	sub ACTION_install {
        my $self = shift;
	 	$self->SUPER::ACTION_install();
		my $p = $self->{properties};		
		
		print "\n";
		print "-" x 80;
		print "Web Directory\n";
		print "-" x 80;
		print "\n";
		
		my $DEF_TMPL_DIR = $p->{install_web_directory};
		my $prompt;
		my $count = 0;
		my ( %dir_hash, @choices );
		
		foreach my $k ( sort{ $a cmp $b }
			keys %{ $p->{install_web_directories} } ) {
				
			$prompt .= (
				sprintf( "%-7s: ", $k )
				. $p->{install_web_directories}{$k} . "\n" );
				
			push( @choices, $k );
		}

		$prompt .= "Web Directory [" . join( ',', @choices ) . "]?";
		
		my $choice = $self->prompt( $prompt );
		
		my $tmpl_dir;
        # XXX unix specific slash test
		if ( $choice =~ /\// ) {
			$tmpl_dir = $choice;
		}
		elsif ( ! defined $p->{install_web_directories}{$choice} ) {
			$tmpl_dir = '__skip__';
		}
		else {
			$tmpl_dir = $p->{install_web_directories}{$choice}
		}
		
        # XXX unix specific slash cleanup
		$tmpl_dir =~ s/\/$//g;
			
		if( $tmpl_dir && $tmpl_dir ne '__skip__' ) {
			
			if ( ! -d $tmpl_dir ) {
				my $create = $self->prompt(  
					"Directory doesn't exist. Create [yes]?"
				);
				exit if $create =~ /^n/i; 
			}
			
			eval {	
				File::Path::mkpath( $tmpl_dir );
			};
			if ( $@ ) {
				print "Error: unable to create directory $tmpl_dir\n";
				$@ =~ s/ at .+?$//;
				die( "$@\n" );
			}
			
			my $blib_tmpl_dir = File::Spec->catdir(
				$self->blib, 'web', $p->{build_web_directory} 
			);	
			
			my $num;
			eval {
				$num = dircopy($blib_tmpl_dir, $tmpl_dir);
			};
			if ( $@ ) {
				print "Error coping templates:\n";
				print $@ . "\n";
			}
			else {
				print "Web content copied: $num\n";
			}
		}
		else {
			print "SKIPPING WEB CONTENT INSTALL\n";
		}
		print "-" x 80;
		print "\n";

	} # end ACTION_install

	sub process_web_files {
  		my $self = shift;
  		my $files = $self->find_web_files;
  		return unless @$files;
		
  		my $tmpl_dir = File::Spec->catdir($self->blib, 'web');
  		File::Path::mkpath( $tmpl_dir );
		
  		foreach my $file (@$files) {
			my $result = $self->copy_if_modified($file, $tmpl_dir);
		}
	}

	sub find_web_files {
  		my $self = shift;
  		my $p = $self->{properties};
		my $b_tmpl_dir = $p->{build_web_directory};
		$b_tmpl_dir =~ s/\/$//g;

  		if (my $files = $p->{web_files}) {
    		if (  UNIVERSAL::isa($files, 'HASH') ) {
				my @files = [keys %$files];
				return( \@files );
			}
			
			my @files;
			foreach my $glob ( @$files ) {
				$glob = "$b_tmpl_dir/$glob";
				push( @files, glob( $glob ) );
			} 		
			return( \@files );
  		} 
	}

	sub web_files {
 	 	my $self = shift;
  		for ($self->{properties}{web_files}) {
			$_ = shift if @_;
    		return unless $_;
			
    		# Always coerce into a hash
    		return $_ if UNIVERSAL::isa($_, 'HASH');
    		return $_ = {$_ => 1} unless ref();
    		return { map {$_,1} @$_ };
  		}
	}
	
	} ); # end return

} # end _custom_code
[% END %]
EO_Template

sub setup_template {
    my $class         = shift;
    my $template_text = shift || $default_template_text;

    return if ( $template_is_setup );

    Inline->bind(
        TT                  => $template_text,
        PRE_CHOMP           => 0,
        POST_CHOMP          => 0,
        TRIM_LEADING_SPACE  => 1,
        TRIM_TRAILING_SPACE => 0,
    );

    $template_is_setup = 1;
}

sub gen_Init {
    my $class       = shift;
    my $build_dir   = shift;
    my $tree        = shift;
    my $bigtop_file = shift;

    # build dirs: lib, t
    my $test_dir     = File::Spec->catdir( $build_dir, 't' );
    my $lib_dir      = File::Spec->catdir( $build_dir, 'lib' );
    mkdir $test_dir;
    mkdir $lib_dir;

    # build flat files
    foreach my $simple_file
                    qw(
                        Changes
                        MANIFEST.SKIP
                        README
                        Build.PL
                    )
    {
        next if ( defined $tree->{configuration}{Init}{$simple_file}
                    and
                  $tree->{configuration}{Init}{$simple_file} eq 'no_gen'
                );
        $class->init_simple_file( $build_dir, $tree, $simple_file );
    }

    # copy the bigtop file to its new home
    if ( defined $bigtop_file ) {
        my $docs_dir        = File::Spec->catdir( $build_dir, 'docs' );
        mkdir $docs_dir;

        my $bigtop_basename = File::Basename::basename( $bigtop_file );
        my $bigtop_copy
                = File::Spec->catfile( $docs_dir, $bigtop_basename );
        File::Copy::copy( $bigtop_file, $bigtop_copy );
    }

    # build the MANIFEST
    unless ( defined $tree->{configuration}{Init}{MANIFEST}
                and
             $tree->{configuration}{Init}{MANIFEST} eq 'no_gen' )
    {
        my $original_dir = getcwd();
        chdir $build_dir;

        $ExtUtils::Manifest::Verbose = 0;
        ExtUtils::Manifest::mkmanifest();

        chdir $original_dir;
    }
}

sub init_simple_file {
    my $class        = shift;
    my $build_dir    = shift;
    my $tree         = shift;
    my $file_base    = shift;

    # where does this belong?
    my $file_name    = File::Spec->catfile( $build_dir, $file_base );
    my $app_name     = $tree->get_appname();
    my $app_dash_name= $app_name;
    $app_dash_name   =~ s/::/-/g;

    # get the time
    my $right_now = scalar localtime;
    my $year      = ( localtime )[5];
    $year        += 1900;

    # who owns this?
    my $statements       = $tree->{application}{lookup}{app_statements};
    my $copyright_holder;
    my $license_text;
    
    if ( defined $statements->{copyright_holder} ) {
        $copyright_holder = $statements->{copyright_holder}[0];
    }
    else {
        $copyright_holder = $statements->{authors}[0];
    }

    if ( defined $statements->{license_text} ) {
        $license_text = $statements->{license_text}[0];
    }

    # what Inline::TT sub are we calling?
    my $block_sub = "$class\::$file_base";
    $block_sub    =~ s/\./_/g;

    # open wide
    my $SIMPLE_FILE;
    unless ( open $SIMPLE_FILE, '>', $file_name ) {
        warn "Couldn't write $file_name: $!\n";
        return;
    }

    # make and print file
    {
        no strict 'refs';
        print $SIMPLE_FILE $block_sub->( {
            time_stamp       => $right_now,
            app_name         => $app_name,
            app_dash_name    => $app_dash_name,
            copyright_holder => $copyright_holder,
            year             => $year,
            license_text     => $license_text,
        } );
    }

    # all done
    close $SIMPLE_FILE or warn "Problem closing $file_name: $!\n";
}

1;

__END__

=head1 NAME

Bigtop::Backend::Init::Std - Bigtop backend which works sort of like h2xs

=head1 SYNOPSIS

If your bigtop file looks like this:

    config {
        build_dir `/home/yourname`;
        app_dir   `appsubdir`;
        Init Std {}
    }
    app App::Name {
    }

when you type

    bigtop --create your.bigtop Init

or

    bigtop --create your.bigtop all

this module will generate the build directory as

    /home/yourname/appsubdir

Then it will make subdirectories: t, lib, and docs.  Then it will make
files: Changes, MANIFEST, MANIFEST.SKIP, README, and Build.PL. 
Finally, it will copy your.bigtop into the docs dir of under appsubdir.

As with any backend, you can include C<no_gen 1;> in its config block:

    config {
        Init Std { no_gen 1; }
    }

Then, no files will be generated.  But, you can also exclude indiviual
files it would build.  Simply list the file name as a keyword and
give the value no_gen:

    config {
        Init Std {
            MANIFEST no_gen;
            Changes  no_gen;
        }
    }

If you are in create mode and your config does not include app_dir, one
will be formed from the app name, in the manner of h2xs.  So, in the above
example it would be

    /home/yourname/App-Name

Outside of create mode, the current directory is used for building, if
it looks like a plausible build directory (it has a Build.PL, etc).  In
that case, having a base_dir and/or app_dir in your config will result
in warning(s) that they are being ignored.

=head1 KEYWORDS

This module registers app level keywords: authors, contact_us,
copyright_holder, license_text, and the now deprecated email (which is a
synonymn for contact_us).  These are also regiersted by Bigtop::Control and
they have the same meaning there.

It actually pays no attention to the rest of the app section of the
bigtop input, except to build the default app_dir from the app_name.

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
