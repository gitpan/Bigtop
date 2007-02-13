use strict;

use Test::More tests => 3;

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
            'pos' => [ { table => 'job', col => 1 } ],
            'res' => [ { table => 'pos', col => 1 } ],
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
# specifying some columns for one table
#--------------------------------------------------------------------

$struct = $style->get_db_layout( 'job(ident,descr)' );

$correct_struct = {
    joiners => [],
    new_tables => [],
    all_tables => { job => 1 },
    foreigners => {},
    columns => {
        job => [
            { name => 'id',
              types => [ 'int4', 'primary_key', 'auto'     ], },
            { name => 'ident', types => [ 'varchar' ] },
            { name => 'descr', types => [ 'varchar' ] },
            { name => 'created',     types => [ 'datetime' ], },
            { name => 'modified',    types => [ 'datetime' ], },
        ],
    },
};

is_deeply( $struct, $correct_struct, 'one table with columns' );

#--------------------------------------------------------------------
# specifying some columns
#--------------------------------------------------------------------

$struct = $style->get_db_layout(
        '  job(ident,descr)<->skill pos->job '
            .   'res(id:integer:pk:auto,name=Phil,+body:text)->pos ',
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
        'pos' => [ { table => 'job', col => 1 } ],
        'res' => [ { table => 'pos', col => 1 } ]
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
            { name => 'name', types => [ 'varchar'  ], default => 'Phil' },
            { name => 'body', types => [ 'text'     ], optional => 1 },
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

is_deeply( $struct, $correct_struct, 'ascii art /w full column info' );

