<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<?php
#
# Log defines
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
	WSPrintT($ldvs_server_config);
	if(!is_file($ldvs_server_config)) {
		WSPrintE("Can't find file with configuration.");
		WSInitDefault();
		WSInitPrint();
		return;
	}
        if(($file_array=file($ldvs_server_config))) {
                for($i=0; $i<count($file_array); $i++) {
			if(preg_match('/DriverMaxSizeForUpload=(.*)/', $file_array[$i], $lmatches)) 
				define("WS_MAX_DRIVER_SIZE",$lmatches[1]);
			if(preg_match('/WSTempDir=(.*)/', $file_array[$i], $lmatches)) 
				define("WS_TMP_DIR",$lmatches[1]);
			if(preg_match('/ErrorTraceVisualizer=(.*)/', $file_array[$i], $lmatches)) 
				define("WS_ETV",$lmatches[1]);
			if(preg_match('/LDVFaceDebugMode=(.*)/', $file_array[$i], $lmatches)) 
				define("WS_DEBUG_MODE",$lmatches[1]);
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
                       	if(preg_match('/RulesDBPath=(.*)/', $file_array[$i], $lmatches))
				define("WS_RULES_DB_PATH",$lmatches[1]);
                       	if(preg_match('/ModelsDBPath=(.*)/', $file_array[$i], $lmatches))
				define("WS_MODELS_DB_PATH",$lmatches[1]);
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
	WSPrintD("Set up WS_RULES_DB_PATH=".WS_RULES_DB_PATH);
	WSPrintD("Set up WS_MODELS_DB_PATH=".WS_MODELS_DB_PATH);
	WSPrintD("Set up WS_DEBUG_MODE=".WS_DEBUG_MODE);
	WSPrintD("Set up WS_ETV=".WS_ETV);
	WSPrintD("Set up WS_TMP_DIR=".WS_TMP_DIR);
	WSPrintD("Set up WS_MAX_DRIVER_SIZE=".WS_MAX_DRIVER_SIZE);
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
	define("WS_MODELS_DB_PATH","/home/iceberg/ldv-tools/kernel-rules/model-db.xml");
	define("WS_RULES_DB_PATH","/home/iceberg/ldv-tools/kernel-rules/rules/DRVRULES_en.trl");
	define("WS_DEBUG_MODE","off");
	define("WS_ETV","/opt/ldv/bin/error-trace-visualizer.pl");
	define("WS_TMP_DIR","/home/iceberg/ldvtest/ldv-online/tmpdir");
	define("WS_MAX_DRIVER_SIZE",1500000);
}

#
# get kernel list strucure
#
function WSGetSupportedEnvList() {
	$rules1 = array('32_1','77_1','08_1','29_1','37_1','43_1','60_1','68_1');
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
	if(WSIsDebug() == "toface")
		print("<b>$type:</b> $string\n<br>");
}

function WSIsDebug() {
	return WS_DEBUG_MODE;
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
	// Wrapper for fix : "Premature end of file on server side message"
	$result = __WSPutTask($task);
	for($i=0; $i<3; $i++) {
		if($result != null) return $result;
		sleep(1);
		$result = __WSPutTask($task);
	}
	return $result;
}

function __WSPutTask($task) {
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
	// Workaround for task for linux-2.6.35-rc3 - wl...., when launch have status finished
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




	$result = WSStatsQuery('SELECT tasks.id AS task_id, tasks.timestamp, launches.id, drivers.name AS drivername, launches.driver_id, launches.environment_id, launches.rule_model_id, launches.scenario_id, launches.trace_id, environments.version AS env, rule_models.name AS rule, drivers.name AS driver, launches.status FROM launches, tasks, environments, rule_models, drivers WHERE tasks.id='.$task_id.' AND  launches.task_id=tasks.id AND environments.id=launches.environment_id AND drivers.id=launches.driver_id AND rule_models.id=launches.rule_model_id AND scenario_id IS NULL AND trace_id IS NULL ORDER BY scenario_id, trace_id, env, rule;');
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
		$task['task_id']=$row['task_id'];
		$task['timestamp']=$row['timestamp'];
		// Fix for driver name that uploading to ldvs twice
                $task['drivername'] = preg_replace('/_\d+$/','', $row['drivername']);
		//	$task['drivername']=$row['drivername'];
		$task['ldvs_drivername']=$row['drivername'];
		if(empty($last_env) || $last_env!=$row['env']) {
			$i++;
			$j=0;
			$last_env = $row['env'];
			$task['envs'][$i]['name']=$row['env'];
			$task['envs'][$i]['status']='ok';
			$task['envs'][$i]['environment_id']=$row['environment_id'];
			unset($last_rule);
		}
		$task['envs'][$i]['rules'][$j]['model_ident']=$row['rule'];
		$task['envs'][$i]['rules'][$j]['results']=array();
		$task['envs'][$i]['rules'][$j]['id']=$row['id'];
		$task['envs'][$i]['rules'][$j]['status']=$row['status'];
		$task['envs'][$i]['rules'][$j]['rule_model_id']=$row['rule_model_id'];
		// Add information from model_db and rules db
		$rule_info = WSGetRuleInfoByLDVIdent($task['envs'][$i]['rules'][$j]['model_ident']);
		$task['envs'][$i]['rules'][$j]['tooltip']=$rule_info['TITLE'];
		$task['envs'][$i]['rules'][$j]['rule_id']=$rule_info['ID'];
		$task['envs'][$i]['rules'][$j]['summary']=$rule_info['SUMMARY'];
		$task['envs'][$i]['rules'][$j]['description']=$rule_info['DESCRIPTION'];
		$task['envs'][$i]['rules'][$j]['name']=$rule_info['NAME'];
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
	// Add build failed statuses - replace it to first select
	$result=WSStatsQuery('SELECT stats.id AS trace_id, tasks.timestamp, launches.id, drivers.name AS drivername, launches.driver_id, launches.environment_id, environments.version AS env FROM environments,drivers,tasks,launches,traces,stats WHERE environments.id=launches.environment_id AND drivers.id=launches.driver_id AND launches.task_id=tasks.id AND stats.id=traces.build_id AND launches.task_id='.$task_id.' AND launches.rule_model_id IS NULL AND launches.scenario_id IS NULL AND launches.trace_id=traces.id AND success=0 AND launches.status=\'finished\';');
	while($row = mysql_fetch_array($result)) {
		foreach($task['envs'] as $env_key => $env) {
			if($env['environment_id'] == $row['environment_id']) {
				$task['envs'][$env_key]['status']='Build failed';
				$task['envs'][$env_key]['trace_id']=$row['trace_id'];
				break;
			}
		}
	}
	// Sort by groups safe/unsafe/unknown etc
	foreach($task['envs'] as $env_key => $env) {
		foreach($env['rules'] as $rule_key => $rule) {
			// calculate SAFE/UNSAFE/UNKNOWN
			$unsafes=array();
			$safes=array();
			$unknowns=array();
			foreach($rule['results'] as $result_key => $result) {
				if($result['status'] == 'safe')
					array_push($safes,$result);		
				else if ($result['status'] == 'unsafe')  
					array_push($unsafes,$result);		
				else if ($result['status'] == 'unknown')
					array_push($unknowns,$result);
			}
			if(count($unsafes)>0) 
				$task['envs'][$env_key]['rules'][$rule_key]['results'] = $unsafes;
			else if(count($safes)>0)	
				$task['envs'][$env_key]['rules'][$rule_key]['results'] = array($safes[0]);
			else if(count($unknowns)>0)		
				$task['envs'][$env_key]['rules'][$rule_key]['results'] = array($unknowns[0]);
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
		//$trace['drivername']=$row['driver'];
                $trace['drivername'] = preg_replace('/_\d+$/','', $row['driver']);
		$trace['error_trace']=$row['error_trace'];
		$trace['verifier']=$row['verifier'];
	}
	
	$result = WSStatsQuery('SELECT name, contents FROM sources WHERE trace_id='.$trace_id.';');
	$trace['sources'] = array();
	while($row = mysql_fetch_array($result)) {
	//	print "s";
		$source = array('name'=>  $row['name'], 'content' => $row['contents']);
	//	$source = array('name'=>  $row['name']);
		array_push($trace['sources'],$source);
	}
	WSStatsDisconnect($conn);
	return $trace;
}


// TODO: add check for trace type (build error or unsafe)
function WSGetDetailedReport($trace_id) {
	$trace = __WSGetDetailedReport($trace_id);
	$tmpdir = WS_TMP_DIR;
	if(!is_dir($tmpdir)) {
		WSPrintW('Temp dir not exists: '.$tmpdir.' - try to create it...');
		if(!mkdir($tmpdir)) {
			WSPrintE('Can\'t create temp dir: '.$tmpdir);
			return;
		}
		chmod($tmpdir, 0777);
     //   chmod($task_dir, 0777);
      //  chmod($task_dir.'/description', 0666);
       // chmod($task_dir.'/driver', 0666);

	}

	$current_tmpdir=$tmpdir.'/'.$trace_id;
	$tmpfile = $current_tmpdir.'/trace';
	if(!is_dir($current_tmpdir)) {
		// create dir
		if(!mkdir($current_tmpdir)) {
			WSPrintD('Can\'t create tmp directory for current trace: '.$current_tmpdir);
			WSPrintD('Check permissions.');
			return;
		}
		chmod($current_tmpdir, 0777);
		// write trace
		$tmpfile_report = $current_tmpdir.'/report';
		$freport = fopen($tmpfile_report, 'w');
		if(!$freport) {
			WSPrintD('Can\'t open file for write trace: '.$tmpfile_report);
			WSPrintD('Check permissions.');
			return;
		}
		fwrite($freport, $trace['error_trace']);
		fclose($freport);
      		chmod($tmpfile_report, 0666);

		// write sources
		$tmpfile_sources = $current_tmpdir.'/sources';
		$freport = fopen($tmpfile_sources, 'w');
		if(!$freport) {
			WSPrintD('Can\'t open file for write source files: '.$tmpfile_sources);
			WSPrintD('Check permissions.');
			return;
		}
		// write our data
		$first=true;
		foreach($trace['sources'] as $source) {
			if($first) {
				$first=false;
				fwrite($freport, '-------'.$source['name'].'-------'."\n");
			} else {
				fwrite($freport, "\n".'-------'.$source['name'].'-------'."\n");
			}
			fwrite($freport, $source['content']).'<br>';
		}
		fclose($freport);
      		chmod($tmpfile_sources, 0666);
		// TODO: set up in parameters
		//$etv = $pwd.'/ldv/etv/bin/error-trace-visualizer.pl';
		WSPrintD(exec('/usr/bin/perl '.WS_ETV.' --engine '.$trace['verifier'].' --report '.$tmpfile_report.' --src-files '.$tmpfile_sources.' -o '.$tmpfile));
		WSPrintT('/usr/bin/perl '.WS_ETV.' --engine '.$trace['verifier'].' --report '.$tmpfile_report.' --src-files '.$tmpfile_sources.' -o '.$tmpfile);
		chmod($tmpfile, 0666);		

	}
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

function WSGetDetailedBuildError($trace_id) {
	$conn = WSStatsConnect();
	// TODO: add user=user .....
	$result = WSStatsQuery('SELECT stats.id, stats.description AS error_trace, drivers.name AS driver, environments.version AS env FROM stats,traces,launches,drivers,environments WHERE stats.id='.$trace_id.' AND traces.build_id='.$trace_id.' AND traces.result=\'unknown\' AND traces.maingen_id IS NULL AND traces.dscv_id IS NULL AND traces.ri_id IS NULL AND traces.rcv_id IS NULL AND launches.trace_id=traces.id AND drivers.id=launches.driver_id AND environments.id=launches.environment_id;');
	if($row = mysql_fetch_array($result)) {
		$trace['trace_id']=$row['id'];
		$trace['env']=$row['env'];
	#	$trace['drivername']=$row['driver'];
                $trace['drivername'] = preg_replace('/_\d+$/','', $row['driver']);
        #        $trace['error_trace'] = preg_replace('/\n/','<br>', $row['error_trace']);
                $trace['error_trace'] = $row['error_trace'];
	}
	$lines = preg_split('/\n/', $trace['error_trace']);
	
	$lines_count = count($lines);
	$trace['error_trace'] = '<p style="border:1px solid black;line-height: normal; height:400px;font-size:10px;font-family:monospace;overflow:scroll;white-space:pre">';
	for ($i = 0; $i <= $lines_count; $i++) { 
		$trace['error_trace'] .= sprintf ("<span style=\"background-color:#E0E0E0\">%5d </span>", $i); 
		$trace['error_trace'] .=  $lines[$i].'<BR>';
	}
	$trace['error_trace'] .= '</p>';

	WSStatsDisconnect($conn);
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
                $history[$i]['ldvs_drivername'] = $row['driver'];
                $history[$i++]['driver'] = preg_replace('/_\d+$/','', $row['driver']);
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

#
# functions to work with rules db
#
function WSGetRulesXml() {
	return WS_RULES_DB_PATH;
}

function WSGetModelDbXml() {
	return WS_MODELS_DB_PATH;
}


#
# 32_1 -> 0032
#
function WSGetRuleIdByLDVIdent($rule_id) {
	//TODO: trim rule id
	$dom = new DomDocument();
	$dom->load(WSGetModelDbXml());
	foreach ($dom->getElementsByTagName('model') as $model) {
		if ($model->hasAttribute('id') && $model->getAttribute('id') == $rule_id) {
			foreach ($model->childNodes as $model_node) {
				if ( $model_node->nodeType == 1 && $model_node->nodeName == 'rule')
					return $model_node->textContent;
			}
		}
	}
}

function WSGetRuleNodeById($rule_id) {
	$dom = new DomDocument();
	$dom->load(WSGetRulesXml());
	foreach ($dom->documentElement->childNodes as $articles) {
		if ($articles->nodeType == 1 &&
			$articles->nodeName == 'RULE_ERROR' ||
			$articles->nodeName == 'RULE_WARNING' ||
			$articles->nodeName == 'RULE_RECOMMENDATION') {
			foreach ($articles->childNodes as $articles_l1) {
				if ( $articles_l1->nodeType == 1 &&
					$articles_l1->nodeName == 'ID' &&
					$articles_l1->textContent == $rule_id)
				return $articles;
			}
		}
	}
}

function WSGetRuleByNumber($rule_XML_ID) {
    $dom_node = WSGetRuleNodeById($rule_XML_ID);
    if(!isset($dom_node)) {
        print "Rule not exists.<br>";
        return;
    }
    $rule_XML_TYPE = $dom_node->nodeName;
    foreach ($dom_node->childNodes as $articles)
            if ($articles->nodeType == 1)
            switch ($articles->nodeName) {
                case 'NAME':
                    $rule_XML_NAME = $articles->textContent;
                    break;
                case 'TITLE':
                    $rule_XML_TITLE = $articles->textContent;
                    break;
                case 'STATUS':
                    $rule_XML_S = $articles->textContent;
                    break;
                case 'SUMMARY':
                    $rule_XML_SUMMARY = $articles->textContent;
                    break;
                case 'DESCRIPTION':
                    $rule_XML_DESCRIPTION = $articles->textContent;
                    break;
                case 'NOTES':
//                    $rule_XML_NOTES = preg_replace('/\n/','<br>', $articles->textContent);
                    $rule_XML_NOTES = $articles->textContent;
                    break;
                case 'LINKS':
                    $rule_XML_LINKS = $articles->textContent;
                    break;
                case 'EXAMPLE':
                    $rule_XML_EXAMPLE = $articles->textContent;
                    break;
                }
		// While  filed NAME is not released - print 'NAME' -> "Its rule name". 
		// TODO: 'NAME' => $rule_XML_NAME
    $rule = array('ID' => $rule_XML_ID, 'NAME' =>$rule_XML_NAME, 'TYPE' => $rule_XML_TYPE, 'STATUS' => $rule_XML_STATUS, 'TITLE' => $rule_XML_TITLE, 'SUMMARY' => $rule_XML_SUMMARY,
        'DESCRIPTION' => $rule_XML_DESCRIPTION, 'EXAMPLE' => $rule_XML_EXAMPLE, 'LINKS' => $rule_XML_LINKS,
        'NOTES' => $rule_XML_NOTES);
    return $rule;
}

function WSGetRuleInfoByLDVIdent($rule_ldv_id) {
	return WSGetRuleByNumber(WSGetRuleIdByLDVIdent($rule_ldv_id));
}

?>
