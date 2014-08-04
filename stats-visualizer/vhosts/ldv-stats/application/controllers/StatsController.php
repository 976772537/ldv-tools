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
  
  protected $url = "http://linuxtesting.org/";
  protected $url_local = "http://localhost:8080/php/impl_reports_admin";//TODO:change all those links to $url
  
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

 /*
  * Test function, which creates new bug_report on linuxtesting.
  * TODO: delete it!
  * Edit: was successfully tested.
  */
  public function testCookieAction()
  {
	// Get cookie.
	$cookie = $_SESSION['cookie'];

	// Get url.
	$url = $this->url; // Good url.
	
	// Get 
	$data = array(
			'num' => 'TEST_0001',
			'sh_descr_ru' => 'Test desc 0001');
	$result = $this->curlPostRequestByCookie($url . "results/impl_reports_admin?action=submit", $cookie, $data);

	// Check status.
	if (!preg_match("/<h1>Issue of the Implementation No. (\S+)<\/h1>/", $result, $array))
	{
		$error = "There was an error during uploading on linuxtesting.";
		echo Zend_Json::encode(array('errors' => $error));
		return;
	}

	// Successful exit from function.
	echo Zend_Json::encode(array('errors' => ''));
  }

 /*
  * Function implements 'publish' action from errortrace page.
  * Intends to publish or update Traces in linuxtesting from LDV Analytics Center. 
  */
  public function publishKbRecordAction()
  {
	// Obtain KB specific data.
	$traceId=$this->_getParam('trace_id');
	$comment=$this->_getParam('comment');
	$verdict=$this->_getParam('verdict');
	$status=$this->_getParam('status');
	$ppobId=$this->_getParam('ppob_id');
	$kbId=$this->_getParam('KB_id');

	// Get current link.
	$currentLink = "http://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]";
	$currentLink = preg_replace("/publish-kb-record/", "errortrace", $currentLink);

	// Get cookie.
	$cookie = $_SESSION['cookie'];

	// Get url.
	$url = $this->url_local;

	if ($ppobId) // Update existed Trace into linuxtesting.
	{
		// Check status of that Trace. If it is not equal to 'Unreported', stop updating.
		if (!$this->checkForUnreported($url . "?action=details_ppob&num=$ppobId", $cookie))
		{
			$error = "Status of Trace # $ppobId is no longer 'Unreported'.\n" .
				"In order to changed it please contact the Expert with access to linuxtesting.";
			echo Zend_Json::encode(array('errors' => $error));
			return;
		}

		// Combine all data to be updated. Only 'verdict' and 'status' fields will be updated. 
		$data = array(
			'verdict' => $verdict,
			'status' => $status,
			'sync_status' => 'KB-Synchronized');
		$result = $this->curlPostRequestByCookie($url . "?action=update_ppob&num=$ppobId", $cookie, $data);
	}
	else // Insert new Trace into linuxtesting.
	{
		// Get non KB specific data.
		$query = "
		SELECT 
			environments.version as kernel, 
			drivers.name as module, 
			rule_models.name as rule, 
			toolsets.verifier as verifier, 
			scenarios.main as main
		FROM traces
			LEFT JOIN launches on launches.trace_id=traces.id
			LEFT JOIN environments on launches.environment_id=environments.id
			LEFT JOIN toolsets on launches.toolset_id=toolsets.id
			LEFT JOIN rule_models on launches.rule_model_id=rule_models.id
			LEFT JOIN drivers on launches.driver_id=drivers.id
			LEFT JOIN scenarios on launches.scenario_id=scenarios.id
		WHERE traces.id=$traceId
		LIMIT 1";
		$result = $this->mysqlSelectQuery($query);
		if (!$result)
		{
			$error = "There was an error during executing query:$query\nwhile getting non KB specific information";
			echo Zend_Json::encode(array('errors' => $error));
			return;
		}
		$kernel = $result['kernel'];
		$module = $result['module'];
		$rule = $result['rule'];
		$verifier = $result['verifier'];
		$main = $result['main'];

		// File with processed error trace.
		$errorTraceFile = APPLICATION_PATH . "/../data/trace/processed";

		// Combine all data to be published.
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
			'link' => $currentLink);
		$result = $this->curlPostRequestByCookie($url . "?action=submit_ppob", $cookie, $data);
	}

	// Check status and get inserted/updated Trace id.
	if (preg_match("/<h1> Details for Public Pool of Bugs issue # (\d+)<\/h1>/", $result, $array))
	{
		$newPpobId = $array[1];
	}
	else
	{
		$error = "There was an error during uploading to linuxtesting.";
		echo Zend_Json::encode(array('errors' => $error));
		return;
	}

	// Now KB record should be updated (fields "Synchronized status" and "Published record" should be updated).
	$query = "
	UPDATE results_kb 
	SET sync_status = 'Synchronized', published_trace_id = $newPpobId
	WHERE trace_id = $traceId AND kb_id = $kbId";
	$result = $this->mysqlQuery($query);
	if (!$result)
	{
		// Stop updating.
		$error = "There was an error during executing query:$query\nwhile updating KB record";
		echo Zend_Json::encode(array('errors' => $error));
		return;
	}

	// Successful exit from function.
	// Returned value: result - inserted/updated Trace id.
	echo Zend_Json::encode(array('result' => $newPpobId, 'errors' => ''));
  }

 /*
  * Function checks if trace with known id has 'Unereported' status on linuxtesting 
  * and thus can be updated/deleted from LDV Analytics Center.
  */
  protected function checkForUnreported($url, $cookie)
  {
	$result = $this->curlGetRequestByCookie($url, $cookie);
	if (preg_match("/<td><b>Status: <\/b><\/td>(\s*)<td>(\s*)<font color=\"(\w+)\">(\w+)<\/font>/", $result, $array))
	{
		$status = $array[4];
		if ($status == 'Unreported')
			return TRUE;
		else
			return FALSE;
	}
	return FALSE;
  }

 /*
  * Function executes mysql select query in LDV Analytics Center database
  * and returns resulting rows.
  */
  protected function mysqlSelectQuery($query)
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

	// Connect to database.
	$link = mysql_connect($host, $user, $passwd);
    if (!$link)
    	return FALSE;

    mysql_query("USE $db");
    // Execute query.
    $result = mysql_query($query);
	if(!$result)
		return FALSE;
	$row = mysql_fetch_array($result);
    
    // Close connection.
    mysql_close($link);
    return $row;
  }

 /*
  * Function executes mysql query in LDV Analytics Center database.
  */
  protected function mysqlQuery($query)
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

	// Connect to database.
	$link = mysql_connect($host, $user, $passwd);
    if (!$link)
    	return FALSE;

    mysql_query("USE $db");
    // Execute query.
    $result = mysql_query($query);
	if(!$result)
		return FALSE;

    // Close connection.
    mysql_close($link);
    return TRUE;
  }

 /*
  * Function executes curl GET request for selected url and known cookie.
  * Returns content of url after executing GET request.
  */
  protected function curlGetRequestByCookie($url, $cookie)
  {
	// Init curl.
	$curl = curl_init();

	// Set parameters.
	curl_setopt($curl, CURLOPT_URL, $url);
	curl_setopt($curl, CURLOPT_COOKIESESSION, FALSE);
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, TRUE);
	curl_setopt($curl, CURLOPT_COOKIEJAR, "cookie.txt");
	curl_setopt($curl, CURLOPT_COOKIEFILE, 'cookie.txt');
	curl_setopt($curl, CURLOPT_COOKIE, "$cookie");
	// Execute request.
	$result = curl_exec($curl);

	// Close connection.
	curl_close($curl);

	return $result;
  }

 /*
  * Function executes curl POST request for selected url and known cookie.
  * Returns content of url after executing POST request.
  */
  protected function curlPostRequestByCookie($url, $cookie, $data)
  {
	// Init curl.
	$curl = curl_init();

	// Get url representation of array $data.
	$processedData = http_build_query($data);

	// Set parameters.
	curl_setopt($curl, CURLOPT_URL, $url);
	curl_setopt($curl, CURLOPT_COOKIESESSION, FALSE);
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, TRUE);
	curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1);
	curl_setopt($curl, CURLOPT_COOKIEJAR, "cookie.txt");
	curl_setopt($curl, CURLOPT_COOKIEFILE, "cookie.txt");
	curl_setopt($curl, CURLOPT_COOKIE, "$cookie");
	curl_setopt($curl, CURLOPT_POST, 1);
	curl_setopt($curl, CURLOPT_POSTFIELDS, "$processedData");

	// Execute request.
	$result = curl_exec($curl);

	// Close connection.
	curl_close($curl);

	return $result;
  }

 /*
  * Function implements 'update' action from errortrace page.
  * Intends to update KB record in LDV Analytics Center from linuxtesting.
  * Only fields 'status' and 'verdict' will be updated.
  */
  public function getKbRecordAction()
  {
	// Obtain useful ids.
	$kbId=$this->_getParam('KB_id');
	$traceId=$this->_getParam('trace_id');
	$ppobId=$this->_getParam('ppob_id');
	$status=$this->_getParam('status');
	$verdict=$this->_getParam('verdict');
	$syncStatus=$this->_getParam('sync_status');

	// Get cookie.
	$cookie = $_SESSION['cookie'];

	// Get url.
	$url = $this->url_local;

	// Get information from linuxtesting - status and verdict fields.
	$result = $this->curlGetRequestByCookie($url . "?action=details_ppob&num=$ppobId", $cookie);
	if (preg_match("/<td><b>Status: <\/b><\/td>(\s*)<td>(\s*)<font color=\"(\S+)\">(\w+)<\/font>/", $result, $array))
	{
		$newStatus = $array[4];
	}
	if (preg_match("/<td><b>Verdict: <\/b><\/td>(\s*)<td>(\s*)<font color=\"(\S+)\">(.+)<\/font>/", $result, $array))
	{
		$newVerdict = $array[4];
	}
	if (preg_match("/<td><b>Synchronized status: <\/b><\/td>(\s*)<td>(\s*)<font color=\"(\S+)\">(\w+)<\/font>/", $result, $array))
	{
		$newSyncStatus = $array[4];
	}
	if (!isset($newStatus) || !isset($newVerdict) || !isset($newSyncStatus))
	{
		$error = "Can not retrieve information from linuxtesting on Trace # $ppobId.";
		echo Zend_Json::encode(array('errors' => $error));
		return;
	}

	// Log of updated fields.
	$log = ""; 
	// Check if update for KB record is really needed.
	if (($newStatus != $status) || ($newVerdict != $verdict) || ($syncStatus != "Synchronized"))
	{
		// Update KB record.
		$query = "
		UPDATE kb, results_kb
		SET verdict = '$newVerdict', status = '$newStatus', sync_status = 'Synchronized'
		WHERE kb.id = $kbId AND results_kb.kb_id = $kbId AND results_kb.trace_id = $traceId";
		$this->mysqlQuery($query);
		if (!$result)
		{
			$error = "There was an error during executing query:$query\nwhile updating KB record";
			echo Zend_Json::encode(array('errors' => $error));
			return;
		}
		$log .= "Updated on LDV Analytics Center:\n"; 
		if ($newStatus != $status)
			$log .= "\tstatus=$newStatus (was $status)\n";
		if ($syncStatus != "Synchronized")
			$log .= "\tsync_status=Synchronized (was $syncStatus)\n";
		if ($newVerdict != $verdict)
			$log .= "\tverdict=$newVerdict (was $verdict)\n";
	}

	// Check if sync_status of linuxtesting Trace should be updated.
	if ($newSyncStatus != "Synchronized")
	{
		$data = array('sync_status' => 'KB-Synchronized');
		$result = $this->curlPostRequestByCookie($url . "?action=update_ppob&num=$ppobId", $cookie, $data);
		if (!preg_match("/<h1> Details for Public Pool of Bugs issue # (\d+)<\/h1>/", $result, $array))
		{
			$error = "Can not update status for linuxtesting Trace # $ppobId";
			echo Zend_Json::encode(array('errors' => $error));
			return;
		}
		$log .= "Updated on linuxtesting:\n";
		$log .= "\tsync_status=Synchronized (was $newSyncStatus)\n";
	}

	// Successful return.
	// Log keeps all updated fields. If it is empty, then nothing was actually updated.
    echo Zend_Json::encode(array('log' => $log, 'errors' => ''));
  }

 /*
  * Function implements 'delete' action from errortrace page.
  * Intends to delete KB record from LDV Analytics Center if it does not have published record id.
  * Otherwise it will delete not only KB record but also corresponding Trace from linuxtesting.
  */
  public function deleteKbRecordAction()
  {
	// First, Trace from linuxtesting should be deleted (if it exists).
	// Get Trace id.
	$ppobId=$this->_getParam('ppob_id');
	if ($ppobId)
	{
		// Get cookie.
		$cookie = $_SESSION['cookie'];

		// Get url.
		$url = $this->url_local;

		// Check status of that Trace. If it is not equal to 'Unreported', stop deleting.
		if (!$this->checkForUnreported($url . "?action=details_ppob&num=$ppobId", $cookie))
		{
			$error = "Status of Trace # $ppobId is no longer 'Unreported'.\n" .
				"In order to delete it please contact the Expert with access to linuxtesting.";
			echo Zend_Json::encode(array('errors' => $error));
			return;
		}
		$result = $this->curlPostRequestByCookie($url . "?action=del_ppob&num=$ppobId", $cookie, array());
	}
	
	// Second, KB record should be deleted from LDV Analytics Center (as before).
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

    // Delete KB record.
    exec("LDV_DEBUG=30 LDVDB=$db LDVUSER=$user LDVDBHOST=$host $passwd $kbRecalc --delete=$kbId 2>&1" , $output, $retCode);

    // TODO: it should be filed from the output.
    $result = '';

    // Show output in case of errors.
    $error = '';
    if ($retCode)
      $error = $output;

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

        // Set status and sync_status (must be after kb-recalc).
        $kbId = $results['New KB id'];
        $status = $this->_getParam('KB_status');
        $query = "UPDATE results_kb SET status='$status' WHERE kb_id=$kbId";
        $updateStatusResult = $this->mysqlQuery($query);
		if (!$updateStatusResult)
		  $error = "There was an error during executing query:\n$query\nwhile updating status of KB record";
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
