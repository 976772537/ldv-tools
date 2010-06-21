<?php
require_once("ldv_online/include/include.php");

function html($text)
{
        return htmlspecialchars($text, ENT_QUOTES);
}

function request_var($name, $default=NULL, $row=NULL)
{
        $var = NULL;
        if( isset($_POST[$name]) ) {
                $var = $_POST[$name];
                if ( get_magic_quotes_gpc() )
                        $var = stripslashes($var);
        }
        elseif( isset($_GET[$name]) ) {
                $var = $_GET[$name];
                if ( get_magic_quotes_gpc() )
                        $var = stripslashes($var);
        }
        elseif( isset($row) ) {
                if ( is_array($row) && isset($row[$name]) )
                        $var = $row[$name];
                elseif ( !is_array($row) )
                        $var = $row;
                else
                        $var = $default;
        } elseif ( isset($default) )
                $var = $default;
        return $var;
}

function myself() {
    return $_SERVER['PHP_SELF'];
}

function getservname() {
    return 'http://'.$_SERVER['SERVER_NAME'];
}

function getlddv() {
    return "./files/lddv";
}
	
function view_main_page() {
	view_upload_driver_form();
}

function view_header() {
	?>
		<style type="text/css">
		BODY {
			margin: 0; /* Убираем отступы */
			padding: 0; /* Убираем поля */
		} 
		</style>
		<div style="width: 100%; height: 30px; background: #666666;"></div>
	<?php	
}

function view_upload_driver_form() {
	?>
	<form action="<?php print myself(); ?>" method="post" enctype="multipart/form-data">
	<input type="file" name="file" size=50/>
    	<input type='hidden' name="action" value="upload_driver">
	<input type="submit" name="submit" value="Submit" /></p>
	</form>
	<?php
}

function action_upload_driver() {
        $envs = array($_POST['envs']);
        if(count($envs) == 0) {
                print '<b><font color="red">Empty environment field.</font></b><br>';
                view_upload_driver_form();
                return;
        }
        $file = $_FILES['file']['name'];
        if(!$file) {
                print '<b><font color="red">Empty filename field.</font></b><br>';
                view_upload_driver_form();
                return;
        }
        $file_size = $_FILES['file']['size'];
        if($file_size > 1000999) {
                print '<b><font color="red">File size too long.</font></b><br>';
                view_upload_driver_form();
                return;
        }

	$task['user'] = "mong";
	$task['driverpath'] = $_FILES['file']['tmp_name'];
	$task['envs'] = WSGetSupportedEnvList();
	if(WSPutTask($task)) {
                print '<b><font color="red">Task successfully uploading..</font></b><br>';
	} else {
                print '<b><font color="red">Error upload task</font></b><br>';
	}
}

function view_task_status() {
	$task['user'] = "mong";
	$task['id']=1;
	$status = WSGetTaskStatus($task);
	if(empty($status)) {
		print "Can't get status for your task.";
		return;
	}
	// print our result
	print 'Result for task id='.$task['id'].'.';
	print_r($status);
/*	foreach($status['envs'] as $env) {
		print $env['status']."\n";
	}*/
}

$action=request_var('action','');
$exit=false;


view_header();
if ($action == "upload" && !$exit)
{
	view_upload_driver_form();
}
else if ($action == "upload_driver" && !$exit)
{
	action_upload_driver();
}
else if ($action == "get_status" && !$exit) 
{
	view_task_status();
}
else 
{
	view_main_page();
}

?>
