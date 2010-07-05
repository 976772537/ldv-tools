<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<?php
#
# Log degines
#
define("WS_LL_DEBUG", "DEBUG");
define("WS_LL_TRACE", "TRACE");
define("WS_LL_ALL", "ALL");
define("WS_LL_ERROR", "ERROR");
define("WS_LL_NORMAL", "NORMAL");
define("WS_LL_INFO", "INFO");

#
# WS Protocol defines
#
define("WSM_WSTOLDVS_TASK_PUT_REQUEST","WSTOLDVS_TASK_PUT_REQUEST");
define("WSM_LDVSTOWS_TASK_PUT_RESPONSE","LDVSTOWS_TASK_PUT_RESPONSE");
define("WSM_LDVSTOWS_TASK_DESCR_RESPONSE","LDVSTOWS_TASK_DESCR_RESPONSE");

#
# WS Net function defines
#
function WSInit($ldvs_server_config) {
	define("WS_BLOCK_SIZE",8192);
	if(empty($ldvs_server_config)) {
		WSInitDefault();
		WSInitPrint();
		return;
	} 
	if(!is_file($ldvs_server_config)) {
		WSPrintE("Can't find file with configuration.");
		WSInitDefault();
		WSInitPrint();
		return;
	}
        if(($file_array=file($ldvs_server_config))) {
                for($i=0; $i<count($file_array); $i++) {
			if(preg_match('/LDVServerAddress=(.*)/', $file_array[$i], $lmatches)) 
				define("WS_LDVS_SERVER_NAME",$lmatches[1]);
                       	if(preg_match('/WSPort=(.*)/', $file_array[$i], $lmatches))
				define("WS_LDVS_SERVER_PORT",$lmatches[1]);
                        if(preg_match('/StatsDBUser=(.*)/', $file_array[$i], $lmatches))
				define("WS_SDB_USER",$lmatches[1]);
                        if(preg_match('/StatsDBPass=(.*)/', $file_array[$i], $lmatches))
				define("WS_SDB_PASS",$lmatches[1]);
                        if(preg_match('/StatsDBName=(.*)/', $file_array[$i], $lmatches))
				define("WS_SDB_NAME",$lmatches[1]);
                       	if(preg_match('/StatsDBHost=(.*)/', $file_array[$i], $lmatches))
				define("WS_SDB_HOST",$lmatches[1]);
                       	if(preg_match('/StatsDBPort=(.*)/', $file_array[$i], $lmatches))
				define("WS_SDB_PORT",$lmatches[1]);
                       	if(preg_match('/LogLevel=(.*)/', $file_array[$i], $lmatches))
				define("WS_LDV_DEBUG",$lmatches[1]);
		}
		WSInitPrint();
		// TODO: test all options!
        } else {
		WSPrintE("Can't read file with configuration.");
		WSInitDefault();
		WSInitPrint();
	}
}

function WSInitPrint() {
	WSPrintD("Set up WS_LDVS_SERVER_NAME=".WS_LDVS_SERVER_NAME);
	WSPrintD("Set up WS_LDVS_SERVER_PORT=".WS_LDVS_SERVER_PORT);
	WSPrintD("Set up WS_SDB_USER=".WS_SDB_USER);
	WSPrintD("Set up WS_SDB_PASS=".WS_SDB_PASS);
	WSPrintD("Set up WS_SDB_NAME=".WS_SDB_NAME);
	WSPrintD("Set up WS_SDB_HOST=".WS_SDB_HOST);
	WSPrintD("Set up WS_SDB_PORT=".WS_SDB_PORT);
}

function WSInitDefault() {
	WSPrintD("Try to use default configureation.");
	// how to connect to LDV Server
	define("WS_LDVS_SERVER_PORT",11111);
	define("WS_LDVS_SERVER_NAME","localhost");
	// options for stats db
	define("WS_SDB_USER","statsuserd");
	define("WS_SDB_PASS","statspass");
	define("WS_SDB_NAME","statsdb");
	define("WS_SDB_HOST","10.10.2.82");
	define("WS_SDB_PORT","3306");
	// TODO: log level 
	define("WS_LDV_DEBUG","100");
}

#
# get kernel list strucure
#
function WSGetSupportedEnvList() {
	$rules1 = array('32_1','77_1','08_1','29_1','37_1','39_1','43_1','60_1','68_1');
//	$rules2 = array("32_1","77_1");
	
	$env1 = array('name' => "linux-2.6.32.12", 'rules' => $rules1);
//	$env2 = array('name' => "linux-2.6.35-rc3", 'rules' => $rules2);
	$env2 = array('name' => "linux-2.6.33.3", 'rules' => $rules1);
//	$env3 = array('name' => "linux-2.6.35-rc3", 'rules' => $rules1);

	$envs = array($env1, $env2);
	//$envs = array($env2);
	return $envs;
}

#
# WS XML functions
#
#
function WSConverToSmallXML($data) {
	$smalldxml="";
	foreach ($data as $key => $val) {
		if(is_array($val)) 
			$smalldxml.="<$key>".WSConverToSmallXML($val)."</$key>";
		else 
			$smalldxml.="<$key>".$val."</$key>";	
        }
	return $smalldxml;
}

function WSConvertToMsg($data, $type) {
	return "<?xml version=\"1.0\"?><msg><type>$type</type>".WSConverToSmallXML($data).'</msg>';
}

function WSGetXMLHeader() {
	return('<?xml version="1.0"?>');
}

function WSMWrapMsg($msg) {
	return WSGetXMLHeader()."<msg>$msg</msg>";
}


#
# WS Log functions
#
#
function WSPrintD($string) {
	WSPrintByLogLevel($string,WS_LL_DEBUG);
}

function WSPrintE($string) {
	WSPrintByLogLevel($string,WS_LL_ERROR);
}

function WSPrintN($string) {
	WSPrintByLogLevel($string,WS_LL_NORMAL);
}

function WSPrintT($string) {
	WSPrintByLogLevel($string,WS_LL_TRACE);
}

function WSPrintA($string) {
	WSPrintByLogLevel($string,WS_LL_ALL);
}

function WSPrintI($string) {
	WSPrintByLogLevel($string,WS_LL_INFO);
}

function WSPrintByLogLevel($string,$type) {
//	if(WSIsDebug())
//		print("<b>$type:</b> $string\n<br>");
}

function WSIsDebug() {
	return true;
}

#
# Functions that creates WS Messages from 
# corresponding structures
#
# If no error - returns string prepared 
# for sending
#
# If error - returns null
#
function WSM_DEBUG_XML_WSTOLDVS_TASK_STATUS_GET_REQUEST($task) {
	if(WSIsDebug()) {
		if(empty($task['user'])) {
			WSPrintE('Field "user" - not found.');
			return false;
		} else if(empty($task['id'])) {
			WSPrintE('Field "id" - not found.');
			return false;
		} else if($task['id']<=0) {
			WSPrintE('Task id must be greater than 0.');
			return false;
		}
	}
	return true;
}

function WSM_DEBUG_XML_WSTOLDVS_TASK_PUT_REQUEST($task) {
	if(WSIsDebug()) {
		if(empty($task['user'])) {
			WSPrintE('Field "user" - not found.');
			return false;
		} else if(empty($task['driverpath'])) {
			WSPrintE('Field "driverpath" - not found.');
			return false;
		} else if(empty($task['drivername'])) {			
			WSPrintE('Field "drivername" - not found.');
			return false;
		} else if(!file_exists($task['driverpath'])) {
			WSPrintE('File '.$task['driverpath'].'" - not exists.');
			return false;
		} else if(!is_readable($task['driverpath'])) {
			WSPrintE('File "'.$task['driverpath'].'" - not redable.');
			return false;
		} else if(empty($task['envs'])) {
			WSPrintE('Field "envs" - not found.');
			return false;
		} else if(count($task['envs']) == 0) {
			WSPrintE('Size of "envs" - equals 0.');
			return false;
		}
	}
	return true;
}

function WSM_XML_WSTOLDVS_TASK_PUT_REQUEST($task) {
	# some checks
	if(!WSM_DEBUG_XML_WSTOLDVS_TASK_PUT_REQUEST($task)) return;
	$WSMsg='<type>'.WSM_WSTOLDVS_TASK_PUT_REQUEST.'</type>';
	$WSMsg.='<user>'.$task['user'].'</user>';
	$WSMsg.='<sourcelen>'.filesize($task['driverpath']).'</sourcelen>';
	$WSMsg.='<driver>'.$task['drivername'].'</driver>';
	foreach($task['envs'] as $env_key => $env) {
		$WSMsg.='<env name="'.$env['name'].'">';
			foreach($env['rules'] as $rule_key => $rule) {
				$WSMsg.="<rule>$rule</rule>";
			}
		$WSMsg.='</env>';
	}
	return WSMWrapMsg($WSMsg);
}

#
# small function for parse xml strings
#
function WSM_OBJ_XML_StandartParse($wsm) {
	$wsm=trim($wsm); 
	$msg['wsmbuf'] = preg_replace("/.*<msg>(.*)<\/msg>.*/", "$1", $wsm);
	$msg['type'] = preg_replace("/.*<type>(.*)<\/type>.*/", "$1", $msg['wsmbuf']);
	preg_match("/<result>(.*?)<\/result>/", $msg['wsmbuf'], $result);
	$msg['result'] = $result[1];
	return $msg;
}

function WSM_OBJ_XML_Parse_WSM_LDVSTOWS_TASK_PUT_RESPONSE($msg) {
	$msg['id'] = preg_replace("/.*<id>(.*)<\/id>.*/", "$1", $msg['wsmbuf']);
	unset($msg['wsmbuf']);
	return $msg;
}

#
# Functions that conver WMS from XMl format
# 	to corresponding PHP structures;
#
#
function WSM_OBJ_XML($wsm) {
	$msg = WSM_OBJ_XML_StandartParse($wsm);
	if($msg['type'] == WSM_LDVSTOWS_TASK_DESCR_RESPONSE) {
		return $msg;
	} else if($msg['type'] == WSM_LDVSTOWS_TASK_PUT_RESPONSE) {
		$msg = WSM_OBJ_XML_Parse_WSM_LDVSTOWS_TASK_PUT_RESPONSE($msg);
	} else {
		WSPrintE('Unknown msg type: "'.$msg['type'].'".');
		return null;
	}
	unset($msg['wsmbuf']);
	return $msg;
}

function WSM_OBJ_XML_ResultSharedTest($msg,$type) {
	if($msg['type'] != $type) {
		WSPrintE("Not $type message from WS. Type \"".$msg['type'].'".');
		return false;
	}
	if($msg['result'] != "OK") {
		WSPrintE('Result: "'.$msg['type'].'".');
		return false;
	}
	return true;
}

function WSM_OBJ_XML_LDVSTOWS_TASK_DESCR_RESPONSE($wsm) {
	$msg = WSM_OBJ_XML($wsm);
	if(WSM_OBJ_XML_ResultSharedTest($msg,WSM_LDVSTOWS_TASK_DESCR_RESPONSE)) return true;
}

function WSM_OBJ_XML_LDVSTOWS_TASK_PUT_RESPONSE($wsm) {
	$msg = WSM_OBJ_XML($wsm);
	if(!WSM_OBJ_XML_ResultSharedTest($msg,WSM_LDVSTOWS_TASK_PUT_RESPONSE)) return;
	return $msg;
}

#
# Net functions 
#
#

function WSConnect() {
	$sock = fsockopen(WS_LDVS_SERVER_NAME,WS_LDVS_SERVER_PORT,$errno,$errstr);
	if (!$sock) 
	{
		WSPrintE($errstr);  
		return;
	} else {
		return $sock;
	}
}

function WSRead($sock) {
	$buffer = "";
	while (!feof($sock))
		$buffer.= fgets($sock, WS_BLOCK_SIZE);
	return $buffer;
}

#
# WS Server API functions
#

#
# WSPutTask - upload task to LDVS
# for verification
#
# Use it like this:
# $rules1 = array("8_1","32_1");
# $rules2 = array("64","89");
#
# $env1 = array('name' => "vanilla", 'rules' => $rules1);
# $env2 = array('name' => "rhkernel", 'rules' => $rules2);
#
# $task['user'] = "mong"; --- NOT NEEDED
# $task['driverpath'] = "/home/iceberg/ldv-tools/ldv-online/ldvsrv/lsapi.tar.bz2";
# $task['drivername'] = "lsapi.tar.bz2";
# $task['envs'] = array($env1, $env2);
#
# WSPutTask($task);
function WSPutTask($task) {
	$task['user']=WSGetUser();
	$sock = WSConnect();
	if(empty($sock)) return;
	$WSMsg = WSM_XML_WSTOLDVS_TASK_PUT_REQUEST($task);
	if(empty($WSMsg)) { fclose($sock); return; };
	# send WSTOLDVS_TASK_PUT_REQUEST
	WSPrintD("Send request:$WSMsg");
	fputs($sock,$WSMsg);
	# wait for response LDVSTOWS_TASK_DESCR_RESPONSE
	WSPrintD('Wait for response LDVSTOWS_TASK_PUT_RESPONSE');
	if(WSM_OBJ_XML_LDVSTOWS_TASK_DESCR_RESPONSE(fgets($sock)) == null) {
		fclose($sock);
		return;
	}
	# send binary data
	$fh = fopen($task['driverpath'], "r");
	if(!$fh) {
		WSPrintE('Failed to open file "'.$task['driverpath'].'".');
		fclose($sock);
		return;
	}
	WSPrintD('Start to send binary data');
	while (!feof($fh)) {
		$data = fread($fh, WS_BLOCK_SIZE);
		fputs($sock, $data);
	}
	WSPrintD('End sending binary data');
	fclose($fh);
	# try to get LDVSTOWS_TASK_PUT_RESPONSE
	WSPrintD('Wait for LDVSTOWS_TASK_PUT_RESPONSE.');
	$response = WSM_OBJ_XML_LDVSTOWS_TASK_PUT_RESPONSE(fgets($sock));
	if($response == null) {
		fclose($sock);
		return;
	}
	fclose($sock);
	WSPrintD('Task successfully put to LDVS Server.');
	return $response['id'];
}

#
# Get task status -
# get all information about 
# task 
#
# input: id - id for task
#
# return next information
#
#         _ task _______________________________________________
# 	/   |     \          \                          \       \ 
#      |   id     envs[i]     progress                   \        finished
#   status      /    \        (percent of finished tasks) \   (number of finfished tasks)
#          rules[i]   status                               \
#           /     \                                      running
#      results[i]  status?                            (number of runnig tasks) 
#        /   \
#   status   report_id??
#
#
function WSGetTaskReport($task_id) {
	$conn = WSStatsConnect();


	// TODO: Fix ldv-uploader !
	// NOW WE HAVE TWO WORKAROUNDS:
	// First when in environmnets ldv-uploader add wrong environment version in case of failed 
	// verification results (driver not compiled with kernel or have no ld commands):
	// Run verification with 
	// Environmnets: 32_1,77_1,08_1,29_1,37_1,39_1,43_1,60_1,68_1
	// On each kernels: linux-2.6.33.3, linux-2.6.32.12
	// In one task on driver serial-safe.tar.bz2 - from dir safe
	$result = WSStatsQuery('SELECT id,version FROM environments WHERE version LIKE \'%.tar.bz2\';');
	while($row = mysql_fetch_array($result)) {
			preg_match('/(.*)\.tar\.bz2$/', $row['version'], $lmatches);
			$fixed_version=$lmatches[1];
			// find original environmnet version
			$fresult = WSStatsQuery('SELECT id,version FROM environments WHERE version=\''.$fixed_version.'\';');
			if($frow = mysql_fetch_array($fresult)) {
				// fix all results - 1. replace env_id with fixed env_id
				WSStatsQuery('UPDATE launches SET environment_id='.$frow['id'].' WHERE scenario_id IS NULL AND trace_id IS NULL AND status=\'failed\';');
				// replace status running with status finished - OR SET IT TO FAILED?
				WSStatsQuery('UPDATE launches SET status=\'finished\' WHERE scenario_id IS NULL AND trace_id IS NULL AND status=\'running\' AND environment_id='.$frow['id'].';');
			}
			// remove wrong kernel environment
			WSStatsQuery('DELETE FROM environments WHERE id='.$row['id'].';');
	}
	// TODO: Add workaround for task for linux-2.6.35-rc3 - wl...., when launch have status finished
	//  and some other records in launches table with scenario_id or trace_id null
	// 1. if records with null and failed exists then we replace status running with status 
	// finished on ocrresponding records (rule + kernel compile failed)
	// Run verification with 
	// Environmnets: 32_1,77_1
	// On each kernels: linux-2.6.33.3, linux-2.6.35-rc3
	// In one task with driver wl.. unsafe
	$result = WSStatsQuery('SELECT driver_id,toolset_id,environment_id,task_id FROM launches WHERE rule_model_id IS NULL AND scenario_id IS NULL AND trace_id IS NOT NULL AND status=\'finished\';');
	while($row = mysql_fetch_array($result)) {
		WSStatsQuery('UPDATE launches SET status=\'finished\' WHERE task_id='.$row['task_id'].' AND environment_id='.$row['environment_id'].' AND toolset_id='.$row['toolset_id'].' AND driver_id='.$row['driver_id'].' AND rule_model_id IS NOT NULL AND scenario_id IS NULL AND trace_id IS NULL AND status=\'running\';');
	}




	$result = WSStatsQuery('SELECT launches.id, drivers.name AS drivername, launches.driver_id, launches.environment_id, launches.rule_model_id, launches.scenario_id, launches.trace_id, environments.version AS env, rule_models.name AS rule, drivers.name AS driver, launches.status FROM launches, tasks, environments, rule_models, drivers WHERE tasks.id='.$task_id.' AND  launches.task_id=tasks.id AND environments.id=launches.environment_id AND drivers.id=launches.driver_id AND rule_models.id=launches.rule_model_id AND scenario_id IS NULL AND trace_id IS NULL ORDER BY scenario_id, trace_id, env, rule;');
	if(mysql_num_rows($result) == 0) {
		WSPrintE("Could not find task or wrong user.");
		return;
	}	
	$i=-1;
	$j=0;
	$count=0;
	$last_env;
	$finished = 0;
	while($row = mysql_fetch_array($result))
  	{
		$task['driver_id']=$row['driver_id'];
		$task['drivername']=$row['drivername'];
		if(empty($last_env) || $last_env!=$row['env']) {
			$i++;
			$j=0;
			$last_env = $row['env'];
			$task['envs'][$i]['name']=$row['env'];
			$task['envs'][$i]['environment_id']=$row['environment_id'];
			unset($last_rule);
		}
		$task['envs'][$i]['rules'][$j]['name']=$row['rule'];
		$task['envs'][$i]['rules'][$j]['results']=array();
		$task['envs'][$i]['rules'][$j]['id']=$row['id'];
		$task['envs'][$i]['rules'][$j]['status']=$row['status'];
		$task['envs'][$i]['rules'][$j]['rule_model_id']=$row['rule_model_id'];
		if($row['status'] == 'finished') 
			$finished++;
		if($row['status'] != 'failed')
			$count++;
		$j++;
		WSPrintT($row['rule'].' '.$row['env'].' '.$row['status']);
	}
	WSPrintD('Count: '.$count);
	WSPrintD('All finished: '.$finished);
	if($finished == $count) {
		$task['progress'] = 100;
		$task['status'] = 'finished';
	} else if ($finished == 0) {
		$task['progress'] = 1;
	} else {
		$task['progress'] = round($finished*(100/$count));
	}
	$task['finished'] = $finished;
	// select result - very bad part - 
        // TODO: replace it to first select
	$result = WSStatsQuery('SELECT launches.id, launches.rule_model_id,  launches.environment_id, launches.trace_id, traces.result FROM launches, traces, tasks WHERE tasks.id='.$task_id.' AND launches.driver_id='.$task['driver_id'].' AND launches.task_id=tasks.id AND traces.id=trace_id AND scenario_id IS NOT NULL;');
	while($row = mysql_fetch_array($result)) {
		foreach ($task['envs'] as $env_key => $env) {
			if($env['environment_id']==$row['environment_id'])
			foreach($env['rules'] as $rule_key => $rule) {
				if($rule['rule_model_id']==$row['rule_model_id']) {
					$ver_result = array('status'=>  $row['result'], 'trace_id' => $row['trace_id']);
					array_push($task['envs'][$env_key]['rules'][$rule_key]['results'],$ver_result);
					break 2;
				}
			}
		}
	}
	WSStatsDisconnect($conn);
	return $task;
}

function __WSGetDetailedReport($trace_id) {
	$conn = WSStatsConnect();
	// TODO: add user=user .....
	$result = WSStatsQuery('SELECT traces.id AS id, traces.verifier, environments.version AS env, rule_models.name AS rule, drivers.name AS driver, traces.error_trace FROM launches, environments, rule_models, drivers, traces WHERE traces.id='.$trace_id.' AND launches.trace_id=traces.id AND environments.id=launches.environment_id AND drivers.id=launches.driver_id AND rule_models.id=launches.rule_model_id AND scenario_id IS NOT NULL AND trace_id IS NOT NULL;');
	if($row = mysql_fetch_array($result)) {
		$trace['trace_id']=$row['id'];
		$trace['env']=$row['env'];
		$trace['rule']=$row['rule'];
		$trace['drivername']=$row['driver'];
		$trace['error_trace']=$row['error_trace'];
		$trace['verifier']=$row['verifier'];
	}
	WSStatsDisconnect($conn);
	return $trace;
}

function WSGetDetailedReport($trace_id) {
	$trace = __WSGetDetailedReport($trace_id);
	$pwd = getcwd();
	$tmpdir = $pwd.'/ldv/tmp';
	// TODO:  test if this file already exists
	$tmpfile = $tmpdir.'/1';
	$tmpfile_report = $tmpdir.'/1.report';
	// write report to file
	// apache dir must be chmod a+x recursive 
	$freport = fopen($tmpfile_report, 'w');
	if(!$freport) {
		WSPrintD('Can\'t open file for write source trace: '.$tmpfile_report);
		WSPrintD('Check permissions.');
		return;
	}
	// write our data
	fwrite($freport, $trace['error_trace']);
	fclose($freport);
	$etv = $pwd.'/ldv/etv/bin/error-trace-visualizer.pl';
	WSPrintD(exec('/usr/bin/perl '.$etv.' --engine '.$trace['verifier'].' --report '.$tmpfile_report.' -o '.$tmpfile));
	WSPrintT('/usr/bin/perl '.$etv.' --engine '.$trace['verifier'].' --report '.$tmpfile_report.' -o '.$tmpfile);
	// read report :
	$fh = fopen($tmpfile, "rb");
	if(!$fh) {
		WSPrintD('Can\'t open tempfile with trace:'.$tmpfile);
		return;
	}
	$size = filesize($tmpfile);
	WSPrintD('Trace have size: '.$size);
	$trace['error_trace'] = fread($fh,$size);
	fclose($fh);
	return $trace;	
}

function WSGetHistory() {
	$conn = WSStatsConnect();
	$result = WSStatsQuery('select distinct tasks.id AS id,drivers.name AS driver, tasks.timestamp from tasks,launches,drivers WHERE tasks.username=\''.WSGetUser().'\' AND tasks.id=launches.task_id AND drivers.id=launches.driver_id;');
	$i=0;
	while($row = mysql_fetch_array($result))
  	{
		$history[$i]['id'] = $row['id'];
		$history[$i]['timestamp'] = $row['timestamp'];
		$history[$i++]['driver'] = $row['driver'];
	}
	WSStatsDisconnect($conn);
	return $history;
}

#
# Database functions 
#
function WSStatsQuery($query) {
	WSPrintT($query);
	return mysql_query($query);
}

function WSStatsConnect() {
	$conn = mysql_connect(WS_SDB_HOST, WS_SDB_USER, WS_SDB_PASS);
	if(!$conn) {
		WSPrintE('Could not connect to stats DB host: '.mysql_error());
		return;
	}	
	if(!mysql_select_db(WS_SDB_NAME)) {
		WSPrintE('Could not select stats db: '.mysql_error());
		return;
	}
	return $conn;
}

function WSStatsDisconnect($conn) {
	if(empty($conn)) {
		WSPrintE('Could not close epmty connection.');
		return;
	}
	if(!mysql_close($conn))	
		PrintE('Could not close connection to stats db: '.mysql_error());
}

#
# Drupal user functions
#
function WSGetUser() {
	// Drupal integration
       /* global $user;
	return $user;*/
	return 'mong';
}


?>
