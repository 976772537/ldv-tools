#!/usr/bin/php
<?php

function WSGetPort() {
	return "111111";
}

function WSGetServerName() {
	return "localhost";
}

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

function WSM_XML_WSTOLDVS_TASK_PUT_REQUEST($data) {
	
}


function WSPutTask($task) {
	$sock = fsockopen(WSGetServerName(),WSGetPort(),$errno,$errstr);
	if (!$sock) 
	{ 
		return $errno($errstr);  
	} else {
		fputs($sock,$sGetTaskRequest);
		$sym = serializeTaskDescription($task);
		fputs($sock,$sym);
		echo "1stage\n";
		if(fgets($sock,2) == $sGetTaskFile) {
			echo "Get task file stage\n";
			$fh = fopen($task['driver'], "r") or die("Can't open file!");
			while (!feof($fh)) {
				$data = fread($fh, 8192);
				fputs($sock, $data);
			}
			fclose($fh);
			if(fgets($sock,2) == $sGetTaskResponse) {
				echo "Ok\n";
				fclose($sock);
				return true;
			}
		}
		fclose($sock);
	}
	return false;
}


$rules1 = array("8_1","32_1");
$rules2 = array("64","89");

$env1 = array('name' => "vanilla", 'rules' => $rules1);
$env2 = array('name' => "rhkernel", 'rules' => $rules2);

$task['user'] = "Usver";
$task['driverpath'] = "/home/iceberg/ldvtest/drivers/reports_bad.tar.bz2";
$task['envs'] = array($env1, $env2);

echo WSConvertToMsg($task,"WS");
?>
