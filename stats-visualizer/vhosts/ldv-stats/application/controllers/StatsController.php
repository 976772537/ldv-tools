<?php

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
    exec("LDV_DEBUG=30 $etv --report=$errorTraceRawFile --report-out=$errorTraceFile --src-files=$sourceCodeFile 2>&1", $output, $retCode);

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
    exec("mysqldump -u$dbConnection[username] $dbConnection[dbname] kb results_kb -r'" . APPLICATION_PATH . "/../data/trace/kb-dump.sql" . "' 2>&1" , $output, $retCode);

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
    exec("mysql -u$dbConnection[username] $dbConnection[dbname] < " . APPLICATION_PATH . "/../data/trace/kb-dump.sql" . " 2>&1" , $output, $retCode);

    // TODO: it should be filed from the output.
    $result = '';

    // Show output in case of errors.
    $error = '';
    if ($retCode)
      $error = $output;

    echo Zend_Json::encode(array('result' => $result, 'errors' => $error));
  }

  public function deleteKbRecordAction()
  {
    // Find out database connection settings.
    $statsMapper = new Application_Model_StatsMapper();
    $dbConnection = $statsMapper->connectToDb($this->_profileInfo->dbHost, $this->_profileInfo->dbName, $this->_profileInfo->dbUser, $this->_profileInfo->dbPassword, $this->_getAllParams());

    // Obtain the path to the kb-recalc script.
    $kbRecalcConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'kb-recalc');
    $kbRecalc = $kbRecalcConfig->script;

    // Delete KB id.
    exec("LDV_DEBUG=30 LDVDB=$dbConnection[dbname] LDVUSER=$dbConnection[username] LDVDBHOST=$dbConnection[host] $kbRecalc --delete=" . $this->_getParam('KB_id') . " 2>&1" , $output, $retCode);

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

        // TODO: I used --init-cache that may be too long.
        // Regenerate KB cache by means of script application for a given KB id.
        exec("LDV_DEBUG=30 LDVDB=$dbConnection[dbname] LDVUSER=$dbConnection[username] LDVDBHOST=$dbConnection[host] $kbRecalc --init-cache --new=" . $results['New KB id'] . " 2>&1" , $output, $retCode);
        $result = $output;
      }
      else
        $error = $results['Errors'];
    }
    else {
      $results = $statsMapper->updateKBRecord($this->_profileInfo, $this->_getAllParams());
      $dbConnection = $results['Database connection'];

      if ($this->_getParam('KB_model') != $this->_getParam('KB_model_old')
        or $this->_getParam('KB_module') != $this->_getParam('KB_module_old')
        or $this->_getParam('KB_main') != $this->_getParam('KB_main')) {
        // Regenerate KB cache by means of db tools for a given KB id.
        exec("LDV_DEBUG=30 LDVDB=$dbConnection[dbname] LDVUSER=$dbConnection[username] LDVDBHOST=$dbConnection[host] $kbRecalc --update-pattern=" . $this->_getParam('KB_id') . " 2>&1" , $output, $retCode);
        $result = $output;
      }

      if ($this->_getParam('KB_script') != $this->_getParam('KB_script_old')) {
        // Regenerate KB cache by means of script application for a given KB id.
        exec("LDV_DEBUG=30 LDVDB=$dbConnection[dbname] LDVUSER=$dbConnection[username] LDVDBHOST=$dbConnection[host] $kbRecalc --update-pattern-script=" . $this->_getParam('KB_id') . " 2>&1" , $output, $retCode);
      }

      if ($this->_getParam('KB_verdict') != $this->_getParam('KB_verdict_old')
        or $this->_getParam('KB_tags') != $this->_getParam('KB_tags_old')
        or $this->_getParam('KB_comment') != $this->_getParam('KB_comment_old')) {
        // Regenerate KB cache for a given KB id (in fact nothing will be done).
        // KB comment is also assigned to result here.
        exec("LDV_DEBUG=30 LDVDB=$dbConnection[dbname] LDVUSER=$dbConnection[username] LDVDBHOST=$dbConnection[host] $kbRecalc --update-result=" . $this->_getParam('KB_id') . " 2>&1" , $output, $retCode);
      }

      // Take KB (ge)nerator output if so as result at the moment;
      $result = $output;
    }

    echo Zend_Json::encode(array('result' => $result, 'errors' => $error));
  }
}
