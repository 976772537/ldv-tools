#!/usr/bin/php
<?php

function ssendTask($task) {
	
}

function serializeTaskDescription($task) {
	$sTask = filesize($task['driver'])."@";
	foreach ($task['envs'] as $task_num => $env) {
		$sTask .= $env['name']."@";
		foreach ($env['rules'] as $rule_num => $rule) {
			if($rule_num != 0)
				$sTask .= ",".$rule;
			else
				$sTask .= $rule;
		}	
		$sTask .= ":";
	}	
	return $sTask;
}



function sendTask($task) {
	$sGetTaskRequest = chr(1);
	$sGetTaskResponse = chr(2);
	$sGetTaskFile = chr(3);
	$sock = fsockopen("localhost",11111,$errno,$errstr);
	if (!$sock) 
	{ 
		echo("$errno($errstr)"); 
		return; 
	} else {
//		echo "1stage\n";	
//		fputs($sock,$sGetTaskRequest);
//		fputs($sock,"hello");
//		echo "2stage\n";	
//		$result = fgets($sock,2);
//		$res = ord($result);
//		echo "\"$res\"\n";

//		socket_set_blocking($sock,1);
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

$ctask['driver'] = "/home/iceberg/ldvtest/drivers/reports_bad.tar.bz2";
$ctask['envs'] = array($env1, $env2);

sendTask($ctask);
?>
