use strict;

use Test::More tests => 3;
use Test::Files;
use File::Spec;
use File::Find;

use Bigtop::Parser;

use lib 't';
use Purge;

my $play_dir = File::Spec->catdir( qw( t sitelook play ) );
my $html_dir = File::Spec->catdir(
        $play_dir, 'Apps-Checkbook', 'html', 'templates'
);
my $wrapper  = File::Spec->catfile( qw( t sitelook sample_wrapper.tt ) );

#-------------------------------------------------------------------
# build wrapper.tt
#-------------------------------------------------------------------

Purge::real_purge_dir( $play_dir );
mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    SiteLook        GantryDefault {
        gantry_wrapper `$wrapper`;
    }
}
app Apps::Checkbook {
    location checks;
    controller is base_controller {
        page_link_label Home;
    }
    controller PayeeOr {
        rel_location    payeeor;
        page_link_label `Payee/Payor`;
    }
    controller Trans {
        location    trans;
    }
}
EO_Bigtop_File

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'SiteLook', ],
    }
);

my $correct_wrapper = << 'EO_WRAPPER';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>[% view.title %]</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<link rel="stylesheet" type="text/css" media="screen"
			title="Default" href="[% self.css_rootp %]/default.css" />

    </head>
    <body id="">
	
	<!-- START: top nav logo (using page element style) -->
	<div id="page">
		<img width="740" src="[% self.img_rootp %]/nav_banner3.jpg" 
			alt="Billing Logo" />
	</div>
	<!-- END: top nav logo -->

	<!-- START: top navigation -->
	<div id="nav">
		<div class="lowtech">Site Navigation:</div>	
		<ul>
            <li><a href='[% self.app_rootp %]/'>Home</a></li>
            <li><a href='[% self.app_rootp %]/checks/payeeor'>Payee/Payor</a></li>
            <!-- <li><a href='[% self.app_rootp %]/tasks'>Tasks</a></li> -->
		</ul>
	</div>
	<!-- END: top navigation -->
	
	<br /><br /><br />

	<!-- START: title bar -->
	<div id="title">
		<h1>[% title %]</h1>
		<p>&nbsp;</p>
		<!-- form method="get" action="[% app_rootp %]/search">
		<p>
			<input type="text" name="searchw" value="search" size="10" />
			<input type="submit" value="Disabled" />
		</p>
		</form -->
	</div>
	<!-- END: title bar -->
	
	<!-- START: page -->
	<div id="page">
	
		<!-- START: content -->
		<div id="content">
	
			[% content %]
			
			<br class="clear" />
		</div>
		<!-- END: content -->
	
	</div>
	<!-- END: page -->

	<!-- START: footer -->
	<div id="footer">
		[% USE Date %]
		<p>Page generated on [% Date.format(Date.now, "%A, %B %d, %Y at %l:%M %p") %]
		[% IF r.user; "for $r.user"; END; %]
		<br />
			
		This site is licensed under a 
		<a rel="license" href="http://creativecommons.org/licenses/by/2.0/">
		Creative Commons License</a>,<br />
		except where otherwise noted.
		<br />
		<a rel="license" href="http://creativecommons.org/licenses/by/2.0/">
		<img src="/images/cc.primary.srr.gif" width="88" 
			height="31" alt="Creative Commons License" border="0" /></a>

		</p>
	</div>
	<!-- END: footer -->
	
    </body>
</html>
EO_WRAPPER

my $gened_wrapper = File::Spec->catfile( $html_dir, 'genwrapper.tt' );

file_ok( $gened_wrapper, $correct_wrapper, 'site wrapper' );

Purge::real_purge_dir( $play_dir );

#-------------------------------------------------------------------
# build wrapper.tt without app base location
#-------------------------------------------------------------------

mkdir $play_dir;

$bigtop_string = <<"EO_Bigtop_File_No_Base_Loc";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    SiteLook        GantryDefault {
        gantry_wrapper `$wrapper`;
    }
}
app Apps::Checkbook {
    controller PayeeOr {
        rel_location    payeeor;
        page_link_label `Payee/Payor`;
    }
    controller Trans {
        location    trans;
    }
}
EO_Bigtop_File_No_Base_Loc

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'SiteLook', ],
    }
);

$correct_wrapper = << 'EO_WRAPPER';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>[% view.title %]</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<link rel="stylesheet" type="text/css" media="screen"
			title="Default" href="[% self.css_rootp %]/default.css" />

    </head>
    <body id="">
	
	<!-- START: top nav logo (using page element style) -->
	<div id="page">
		<img width="740" src="[% self.img_rootp %]/nav_banner3.jpg" 
			alt="Billing Logo" />
	</div>
	<!-- END: top nav logo -->

	<!-- START: top navigation -->
	<div id="nav">
		<div class="lowtech">Site Navigation:</div>	
		<ul>
            <li><a href='[% self.app_rootp %]/'>Home</a></li>
            <li><a href='[% self.app_rootp %]/payeeor'>Payee/Payor</a></li>
            <!-- <li><a href='[% self.app_rootp %]/tasks'>Tasks</a></li> -->
		</ul>
	</div>
	<!-- END: top navigation -->
	
	<br /><br /><br />

	<!-- START: title bar -->
	<div id="title">
		<h1>[% title %]</h1>
		<p>&nbsp;</p>
		<!-- form method="get" action="[% app_rootp %]/search">
		<p>
			<input type="text" name="searchw" value="search" size="10" />
			<input type="submit" value="Disabled" />
		</p>
		</form -->
	</div>
	<!-- END: title bar -->
	
	<!-- START: page -->
	<div id="page">
	
		<!-- START: content -->
		<div id="content">
	
			[% content %]
			
			<br class="clear" />
		</div>
		<!-- END: content -->
	
	</div>
	<!-- END: page -->

	<!-- START: footer -->
	<div id="footer">
		[% USE Date %]
		<p>Page generated on [% Date.format(Date.now, "%A, %B %d, %Y at %l:%M %p") %]
		[% IF r.user; "for $r.user"; END; %]
		<br />
			
		This site is licensed under a 
		<a rel="license" href="http://creativecommons.org/licenses/by/2.0/">
		Creative Commons License</a>,<br />
		except where otherwise noted.
		<br />
		<a rel="license" href="http://creativecommons.org/licenses/by/2.0/">
		<img src="/images/cc.primary.srr.gif" width="88" 
			height="31" alt="Creative Commons License" border="0" /></a>

		</p>
	</div>
	<!-- END: footer -->
	
    </body>
</html>
EO_WRAPPER

$gened_wrapper = File::Spec->catfile( $html_dir, 'genwrapper.tt' );

file_ok( $gened_wrapper, $correct_wrapper, 'site wrapper, no base location' );

Purge::real_purge_dir( $play_dir );

#-------------------------------------------------------------------
# build wrapper.tt from Gantry's default (note this now amounts to
# copying the file, since the new gantry default calls site_looks to
# get the nav links at run time).
#-------------------------------------------------------------------

mkdir $play_dir;

$bigtop_string = <<"EO_Bigtop_File_No_Base_Loc";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    SiteLook        GantryDefault { }
}
app Apps::Checkbook {
    controller PayeeOr {
        rel_location    payeeor;
        page_link_label `Payee/Payor`;
    }
    controller Trans {
        location    trans;
    }
}
EO_Bigtop_File_No_Base_Loc

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'SiteLook', ],
    }
);

$gened_wrapper = File::Spec->catfile( $html_dir, 'genwrapper.tt' );

$correct_wrapper = << 'EO_New_Wrapper';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>[% view.title %]</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <!-- include a style sheet if you like:
		<link rel="stylesheet" type="text/css" media="screen"
			title="Default" href="[% self.css_rootp %]/default.css" />
    -->
    <style type='text/css'>
        input {
            border: 1px solid #777;
            background: dce2da;
        }
        a {
            color: #333;
        }
        a:active {
            color: #ddd;
        }
        a:hover {
            color: blue;
        }
        
        #user_content {
          width: 150px;
          margin: 0 0 10px 0;
        }
        
        #products {
          width: 150px;
          margin: 0 0 10px 0;
        }
        
        #product_attribs {
          width: 150px;
          margin: 0 0 10px 0;
        }
        
        #users {
          width: 150px;
          margin: 0 0 10px 0;
        }
        
        #user_content ul {
            list-style: none;
            margin: 0;
            padding: 0;
        }
        
        #products ul {
            list-style: none;
            margin: 0;
            padding: 0;
        }
        
        #product_attribs ul {
            list-style: none;
            margin: 0;
            padding: 0;
        }
        
        #users ul {
            list-style: none;
            margin: 0;
            padding: 0;
        }
        
        #site_links {
            visibility: hidden;
        }
        
        #footer #site_links {
            visibility: visible;
        }
        fieldset {    
            background: #e9e9e9;
            border: 1px solid #c7c7c7;
        }
        
        legend {
            padding: 0 10px 0 10px;
            border: 1px solid #c7c7c7;
            background: #fff;
        }
        
        #content .box table {
            padding: 0;
            margin: 0;
            background: #eee;
            width: 100%;
        }
        
        #content .box table td {
            padding: 0 4px 0 4px;
            margin: 0;
            border: 0;
        }
        
        #content .box table tr {
            background: #b9c5b4;
        }
        
        #content .box table tr + tr {
            background: #fff;
        }
        
        #footer {
            font: normal 12px/20px sans-serif;
            text-align: center;
            padding: 10px;
            margin: 0px auto ;
            width: 740px;
        }
        
        #float_right {
            float: right;
        }
        
        #float_left {
            float: left;
        }
        
        #right {
            text-align: right;
        }
        body {
            margin: 0;
            background: #eee;
            font-family: sans-serif;
            font-size: 100%;
        }
        
        #header {
            background: #fff;
            margin: 0px auto 0px auto;
            border-bottom: 1px solid #778;
        }
        
        #page {
            background: #fff;
            width: 740px;
            margin: 0 auto;
            padding: 0px 0px 0px 0px;
            border: 1px solid #c7c7c7;
            border-top: 0;
        }
        
        #content {
            background: #fff;
            margin: 0px 0px 0px 0px;
            padding: 10px 10px 10px 10px;
            font: normal 12px/20px sans-serif;
            /* border-right: 1px dotted #99d; */
        }
        #title_bar {
            clear: both;
            border: 1px solid #c7c7c7;
            background: #b9c5b4;
            width: 740px;
            text-align: center;
            padding: 3px 0 0 0;
            margin: 0 auto 0 auto;
            -moz-border-radius-topright: 6px;
        }
        
        #nav {
            background: #eee;
            margin: 0px auto 0px auto;
            padding: 0px;
            width: 742px;
        }

        #nav ul {
            background: #fff;
            list-style: none;
            border: 0;
            margin: 0 0 0 0 ;
            padding: 0;
        }

        #nav ul li {
            display: block;
            float: left;
            text-align: center;
            padding: 0;
            margin: 0;
            border-left: 1px solid #99d;
        }

        #nav ul li + li {
            border-left: none;
            display: block;
            float: left;
            text-align: center;
            padding: 0;
            margin: 0;
        }
        #nav ul li a {
            background: #fff;
            border-bottom: 1px solid #99d;
            border-right: 1px solid #99d;
            border-left: none;
            padding: 0 8px 0 8px;
            margin: 0 0 0px 0;
            color: #9a9a9a;
            text-decoration: none;
            display: block;
            text-align: center;
            font: normal 12px/20px sans-serif;
        }

        #nav ul li a:hover {
            color: #000;
            background: #bbe;
        }
        
        #nav a:active {
            background: #c60;
            color: #fff;
        }
        
        #nav li strong a {
            background: #bbf;
            font-weight: bold;
            color: #000;
        }

        .lowtech {
            visibility: hidden;
        }
    </style>

    </head>
    
    <body id="">
	
	<br />

	<!-- START: title bar -->
	<div id="title_bar">
        [% title %]
	</div>
	<!-- END: title bar -->
	
	<!-- START: page -->
	<div id="page">
	
		<!-- START: content -->
		<div id="content">
	
			[% content %]
			
			<br class="clear" />
		</div>
		<!-- END: content -->
	
	</div>
	<!-- END: page -->

	<!-- START: footer -->
	<div id="footer">
        <div id="site_links">
            [% FOREACH page IN self.site_links %]
            <a href='[% page.link %]'> [% page.label %] </a>
            [% IF ! loop.last; ' | '; END; %]
            [% END %]
         </div>
        
		[% USE Date %]
		<p>Page generated on [% Date.format(Date.now, "%A, %B %d, %Y at %l:%M %p") %]
		[% IF r.user; "for $r.user"; END; %]
		<br />
		</p>
	</div>
	<!-- END: footer -->
	
    </body>
</html>
EO_New_Wrapper

file_ok( $gened_wrapper, $correct_wrapper, 'actual gantry site wrapper' );

Purge::real_purge_dir( $play_dir );

