<?php
#
# Log degines
#
define("WS_LL_DEBUG", "DEBUG");
define("WS_LL_ERROR", "ERROR");
define("WS_LL_NORMAL", "NORMAL");

#
# WS Protocol defines
#
define("WSM_WSTOLDVS_TASK_PUT_REQUEST","WSTOLDVS_TASK_PUT_REQUEST");
define("WSM_LDVSTOWS_TASK_PUT_RESPONSE","LDVSTOWS_TASK_PUT_RESPONSE");
define("WSM_LDVSTOWS_TASK_DESCR_RESPONSE","LDVSTOWS_TASK_DESCR_RESPONSE");
define("WSM_WSTOLDVS_TASK_STATUS_GET_REQUEST","WSTOLDVS_TASK_STATUS_GET_REQUEST");
define("WSM_LDVSTOWS_TASK_STATUS_GET_RESPONSE","LDVSTOWS_TASK_STATUS_GET_RESPONSE");

#
# WS Net function defines
#
define("WS_BLOCK_SIZE",8192);
define("WS_LDVS_SERVER_PORT",11111);
define("WS_LDVS_SERVER_NAME","localhost");


#
# get kernel list strucure
#
function WSGetSupportedEnvList() {
//	$rules1 = array("77_1","43_1");
	$rules1 = array("32_1","32_1");
//	$rules2 = array("77_1","32_1");
	$rules2 = array("32_1","32_1");
	
	$env1 = array('name' => "vanilla", 'rules' => $rules1);
	$env2 = array('name' => "rhkernel", 'rules' => $rules2);

	$envs = array($env1, $env2);
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

function WSPrintByLogLevel($string,$type) {
	if(WSIsDebug())
		print("<b>$type:</b> $string\n<br>");
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
	foreach($task['envs'] as $env_key => $env) {
		$WSMsg.='<env name="'.$env['name'].'">';
			foreach($env['rules'] as $rule_key => $rule) {
				$WSMsg.="<rule>$rule</rule>";
			}
		$WSMsg.='</env>';
	}
	return WSMWrapMsg($WSMsg);
}

function WSM_XML_WSTOLDVS_TASK_STATUS_GET_REQUEST($task) {
	# some checks
	if(!WSM_DEBUG_XML_WSTOLDVS_TASK_STATUS_GET_REQUEST($task)) return;
	$WSMsg='<type>'.WSM_WSTOLDVS_TASK_STATUS_GET_REQUEST.'</type>';
	$WSMsg.='<user>'.$task['user'].'</user>';
	$WSMsg.='<id>'.$task['id'].'</id>';
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

function WSM_OBJ_XML_Parse_WSM_LDVSTOWS_TASK_STATUS_GET_RESPONSE($msg) {
	$msg['user'] = preg_replace("/.*<user>(.*)<\/user>.*/", "$1", $msg['wsmbuf']);
	$msg['id'] = preg_replace("/.*<id>(.*)<\/id>.*/", "$1", $msg['wsmbuf']);
	preg_match_all("/<env name=.*?<\/env>/", $msg['wsmbuf'],$env_matches);
	$a_envs = array();
	foreach ($env_matches[0] as $env_key => $env) {
		$env_name = preg_replace("/.*<env name=\"(.*?)\">.*/", "$1", $env);
		$a_rules = array();
		preg_match_all("/<rule name=.*?<\/rule>/", $env,$rule_matches);
		foreach ($rule_matches[0] as $rule_key => $rule) {
			$rule_status = preg_replace("/.*<status>(.*)<\/status>.*/", "$1", $rule);
			$rule_name = preg_replace("/.*<rule name=\"(.*?)\">.*/", "$1", $rule);
			$a_results = array();
			preg_match_all("/<result>.*?<\/result>/", $rule,$results);
			foreach ($results[0] as $result_key => $result) {
				$result_verdict = preg_replace("/.*<verdict>(.*)<\/verdict>.*/", "$1", $result);
				$result_report_id = preg_replace("/.*<report>(.*)<\/report>.*/", "$1", $result);
				$a_result = array('verdict' => $result_verdict, 'report' => $result_report_id);
				array_push($a_results,$a_result);	
			}
			$a_rule = array('name' => $rule_name, 'status' => $rule_status, 'results' => $a_results);
			array_push($a_rules,$a_rule);	
		}
		$a_env = array( 'name' => $env_name, 'rules' => $a_rules);
		array_push($a_envs,$a_env);	
	}
	$msg['envs'] = $a_envs;
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
	} else if($msg['type'] == WSM_LDVSTOWS_TASK_STATUS_GET_RESPONSE) {
		$msg = WSM_OBJ_XML_Parse_WSM_LDVSTOWS_TASK_STATUS_GET_RESPONSE($msg);
	} else {
		WSPrintE('Unknown msg type: "'.$msg['type'].'".');
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

function WSM_OBJ_XML_LDVSTOWS_TASK_STATUS_GET_RESPONSE($wsm) {
	$msg = WSM_OBJ_XML($wsm);
	if(!WSM_OBJ_XML_ResultSharedTest($msg,WSM_LDVSTOWS_TASK_STATUS_GET_RESPONSE)) return;
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
# $task['user'] = "mong";
# $task['driverpath'] = "/home/iceberg/ldv-tools/ldv-online/ldvsrv/lsapi.php";
# $task['envs'] = array($env1, $env2);
#
# WSPutTask($task);
function WSPutTask($task) {
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
# input:
# task -> user - username
#      -> id   - id for task
#
# return next information
#
#         _ task _
# 	/         \
#      |         envs[i] 
#   status      /    \ 
#          rules[i]   status
#           /     \
#      results[i]  status?     
#        /   \
#   status   report
#
#
function WSGetTaskStatus($task) {
	$sock = WSConnect();
	if(empty($sock)) return;
	WSPrintD("Try to create WSM message.");
	$WSMsg = WSM_XML_WSTOLDVS_TASK_STATUS_GET_REQUEST($task);
	WSPrintD("WSM Message contains:$WSMsg");
	if(empty($WSMsg)) { fclose($sock); return; };
	WSPrintD("Send request:$WSMsg");
	fputs($sock,$WSMsg);
	# wait for response LDVSTOWS_TASK_DESCR_RESPONSE
	WSPrintD('Wait for response LDVSTOWS_TASK_STATUS_GET_RESPONSE');
	$results = WSM_OBJ_XML_LDVSTOWS_TASK_STATUS_GET_RESPONSE(fgets($sock));
	if(empty($results)) {
		WSPrintD('Empty results');
		fclose($sock);
		return;
	}
	fclose($sock);
	WSPrintD('Task status successfully get.');
	return $results;
}
/*$rules1 = array("8_1","32_1");
$rules2 = array("64","89");

$env1 = array('name' => "vanilla", 'rules' => $rules1);
$env2 = array('name' => "rhkernel", 'rules' => $rules2);

$task['user'] = "mong";
$task['driverpath'] = "/home/iceberg/ldv-tools/ldv-online/ldvsrv/lsapi.php";
$task['envs'] = array($env1, $env2);

WSPutTask($task);*/
?>
