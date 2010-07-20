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


			<a style="text-decoration: none;" href="<?php print myself(); ?>?action=get_history"><span style="font-style: bold; color: #9999FF; font-size: 130%;">&nbsp;&nbsp;history</span></a>
			<a style="text-decoration: none;" href="<?php print myself(); ?>?action=upload"><span style="font-style: bold; color: #9999FF; font-size: 130%;">&nbsp;&nbsp;upload</span></a> 
		</div>
	<?php	
}

function view_upload_driver_form() {
	$last_error = error_get_last();
	if($last_error['type']==2) {
		print '<b><font color="red">File size can\'t be greater than '.WS_MAX_DRIVER_SIZE.' bytes.</font></b><br>';
	}
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
/*	if($_FILES['file']['error'] === true) {
                print '<b><font color="red">Error during uploading file. File size can\'t be greater than '.WS_MAX_DRIVER_SIZE.'.</font></b><br>';
                view_upload_driver_form();
                return;
	}*/
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
	WSPrintD("Content type: $content_type");
	if( strpos($content_type,'application/x-bzip2') === false &&
		strpos($content_type,'application/x-gzip') === false) {
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
		<span>You may see more detailed information about your verification task by clicking on the corresponding driver name.</span>
	</p>
	
	<table width="100%" border="1" style="border-collapse: collapse;">
		<tr>
			<th width="6%" bgcolor="#CCCCFF"><font color="black">Task</font></th>
			<th align="left" width="54%" bgcolor="#CCCCFF"><font color="black">Driver</font></th>
			<th width="20%" bgcolor="#CCCCFF"><font color="black">Timestamp</font></th>
		</tr>
		<?php foreach($history as $item) { ?>
		<tr style="background: #EFEFFF; cursor: hand;" onMouseOver="this.style.background='#FFFFFF'" onMouseOut="this.style.background='#EFEFFF'" style="background: #EFEFFF;" onClick="document.location='<?php print myself(); ?>?action=get_status&task_id=<?php print $item['id'];?>'">
			<td align="center"><a href="<?php print myself(); ?>?action=get_status&task_id=<?php print $item['id'];?>"><font color="black"><?php print $i; ?></font></a></td>
			<td><a href="<?php print myself(); ?>?action=get_status&task_id=<?php print $item['id'];?>&number=<?php print $i++;?>"><font color="black"><?php print $item['driver']; ?></font></a></td>
			<td align="center" ><font color="black"><?php print $item['timestamp']; ?></font></td>
		</tr>	
		<?php } ?>
	</table>
	</form>
	<?php
}

function view_detailed_report($trace_id, $trace_type, $number) {
	if($trace_type == 'kernel') {
		$trace = WSGetDetailedBuildError($trace_id);
		$etheader = 'Task: '.$number.', build error trace for driver: '.$trace['drivername'].' and kernel: '.$trace['env'];
	} else {
		$trace = WSGetDetailedReport($trace_id);
		$etheader = 'Task: '.$number.', error trace for driver: '.$trace['drivername'].'';
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

function view_task_status($task_id,$number) {
	if(empty($number)) {
		$history = WSGetHistory();
		$number = count($history);
	}
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
	<span style="font-style: bold; color: #686868; font-size: 150%;"><?php print 'Task '.$number.', driver: '.$status['drivername'].' ('.$status['timestamp'].')'; ?></span>
	</p>
	<p>
        You can see <b>verification verdict</b> for each rule and linux kernel. Verdict may be:
        <ul>
                <li><i>Safe</i> - there is no mistakes for the given linux kernel and rule.</li>
                <li><i>Unsafe</i> - driver may contain an error. You may see the error trace by clicking on the "Unsafe" link for the corresponding linux kernel and rule.</li>
                <li><i>Build failed</i> - your driver is not compatible with the given linux kernel. In this case you may see the compile error trace by clicking on the "more details" link.</li>
                <li><i>Unknown</i> - tools can not determine whether your driver <i>Safe</i> or <i>Unsafe</i>.</li>
        </ul>
	</p>
	<?php if($status['status'] != 'finished') { ?>
	<META HTTP-EQUIV="refresh" CONTENT="10; URL=<?php print myself(); ?>?action=get_status&task_id=<?php print $task_id; ?>&number=<?php print $number;?>">
	<?php } ?>
	<script>
  		$(document).ready(function(){
			$("#progressbar").progressbar({
				value: <?php print $status['progress']; ?> 
			});
  		});
	</script>
<script type="text/javascript">
$(document).ready(function(){
	$('.rowdiv_minihead_collapsible').each(function(i) {
                if ($.cookie($(this).attr('id'))) { 
	       		$(this).parent().children().not(".rowdiv_minihead_collapsible").show();
                }else {
	       		$(this).parent().children().not(".rowdiv_minihead_collapsible").hide();
                }
		$(this).click(function() {
			if($(this).parent().children().not(".rowdiv_minihead_collapsible").css('display') == 'none') {
	       			$(this).parent().children().not(".rowdiv_minihead_collapsible").show();
				$.cookie($(this).attr('id'), 'opened', {expires: null, path: '/'});
			} else {
	       			$(this).parent().children().not(".rowdiv_minihead_collapsible").hide();
				$.cookie($(this).attr('id'), null, {expires: null, path: '/'});
			}
		});
	});
});
</script>




	<?php $index=0 ?>
	<p>
	<table id="results" name="results_table" width="100%" border="1" style="border-collapse: collapse;">
		<?php foreach($status['envs'] as $env) { ?>	
		<tr>
			<?php if($env['status']=='Build failed') { ?>
				<th COLSPAN=2 bgcolor="#FF6666"><strong><?php print $env['name']; ?>&nbsp;- build failed &nbsp;</strong><a link." href="<?php print myself(); ?>?action=detailed_report&trace_id=<?php print $env['launch_id']; ?>&trace_type=kernel&number=<?php print $number;?>"><font color="black">(more details...)</font></a></th>
			<?php } else { ?>
				<th COLSPAN=2   bgcolor="#CCCCFF"><span><font color="black"><?php print $env['name']; ?></font></span></th>
			<?php } ?>
		</tr>
		<?php if($env['status']!='Build failed') { ?>
		<tr>
			<th width="80%" align="left" bgcolor="#CCCCFF"><font color="#444444">Rule</font></th>
			<th             bgcolor="#CCCCFF"><font color="#444444">Verdict</font></th>
		</tr>
		<?php foreach($env['rules'] as $rule) { ?>
			<?php if ($rule['status'] == 'queued') { ?>
			<tr>
					<td style="cursor: hand;" class="rowdivactivator" ROWSPAN="<?php print count($rule['results']); ?>">
 						<div onMouseOver="this.style.background='#FFFFFF'" onMouseOut="this.style.background='#EFEFFF'" style="background: #EFEFFF;" id="description_<?php print $status['task_id'].'_'.$index++;?>" class="rowdiv_minihead_collapsible">
     						   <a href="javascript:void(0);" title="<?php print $rule['tooltip']; ?>"><font face="Arial"><?php print $rule['name']; ?></font></a>
 						 </div>
						 <div>
							<div style="margin-left:10px; margin-top: 5px; margin-bottom: 7px;">
							<?php print $rule['summary']; ?>
							<a href="#0"><strong>more information...</strong></a>
							</div>
						</div>
					</td>


			<td align="center" style="background: #EFEFFF;">Queued</td>
			</tr>	
			<?php } else if($rule['status'] == 'running') { ?>
			<tr>
                                        <td style="cursor: hand;" class="rowdivactivator" ROWSPAN="<?php print count($rule['results']); ?>">
                                                <div onMouseOver="this.style.background='#FFFFFF'" onMouseOut="this.style.background='#EFEFFF'" style="background: #EFEFFF;" id="description_<?php print $status['task_id'].'_'.$index++;?>" class="rowdiv_minihead_collapsible">
                                                   <a href="javascript:void(0);" title="<?php print $rule['tooltip']; ?>"><font face="Arial"><?php print $rule['name']; ?></font></a>
                                                 </div>
                                                 <div>
							<div style="margin-left:10px; margin-top: 5px; margin-bottom: 7px;">
                                                       <?php print $rule['summary']; ?>
							<a href="#0"><strong>more information...</strong></a>
                                                        </div>
                                                </div>
                                        </td>
	

			<!--	<td align="center"><?php print $rule['status']; ?><img src="ldv/images/load.gif"/></td>-->
				<td align="center" title="Verification in progress..."><img src="ldv/images/load.gif"/></td>
			</tr>	
			<?php } else if($rule['status'] == 'failed') { ?>
			<tr>
                                        <td style="cursor: hand;" class="rowdivactivator" ROWSPAN="<?php print count($rule['results']); ?>">
                                                <div onMouseOver="this.style.background='#FFFFFF'" onMouseOut="this.style.background='#EFEFFF'" style="background: #EFEFFF;" id="description_<?php print $status['task_id'].'_'.$index++;?>" class="rowdiv_minihead_collapsible">
                                                   <a href="javascript:void(0);" title="<?php print $rule['tooltip']; ?>"><font face="Arial"><?php print $rule['name']; ?></font></a>
                                                 </div>
                                                 <div>
							<div style="margin-left:10px; margin-top: 5px; margin-bottom: 7px;">
                                                       <?php print $rule['summary']; ?>
							<a href="#0"><strong>more information...</strong></a>
                                                        </div>
                                                </div>
                                        </td>
				<td align="center" bgcolor="yellow"><font color="black">Unknown</font></td>
			</tr>
			<?php } else { ?>
				<?php $isfirst=true; ?>
				<?php foreach($rule['results'] as $result) { ?>
				<tr>
					<?php if($isfirst == true) { $isfirst=false; ?>
					<td style="cursor: hand;" class="rowdivactivator" ROWSPAN="<?php print count($rule['results']); ?>">
 						<div onMouseOver="this.style.background='#FFFFFF'" onMouseOut="this.style.background='#EFEFFF'" style="background: #EFEFFF;" id="description_<?php print $status['task_id'].'_'.$index++;?>" class="rowdiv_minihead_collapsible">
     						   <a href="javascript:void(0);" title="<?php print $rule['tooltip']; ?>"><font face="Arial"><?php print $rule['name']; ?></font></a>
 						 </div>
						 <div>
							<div style="margin-left:10px; margin-top: 5px; margin-bottom: 7px;">
						<?php print $rule['summary']; ?>
							<a href="#0"><strong>more information...</strong></a>
							</div>
						</div>
					</td>


<!--					<td ROWSPAN="<?php print count($rule['results']); ?>"><a href="<?php print myself(); ?>?action=show_rule&rule_id=<?php print $rule['rule_id']; ?>" title="<?php print $rule['tooltip']; ?>"><font color="#444444"><?php print $rule['name']; ?><font></a></td>-->
					<?php } ?>
					<?php if($result['status'] == 'unsafe') { ?> 
					<td bgcolor="#FF6666" align="center">
						<a href="<?php print myself(); ?>?action=detailed_report&trace_id=<?php print $result['trace_id']; ?>&number=<?php print $number;?>"><font color="black">Unsafe</font></a>
					<?php } else if($result['status']=='safe') { ?>
					<td bgcolor="#66CC33" align="center">
						<font color="black">Safe</font>
					<?php } else { ?>
					<td bgcolor="yellow" align="center">
						<font color="black">Unknown</font>
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
	<?php if($status['status'] != 'finished') { ?>
	<p>
		<span style="font-style: bold; color: #686868; font-size: 110%;"><?php print $status['progress']; ?>%</span>
		<div id="progressbar"></div>
	</p> 
	<?php } ?> 
	</form>
	<?php
}

function view_rule_by_number($rule_id) {
	$rule = WSGetRuleByNumber($rule_id);
    print '<form>';
	print '<p><b>'.$rule['ID'].'</b></p>';
    print '<p><b>'.$rule['TYPE'].'</b></p>';
    print '<p><b>'.$rule['TITLE'].'</b></p>';
    if ($rule['SUMMARY'] != '')
    {
        print '<p><b>Summary</b><br>';
        print Markdown($rule['SUMMARY']).'</p>';
    }

    if ($rule['DESCRIPTION'] != '')
    {
        print '<p><b>Description</b><br>';
        print Markdown($rule['DESCRIPTION']).'</p>';
    }

    if ($rule['LINKS'] != '') {
        print '<p><b>Links:</b><br>';
        print Markdown($rule['LINKS']).'</p>';
    }

   if ($rule['EXAMPLE'] != '') {
        print '<p><b>Example</b><br>';
        print Markdown($rule['EXAMPLE']).'</p>';
   }

   if ($rule['NOTES'] != '') {
        print '<p><b>Notes</b><br>';
        print Markdown($rule['NOTES']).'</p>';
    }
    print '</form>';
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
	$number = request_var('number','');
	view_detailed_report($trace_id,$trace_type,$number);	
}
else if ($action == "get_status" && !$exit) 
{
	$task_id = request_var('task_id','');
	$number = request_var('number','');
	view_task_status($task_id,$number);
}
/*else if ($action == "show_rules" && !$exit)
{
        $rules_type=request_var('rules_type','');
        if (!$rules_type) {
                view_rules_by_type('ALL');
        } else
        if ($rules_type == 'RECOMMENDATION' || $rules_type == 'ERROR' || $rules_type == 'WARNING')
        {
                view_rules_by_type($rules_type);
        } else
        {
                print "Unknown rule type.<br>";
        }
} */ else if ($action == "show_rule" && !$exit)
{
        $rule_id = request_var('rule_id','');
        view_rule_by_number($rule_id);
	?>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shCore.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushCSharp.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushPhp.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushJScript.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushJava.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushVb.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushSql.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushXml.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushDelphi.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushPython.js"></script>
	<script class="javascript" src="ldv/incldue/syntaxhighlighter/Scripts/shBrushRuby.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushCss.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushCpp.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushScala.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushGroovy.js"></script>
	<script class="javascript" src="ldv/include/syntaxhighlighter/Scripts/shBrushBash.js"></script>
	<script class="javascript"> dp.SyntaxHighlighter.HighlightAll('code'); </script>
	<?php
}
else 
{
	view_main_page();
}

?>
