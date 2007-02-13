package Bigtop::Keywords;
use strict; use warnings;

my %doc_for = (
    config     => {
        base_dir => {
            keyword    => 'base_dir',
            label      => 'Parent Dir',
            descr      => 'parent of build dir',
            type       => 'deprecated',
            sort_order  => 20000,
        },
        app_dir  => {
            keyword    => 'app_dir',
            label      => 'Build Dir',
            descr      => 'build dir. relative to parent dir',
            type       => 'deprecated',
            sort_order  => 20001,
        },
        engine   => {
            keyword    => 'engine',
            label      => 'Web Engine',
            descr      => 'mod_perl 1.3, mod_perl 2.0, CGI, etc.',
            type       => 'select',
            options    => [
                { label => 'mod_perl 1.3', value => 'MP13' },
                { label => 'mod_perl 2.0', value => 'MP20' },
                { label => 'CGI/FastCGI',  value => 'CGI'  },
            ],
            sort_order  => 10,
        },
        template_engine => {
            keyword    => 'template_engine',
            label      => 'Template Engine',
            descr      => 'Template Toolkit, Mason, etc.',
            type       => 'text',
            sort_order => 20,
        },
    },

    app        => {
        no_gen => {
            keyword  => 'no_gen',
            label    => 'No Gen',
            descr    => "Skip this app completely",
            type     => 'boolean',
            urgency  => 0,
            sort_order => 10,
        },
        location => {
            keyword  => 'location',
            label    => 'Base Location',
            descr    => 'Base Location of the app [defaults to /]'
                        . '<br />Do not use if you have a Base Controller.',
            type     => 'text',
            multiple => 0,
            urgency  => 0,
            sort_order => 20,
        },
        authors => {
            keyword    => 'authors',
            label      => 'Authors',
            descr      => 'Who to blame for the app',
            type       => 'pair',
            multiple   => 1,
            urgency    => 1,
            pair_labels => [ 'Name', 'Email Address' ],
            pair_required => 0,
            sort_order    => 30,
        },

        contact_us => {
            keyword  => 'contact_us',
            label    => 'Contact Us',
            descr    => 'How to send complaints or join the project',
            type     => 'textarea',
            multiple => 0,
            urgency  => 0,
            sort_order => 40,
        },
        email => {
            keyword  => 'email',
            label    => 'Extra Email',
            descr    => 'Where to send complaints (think mailing list)',
            multiple => 0,
            urgency  => 0,
            type       => 'deprecated',
            sort_order  => 20001,
        },
        copyright_holder => {
            keyword  => 'copyright_holder',
            label    => 'Copyright Holder',
            descr    => 'Who owns the app [defaults to 1st author]',
            type     => 'text',
            multiple => 1,
            urgency  => 0,
            sort_order => 50,
        },
        license_text => {
            keyword  => 'license_text',
            label    => 'License Text',
            descr    => 'Restrictions [defaults to Perl license]',
            type     => 'textarea',
            urgency  => 0,
            sort_order => 60,
        },
        uses => {
            keyword  => 'uses',
            label    => 'Modules Used',
            descr    => 'List of modules used by base module'
                        . '<br />Do not use if you have a Base Controller.',
            type     => 'text',
            multiple => 1,
            urgency  => 0,
            sort_order => 70,
        },
    },

    app_literal => {
        Conf => {
            keyword  => 'Conf',
            label    => 'Global Level',
            descr    => 'Place outside all gened config blocks',
            sort_order => 10,
        },
        GantryLocation => {
            keyword  => 'GantryLocation',
            label    => 'Root level config',
            descr    => 'Place in root GantryLocation',
            sort_order => 20,
        },
        PerlTop => {
            keyword  => 'PerlTop',
            label    => 'Preamble',
            descr    => 'Place at the top of the generated script(s)',
            sort_order => 30,
        },
        PerlBlock => {
            keyword  => 'PerlBlock',
            label    => 'Epilogue',
            descr    => 'Place inside Perl block',
            sort_order => 40,
        },
        HttpdConf => {
            keyword  => 'HttpdConf',
            label    => 'Apache Conf',
            descr    => 'Place outside of all generated blocks',
            sort_order => 50,
        },
        Location => {
            keyword  => 'Location',
            label    => 'Base Location',
            descr    => 'Place inside base Location block',
            sort_order => 60,
        },
        SQL => {
            keyword   => 'SQL',
            label     => 'SQL',
            descr     => 'Dumped directly into schema',
            sort_order => 70,
        },
    },

    table      => {
        no_gen => {
            keyword  => 'no_gen',
            label    => 'No Gen',
            descr    => "Skip this table completely",
            type     => 'boolean',
            sort_order => 10,
        },
        not_for => {
            keyword  => 'not_for',
            label    => 'Not For',
            descr    => 'Tell Model and/or SQL to skip this table',
            type     => 'select',
            multiple => 1,
            options  => [
                { label => 'SQL',       value => 'SQL'        },
                { label => 'Model',     value => 'Model'      },
            ],
            sort_order => 20,
        },
        data => {
            keyword    => 'data',
            label      => 'Data',
            descr      => 'What to INSERT INTO table upon initial creation',
            type       => 'pair',
            multiple   => 1,
            repeatable => 1,
            sort_order => 20000,
        },
        foreign_display => {
            keyword  => 'foreign_display',
            label    => 'Foreign Display',
            descr    => 'Pattern string for other tables: %last, %first',
            type     => 'text',
            multiple => 0,
            urgency  => 3,
            sort_order => 30,
        },
        model_base_class => {
            keyword  => 'model_base_class',
            label    => 'Inherits From',
            descr    => 'Models inherit from this [has good default]',
            type     => 'text',
            multiple => 0,
            sort_order => 40,
        },
        sequence => {
            keyword   => 'sequence',
            label     => 'Sequence',
            descr     => 'Which sequence to take default keys from',
            type      => 'text',
            multiple  => 0,
            urgency   => 1,
            sort_order => 50,
        },
    },

    field      => {
        no_gen => {
            keyword  => 'no_gen',
            label    => 'No Gen',
            descr    => "Skip this field completely",
            type     => 'boolean',
            sort_order => 10,
        },
        not_for => {
            keyword  => 'not_for',
            label    => 'Not For',
            descr    => 'Tell Model and/or SQL to skip this field',
            type     => 'select',
            multiple => 1,
            options  => [
                { label => 'SQL',       value => 'SQL'        },
                { label => 'Model',     value => 'Model'      },
            ],
            sort_order => 20,
        },
        is => {
            keyword   => 'is',
            label     => 'SQL Type Info',
            descr     => 'SQL type clause phrases, e.g.:'
                         .  "<pre>int4\nvarchar\nprimary_key\nauto</pre>",
            type      => 'text',
            multiple  => 1,
            urgency   => 10,
            quick_label => 'SQL Type',
            sort_order  => 30,
        },
        refers_to => {
            keyword       => 'refers_to',
            label         => 'Foreign Key Table',
            descr         => 'Where this foreign key points',
            type          => 'pair',
            pair_labels   => [ 'Table', 'Column' ],
            pair_required => 0,
            multiple      => 0,
            urgency       => 1,
            sort_order    => 40,
        },
        on_delete => {
            keyword  => 'on_delete',
            label    => 'On Delete Behavior',
            descr    => 'What to do when foreign key column\'s row dies',
            type     => 'text',
            multiple => 0,
            urgency   => 0,
            sort_order => 50,
        },
        on_update => {
            keyword  => 'on_update',
            label    => 'On Update Behavior',
            descr    => 'What to do when foreign key column\'s row changes',
            type     => 'text',
            multiple => 0,
            urgency   => 0,
            sort_order => 51,
        },
        label => {
            keyword  => 'label',
            label    => 'Label',
            descr    => 'Default on-screen label for field',
            type     => 'text',
            multiple => 0,
            urgency   => 5,
            quick_label => 'Label',
            sort_order => 60,
        },
        html_form_type => {
            keyword  => 'html_form_type',
            label    => 'Form Type',
            descr    => 'form type: text, textarea, select',
            type     => 'select',
            options  => [
              { label => '-- Choose One --', value => 'undefined' },
              { label => 'text',             value => 'text'      },
              { label => 'textarea',         value => 'textarea'  },
              { label => 'select',           value => 'select'    },
              { label => 'display',          value => 'display'    },
            ],
            urgency   => 5,
            sort_order => 70,
        },
        html_form_optional => {
            keyword  => 'html_form_optional',
            label    => 'Optional',
            descr    => 'May user skip this field?',
            type     => 'boolean',
            quick_label => 'Optional',
            sort_order => 80,
        },
        html_form_constraint => {
            keyword  => 'html_form_constraint',
            label    => 'Constraint',
            descr    => 'Data::FormValidator constraint, e.g.: '
                        .   '<pre>qr{^\d$}</pre>',
            type     => 'text',
            multiple => 0,
            quick_label => 'Constraint',
            sort_order  => 90,
        },
        html_form_default_value => {
            keyword     => 'html_form_default_value',
            label       => 'Default Value',
            descr       => 'Form element value when no other is available',
            type        => 'text',
            multiple    => 0,
            quick_label => 'Default',
            sort_order  => 100,
        },
        html_form_cols => {
            keyword    => 'html_form_cols',
            label      => 'Columns',
            descr      => 'cols attribute of text area',
            type       => 'text',
            field_type => 'textarea',
            multiple   => 0,
            sort_order => 110,
        },
        html_form_rows => {
            keyword    => 'html_form_rows',
            label      => 'Rows',
            descr      => 'rows attribute of text area',
            type       => 'text',
            field_type => 'textarea',
            multiple   => 0,
            sort_order => 120,
        },
        html_form_display_size => {
            keyword    => 'html_form_display_size',
            label      => 'Size',
            descr      => 'width attribute if type is text',
            type       => 'text',
            field_type => 'text',
            multiple   => 0,
            sort_order => 130,
        },
        html_form_options => {
            keyword     => 'html_form_options',
            label       => 'Options',
            descr       => 'Choices for fields of type select '
                                       .   '[ignored for refers_to fields]',
            type        => 'pair',
            field_type  => 'select',
            multiple    => 1,
            pair_labels => [ 'Label', 'Database Value' ],
            pair_required => 1,
            sort_order    => 140,
        },
        html_form_foreign => {
            keyword    => 'html_form_foreign',
            label      => 'Foreign',
            descr      => 'Display field is foreign key',
            type       => 'boolean',
            field_type => 'display',
            multiple   => 0,
            sort_order => 145,
        },
        date_select_text => {
            keyword    => 'date_select_text',
            label      => 'Date Popup Link Text',
            descr      => 'link text for date popup window',
            type       => 'text',
            field_type => 'text',
            multiple   => 0,
            refresh    => 1,
            sort_order => 150,
        },
        html_form_raw_html => {
            keyword    => 'html_form_raw_html',
            label      => 'Raw HTML',
            descr      => q!appears before this field's table row!,
            type       => 'text',
            field_type => 'text',
            multiple   => 0,
            sort_order => 160,
        },
        non_essential => {
            keyword  => 'non_essential',
            label    => 'Non-essential',
            descr    => 'Tells modeler: retrieve only when accessed',
            type     => 'boolean',
            sort_order => 170,
        },
    },

    join_table => {
        joins => {
            keyword       => 'joins',
            label         => 'Joins These',
            descr         => 'Which tables does this one join?',
            type          => 'pair',
            pair_labels   => [ 'Table', 'Table' ],
            pair_required => 1,
            multiple      => 0,
            urgency       => 10,
            sort_order    => 10,
        },
        names => {
            keyword       => 'names',
            label         => 'Name the Joins',
            descr         => 'What should I call the has many?',
            type          => 'pair',
            pair_labels   => [ 'Has Many Name', 'Has Many Name' ],
            pair_required => 1,
            multiple      => 0,
            urgency       => 0,
            sort_order    => 20,
        },
        data => {
            keyword    => 'data',
            label      => 'Data',
            descr      => 'What to INSERT INTO table upon initial creation',
            type       => 'pair',
            multiple   => 1,
            repeatable => 1,
            sort_order => 20000,
        },
    },

    controller => {
        no_gen => {
            keyword  => 'no_gen',
            label    => 'No Gen',
            descr    => "Skip this controller completely",
            type     => 'boolean',
            urgency  => 0,
            sort_order => 10,
            controller_types => {
                all => 1,
            },
        },
        location => {
            keyword  => 'location',
            label    => 'Location',
            descr    => 'Absolute Location of this controller '
                        .   '[non-base controllers must have either a '
                        .   'location or a rel_location.]',
            type     => 'text',
            multiple => 0,
            urgency  => 5,
            sort_order => 20,
            controller_types => {
                all => 1,
            },
        },
        rel_location => {
            keyword  => 'rel_location',
            label    => 'Relative Loc.',
            descr    => 'Location of this controller relative to app location'
                        .   '[non-base controllers must have either a '
                        .   'location or a rel_location.]',
            type     => 'text',
            multiple => 0,
            urgency  => 5,
            sort_order => 30,
            controller_types => {
                stub      => 1,
                AutoCRUD  => 1,
                CRUD      => 1,
                SOAP      => 1,
            },
        },
        controls_table => {
            keyword  => 'controls_table',
            label    => 'Controls Table',
            descr    => 'Table this controller manages',
            type     => 'text',
            multiple => 0,
            urgency  => 5,
            sort_order => 40,
            controller_types => {
                all => 1,
            },
        },
        gen_uses => {
            keyword  => 'gen_uses',
            label    => 'Modules Used',
            descr    => 'List of modules used gen module',
            type     => 'text',
            multiple => 1,
            sort_order => 45,
            controller_types => {
                all => 1,
            },
        },
        stub_uses => {
            keyword  => 'stub_uses',
            label    => 'Modules Used',
            descr    => 'List of modules used stub module',
            type     => 'text',
            multiple => 1,
            sort_order => 48,
            controller_types => {
                all => 1,
            },
        },
        uses => {
            keyword  => 'uses',
            label    => 'Modules Used',
            descr    => 'List of modules used by gen and stub modules',
            type     => 'text',
            multiple => 1,
            sort_order => 50,
            controller_types => {
                all => 1,
            },
        },
        text_description => {
            keyword  => 'text_description',
            label    => 'Text Descr.',
            descr    => 'Required for Gantry\'s AutoCRUD',
            type     => 'text',
            multiple => 0,
            urgency  => 3,
            sort_order => 60,
            controller_types => {
                AutoCRUD        => 1,
                base_controller => 1,
            },
        },
        page_link_label => {
            keyword  => 'page_link_label',
            label    => 'Navigation Label',
            descr    => 'Link text in navigation bar [use only '
                            . 'for navigable controllers]',
            type     => 'text',
            multiple => 0,
            urgency  => 1,
            sort_order => 70,
            controller_types => {
                all => 1,
            },
        },
        autocrud_helper => {
            keyword  => 'autocrud_helper',
            label    => 'AutoCRUDHelper',
            descr    => 'Gantry::Plugins::AutoCRUDHelper for your ORM',
            type     => 'text',
            mulitple => 0,
            urgency  => 0,
            sort_order => 80,
            controller_types => {
                AutoCRUD        => 1,
                base_controller => 1,
            },
        },
        skip_test => {
            keyword  => 'skip_test',
            label    => 'No Test',
            descr    => "Skip default page hit test of this controller",
            type     => 'boolean',
            urgency  => 0,
            sort_order => 90,
            controller_types => {
                all => 1,
            },
        },
        soap_name => {
            keyword  => 'soap_name',
            label    => 'Soap Name',
            descr    => 'Base of all WSDL names',
            type     => 'text',
            urgency  => 10,
            sort_order => 100,
            controller_types => {
                SOAP => 1,
            },
        },
        namespace_base => {
            keyword  => 'namespace_base',
            label    => 'Namespace Base',
            descr    => 'Base URL of WSDL namespace including domain',
            type     => 'text',
            urgency  => 10,
            sort_order => 110,
            controller_types => {
                SOAP => 1,
            },
        },
    },

    controller_literal => {
        Location => {
            keyword  => 'Location',
            label    => 'Controller Loc.',
            descr    => 'Place inside Location block for this controller',
            sort_order => 10,
        },
        GantryLocation => {
            keyword  => 'GantryLocation',
            label    => 'Controller Loc.',
            descr    =>
                'Place inside GantryLocation block for this controller',
            sort_order => 20,
        },
    },

    method     => {
        no_gen => {
            keyword    => 'no_gen',
            label      => 'No Gen',
            descr      => "Skip this method completely",
            type       => 'boolean',
            urgency    => 0,
            sort_order => 10,
            method_types => {
                all => 1,
            },
        },
        extra_args => {
            keyword     => 'extra_args',
            label       => 'Extra Arguments',
            descr       => 'Extra args for any method',
            type        => 'text',
            multiple    => 1,
            urgency     => 0,
            sort_order  => 20,
            method_types => {
                main_listing  => 1,
                base_links    => 1,
                links         => 1,
                AutoCRUD_form => 1,
                CRUD_form     => 1,
            },
        },
        rows => {
            keyword     => 'rows',
            label       => 'Rows per Page',
            descr       => 'How many rows should appear per listing page?',
            type        => 'text',
            multiple    => 0,
            urgency     => 3,
            sort_order  => 25,
            method_types => {
                main_listing => 1,
            },
        },
        paged_conf => {
            keyword     => 'paged_conf',
            label       => 'Conf var for rows',
            descr       => 'Take rows per page from this (conf var) accessor',
            type        => 'text',
            multiple    => 0,
            urgency     => 0,
            sort_order  => 26,
            method_types => {
                main_listing => 1,
            },
        },
        cols => {
            keyword     => 'cols',
            label       => 'Include These Fields',
            descr       => 'Fields to include in main_listing',
            type        => 'text',
            multiple    => 1,
            urgency     => 5,
            sort_order  => 30,
            method_types => {
                main_listing => 1,
            },
        },
        col_labels => {
            keyword     => 'col_labels',
            label       => 'Override Field Labels',
            descr       => 'Labels for fields on main_listing [optional '
                              .     'defaults to fields label]',
            type        => 'text',
            multiple    => 1,
            urgency     => 0,
            sort_order  => 40,
            method_types => {
                main_listing => 1,
            },
        },
        header_options => {
            keyword       => 'header_options',
            label         => 'Header Options',
            descr         => 'User actions affecting the table [like Add]',
            type          => 'pair',
            pair_labels   => [ 'Label', 'Location' ],
            pair_required => 0,
            multiple      => 1,
            urgency       => 5,
            sort_order    => 50,
            method_types => {
                main_listing => 1,
            },
        },
        row_options => {
            keyword       => 'row_options',
            label         => 'Row Options',
            descr         => 'User actions affecting rows [like Edit]',
            type          => 'pair',
            pair_required => 0,
            pair_labels   => [ 'Label', 'Location' ],
            multiple      => 1,
            urgency       => 5,
            sort_order    => 60,
            method_types => {
                main_listing => 1,
            },
        },
        title => {
            keyword     => 'title',
            label       => 'Browser Title',
            descr       => 'Browser title bar title for main_listing',
            type        => 'text',
            multiple    => 0,
            urgency     => 3,
            sort_order  => 70,
            method_types => {
                main_listing => 1,
                base_links   => 1,
            },
        },
        html_template => {
            keyword     => 'html_template',
            label       => 'Output Template',
            descr       => 'Template to use for main_listing [defaults '
                              .     'to results.tt or main.tt]',
            type        => 'text',
            multiple    => 0,
            urgency     => 0,
            sort_order  => 80,
            method_types => {
                main_listing => 1,
                base_links   => 1,
            },
        },
        limit_by => {
            keyword       => 'limit_by',
            label         => 'Limit by Foreign Key',
            descr         => 'If an arg is supplied, show only matching rows',
            type          => 'text',
            pair_required => 0,
            multiple      => 0,
            urgency       => 0,
            sort_order    => 85,
            method_types => {
                main_listing => 1,
            },
        },
        all_fields_but => {
            keyword     => 'all_fields_but',
            label       => 'Exclued These Fields',
            descr       => 'Fields to exclude from a form '
                            .  '[either all_fields_but or fields is REQUIRED]',
            type        => 'text',
            multiple    => 1,
            urgency     => 5,
            sort_order  => 90,
            method_types => {
                AutoCRUD_form => 1,
                CRUD_form     => 1,
            },
        },
        fields => {
            keyword     => 'fields',
            label       => 'Include These Fields',
            descr       => 'Fields to include on a form '
                            .  '[either all_fields_but or fields is REQUIRED]',
            type        => 'text',
            multiple    => 1,
            urgency     => 5,
            sort_order  => 100,
            method_types => {
                AutoCRUD_form => 1,
                CRUD_form     => 1,
            },
        },
        extra_keys => {
            keyword       => 'extra_keys',
            label         => 'Keys for form hash',
            descr         => 'Extra keys to put in the form method hash',
            type          => 'pair',
            pair_labels   => [ 'key', 'value' ],
            pair_required => 1,
            multiple      => 1,
            urgency       => 0,
            sort_order    => 110,
            method_types => {
                AutoCRUD_form => 1,
                CRUD_form     => 1,
            },
        },
        form_name => {
            keyword     => 'form_name',
            label       => 'Form Name',
            descr       => 'Form name [used with date selections]',
            type        => 'text',
            multiple    => 0,
            urgency     => 0,
            sort_order  => 120,
            method_types => {
                AutoCRUD_form => 1,
                CRUD_form     => 1,
            },
        },
        expects => {
            keyword       => 'expects',
            label         => 'Input Parameters',
            descr         => 'Things your SOAP method receives',
            type          => 'pair',
            pair_required => 0,
            pair_labels   => [ 'Name', 'Type' ],
            multiple      => 1,
            urgency       => 10,
            sort_order    => 130,
            method_types  => {
                SOAP => 1,
            },
        },
        returns => {
            keyword       => 'returns',
            label         => 'Output Parameters',
            descr         => 'Things your SOAP method returns',
            type          => 'pair',
            pair_required => 0,
            pair_label    => [ 'Name', 'Type' ],
            multiple      => 1,
            urgency       => 10,
            sort_order    => 140,
            method_types  => {
                SOAP => 1,
            },
        },
    },
);

sub get_docs_for {
    my $class    = shift;
    my $type     = shift;
    my @keywords = @_;

    my @retvals  = ( $type );

    foreach my $keyword ( @keywords ) {
        push @retvals, $doc_for{ $type }{ $keyword };
    }

    return @retvals;
}

1;

=head1 NAME

Bigtop::Keywords - A central place to describe all bigtop keywords

=head1 SYNOPSIS

In your backend or backend type module:

    use Bigtop::Keywords;
    # There is no need to use Bigtop::Parser since it uses you.

    BEGIN {
        Bigtop::Parser->add_valid_keywords(
            Bigtop::Keywords->get_docs_for(
                $keyword_level,
                qw( your keywords here )
            )
        );
    }

Note that this must be done in a BEGIN block.

=head1 DESCRIPTION

Since many backends need to use the same keywords, it eventually dawned
on me that a central place to describe would be a good thing.  This is
that place.  By keeping all the keyword definitions here, all backends
can share them.  This became especially helpful with the birth of tentmaker.
It wants to consistently tell users about the keywords.

If you write or modify a backend and need new keywords in the process,
define them here and send in a patch.  This will avoid name collisions
and keep the tentmaker functioning.  Read on for how to define the keywords.

=head1 DEFINING KEYWORDS

To define a new keyword, first decide at what level it will be used.
That is, does it apply inside controller blocks, table blocks, or somewhere
else.  See L<KEYWORD LEVELS> for a list of all the choices.

Once you know where your keyword should be legal, find its level among
the top level keys in the C<%docs_for> in this file.  Inside the hash for
your level add a new hash keyed by your keyword name (pick the name
carefully, changing them after release is painful).  The value for your
new hash key is itself a hash.  Here are the legal keys for the hash (all
keys are optional unless marked required):

=over 4

=item keyword

Required and must be the same as the key for the hash.  The official name
of the keyword.  The user must type this to use the keyword (or get a tool
to do it for her).

=item label

Required for tentmaker.  The name tentmaker shows its users for this keyword.
Traditionally, this is just the keyword beautified so the label for
keyword 'contact_us' is 'Contact Us'.

=item descr

tentmaker shows this next to the input box for the keyword.  Feel free
to use a bit of html in the value for descr.  For instance, when providing
examples, surround them with pre tags.

=item multiple

Indicates that the keyword can accept a list of values (or pairs of them
if its type is pair).  This only applies to types text, pair, and select.
The others ignore it.  See below for information about types.

=item pair_labels

You probably want to use this key if your keyword's type is pair.
A two element array reference with the labels to display over the two
input columns of keywords whose type is pair.  Example:

    pair_labels => [ 'Name', 'Email Address' ],

=item pair_required

Required for keywords of type pair.

Use this key for all pair keywords.  Make it true if a pair is always
required for the keyword and false if items may have only the first half
of a pair (like author pairs where the name is in the hash key position
and the optional email address is in the value position).

Look for keywords of type pair for examples.

=item options

An array reference of hashes describing the options for the keyword.  Use
this only for keywords of type select.  Example:

    options => [
        { label => 'User Sees This', value => 'internal_value' },
        { label => 'Hourly',         value => '24'             },
    ],

If you don't want a default, you should include a hash like this:

    { label => '-- Choose One --', value => 'undefined' },

The value 'undefined' is special to JavaScript.  So, tentmaker will unset
the value if you the user selects '-- Choose One --'.

=item quick_label

Only applies to field keywords.  Indicates that this keyword should appear
in the Field Quick Edit box in tentmaker.  Fields appear there in
the same order they appear in the full edit expanding box.  The order
here does not matter.  To change the order, look for add_valid_keywords
in the backends.

Quick editing does not allow pairs or multiples.  You can set a quick_label
for a multiple entry keyword, but the quick edit will only update the first
one.  If the user changes the one in the quick edit, only that one will be
preserved.  Pairs will not work in the quick edit box.

=item refresh

Only applies to field keywords.  Indicates that a change in the keyword's
value should trigger a page reload in tentmaker.  This implied by
quick_label, so you only need it for keywords that should trigger
a refresh, but should not appear in the Field Quick Edit box.

=item urgency

Indicates how useful the keyword is.  Most have urgency 0, they show
up white on the screen.  tentmaker currently understands these urgency values:

  value  screen color  implied meaning
  -----------------------------------------------------------------
    10   red           required by someone
     5   yellow        this or a related keyword is likely required
     3   green         many people use this regularly
     1   blue-green    many people use this at least occasionally
     0   white         less frequently used

Note that only values from the above list are understood by tentmaker.
If you use other values, they will be treated as zero.

=item method_types

This tells tentmaker which method types understand a keyword.  It is
a hash.  They keys are individual method types.  The values are 1.
There is one special key 'all'.  If it has a true value, then the keyword
is available to all methods regardless of type.

=item field_type

Not yet used.  Meant to tell tentmaker that a field keyword only applies
to a certain html_form_type.

=item type

Essentially the tentmaker html form element for the keyword.
Note that literal keywords do not need to set this key (and if they do,
it will be ignored).  They always get a textarea for their input.
For other keyword levels choose from these input types (in order by
utility):

=over 4

=item text

This is the most common type.
It tells tentmaker to use a text input box for the keyword.

=item boolean

Indicates that the value is either 1 or 0 and tells tentmaker to use
a checkbox for the keyword.

=item pair

Indicates that the keyword admits either single values or pairs.
A pair is two things separated by =>, like

    name => `email@example.com`

You want to use the pair_labels and pair_required keys if you use this
type, trust me.

=item textarea

Indicates that typical values for this keyword are large text blocks,
so tentmaker should use a textarea for their input.

=item select

Indicates that only certain values are legal so tentmaker users should
pick them from a list.  You must use the options key with this type.
You might also want to use the multiple key.

=item deprecated

Tells tentmaker not to show this keyword, which is usually an archaic
spelling for a keyword.

=back

=back

=head2 KEYWORD LEVELS

There are several levels in the parse tree where keywords may appear.
These are the levels:

=over 4

=item config

Keywords in the bigtop level config block (where the backends are defined).

=item app

Keywords at the top level of the bigtop app block.

=item app_literal

The legal names of literal statements at the bigtop app block level.

=item table

Keywords at the top level of table blocks.

=item field

Keywords in field blocks (inside table blocks).

=item controller

Keywords at the top level of controller blocks.

=item controller_literal

The legal names of literal statements at the controller block level.

=item method

Keywords in method blocks (inside controller blocks).

=back

There are no other valid keyword locations in the current grammar.  Adding
new levels will require substantial change to the grammar, the parser,
and all the backends.  Thus, such changes are extremely unlikely (though
some are in the back of my mind).

=head1 METHODS

There is only one method defined in this module.  Use it as shown in
the SYNOPSIS above.

=over 4

=item get_docs_for

Parameters:

    keyword_level
    list of keywords

Returns:

an array whose first element is the keyword_level and whose remaining
elements are keyword hashes.
This return is designed for direct passing to the add_valid_keywords
method of Bigtop::Parser

=back

=head1 AUTHOR

Phil Crow E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2006 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

