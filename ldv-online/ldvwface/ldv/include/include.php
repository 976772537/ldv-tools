<?php
//int "<script type=\"text/javascript\" src=\"ldv/js/ldv.js\"></script>";
// ldv-online theme from old version
print "<link rel='stylesheet' id='login-css'  href='ldv/styles/ldv.css' type='text/css' media='all' />";

// CSS for Error trace visualizer
print "<link rel='stylesheet' id='login-css'  href='ldv/styles/etv.css' type='text/css' media='all' />";
print "<link rel='stylesheet' id='login-css'  href='ldv/styles/etv-linuxtesting.css' type='text/css' media='all' />";

// ldvs form theme (mod from wordpress)
print "<link rel='stylesheet' id='login-css'  href='ldv/styles/form.css' type='text/css' media='all' />";

// jquery minimal framework
print "<script type=\"text/javascript\" src=\"ldv/include/jquery/js/jquery-1.4.2.min.js\"></script>";
// jquerry user interface framework (start theme)
print "<link rel='stylesheet' id='login-css'  href='ldv/include/jquery/css/start/jquery-ui-1.8.2.custom.css' type='text/css' media='all' />";
print "<script type=\"text/javascript\" src=\"ldv/include/jquery/js/jquery-ui-1.8.2.custom.min.js\"></script>";

// plugin for jQuery - work with cooikies
print "<script type=\"text/javascript\" src=\"ldv/include/jquery/js/jquery.cookie.js\"></script>";

// Add syntax highlighter for view rules
print "<link type=\"text/css\" rel=\"stylesheet\" href=\"ldv/include/syntaxhighlighter/Styles/SyntaxHighlighter.css\">";

// Markdown for rules
include_once("markdown.php");

// API for work with LDV server
include_once("lsapi.php");
?>
