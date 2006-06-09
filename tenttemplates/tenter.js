/*
    The following snippet was taken from Ajax IN ACTION listing 3-1 p. 74.
    I modified it to remove IE support and to simplify it a bit,
    then I added my specific functions update_tree/redraw, etc.
*/
var net=new Object();
net.READY_STATE_UNITIALIZED = 0;
net.READY_STATE_LOADING     = 1;
net.READY_STATE_LOADED      = 2;
net.READY_STATE_INTERACTIVE = 3;
net.READY_STATE_COMPLETE    = 4;
net.ContentLoader = function( url, onload, data ) {
    this.url     = url;
    this.onload  = onload;
    this.onerror = this.defaultError;
    this.data    = data;
    this.loadXMLDoc( url );
}
net.ContentLoader.prototype = {
    loadXMLDoc : function( url ) {
        this.req = new XMLHttpRequest();
        try {
            var loader = this;
            this.req.onreadystatechange = function() {
                loader.onReadyState.call( loader );
            }
            this.req.open( 'GET', url, true );
            this.req.send( null );
        }
        catch ( err ) {
            this.onerror.call( this );
        }
    },
    onReadyState : function () {
        var req = this.req;
        var ready = req.readyState;
        if ( ready == net.READY_STATE_COMPLETE ) {
            var httpStatus = req.status;
            if ( httpStatus == 200 || httpStatus == 0 ) {
                this.onload.call( this );
            }
            else {
                this.onerror.call( this );
            }
        }
    },
    defaultError : function () {
        alert( "error getting data " + this.req.getAllResponseHeaders() );
    }
}

/*----------------------------------------------------------------
    BEGIN my code
  ----------------------------------------------------------------*/

/*
    redraw is the net.ContentLoader callback for when the AJAX call to
    the server works.  All it does is dump the result directly into the
    raw_output field.
*/
function redraw() {
    var output_area       = document.getElementById( 'raw_output' );
    output_area.innerHTML = this.req.responseText;

    chat( 'chatter', '' );
}

/*
    redraw_add_div is the net.ContentLoader callback for when you need to
    update both the raw_output div and add to hideable div.

    You must pass the name of the hideable div to which the new div
    will be appended as that third (and final) argument to the
    net.ContentLoader constructor.

    The server needs to return two concatenated pieces:
        the text of the html to add to the app body
        the deparsed tree output
    These are split at the first line beginning 'config {'.
*/
function redraw_add_div() {
    // break response into parts
    var response     = this.req.responseText;
    var break_point  = response.indexOf( "config {" );
    var new_div_text = response.substring( 0, break_point - 1 );
    var new_input    = response.substring( break_point );

    // show the new input file as raw output
    var output_area       = document.getElementById( 'raw_output'     );
    output_area.innerHTML = new_input;

    // add the new div to the table body, don't forget the line break
    var div_area = document.getElementById( this.data );

    var new_node       = document.createElement( 'div' );
    var new_br         = document.createElement( 'br' );
    new_node.innerHTML = new_div_text

    div_area.appendChild( new_node );
    div_area.appendChild( new_br );
}

/*
    redraw_chat is a net.ContentLoader callback for when you want to make
    an AJAX call, but want the output to appear in the chat area instead
    of in raw_output.
    The save action uses this to report errors or report confirmation.
*/
function redraw_chat() {
    chat( 'chatter', this.req.responseText );
}

/*
    draw_nothing is a net.ContentLoader callback for when you want to make
    an AJAX call, but don't want to update the screen
*/
function draw_nothing() {}

/*
    Tell chat the name of a div where it can dump debugging output
    and the output to send there.
*/
function chat ( chatter_name, output ) {
    var chatter = document.getElementById( chatter_name );

    chatter.innerHTML = output;
}

function dumper( some_object ) {
    var output = '';
    for ( var prop in some_object ) {
        output += prop + "<br />";
    }

    chat( 'chatter', output );
}

/*
    show_or_hide toggles the visibility of bigtop section divs like
    config, backends, etc.  Pass it the name of the div and it will
    do the rest.
*/
function show_or_hide( elem_name ) {
    var elem               = document.getElementById( elem_name );
    var current_visibility = elem.style.display;

    if ( current_visibility == 'none' ) {
        elem.style.display = 'inline';
    }
    else {
        elem.style.display = 'none';
    }
}

/*
    walk_selections takes a select form object and returns a ][ delimited
    list of the values currently selected.  This works for single or
    multiple selects.
*/
function walk_selections ( select_element ) {
    var retval     = '';
    var selections = new Array();
    var i;

    for ( i = 0; i < select_element.options.length; i++ ) {
        if ( select_element.options[i].selected ) {
            selections.push( select_element.options[i].value );
        }
    }

    return selections.join( '][' );
}

/*
    create_app_block creates blocks (including literals) at the app
    level.  Note that you don't need this for the config block.
    It autovivifies the first time you try to put something in it.
    The type and name of the block are unloaded from the entry elements.

    See also create_* which make subblocks.
*/
function create_app_block () {
    
    var type_selector = document.getElementById( 'new_app_block_type' );
    var type_namer    = document.getElementById( 'new_app_block_name' );

    var selected_type = type_selector.selectedIndex;
    var block_type    = type_selector.options[ selected_type ].value;
    var block_name    = type_namer.value;

    type_namer.value  = '';

    // Go do it!
    var update_url    = '/create_app_block/' + block_type + '::' + block_name;
    var loader        = new net.ContentLoader(
                            update_url,
                            redraw_add_div,
                            'tab-app-body'
                        );
//                            'app_body_table'
}

/*
    delete_app_block deletes blocks (including literals) at the app level.
    Note that the config block has its own delete scheme.
*/
function delete_block ( doomed_element ) {
    var trigger_name = doomed_element.name;
    var doomed_ident = trigger_name.replace( /[^:]*::/, "" );

    // Tell the backend
    var update_url   = '/delete_block/' + doomed_ident;
    var loader       = new net.ContentLoader( update_url, redraw );

    // Remove it from the display?
    var doomed_div      = document.getElementById( 'div_' + doomed_ident );
    var grieving_parent = doomed_div.parentNode;
    var whitespace      = doomed_div.nextSibling;
    var useless_break;
    var more_whitespace;

    try {
        useless_break   = whitespace.nextSibling;
        try {
            more_whitespace = useless_break.nextSibling;
        }
        catch ( missing_whitespace ) { }

        grieving_parent.removeChild( doomed_div );
        grieving_parent.removeChild( whitespace );
        grieving_parent.removeChild( useless_break );
        grieving_parent.removeChild( more_whitespace );
    }
    catch ( any_exception ) {
    //    chat( 'debug_chatter', "error " + any_exception.message );
    }

}

/*
    create_field creates a new field in a table.
*/
function create_field ( table_ident ) {
    var field_namer   = document.getElementById( 'new_field_' + table_ident );
    var new_name      = field_namer.value;

    field_namer.value = '';

    var param         = 'table' + '::' + table_ident + '::' +
                        'field' + '::' + new_name;

    var update_url    = '/create_subblock/' + param;
    var loader        = new net.ContentLoader(
                          update_url,
                          redraw_add_div,
                          "hideable_" + table_ident
                        );
}

/*
    create_method creates a new method in a controller.
*/
function create_method ( controller_ident ) {
    // Find the new name.
    var method_namer   = document.getElementById(
                            'new_method_' + controller_ident
                         );
    var new_name       = method_namer.value;
    method_namer.value = '';

    // Find the new type.
    var method_typer   = document.getElementById(
                            'new_method_type_' + controller_ident
                         );
    var new_type       = method_typer.value;

    // Build and send request.
    var param         = 'controller' + '::' + controller_ident + '::' +
                        'method' + '::' + new_name;

    var update_url    = '/create_subblock/' + param + '/' + new_type;
    var loader        = new net.ContentLoader(
                          update_url,
                          redraw_add_div,
                          "hideable_" + controller_ident
                        );
}

/*
    update_tree does an AJAX request which will update the internal
    tree in the server and show the text version of it in the
    raw_output div (output location is goverened by redraw).
    Pass in: suffix of do_update_* method you want
             parameter to change
             new value for it
             optional extra url trailer
*/
function update_tree (update_type, parameter, new_value, extra ) {
    // chat( 'chatter', 'updating tree with ' + update_type +
    // ' ' + parameter + ' ' + new_value );

    var encoded    = escape( new_value );
    encoded        = encoded.replace( /\//g, "%2F" );
    var update_url = '/update_' + update_type + '/'
                        + parameter + '/' + encoded + '/' + extra;

    // chat( 'chatter', update_url );

    var loader     = new net.ContentLoader( update_url, redraw );
}

/*
    update_multivalue is like update_tree, but it works for statements
    that allow multiple values.  Use one text input box for each
    value, name them all the same.  Connect them to this passing in:
        suffix of do_update_* method you want
        parameter (a.k.a. statement keyword) to change
        one of the input text elements in the group.
    Not only are all the boxes in the group checked for values, but
    if they are all full, this routine makes a new one.
    None are ever removed.
*/
function update_multivalue (update_type, parameter, one_input ) {
    var sybs          = document.getElementsByName( one_input.name );
    var new_names     = new Array;

    var current_count = sybs.length;
    var new_count     = 0;

    // Walk the text input boxes, storing values and counting them.
    SYBS:
    for ( var i = 0; i < current_count; i++ ) {
        if ( ! sybs[i].value ) { continue SYBS; }
        new_count++;
        new_names.push( sybs[i].value );
    }
    var output     = new_names.join( '][' );
    var encoded    = escape( output );
    var update_url = '/update_' + update_type + '/'
                        + parameter + '/' + encoded;

    // See if we need to add a new box.
    if ( new_count >= current_count - 1 ) { // we're full up
        // make the new box and a separator element
        var br_node = document.createElement( 'br' );
        var clone   = one_input.cloneNode( true );
        clone.value = '';

        // attach them to the parent
        var parent  = one_input.parentNode;
        parent.appendChild( br_node );
        parent.appendChild( clone );
    }
    var loader      = new net.ContentLoader( update_url, redraw );
}

/*
    update_pairs is like update_multivalue, but it works for statements
    that allow multiple pairs of values.  Use two text input boxes for
    each pair (one for the key, the other for the value).  Name them
    all the same.  Pass these parameters to this function:
        suffix of do_update_* method you want
        parameter (a.k.a. statement keyword) to change
        one of the input text elements in the group
    Like update_tree_multivalue, this one makes new boxes if all the
    existing ones are full.
*/
function update_pairs (update_type, parameter, one_input) {
    // get names of the key and value fields to be updated
    var base_name  = one_input.name.replace( /_[^_]*$/, '' );
    var key_name = base_name + "_key";
    var value_name = base_name + "_value";

    // get the sybling elemens
    var key_sybs          = document.getElementsByName( key_name );
    var new_keys          = new Array;
    var current_key_count = key_sybs.length;
    var new_key_count     = 0;

    var value_sybs          = document.getElementsByName( value_name );
    var new_values          = new Array;
    var current_value_count = value_sybs.length;
    var new_value_count     = 0;

    // Find length of longer list.
    var current_count;
    if ( current_key_count < current_value_count ) {
        current_count = current_value_count;
    }
    else {
        current_count = current_key_count;
    }

    // Walk the key boxes, storing values and counting them.
    LABEL_SYBS:
    for ( var i = 0; i < current_key_count; i++ ) {
        if ( ! key_sybs[i].value ) { continue LABEL_SYBS; }
        new_key_count++;
        new_keys.push( key_sybs[i].value );
    }
    var output_keys = new_keys.join( '][' );

    // Walk the value boxes, storing values and counting them.
    VALUE_SYBS:
    for ( var i = 0; i < current_value_count; i++ ) {
        // Note that we skip only if the KEY is blank.  We take blank
        // values just fine.
        if ( ! key_sybs[i].value )   { continue VALUE_SYBS; }
        new_value_count++;
        new_values.push( value_sybs[i].value );
    }
    var output_values = new_values.join( '][' );

    // Make and send query.
    var output_query  = "keys=" + escape( output_keys ) + "&" +
                        "values=" + escape( output_values );

    var update_url    = '/update_' + update_type + '/'
                        + parameter + '?' + output_query;

    //chat( 'debug_chatter', update_url );

    var loader        = new net.ContentLoader( update_url, redraw );

    // See if we need to add new boxes.
    if ( new_key_count == current_count
            ||
         new_value_count == current_count )
    { // we're full up
        // make the new box and a separator element
        var clone_key   = key_sybs[0].cloneNode( true );
        var clone_value   = value_sybs[0].cloneNode( true );
        clone_key.value = '';
        clone_value.value = '';

        // attach them to the parent
        var parent_table  = document.getElementById(
                base_name + "_input_table"
        );

        var new_row_number  = parent_table.rows.length;
        parent_table.insertRow( new_row_number );
        var inserted_row    = parent_table.rows[ new_row_number ];

        inserted_row.insertCell( 0 );
        inserted_row.insertCell( 1 );

        inserted_row.cells[0].appendChild( clone_key );
        inserted_row.cells[1].appendChild( clone_value );
    }
}

/*
    add_app_config puts an additional row into the app level config table.
    The name of the new config statement is unloaded from the
    app_config_new text input box.
*/
function add_app_config () {
    var config_table    = document.getElementById( 'app_config_table' );
    var last_row_number = config_table.rows.length - 1;
    // We subtract one to account for the row with the button in it.
    var first_row       = config_table.rows[ 0 ];

    var keyword_box     = document.getElementById( 'app_config_new' );
    var new_keyword     = keyword_box.value;
    keyword_box.value   = '';

    config_table.insertRow( last_row_number );
    var inserted_row    = config_table.rows[ last_row_number ];
    inserted_row.id     = 'app_config::row::' + new_keyword

    for ( var i = 0; i < first_row.cells.length; i++ ) {
        inserted_row.insertCell( i );
    }

    // insert the new keyword (once installed, it is imutable)
    inserted_row.cells[0].innerHTML = new_keyword;

    // insert the text box for input
    var value_box_name = 'app_conf_value::' + new_keyword;
    var value_box = myCreateNodeFromText(
         "<input type='text' name='" + value_box_name + "'" +
         "     value=''                                   " +
         "/>                                              "
    );

    value_box.onblur = config_statement_update;

    inserted_row.cells[1].appendChild( value_box );

    // insert the checkbox for accessor skipping (and check it)
    var accessor_bool_name = 'app_conf_box::' + new_keyword;
    var accessor_box     = myCreateNodeFromText(
        "<input type='checkbox' value='" + accessor_bool_name + "'" +
        "       name='" + accessor_bool_name                  + "'" +
        "       checked='checked' />"
    );

    accessor_box.onchange = config_statement_accessor_update;

    inserted_row.cells[2].appendChild( accessor_box );

    // insert delete button
    var delete_button = myCreateNodeFromText(
          "<button type='button'                                      " +
          "           name='app_config_delete::" + new_keyword + "' />" +
          "  Delete                                                   " +
          "</button>                                                  "
    )
    delete_button.onclick = config_statement_delete;

    inserted_row.cells[3].appendChild( delete_button );
}

/*
    delete_app_config is the button handler for all the delete buttons
    in the App Config Block table.  It tells the server to remove the
    config statement and deletes the corresponding table row in the
    browser view.
*/
function delete_app_config ( delete_button ) {
    var name_pieces = delete_button.name.split( '::' );
    var keyword     = name_pieces[1];

    // tell the backend to do the delete
    var update_url = '/delete_app_config/' + keyword;
    var loader     = new net.ContentLoader( update_url, redraw );

    // update the table
    var config_row = document.getElementById(
            'app_config::row::' + keyword
    );
    var config_row_number = config_row.rowIndex;
    var parent_table      = config_row.parentNode;

    parent_table.deleteRow( config_row_number );
}

/*
    The following three event handlers are attached to newly minted
    config table elements so they have the same behavior as the ones
    delivered during initial page load.
*/
function config_statement_update( event ) {

    var source   = event.currentTarget;
    var keyword  = source.name;
    keyword      = keyword.replace( 'app_conf_value::', '' );

    accessor_box = document.getElementsByName( 'app_conf_box::' + keyword )[0];

    update_tree(
        'app_conf_statement',
        keyword,
        source.value,
        accessor_box.checked
    );
}

function config_statement_accessor_update( event ) {
    var source  = event.currentTarget;
    var keyword = source.name;
    keyword     = keyword.replace( 'app_conf_box::', '' );

    update_tree(
        'app_conf_accessor',
        keyword,
        source.checked
    );
}

function config_statement_delete( event ) {
    var source  = event.currentTarget;

    delete_app_config( source );
}

/*
    type_change is like update_tree, but it only affects changes in
    controller or method types.  Pass it:
        block_type - choose from controller or method
        ident      - the grammar assigned ident of the block to change
        new_type   - what to make the type
*/
function type_change ( ident, new_type ) {

    var update_url = '/type_change/' + ident + '/' + new_type;

    var loader     = new net.ContentLoader( update_url, redraw );
}

/*
    saver puts the file back on the server's disk.
*/
function saver () {
    var file_namer = document.getElementById( 'save_file_name' );
    var file_name  = file_namer.value; // don't even think about clearing this

    var encoded    = escape( file_name );
    encoded        = encoded.replace( /\//g, "%2F" );

    var url        = '/save/' + encoded;
    var loader     = new net.ContentLoader( url, redraw_chat );
}

/*
    myCreateNodeFromText is stolen from dojo's html.js, but cleaned
    to remove all dojo dependencies and to make only one node instead
    of an array of them.
*/
function myCreateNodeFromText ( txt ) {
    var new_div = document.createElement( 'div' );
    new_div.style.visibility = 'hidden';

    document.body.appendChild( new_div );

    new_div.innerHTML = txt;

    var node = new_div.childNodes[0].cloneNode( true );

    document.body.removeChild( new_div );

    return node;
}

/*
    changetab sets the display attribute to all tabs to none, then sets
    it to block for the selected tab.  It also puts the link for the
    tab into the active class so its link tab will highlight.  This
    idea is stolen from the sunflowerbroadband.com home page, but the
    implementation is different.
*/
function changetabs( activate_id ) {
    var tab_holder = document.getElementById( 'tabs' );
    var tabs       = tab_holder.getElementsByTagName( 'div' );

    TABS:
    for ( var i = 0; i < tabs.length; i++ ) {
        if ( ! tabs[i].id ) { continue TABS; }

        var link_tab_id       = tabs[i].id + '-link';
        var link_tab          = document.getElementById( link_tab_id );

        // Skip descendent divs.  Ours have ids starting with tab-.
        // There are link elements with corresponding ids ending in -link.
        if ( ! link_tab ) { continue TABS; }

        if ( tabs[i].id == activate_id ) {
            tabs[i].style.display = 'block';
            link_tab.className    = 'active';
        }
        else {
            tabs[i].style.display = 'none';
            link_tab.className    = '';
        }
    }
}
