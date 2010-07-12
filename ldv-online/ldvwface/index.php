<?php
require_once("ldv/include/include.php");

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
		<!--<div style="width: 100%; height: 20px; background: #666666;">
			<span style="font-style: bold; color: #E8E8E8; font-size: 80%;">&nbsp;&nbsp;LDV Online 83.149.198.16</span>
		</div> -->
		<div class="mini_menu">


			<a href="<?php print myself(); ?>?action=get_history"><span style="font-style: bold; color: #9999FF; font-size: 130%;">&nbsp;&nbsp;history</span></a>
			<a href="<?php print myself(); ?>?action=upload"><span style="font-style: bold; color: #9999FF; font-size: 130%;">&nbsp;&nbsp;upload</span></a> 
		</div>
	<?php	
}

function view_upload_driver_form() {
	?>
	<form action="<?php print myself(); ?>" method="post" enctype="multipart/form-data">
	<p>
		<span style="font-style: bold; color: #686868; font-size: 150%;">Start verification !</span>
	</p>

        <h4>1.  Ensure that drivers satisfy the following requirements:</h4>
                <ul>
                <li> The driver is archived using gzip or bzip2 and has one of the following extensions: .tar.bz2, tar.gz, .tgz</li>
                <li> Archive should contain:</li>
                        o Makefile (written to be compiled with the kernel)<br>
                                + obj-m is mandatory<br>
                        o Sources needed by Makefile<br>
                <li> Archive should not contain generated files left from builds</li>
                </ul>
        <h4>2. Upload driver. </h4>
        <h4>3. Wait for results.</h4>
        </ul>
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
        $file = $_FILES['file']['name'];
        if(!$file) {
                print '<b><font color="red">Empty filename field.</font></b><br>';
                view_upload_driver_form();
                return;
        }
        $file_size = $_FILES['file']['size'];
       	if($file_size > WS_MAX_DRIVER_SIZE) {
                print '<b><font color="red">File size too long.</font></b><br>';
                view_upload_driver_form();
                return;
        }
	$task['driverpath'] = $_FILES['file']['tmp_name'];
	// Test MIME-content type
	$content_type =  mime_content_type($task['driverpath']);
	if($content_type != 'application/x-bzip2; charset=binary'
		&& $content_type != 'application/x-gzip; charset=binary') {
                print '<b><font color="red">Driver content type not supported.</font></b><br>';
                view_upload_driver_form();
                return;
	}
	$task['drivername'] = $_FILES['file']['name'];
	$task['envs'] = WSGetSupportedEnvList();
	$task['id'] = WSPutTask($task);
	if($task['id']) {
		header('Location: '.myself().'?action=get_status&task_id='.$task['id']);
	} else {
                print '<b><font color="red">Error upload task</font></b><br>';
	}
}

function view_user_history() {
	$history = WSGetHistory();
	$i=1;
	?>
	<form>
	<p>
		<span style="font-style: bold; color: #686868; font-size: 150%;">Verification history:</span>
	</p>
	<p>
		<span>You may see more detailed information about your verification task by clicking on the corresponding links.</span>
	</p>

	<div class="tablediv">
		<div class="rowdiv_head">
			<div class="col10"><span class="table_headers">task</span></div>
			<div class="col60"><span class="table_headers">driver</span></div>
			<div class="col30"><span class="table_headers">date</span></div>
		</div>
		<?php foreach($history as $item) { ?>
			<div class="rowdiv" align=left style="background-color: #EEEFFF;">
				<div class="col10"><a href="<?php print myself(); ?>?action=get_status&task_id=<?php print $item['id'];?>"><?php print $i++; ?></a></div>
				<div class="col60"><?php print $item['driver']; ?></div>
				<div class="col30"><?php print $item['timestamp']; ?></div>
			</div>
		<?php } ?>
	</div>
	</form>
	<?php
}

function view_detailed_report($trace_id, $trace_type) {
	if($trace_type == 'kernel') {
		$trace = WSGetDetailedBuildError($trace_id);
		$etheader = 'Build error trace for driver: '.$trace['drivername'].' and kernel: '.$trace['env'];
	} else {
		$trace = WSGetDetailedReport($trace_id);
		$etheader = 'Error trace for driver: '.$trace['drivername'].'';
	}
	?>
	<form>
	<p>
		<span style="font-style: bold; color: #686868; font-size: 150%;"><?php print $etheader; ?></span>
	</p>
	<?php print $trace['error_trace'];?>	
	</form>
	<?php
}

function view_task_status($task_id) {
	$status = WSGetTaskReport($task_id);
	if(empty($status)) {
		print "Can't get status for your task.";
		return;
	}
	// jQuery UI framework
	?>	
	
	<form>
	<p>
	<p>
	<span style="font-style: bold; color: #686868; font-size: 150%;"><?php print $status['drivername'].' ('.$status['timestamp'].')'; ?></span>
	</p>
	<?php if($status['status'] != 'finished') { ?>
	<META HTTP-EQUIV="refresh" CONTENT="10; URL=<?php print myself(); ?>?action=get_status&task_id=<?php print $task_id; ?>">
	<?php } ?>
	<script>
  		$(document).ready(function(){
			$("#progressbar").progressbar({
				value: <?php print $status['progress']; ?> 
			});
  		});
	</script>
	<p>
	<table width="100%" border="1" style="border-collapse: collapse;">
		<?php foreach($status['envs'] as $env) { ?>	
		<tr>
			<?php if($env['status']=='Build failed') { ?>
				<th width="80%"  bgcolor="#CCCCFF"><span><font color="black"><?php print $env['name']; ?></font></span></th>
				<th              bgcolor="red"><a href="<?php print myself(); ?>?action=detailed_report&trace_id=<?php print $env['trace_id']; ?>&trace_type=kernel"><font color="black"><strong>Build failed</strong></black></a></th>
			<?php } else { ?>
				<th COLSPAN=2   bgcolor="#CCCCFF"><span><font color="black"><?php print $env['name']; ?></font></span></th>
			<?php } ?>
		</tr>
		<?php if($env['status']!='Build failed') { ?>
		<tr>
			<th width="80%" bgcolor="#CCCCFF"><font color="black">title</font></th>
			<th             bgcolor="#CCCCFF"><font color="black">verdict</font></th>
		</tr>
		<?php foreach($env['rules'] as $rule) { ?>
			<?php if ($rule['status'] == 'queued') { ?>
			<tr>
				<td><a href="#" title="<?php print $rule['tooltip']; ?>"><font color="black"><?php print $rule['name']; ?></font></a></td>
				<td><?php print $rule['status']; ?></td>
			</tr>	
			<?php } else if($rule['status'] == 'running') { ?>
			<tr>
				<td><a href="#" title="<?php print $rule['tooltip']; ?>"><font color="black"><?php print $rule['name']; ?></font></a></td>
				<td><?php print $rule['status']; ?></td>
			</tr>	
			<?php } else if($rule['status'] == 'failed') { ?>
			<tr>
				<td><a href="#" title="<?php print $rule['tooltip']; ?>"><font color="black"><?php print $rule['name']; ?></font></a></td>
				<td bgcolor="yellow"><font color="black">unknown</font></td>
			</tr>
			<?php } else { ?>
				<?php $isfirst=true; ?>
				<?php foreach($rule['results'] as $result) { ?>
				<tr>	
					<?php if($isfirst == true) { $isfirst=false; ?>
					<td ROWSPAN="<?php print count($rule['results']); ?>"><a href="#" title="<?php print $rule['tooltip']; ?>"><font color="black"><?php print $rule['name']; ?><font></a></td>
					<?php } ?>
					<?php if($result['status'] == 'unsafe') { ?> 
					<td bgcolor="red">
						<a href="<?php print myself(); ?>?action=detailed_report&trace_id=<?php print $result['trace_id']; ?>"><font color="black"><?php print $result['status']; ?></font></a>
					<?php } else if($result['status']=='safe') { ?>
					<td bgcolor="#66CC33">
						<font color="black">safe</font>
					<?php } else { ?>
					<td bgcolor="yellow">
						<font color="black">unknown</font>
					<?php } ?>
					</td>
				</tr>		
				<?php } ?>
			<?php } ?>
		<?php } ?>
		<?php } ?>
		<?php } ?>
	</table>
	</p>
<!--
	<?php $i=1; ?>
	<?php if($status['finished'] != 0) { ?>

       <script>
		$(document).ready(function(){
       		 $(".rowdiv_minihead_collapsible").click(function() {
                	$(this).parent().children().not(".rowdiv_minihead_collapsible").slideToggle("fast");
       		 });
        	$(".rowdiv_minihead_collapsible").parent().children().not(".rowdiv_minihead_collapsible").hide();
		});
        </script> 
		
	<div class="tablediv">
		<div class="rowdiv_head">
			<div class="col10"><span>launch</span></div>
			<div class="col40"><span>environmnet</span></div>
			<div class="col30"><span>rule</span></div>
			<div class="col20"><span>status</span></div>
		</div>
		<?php $i=1; ?>
		<?php foreach($status['envs'] as $env) { ?>
		<?php foreach($env['rules'] as $rule) { ?>
		<?php if(($rule['status'] == 'finished' || $rule['status'] == 'running') && count($rule['results'])!=0) { ?>
		          <div class="rowdiv"><div class="rowdivactivator">	
			<div class="rowdiv_minihead_collapsible">
				<div class="col10" style="background-color: #EEEFFF;"><span><?php print $i++; ?></span></div>
				<div class="col40" style="background-color: #EEEFFF;"><span><?php print $env['name']; ?></span></div>
				<div class="col30" style="background-color: #EEEFFF;"><span><?php print $rule['name']; ?></span></div>
				<div class="col20" style="background-color: #EEEFFF;"><span><?php print $rule['status']; ?></span></div>
			</div>
			<div>
				<?php foreach($rule['results'] as $result) { ?>
				<div>
					<div class="col60">&nbsp;</div>
					<div class="col40">
					<?php if($result['status'] == 'unsafe') { ?> 
						<a href="<?php print myself(); ?>?action=detailed_report&trace_id=<?php print $result['trace_id']; ?>"><?php print $result['status']; ?></a>
					<?php } else if($result['status']=='safe') { ?>
						safe
					<?php } else { ?>
						unknown
					<?php } ?>
					</div>
				</div>
				<?php  } ?>
			</div>
		</div></div>
		<?php } ?>
		<?php } ?>
		<?php } ?>
	</div> 
	<?php }  ?> -->
	<?php if($status['status'] != 'finished') { ?>
	<p>
		<span style="font-style: bold; color: #686868; font-size: 110%;"><?php print $status['progress']; ?>%</span>
		<div id="progressbar"></div>
	</p> 
	<?php } ?> 
	</form>
	<?php
}

$action=request_var('action','');
$exit=false;



view_header();
/**
 * 
 *  Configuration file
 *
 */ 
WSInit("server.conf");

if ($action == "upload" && !$exit)
{
	view_upload_driver_form();
}
else if ($action == "upload_driver" && !$exit)
{
	action_upload_driver();
}
else if ($action == "get_history" && !$exit)
{
	view_user_history();
}
else if ($action == "detailed_report" && !$exit) 
{
	$trace_id = request_var('trace_id','');
	$trace_type = request_var('trace_type','');
	view_detailed_report($trace_id,$trace_type);	
}
else if ($action == "get_status" && !$exit) 
{
	$task_id = request_var('task_id','');
	view_task_status($task_id);
}
else 
{
	view_main_page();
}

?>
