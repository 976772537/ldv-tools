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
	$rules1 = array("32_1","77_1");
	$rules2 = array("32_1","77_1");
	
	$env1 = array('name' => "linux-2.6.32.12", 'rules' => $rules1);
	$env2 = array('name' => "linux-2.6.35-rc3", 'rules' => $rules2);

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
function WSGetTaskReport($task) {
	$result = array( 'verdict' => "UNKNOWN");
	$results = array($result);
	$rule = array ('name' => "32_1", 'status' => "UNKNOWN", 'results' => $results);
	$rules = array($rule);
	$env = array( 'name' => "linux-2.6.32.12", 'status' => "OK", 'rules' => $rules);
	$envs = array($env);
	$tresult = array( 'id' => 1, 'status' => "OK", 'envs' => $envs);
	
	$conn = WSStatsConnect();
	// test if task with this id and username exists
	WSPrintT("SELECT id FROM tasks WHERE id=".$task['id']." AND username='".$task['user']."';");
	$result = mysql_query("SELECT id FROM tasks WHERE id=".$task['id']." AND username='".$task['user']."'",$conn);
	if(mysql_num_rows($result)==0) {
		WSPrintE("Could not find task or wrong user.");
		return;
	}


	WSStatsDisconnect($conn);
	// get all small task statuses
/*	while($row = mysql_fetch_array($result))
  	{
  		echo $row['FirstName'] . " " . $row['LastName'];
  		echo "<br />";
	}*/
	return $tresult;
}

#
# Sandbox - for develop new functions
#
/*function WSSandbox() {
	$conn = WSStatsConnect();
	WSStatsDisconnect($conn);
}*/

#
# Database functions 
#
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
		WSPrintE("Could not close epmty connection.");
		return;
	}
	if(!mysql_close($conn))	
		PrintE('Could not close connection to stats db: '.mysql_error());
}



?>
