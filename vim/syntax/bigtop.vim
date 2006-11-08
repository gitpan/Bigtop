" Vim syntax file
" Language:    Bigtop (a language for describing database backed web apps)
" Maintaner:   Phil Crow <philcrow2000@yahoo.com>
" Last Change: Sat Nov  5 09:15:53 CST 2005
" Filenames:   *.bigtop
"

if version < 600
    syntax clear
else
    if exists("b:current_syntax")
        finish
    endif
endif

syn case match

syn match  bigtopComment /^#.*/
syn region bigtopString start=+`+ end=+`+

syn keyword bigtopBlocks block config app table field controller method sequence

syn keyword bigtopEngines        MP13 MP20 TT
syn keyword bigtopBackendTypes   Init SQL Conf CGI HttpdConf Control Model SiteLook
syn keyword bigtopBackends       Std SQLite MySQL Postgres General Gantry GantryDBIxClass GantryCDBI GantryDefault
syn keyword bigtopValues         no_gen no_accessor fast_cgi instance conffile with_server server_port gen_root flex_db full_use skip_config dbix model_base_class gantry_wrapper

syn keyword bigtopConfigKeywords base_dir app_dir conf_instance engine template_engine
syn keyword bigtopAppKeywords    location authors email copyright_holder license_text
syn keyword bigtopTableKeywords  sequence foreign_display data
syn keyword bigtopFieldKeywords  is refers_to non_essential label html_form_type html_form_default_value html_form_optional html_form_options html_form_rows html_form_cols date_select_text html_form_constraint
syn keyword bigtopFieldValues    text textarea select
syn keyword bigtopSQLKeywords    int4 varchar text boolean int primary_key assign_by_sequence auto
syn keyword bigtopControlKeywords controls_table location rel_location uses text_description page_link_label
syn keyword bigtopMethodTypes    main_listing stub AutoCRUD_form
syn keyword bigtopMethodKeywords extra_args title html_template cols header_options row_options form_name fields all_fields_but extra_keys

" syn match  bigtopValue  /\b[_\w]([_\w\d]|::)*\b/

hi def link bigtopComment        Comment
hi def link bigtopString         String
hi def link bigtopBlocks         Keyword
hi def link bigtopBackendTypes   Keyword
hi def link bigtopBackends       Identifier
hi def link bigtopValues         Identifier
hi def link bigtopEngines        Constant
hi def link bigtopConfigKeywords Identifier
hi def link bigtopAppKeywords    Identifier
hi def link bigtopTableKeywords  Identifier
hi def link bigtopFieldKeywords  Identifier
hi def link bigtopFieldValues    Identifier
hi def link bigtopSQLKeywords    Identifier
hi def link bigtopControlKeywords    Identifier
hi def link bigtopMethodTypes    Keyword
hi def link bigtopMethodKeywords Identifier
" hi def link bigtopValue          Constant

" Comment
" Constant
"     String
"     Number
" Identifier
"     Function
" Statement
"     Conditional
"     Repeat
"     Label
"     Operator
"     Keyword
"     Exception
" Type

if exists("bigtop_fold")
    syn region blockFold start="{" end ="}" transparent fold
    syn sync fromstart
    set foldmethod=syntax
endif
