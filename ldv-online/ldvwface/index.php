<link rel='stylesheet' id='login-css'  href='form.css' type='text/css' media='all' />
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
		<div style="width: 100%; height: 30px; background: #666666;">
			<span style="font-style: bold; color: #E8E8E8; font-size: 80%;">&nbsp;&nbsp;LDV Online iteration</span>
		</div>
	<?php	
}

function view_upload_driver_form() {
	?>
	<form name="loginform" id="loginform"  action="<?php print myself(); ?>" method="post" enctype="multipart/form-data">
	<p>
		<span style="font-style: bold; color: #686868; font-size: 150%;">Start verification !</span>
	</p>


	        <p>
	                <label><br />
	                <input type="file" name="file" id="user_login" class="input" value="" size="50" tabindex="10" /></label>
	        </p>
	        <p class="submit">
	                <input type="submit" name="submit" id="wp-submit" class="button-primary" value="Start verification!" tabindex="100" />
	        </p>
		    	<input type='hidden' name="action" value="upload_driver">
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
        $file = $_FILES['file']['name']; // or tmp_name?
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
	$task['drivername'] = $_FILES['file']['name'];
	$task['envs'] = WSGetSupportedEnvList();
	$task['id'] = WSPutTask($task);
	if($task['id']) {
             // print '<b><font color="red">Task successfully uploading with id '.$task['id'].' ..</font></b><br>';
		view_task_status($task);
	} else {
                print '<b><font color="red">Error upload task</font></b><br>';
	}
}

function view_task_status($task) {
	$status = WSGetTaskStatus($task);
	if(empty($status)) {
		print "Can't get status for your task.";
		return;
	}
	
	?>
	<META HTTP-EQUIV="refresh" CONTENT="10; URL=<?php print myself(); ?>?action=get_status&task_id=<?php print $task['id']; ?>">
	<form name="loginform" id="loginform">
	<p>
		<span style="font-style: bold; color: #686868; font-size: 150%;">Verification results:</span>
	</p>
	<table border="1" cellspacing="0" cellpadding="4" width="100%">
        	<tr>
			<th style="font-style: bold; color: #686868;">task</th>
			<th style="font-style: bold; color: #686868;">environment</th>
			<th style="font-style: bold; color: #686868;">rule</th>
			<th style="font-style: bold; color: #686868;">result</th>
	        <tr>
		<?php foreach($status['envs'] as $env) { ?>
			<?php foreach($env['rules'] as $rule) { ?>
				<?php foreach($rule['results'] as $result) { ?>
				<tr>
					<td><?php print $status['id']; ?></td>
					<td><?php print $env['name']; ?></td>
					<td><?php print $rule['name']; ?></td>
					<td><?php print $result['verdict']; ?></td>
				</tr>
				<?php } ?>
			<?php } ?>
		<?php } ?>
	</table>
	</form>
	<?php
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
	$task_id = request_var('task_id','');
	$task = array('user' => "mong", 'id' => $task_id);
	view_task_status($task);
}
else 
{
	view_main_page();
}

?>
