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
	$rules1 = array("77_1","43_1");
	$rules2 = array("77_1","32_1");
	
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

#
# small function for parse xml strings
#
function WSM_OBJ_XML_StandartParse($wsm) {
	$wsm=trim($wsm); 
	$msg['wsmbuf'] = preg_replace("/.*<msg>(.*)<\/msg>.*/", "$1", $wsm);
	$msg['type'] = preg_replace("/.*<type>(.*)<\/type>.*/", "$1", $msg['wsmbuf']);
	$msg['result'] = preg_replace("/.*<result>(.*)<\/result>.*/", "$1", $msg['wsmbuf']);
	return $msg;
}

#
# Functions that conver WMS from XMl format
# 	to corresponding PHP structures;
#
#
function WSM_OBJ_XML($wsm) {
	$msg = WSM_OBJ_XML_StandartParse($wsm);
	if($msg['type'] == WSM_LDVSTOWS_TASK_DESCR_RESPONSE || $msg['type'] == WSM_LDVSTOWS_TASK_PUT_RESPONSE) {
		return $msg;
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
	if(WSM_OBJ_XML_ResultSharedTest($msg,WSM_LDVSTOWS_TASK_PUT_RESPONSE)) return true;
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
	if(WSM_OBJ_XML_LDVSTOWS_TASK_PUT_RESPONSE(fgets($sock)) == null) {
		fclose($sock);
		return;
	}
	fclose($sock);
	WSPrintD('Task successfully put to LDVS Server.');
	return true;
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
