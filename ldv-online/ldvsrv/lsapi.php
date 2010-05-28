#!/usr/bin/php
<?php
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
	return "<?xml version=\"1.0\"?><msg><type>$type</type>".WSConverToSmallXML($data)."</msg>";
}

function WSGetXMLHeader() {
	return("<?xml version=\"1.0\"?>");
}

function WSMWrapMsg($msg) {
	return WSGetXMLHeader()."<msg>$msg</msg>";
}


#
# WS Log functions
#
#
function WSPrintE($string) {
	WSPrintByLogLevel($string,"ERROR");
}

function WSPrintN($string) {
	WSPrintByLogLevel($string,"NORMAL");
}

function WSPrintByLogLevel($string,$type) {
	print("$type: $string\n");
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
			WSPrintE("Field \"user\" - not found.");
			return false;
		} else if(empty($task['driverpath'])) {
			WSPrintE("Field \"driverpath\" - not found.");
			return false;
		} else if(!file_exists($task['driverpath'])) {
			WSPrintE("File \"".$task['driverpath']."\" - not exists.");
			return false;
		} else if(!is_readable($task['driverpath'])) {
			WSPrintE("File \"".$task['driverpath']."\" - not redable.");
			return false;
		} else if(empty($task['envs'])) {
			WSPrintE("Field \"envs\" - not found.");
			return false;
		} else if(count($task['envs']) == 0) {
			WSPrintE("Size of \"envs\" - equals 0.");
			return false;
		}
	}
	return true;
}

function WSM_XML_WSTOLDVS_TASK_PUT_REQUEST($task) {
	# some checks
	if(!WSM_DEBUG_XML_WSTOLDVS_TASK_PUT_REQUEST($task)) return;
	$WSMsg="<type>WSTOLDVS_TASK_PUT_REQUEST</type>";
	$WSMsg.="<user>".$task['user']."</user>";
	$WSMsg.="<sourcelen>".filesize($task['driverpath'])."</sourcelen>";
	foreach($task['envs'] as $env_key => $env) {
		$WSMsg.="<env name=\"".$env['name']."\">";
			foreach($env['rules'] as $rule_key => $rule) {
				$WSMsg.="<rule>$rule</rule>";
			}
		$WSMsg.="</env>";
	}
	return WSMWrapMsg($WSMsg);
}

#
# small function for parse xml strings
#
function WSM_OBJ_XML_StandartParse($wsm) {
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
	if($msg['type'] == "LDVSTOWS_TASK_DESCR_RESPONSE" || $msg['type'] == "LDVSTOWS_TASK_PUT_RESPONSE") {
		return $msg;
	} else {
		WSPrintE("Unknown msg type: \"".$msg['type']."\".");
	}
	unset($msg['wsmbuf']);
	return $msg;
}

function WSM_OBJ_XML_ResultSharedTest($msg,$type) {
	if($msg['type'] != $type) {
		WSPrintE("Not $type message from WS. Type \"".$msg['type']."\".");
		return false;
	}
	if($msg['result'] != "OK") {
		WSPrintE("Result: \"".$msg['type']."\".");
		return false;
	}
	return true;
}

function WSM_OBJ_XML_LDVSTOWS_TASK_DESCR_RESPONSE($wsm) {
	$msg = WSM_OBJ_XML($wsm);
	if(WSM_OBJ_XML_ResultSharedTest($msg,"LDVSTOWS_TASK_DESCR_RESPONSE")) return true;
}

function WSM_OBJ_XML_LDVSTOWS_TASK_PUT_RESPONSE($wsm) {
	$msg = WSM_OBJ_XML($wsm);
	if(WSM_OBJ_XML_ResultSharedTest($msg,"LDVSTOWS_TASK_PUT_RESPONSE")) return true;
}


#
# Net functions 
#
#
function WSGetPort() {
	return "11111";
}

function WSGetServerName() {
	return "localhost";
}

function WSGetBlockSize() {
	return 8192;
}

function WSConnect() {
	$sock = fsockopen(WSGetServerName(),WSGetPort(),$errno,$errstr);
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
		$buffer.= fgets($sock, WSGetBlockSize());
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
	print("Send request:$WSMsg\n");
	fputs($sock,$WSMsg);
	# wait for response LDVSTOWS_TASK_DESCR_RESPONSE
	print("First response.\n");
	if(WSM_OBJ_XML_LDVSTOWS_TASK_DESCR_RESPONSE(fgets($sock)) == null) {
		fclose($sock);
		return;
	}
	# send binary data
	$fh = fopen($task['driverpath'], "r");
	if(!$fh) {
		WSPrintE("Failed to open file \"".$task['driverpath']."\".");
		fclose($sock);
		return;
	}
	print("Start to send binary data\n");
	while (!feof($fh)) {
		$data = fread($fh, WSGetBlockSize());
		print("Send iterate size ".count($data)." bytes\n");
		fputs($sock, $data);
	}
	print("End sending binary data\n");
	fclose($fh);
	# try to get LDVSTOWS_TASK_PUT_RESPONSE
	print("Last response.\n");
	if(WSM_OBJ_XML_LDVSTOWS_TASK_PUT_RESPONSE(fgets($sock)) == null) {
		fclose($sock);
		return;
	}
	fclose($sock);
	return true;
}


$rules1 = array("8_1","32_1");
$rules2 = array("64","89");

$env1 = array('name' => "vanilla", 'rules' => $rules1);
$env2 = array('name' => "rhkernel", 'rules' => $rules2);

$task['user'] = "Usver";
$task['driverpath'] = "/home/iceberg/ldvtest/drivers/reports_bad.tar.bz2";
$task['envs'] = array($env1, $env2);

if(WSPutTask($task)) WSPrintN("Task successfully put to LDVS Server.");
?>
