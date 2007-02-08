use strict;

use Test::More tests => 2;

use Bigtop::ScriptHelp::Style;

my $style = Bigtop::ScriptHelp::Style->get_style( 'Original' );

#--------------------------------------------------------------------
# simple test of original features
#--------------------------------------------------------------------

my $struct = $style->get_db_layout(
        '  job<->skill pos->job res->pos stray ',
        { pos => 1 }
);

my $correct_struct = {
        'joiners' => [ [ 'job', 'skill' ] ],
        'all_tables' => {
            'skill' => 1,
            'pos' => 1,
            'res' => 1,
            'job' => 1,
            'stray' => 1,
        },
        'new_tables' => [ 'job', 'skill', 'res', 'stray' ],
        'foreigners' => {
            'pos' => [ 'job' ],
            'res' => [ 'pos' ],
        },
        'columns' => {
            'job'   => [
                { name => 'id',
                  types => [ 'int4', 'primary_key', 'auto'     ], },
                { name => 'ident',       types => [ 'varchar'  ], },
                { name => 'description', types => [ 'varchar'  ], },
                { name => 'created',     types => [ 'datetime' ], },
                { name => 'modified',    types => [ 'datetime' ], },
            ],
            'skill' => [
                { name => 'id',
                  types => [ 'int4', 'primary_key', 'auto'     ], },
                { name => 'ident',       types => [ 'varchar'  ], },
                { name => 'description', types => [ 'varchar'  ], },
                { name => 'created',     types => [ 'datetime' ], },
                { name => 'modified',    types => [ 'datetime' ], },
            ],
            'res'   => [
                { name => 'id',
                  types => [ 'int4', 'primary_key', 'auto'     ], },
                { name => 'ident',       types => [ 'varchar'  ], },
                { name => 'description', types => [ 'varchar'  ], },
                { name => 'created',     types => [ 'datetime' ], },
                { name => 'modified',    types => [ 'datetime' ], },
            ],
            'stray' => [
                { name => 'id',
                  types => [ 'int4', 'primary_key', 'auto'     ], },
                { name => 'ident',       types => [ 'varchar'  ], },
                { name => 'description', types => [ 'varchar'  ], },
                { name => 'created',     types => [ 'datetime' ], },
                { name => 'modified',    types => [ 'datetime' ], },
            ],
        },
};

is_deeply( $struct, $correct_struct, 'original ascii art' );

#--------------------------------------------------------------------
# specifying some columns
#--------------------------------------------------------------------

$struct = $style->get_db_layout(
        '  job(ident,descr)<->skill pos->job '
            .   'res(id:integer:pk:auto,name,body:text)->pos ',
        { pos => 1 }
);

$correct_struct = {
    'joiners' => [ [ 'job', 'skill' ] ],
    'all_tables' => {
        'skill' => 1,
        'pos' => 1,
        'res' => 1,
        'job' => 1
    },
    'new_tables' => [ 'job', 'skill', 'res' ],
    'foreigners' => {
        'pos' => [ 'job' ],
        'res' => [ 'pos' ]
    },
    'columns' => {
        'skill' => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'ident',       types => [ 'varchar'  ], },
            { name => 'description', types => [ 'varchar'  ], },
            { name => 'created',     types => [ 'datetime' ], },
            { name => 'modified',    types => [ 'datetime' ], },
        ],
        'res'   => [
            { name => 'id',
              types => [ 'integer', 'pk', 'auto'    ], },
            { name => 'name', types => [ 'varchar'  ], },
            { name => 'body', types => [ 'text'     ], },
        ],
        'job'   => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'ident',       types => [ 'varchar'  ], },
            { name => 'descr',       types => [ 'varchar'  ], },
            { name => 'created',     types => [ 'datetime' ], },
            { name => 'modified',    types => [ 'datetime' ], },
        ],
    }
};

is_deeply( $struct, $correct_struct, 'ascii art /w column names' );

