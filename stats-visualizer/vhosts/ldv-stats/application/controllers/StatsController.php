<?php
/*
 * Copyright (C) 2010-2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

class StatsController extends Zend_Controller_Action
{
  protected $_globals;
  protected $_profileInfo;

  public function init()
  {
    // Disable rendering and layout printing for AJAX requests.
    if ($this->getRequest()->isXmlHttpRequest()) {
      $this->_helper->viewRenderer->setNoRender();
      $this->_helper->layout->disableLayout();
    }

    $this->_globals = array();

    // Obtain profile name from parameters.
    if ($this->_hasParam('profilename')) {
      $this->_globals['profilename'] = $this->_getParam('profilename');
    }

    // Get current database connection settings from the address to be used
    // instead of the current profile ones.
    if ($this->_hasParam('name')) {
      $this->_globals['name'] =  $this->_getParam('name');
    }
    if ($this->_hasParam('user')) {
      $this->_globals['user'] =  $this->_getParam('user');
    }
    if ($this->_hasParam('host')) {
      $this->_globals['host'] =  $this->_getParam('host');
    }
    if ($this->_hasParam('password')) {
      $this->_globals['password'] =  $this->_getParam('password');
    }

    // Get information on an url-specified filter.
    if ($this->_hasParam('filter')) {
      $this->_globals['filter'] =  $this->_getParam('filter');
    }

    // Use session global variables just for unimportant time counting.
    $global = new Zend_Session_Namespace();

    // Remember the time where the page processing was begin.
    $starttime = explode(' ', microtime());
    $starttime =  $starttime[1] + $starttime[0];
    $global = new Zend_Session_Namespace();
    $global->startTime = $starttime;

    // Get information on the current profile.
    $this->_logger = Zend_Registry::get('logger');

    // Try to use previously obtained information on a given profile.
    if ($global->profileCurrent['name']) {
      if (array_key_exists('profilename', $this->_globals) && $global->profileCurrent['name'] == $this->_globals['profilename']
        || !array_key_exists('profilename', $this->_globals) && $global->profileCurrent['name'] == '__DEFAULT') {
        $this->_logger->log("Use previously obtained information on the given profile: '" . $global->profileCurrent['name'] . "'", Zend_Log::DEBUG);
        $this->_profileInfo = $global->profileCurrent['info'];
        return;
      }
    }

    $profileMapper = new Application_Model_ProfileMapper();
    if (array_key_exists('profilename', $this->_globals)) {
      $this->_profileInfo = $profileMapper->getProfileInfo($profileMapper->getProfile($this->_globals['profilename']));
      $global->profileCurrent['name'] = $this->_globals['profilename'];
    }
    else {
      $this->_profileInfo = $profileMapper->getProfileInfo();
      $global->profileCurrent['name'] = '__DEFAULT';
    }

    $global->profileCurrent['info'] = $this->_profileInfo;

    $this->_logger->log("Successfully collect information on the given profile: '" . $global->profileCurrent['name'] . "'", Zend_Log::DEBUG);
  }

  public function indexAction()
  {
    // Get all parameters including page name, statistics key names and values
    // and so on.
    $params = $this->_getAllParams();

    $submit = '';
    if (array_key_exists('submit', $params)) {
      $submit = $params['submit'];
    }

    $statsMapper = new Application_Model_StatsMapper();
    $this->view->entries = $statsMapper->getPageStats($this->_profileInfo, $params);
    $this->view->entries['Globals'] = $this->_globals;
    $this->view->entries['Profile'] = array('name' => $this->_profileInfo->profileName, 'user' => $this->_profileInfo->profileUser);
    $this->view->entries['Profile pages'] = $this->_profileInfo->getPageNames();

    if ($submit == 'Print CSV') {
      $this->view->entries['Format'] = 'CSV';
    }

    $request = $this->getRequest();

    // Make a form for the tasks comparison.
    $formTasksComparison = new Application_Form_TasksComparison();

    // Make a form for the profiles update.
    $formUpdateProfiles = new Application_Form_UpdateProfiles();

    if ($this->getRequest()->isPost()) {
      if ($formTasksComparison->isValid($request->getPost())) {
        $taskIdsStr = $formTasksComparison->getValue('SSTaskIds');
        // Replace commas with usual spaces.
        $taskIdsStr = preg_replace('/,/', ' ', $taskIdsStr);

        // Delete continuos spaces.
        $taskIdsStr = trim(preg_replace('/\s+/', ' ', $taskIdsStr));
        return $this->_helper->redirector->gotoSimple(
          'comparison'
          , 'stats'
          , null
          , array_merge(
            array('task ids' => $taskIdsStr)
            , $this->_globals));
      }
      else if ($formUpdateProfiles->isValid($request->getPost())) {
        // Delete a stored information on a profile.
        $global = new Zend_Session_Namespace();
      #  print_r($global->profileCurrent);exit;
        unset($global->profileCurrent);
        return $this->_helper->redirector->gotoSimple(
          'index'
          , 'stats'
          , null
          , $params);
      }
    }

    $this->view->formTasksComparison = $formTasksComparison;
    $this->view->formUpdateProfiles = $formUpdateProfiles;

    // Make a form for the csv export.
    $formPrintCSV = new Application_Form_PrintCSV();

    if ($this->getRequest()->isPost()) {
      if ($formPrintCSV->isValid($request->getPost())) {
        return $this->_helper->redirector->gotoSimple(
          'index'
          , 'stats'
          , null
          , $params);
      }
    }

    $this->view->formPrintCSV = $formPrintCSV;
  }

  public function errortraceAction()
  {
    // Get all parameters including page name, trace id and so on.
    $params = $this->_getAllParams();

    $statsMapper = new Application_Model_StatsMapper();
    $results = $statsMapper->getErrorTrace($this->_profileInfo, $params);

    // Write raw representation of error trace directly to the file.
    $errorTraceRawFile = APPLICATION_PATH . "/../data/trace/original";
    $handleErrorTrace = fopen($errorTraceRawFile, 'r+')
      or die("Can't open the file '$errorTraceRawFile' for write");
    // We should lock files with error trace and source code until error trace
    // visualizer will process it.
    flock($handleErrorTrace, LOCK_EX)
      or die ("Can't lock the file '$errorTraceRawFile'");
    // Remove previous content of the given file before writing.
    ftruncate($handleErrorTrace, 0)
      or die ("Can't truncate the file '$errorTraceRawFile'");
    fwrite($handleErrorTrace, $results['Error trace']->errorTraceRaw)
      or die("Can't write raw error trace to the file '$errorTraceRawFile'");

    // Write file names and source code directly to the file.
    $sourceCodeFile = APPLICATION_PATH . "/../data/trace/src";
    $handleSrc = fopen($sourceCodeFile, 'r+')
      or die("Can't open the file '$sourceCodeFile' for write");
    flock($handleSrc, LOCK_EX)
      or die ("Can't lock the file '$sourceCodeFile'");
    // Remove previous content of the given file before writing.
    ftruncate($handleSrc, 0)
      or die ("Can't truncate the file '$sourceCodeFile'");
    $fileSeparator = '---LDV---';
    foreach ($results['Error trace']->sourceCodeFiles as $fileName => $sourceCode) {
      fwrite($handleSrc, "$fileSeparator$fileName$fileSeparator\n$sourceCode\n")
        or die("Can't write source code to the file '$sourceCodeFile'");
    }

    // Obtain the path to the error trace visualizer script.
    $etvConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'error-trace-visualizer');
    $etv = $etvConfig->script;

    $errorTraceFile = APPLICATION_PATH . "/../data/trace/processed";

    // Make error trace visualization.
    exec("LDV_DEBUG=30 $etv --original-error-trace=$errorTraceRawFile --visualized-error-trace=$errorTraceFile --referred-source-code=$sourceCodeFile 2>&1", $output, $retCode);

    // Store log to see it for debug.
    $this->view->entries = array();
    $this->view->entries['ETV log'] = $output;

    if ($retCode) {
      $error = "<h1>The error trace visualizer fails!!!</h1>";
      $this->view->error = $error;
    }
    else {
      // Store the html representation of error trace and source code.
      $errorTrace = file_get_contents($errorTraceFile)
        or die("Can't read processed error trace from the file '$errorTraceFile'");

      $results['Error trace']->setOptions(array('errorTrace' => $errorTrace));

      $this->view->entries = array_merge($this->view->entries, $results);
      $this->view->entries['Globals'] = $this->_globals;
      $this->view->entries['Profile'] = array('name' => $this->_profileInfo->profileName, 'user' => $this->_profileInfo->profileUser);
      $this->view->entries['Knowledge base'] = $results['Knowledge base'];

      // Close file handlers and release corresponding locks after processed
      // error trace was obtained.
      fclose($handleErrorTrace);
      fclose($handleSrc);
    }
  }

  public function unsafesAction()
  {
	// Get all parameters including page name, trace id and so on.
	$params = $this->_getAllParams();

	$statsMapper = new Application_Model_StatsMapper();
	$results = $statsMapper->getUnsafes($this->_profileInfo, $params);
	$this->view->entries = array();
	$this->view->entries = array_merge($this->view->entries, $results);
	$this->view->entries['Globals'] = $this->_globals;
	$this->view->entries['Profile'] = array('name' => $this->_profileInfo->profileName, 'user' => $this->_profileInfo->profileUser);
  }

  public function comparisonAction()
  {
    // Get all parameters including page name, statistics key names and values
    // and so on.
    $params = $this->_getAllParams();

    $statsMapper = new Application_Model_StatsMapper();
    $this->view->entries = $statsMapper->getComparisonStats($this->_profileInfo, $params);
    $this->view->entries['Globals'] = $this->_globals;
    $this->view->entries['Profile'] = array('name' => $this->_profileInfo->profileName, 'user' => $this->_profileInfo->profileUser);
  }

  public function editTaskDescriptionAction()
  {
    $params = $this->_getAllParams();

    $statsMapper = new Application_Model_StatsMapper();
    $results = $statsMapper->updateTaskDescription($this->_profileInfo, $params);

    echo $results;
  }

  public function storeKbAction()
  {
    // Find out database connection settings.
    $statsMapper = new Application_Model_StatsMapper();
    $dbConnection = $statsMapper->connectToDb($this->_profileInfo->dbHost, $this->_profileInfo->dbName, $this->_profileInfo->dbUser, $this->_profileInfo->dbPassword, $this->_getAllParams());

    // Dump KB tables schemas and data.
    exec("mysqldump -u$dbConnection[username] $dbConnection[dbname] kb results_kb -r'" . APPLICATION_PATH . "/../data/kb-dump.sql" . "' 2>&1" , $output, $retCode);

    // TODO: it should be filed from the output.
    $result = '';

    // Show output in case of errors.
    $error = '';
    if ($retCode)
      $error = $output;

    echo Zend_Json::encode(array('result' => $result, 'errors' => $error));
  }

  public function restoreKbAction()
  {
    // Find out database connection settings.
    $statsMapper = new Application_Model_StatsMapper();
    $dbConnection = $statsMapper->connectToDb($this->_profileInfo->dbHost, $this->_profileInfo->dbName, $this->_profileInfo->dbUser, $this->_profileInfo->dbPassword, $this->_getAllParams());

    // Upload KB tables schemas and data.
    exec("mysql -u$dbConnection[username] $dbConnection[dbname] < " . APPLICATION_PATH . "/../data/kb-dump.sql" . " 2>&1" , $output, $retCode);

    // TODO: it should be filed from the output.
    $result = '';

    // Show output in case of errors.
    $error = '';
    if ($retCode)
      $error = $output;

    echo Zend_Json::encode(array('result' => $result, 'errors' => $error));
  }

  public function publishKbRecordAction()
  {
    // Find out database connection settings.
    $statsMapper = new Application_Model_StatsMapper();
    $dbConnection = $statsMapper->connectToDb($this->_profileInfo->dbHost, $this->_profileInfo->dbName, $this->_profileInfo->dbUser, $this->_profileInfo->dbPassword, $this->_getAllParams());

    $db = $dbConnection['dbname'];
    $user = $dbConnection['username'];
    $host = $dbConnection['host'];
    $passwd = '';
    if ($dbConnection['password'] != '')
      $passwd = "LDVDBPASSWD=$dbConnection[password]";

    # TODO: review this location.
	$prepairedKBRecord = "/tmp/prepairedKBRecord";

	// Obtain the path to the ppob-publisher script.
    $ppobPublisherConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'ppob-publisher');
    $ppobPublisher = $ppobPublisherConfig->script;

	// Obtain current trace id and other useful information.
	$traceId=$this->_getParam('trace_id');
	$comment=$this->_getParam('comment');
	$verdict=$this->_getParam('verdict');
	$status=$this->_getParam('status');
	$ppobId=$this->_getParam('ppob_id');
	$kbId=$this->_getParam('KB_id');

	// Create published record.
    exec("LDV_DEBUG=30 LDVDB=$db LDVUSER=$user LDVDBHOST=$host $passwd $ppobPublisher --id=$traceId --output=$prepairedKBRecord" . " 2>&1" , $output, $retCode);

	// File with processed error trace.
    $errorTraceFile = APPLICATION_PATH . "/../data/trace/processed";

	// Process file with information from ppob-publisher.
    $info = file_get_contents($prepairedKBRecord)
        or die("Can't read information from the file '$prepairedKBRecord'");
    parse_str($info, $out);
    $kernel = $out['kernel'];
    $module = $out['module'];
    $rule = $out['rule'];
    $verifier = $out['verifier'];
    $main = $out['main'];

    // Clear any previous data.
	file_put_contents("/tmp/ppob_id", "");

	// Send information into the PPoB.
	$ppob_url = "http://localhost:8080/php/impl_reports_admin.php"; //TODO: real address!
	$current_link = "http://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]";
	$current_link = preg_replace("/publish-kb-record/", "errortrace", $current_link);
	$data = array(
		'kernel' => $kernel, 
		'module' => $module, 
		'rule' => $rule, 
		'verifier' => $verifier, 
		'main' => $main,
		'comment' => $comment,
		'verdict' => $verdict,
		'status' => $status,
		'error_trace_file' => $errorTraceFile,
		'sync_status' => 'KB-Synchronized',
		'link' => $current_link);
	$options = array(
		'http' => array(
		    'header'  => "Content-type: application/x-www-form-urlencoded\r\n",
		    'method'  => 'POST',
		    'content' => http_build_query($data),
		),
	);
	$context  = stream_context_create($options);
	if ($ppobId) // Update.
	{
		$result = file_get_contents($ppob_url."?action=update_ppob&num=$ppobId", false, $context);
	}
	else // Insert.
	{
		$result = file_get_contents($ppob_url."?action=submit_ppob", false, $context);
	}

	$ppob_id = file_get_contents("/tmp/ppob_id"); // TODO: location

	if ($ppob_id) // Success.
	{
		$error = "KB record has been published into the linuxtesting.\nPublished trace id=$ppob_id.\n" .
			"In order to edit it use the following link:\n$ppob_url?action=details_ppob&num=$ppob_id";

		$kb_table = "$db.results_kb";
		$link = mysql_connect($host, $user, $passwd);
		mysql_query ("UPDATE $kb_table SET sync_status='Synchronized', published_trace_id=$ppob_id where kb_id=$kbId AND trace_id=$traceId");
		mysql_close($link);
	}
	else
	{
		$error = "There was en error during KB record publishing.\n" .
			"Please, make sure you have the proper access.\n";
	}
    echo Zend_Json::encode(array('result' => $result, 'errors' => $error));
  }

  public function getKbRecordAction()
  {
    // Find out database connection settings.
    $statsMapper = new Application_Model_StatsMapper();
    $dbConnection = $statsMapper->connectToDb($this->_profileInfo->dbHost, $this->_profileInfo->dbName, $this->_profileInfo->dbUser, $this->_profileInfo->dbPassword, $this->_getAllParams());

    $db = $dbConnection['dbname'];
    $user = $dbConnection['username'];
    $host = $dbConnection['host'];
    $passwd = '';
    if ($dbConnection['password'] != '')
      $passwd = "LDVDBPASSWD=$dbConnection[password]";

	// Obtain the path to the ppob-publisher script.
    $ppobPublisherConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'ppob-publisher');
    $ppobPublisher = $ppobPublisherConfig->script;

	// Obtain kb_id.
	$kbId=$this->_getParam('KB_id');
	$traceId=$this->_getParam('trace_id');
	$ppobId=$this->_getParam('ppob_id');

	// Send information into the PPoB.
	$ppob_url = "http://localhost:8080/php/impl_reports_admin.php"; //TODO: real address!
	$result = file_get_contents($ppob_url."?action=details_ppob&num=$ppobId");
	$params = "";
	foreach(preg_split("/((\r?\n)|(\r\n?))/", $result) as $line){
		if (preg_match("/<p type=\"get\" (\w*)=\"(.*)\"><\/p>/", $line, $array))
		{
			$name = $array[1];
			$value = $array[2];
			if (!$params)
			{
				$params = $params."$name='$value' ";
			}
			else
			{
				$params = $params.", $name='$value' ";
			}
		}
	}
	$kb_table = "$db.kb";
	$results_kb_table = "$db.results_kb";
	$link = mysql_connect($host, $user, $passwd);
	if (!mysql_query ("UPDATE $kb_table, $results_kb_table SET $params, sync_status='Synchronized' where $kb_table.id=$kbId AND $results_kb_table.kb_id=$kbId AND $results_kb_table.trace_id=$traceId"))
		$error = "UPDATE $kb_table, $results_kb_table SET $params, sync_status='Synchronized' where $kb_table.id=$kbId AND $results_kb_table.kb_id=$kbId AND $results_kb_table.trace_id=$traceId\n$ppobId";
    mysql_close($link);
    $error = "";
    
    // Send query for sync in PPoB.
    $ppob_url = "http://localhost:8080/php/impl_reports_admin.php"; //TODO: real address!
	$data = array('sync_status' => 'KB-Synchronized');
	$options = array(
		'http' => array(
		    'header'  => "Content-type: application/x-www-form-urlencoded\r\n",
		    'method'  => 'POST',
		    'content' => http_build_query($data),
		),
	);
	$context  = stream_context_create($options);
	$result = file_get_contents($ppob_url."?action=update_ppob&num=$ppobId", false, $context);
	
    echo Zend_Json::encode(array('result' => $result, 'errors' => $error));
  }

  public function deleteKbRecordAction()
  {
    // Find out database connection settings.
    $statsMapper = new Application_Model_StatsMapper();
    $dbConnection = $statsMapper->connectToDb($this->_profileInfo->dbHost, $this->_profileInfo->dbName, $this->_profileInfo->dbUser, $this->_profileInfo->dbPassword, $this->_getAllParams());
    $db = $dbConnection['dbname'];
    $user = $dbConnection['username'];
    $host = $dbConnection['host'];
    $passwd = '';
    if ($dbConnection['password'] != '')
      $passwd = "LDVDBPASSWD=$dbConnection[password]";

    // Obtain the path to the kb-recalc script.
    $kbRecalcConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'kb-recalc');
    $kbRecalc = $kbRecalcConfig->script;

	// Obtain kb_id.
	$kbId=$this->_getParam('KB_id');
	$ppobId=$this->_getParam('ppob_id');

    // Delete KB id.
    exec("LDV_DEBUG=30 LDVDB=$db LDVUSER=$user LDVDBHOST=$host $passwd $kbRecalc --delete=$kbId 2>&1" , $output, $retCode);

    // TODO: it should be filed from the output.
    $result = '';

    // Show output in case of errors.
    $error = '';
    if ($retCode)
      $error = $output;

    // Delete from PPoB (or try to delete).
    $ppob_url = "http://localhost:8080/php/impl_reports_admin.php"; //TODO: real address!
	$options = array(
		'http' => array(
		    'header'  => "Content-type: application/x-www-form-urlencoded\r\n",
		    'method'  => 'POST',
		),
	);
	$context  = stream_context_create($options);
	$result = file_get_contents($ppob_url."?action=del_ppob&num=$ppobId", false, $context);

    echo Zend_Json::encode(array('result' => $result, 'errors' => $error));
  }

  public function updateKbRecordAction()
  {
    // Obtain the path to the kb-recalc script.
    $kbRecalcConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'kb-recalc');
    $kbRecalc = $kbRecalcConfig->script;
    $result = '';
    $error = '';
    $output = '';

    $statsMapper = new Application_Model_StatsMapper();

    if ($this->_getParam('KB_new_record') == 'true') {
      $results = $statsMapper->updateKBRecord($this->_profileInfo, $this->_getAllParams(), true);

      if (empty($results['Errors'])) {
        $dbConnection = $results['Database connection'];
        $db = $dbConnection['dbname'];
        $user = $dbConnection['username'];
        $host = $dbConnection['host'];
        $passwd = '';
        if ($dbConnection['password'] != '')
          $passwd = "LDVDBPASSWD=$dbConnection[password]";

        // TODO: I used --init-cache that may be too long.
        // Regenerate KB cache by means of script application for a given KB id.
        exec("LDV_DEBUG=30 LDVDB=$db LDVUSER=$user LDVDBHOST=$host $passwd $kbRecalc --init-cache --new=" . $results['New KB id'] . " 2>&1" , $output, $retCode);
        $result = $output;
      }
      else
        $error = $results['Errors'];
    }
    else {
      $results = $statsMapper->updateKBRecord($this->_profileInfo, $this->_getAllParams());
      $dbConnection = $results['Database connection'];
      $db = $dbConnection['dbname'];
      $user = $dbConnection['username'];
      $host = $dbConnection['host'];
      $passwd = '';
      if ($dbConnection['password'] != '')
        $passwd = "LDVDBPASSWD=$dbConnection[password]";

      if ($this->_getParam('KB_model') != $this->_getParam('KB_model_old')
        or $this->_getParam('KB_module') != $this->_getParam('KB_module_old')
        or $this->_getParam('KB_main') != $this->_getParam('KB_main')) {
        // Regenerate KB cache by means of db tools for a given KB id.
        exec("LDV_DEBUG=30 LDVDB=$db LDVUSER=$user LDVDBHOST=$host $passwd $kbRecalc --update-pattern=" . $this->_getParam('KB_id') . " 2>&1" , $output, $retCode);
        $result = $output;
      }

      if ($this->_getParam('KB_script') != $this->_getParam('KB_script_old')) {
        // Regenerate KB cache by means of script application for a given KB id.
        exec("LDV_DEBUG=30 LDVDB=$db LDVUSER=$user LDVDBHOST=$host $passwd $kbRecalc --update-pattern-script=" . $this->_getParam('KB_id') . " 2>&1" , $output, $retCode);
      }

      if ($this->_getParam('KB_verdict') != $this->_getParam('KB_verdict_old')
        or $this->_getParam('KB_tags') != $this->_getParam('KB_tags_old')
        or $this->_getParam('KB_comment') != $this->_getParam('KB_comment_old')
        or $this->_getParam('KB_status') != $this->_getParam('KB_status_old')) {
        // Regenerate KB cache for a given KB id (in fact nothing will be done).
        // KB comment is also assigned to result here.
        exec("LDV_DEBUG=30 LDVDB=$db LDVUSER=$user LDVDBHOST=$host $passwd $kbRecalc --update-result=" . $this->_getParam('KB_id') . " 2>&1" , $output, $retCode);
      }

      // Take KB (ge)nerator output if so as result at the moment;
      $result = $output;
    }

    echo Zend_Json::encode(array('result' => $result, 'errors' => $error));
  }
}
