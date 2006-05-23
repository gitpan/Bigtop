package Bigtop::Keywords;
use strict; use warnings;

my %doc_for = (
    config     => {
        base_dir => {
            keyword    => 'base_dir',
            label      => 'Parent Dir',
            descr      => 'parent of build dir',
            type       => 'deprecated',
        },
        app_dir  => {
            keyword    => 'app_dir',
            label      => 'Build Dir',
            descr      => 'build dir. relative to parent dir',
            type       => 'deprecated',
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
            ]
        },
        template_engine => {
            keyword    => 'template_engine',
            label      => 'Template Engine',
            descr      => 'Template Toolkit, Mason, etc.',
            type       => 'text'
        },
    },

    app        => {
        no_gen => {
            keyword  => 'no_gen',
            label    => 'No Gen',
            descr    => "Skip this app completely",
            type     => 'boolean',
            urgency  => 0,
        },
        location => {
            keyword  => 'location',
            label    => 'Base Location',
            descr    => 'Base Location of the app [defaults to /]',
            type     => 'text',
            multiple => 0,
            urgency  => 0,
        },
        authors => {
            keyword  => 'authors',
            label    => 'Authors',
            descr    => 'Who to blame for the app',
            type     => 'text',
            multiple => 1,
            urgency  => 10,
        },
        email => {
            keyword  => 'email',
            label    => 'Email',
            descr    => 'Where to send complaints',
            type     => 'text',
            multiple => 0,
            urgency  => 0,
        },
        copyright_holder => {
            keyword  => 'copyright_holder',
            label    => 'Copyright Holder',
            descr    => 'Who owns the app [defaults to 1st author]',
            type     => 'text',
            multiple => 1,
            urgency  => 0,
        },
        license_text => {
            keyword  => 'license_text',
            label    => 'License Text',
            descr    => 'Restrictions [defaults to Perl license]',
            type     => 'textarea',
            urgency  => 0,
        },
        uses => {
            keyword  => 'uses',
            label    => 'Modules Used',
            descr    => 'List of modules used by base module',
            type     => 'text',
            multiple => 1,
            urgency  => 0,
        },
    },

    app_literal => {
        Conf => {
            keyword  => 'Conf',
            label    => 'Global Level',
            descr    => 'Place outside all gened config blocks',
        },
        GantryLocation => {
            keyword  => 'GantryLocation',
            label    => 'Root level config',
            descr    => 'Place in root GantryLocation',
        },
        PerlTop => {
            keyword  => 'PerlTop',
            label    => 'Preamble',
            descr    => 'Place at the top of the generated script(s)',
        },
        HttpdConf => {
            keyword  => 'HttpdConf',
            label    => 'Apache Conf',
            descr    => 'Place outside of all generated blocks',
        },
        Location => {
            keyword  => 'Location',
            label    => 'Base Location',
            descr    => 'Place inside base Location block',
        },
        PerlBlock => {
            keyword  => 'PerlBlock',
            label    => 'Epilogue',
            descr    => 'Place inside Perl block',
        },
        SQL => {
            keyword   => 'SQL',
            label     => 'SQL',
            descr     => 'Dumped directly into schema',
        },
    },

    table      => {
        no_gen => {
            keyword  => 'no_gen',
            label    => 'No Gen',
            descr    => "Skip this table completely",
            type     => 'boolean',
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
        },
        sequence => {
            keyword   => 'sequence',
            label     => 'Sequence',
            descr     => 'Which sequence to take default keys from',
            type      => 'text',
            multiple  => 0,
            urgency   => 5,
        },
        data => {
            keyword    => 'data',
            label      => 'Data',
            descr      => 'What to INSERT INTO table upon initial creation',
            type       => 'pair',
            multiple   => 1,
            repeatable => 1,
        },
        foreign_display => {
            keyword  => 'foreign_display',
            label    => 'Foreign Display',
            descr    => 'Pattern string for other tables: %last, %first',
            type     => 'text',
            multiple => 0,
            urgency  => 3,
        },
        model_base_class => {
            keyword  => 'model_base_class',
            label    => 'Inherits From',
            descr    => 'Models inherit from this [has good default]',
            type     => 'text',
            multiple => 0,
        },
    },

    field      => {
        no_gen => {
            keyword  => 'no_gen',
            label    => 'No Gen',
            descr    => "Skip this method completely",
            type     => 'boolean',
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
        },
        is => {
            keyword   => 'is',
            label     => 'SQL Type Info',
            descr     => 'SQL type clause phrases, e.g.:'
                         .  "<pre>int4\nvarchar\nprimary_key\nauto</pre>",
            type      => 'text',
            multiple  => 1,
            urgency   => 10,
        },
        refers_to => {
            keyword   => 'refers_to',
            label     => 'Foreign Key Table',
            descr     => 'Table this foreign key points to',
            type      => 'text',
            multiple  => 0,
            urgency   => 1,
        },
        label => {
            keyword  => 'label',
            label    => 'Label',
            descr    => 'Default on-screen label for field',
            type     => 'text',
            multiple => 0,
            urgency   => 5,
        },
        non_essential => {
             keyword  => 'non_essential',
             label    => 'Non-essential',
             descr    => 'Tells modeler: retrieve only when accessed',
             type     => 'boolean',
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
            ],
            urgency   => 5,
        },
        html_form_constraint => {
            keyword  => 'html_form_constraint',
            label    => 'Constraint',
            descr    => 'Data::FormValidator constraint, e.g.: '
                        .   '<pre>qr{^\d$}</pre>',
            type     => 'text',
            multiple => 0,
        },
        html_form_optional => {
            keyword  => 'html_form_optional',
            label    => 'Optional',
            descr    => 'May user skip this field?',
            type     => 'boolean',
        },
        html_form_cols => {
            keyword    => 'html_form_cols',
            label      => 'Columns',
            descr      => 'cols attribute of text area',
            type       => 'text',
            field_type => 'textarea',
            multiple   => 0,
        },
        html_form_rows => {
            keyword    => 'html_form_rows',
            label      => 'Rows',
            descr      => 'rows attribute of text area',
            type       => 'text',
            field_type => 'textarea',
            multiple   => 0,
        },
        html_form_display_size => {
            keyword    => 'html_form_display_size',
            label      => 'Size',
            descr      => 'width attribute if type is text',
            type       => 'text',
            field_type => 'text',
            multiple   => 0,
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
        },

        date_select_text => {
            keyword    => 'date_select_text',
            label      => 'Date Popup Link Text',
            descr      => 'link text for date popup window',
            type       => 'text',
            field_type => 'text',
            multiple   => 0,
        },
    },

    controller => {
        no_gen => {
            keyword  => 'no_gen',
            label    => 'No Gen',
            descr    => "Skip this controller completely",
            type     => 'boolean',
            urgency  => 0,
        },
        location => {
            keyword  => 'location',
            label    => 'Location',
            descr    => 'Absolute Location of this controller '
                        .   '[You must choose either a location or '
                        .   'a rel_location.]',
            type     => 'text',
            multiple => 0,
            urgency  => 5,
        },
        rel_location => {
            keyword  => 'rel_location',
            label    => 'Relative Loc.',
            descr    => 'Location of this controller relative to app location'
                        .   '[You must choose either a location or '
                        .   'a rel_location.]',
            type     => 'text',
            multiple => 0,
            urgency  => 5,
        },
        controls_table => {
            keyword  => 'controls_table',
            label    => 'Controls Table',
            descr    => 'Table this controller manages [REQUIRED]',
            type     => 'text',
            multiple => 0,
            urgency  => 10,
        },
        uses => {
            keyword  => 'uses',
            label    => 'Modules Used',
            descr    => 'List of modules used by this controller',
            type     => 'text',
            multiple => 1,
        },
        text_description => {
            keyword  => 'text_description',
            label    => 'Text Descr.',
            descr    => 'Required for Gantry\'s AutoCRUD',
            type     => 'text',
            multiple => 0,
            urgency  => 3,
        },
        page_link_label => {
            keyword  => 'page_link_label',
            label    => 'Navigation Label',
            descr    => 'Link text in navigation bar [use only '
                            . 'for navigable controllers]',
            type     => 'text',
            multiple => 0,
            urgency  => 1,
        },
        autocrud_helper => {
            keyword  => 'autocrud_helper',
            label    => 'AutoCRUDHelper',
            descr    => 'Gantry::Plugins::AutoCRUDHelper for your ORM',
            type     => 'text',
            mulitple => 0,
            urgency  => 0,
        },
    },

    controller_literal => {
        Location => {
            keyword  => 'Location',
            label    => 'Controller Loc.',
            descr    => 'Place inside Location block for this controller',
        },
        GantryLocation => {
            keyword  => 'GantryLocation',
            label    => 'Controller Loc.',
            descr    => 'Place inside GantryLocation block for this controller'
        },
    },

    method     => {
        no_gen => {
            keyword    => 'no_gen',
            label      => 'No Gen',
            descr      => "Skip this method completely",
            type       => 'boolean',
            applies_to => 'All',
            urgency    => 0,
        },
        cols => {
            keyword     => 'cols',
            label       => 'Include These Fields',
            descr       => 'Fields to include in main_listing',
            type        => 'text',
            applies_to  => 'main_listing',
            multiple    => 1,
            urgency     => 5,
        },
        col_labels => {
            keyword     => 'col_labels',
            label       => 'Override Field Labels',
            descr       => 'Labels for fields on main_listing [optional '
                              .     'defaults to fields label]',
            type        => 'text',
            applies_to  => 'main_listing',
            multiple    => 1,
            urgency     => 0,
        },
        extra_args => {
            keyword     => 'extra_args',
            label       => 'Extra Arguments',
            descr       => 'Extra args for any method',
            type        => 'text',
            applies_to  => 'All',
            multiple    => 1,
            urgency     => 0,
        },
        extra_keys => {
            keyword     => 'extra_keys',
            label       => 'Keys for form hash',
            descr       => 'Extra keys to put in the form method hash',
            type        => 'text',
            applies_to  => 'forms',
            multiple    => 1,
            urgency     => 0,
        },
        all_fields_but => {
            keyword     => 'all_fields_but',
            label       => 'Exclued These Fields',
            descr       => 'Fields to exclude from a form '
                            .  '[either all_fields_but or fields is REQUIRED]',
            type        => 'text',
            applies_to  => 'forms',
            multiple    => 1,
            urgency     => 5,
        },
        fields => {
            keyword     => 'fields',
            label       => 'Include These Fields',
            descr       => 'Fields to include on a form '
                            .  '[either all_fields_but or fields is REQUIRED]',
            type        => 'text',
            applies_to  => 'forms',
            multiple    => 1,
            urgency     => 5,
        },
        form_name => {
            keyword     => 'form_name',
            label       => 'Form Name',
            descr       => 'Form name [used with date selections]',
            type        => 'text',
            applies_to  => 'forms',
            multiple    => 0,
            urgency     => 0,
        },
        header_options => {
            keyword     => 'header_options',
            label       => 'Header Options',
            descr       => 'User actions affecting the table [like Add]',
#            type        => 'text_or_pair',
            type        => 'text',
            applies_to  => 'main_listing',
            multiple    => 1,
            urgency     => 5,
        },
        html_template => {
            keyword     => 'html_template',
            label       => 'Output Template',
            descr       => 'Template to use for main_listing [defaults '
                              .     'to results.tt]',
            type        => 'text',
            applies_to  => 'main_listing',
            multiple    => 0,
            urgency     => 0,
        },
        row_options => {
            keyword     => 'row_options',
            label       => 'Row Options',
            descr       => 'User actions affecting rows [like Edit]',
#            type        => 'text_or_pair',
            type        => 'text',
            applies_to  => 'main_listing',
            multiple    => 1,
            urgency     => 5,
        },
        title => {
            keyword     => 'title',
            label       => 'Browser Title',
            descr       => 'Browser title bar title for main_listing',
            type        => 'text',
            applies_to  => 'main_listing',
            multiple    => 0,
            urgency     => 3,
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
