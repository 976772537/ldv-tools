<?php

class StatsController extends Zend_Controller_Action
{
  protected $_globals;
  protected $_profileInfo;

  public function init()
  {
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
    $profileMapper = new Application_Model_ProfileMapper();
    if (array_key_exists('profilename', $this->_globals)) {
      $this->_profileInfo = $profileMapper->getProfileInfo($profileMapper->getProfile($this->_globals['profilename']));
    }
    else {
      $this->_profileInfo = $profileMapper->getProfileInfo();
    }
  }

  public function indexAction()
  {
    // Get all parameters including page name, statistics key names and values
    // and so on.
    $params = $this->_getAllParams();

    $statsMapper = new Application_Model_StatsMapper();
    $this->view->entries = $statsMapper->getPageStats($this->_profileInfo, $params);
    $this->view->entries['Globals'] = $this->_globals;
    $this->view->entries['Profile'] = array('name' => $this->_profileInfo->profileName, 'user' => $this->_profileInfo->profileUser);
    $this->view->entries['Profile pages'] = $this->_profileInfo->getPageNames();

    // Make a form for the tasks comparison.
    $request = $this->getRequest();
    $form = new Application_Form_TasksComparison();

    if ($this->getRequest()->isPost()) {
      if ($form->isValid($request->getPost())) {
        $taskIdsStr = $form->getValue('SSTaskIds');
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
    }

    $this->view->form = $form;
  }

  public function errortraceAction()
  {
    // Get all parameters including page name, trace id and so on.
    $params = $this->_getAllParams();

    $statsMapper = new Application_Model_StatsMapper();
    $results = $statsMapper->getErrorTrace($this->_profileInfo, $params);

    // Write raw representation of error trace directly to the file.
    $errorTraceRawFile = APPLICATION_PATH . "/../data/trace/original";
    $handle = fopen($errorTraceRawFile, 'w')
      or die("Can't open the file '$errorTraceRawFile' for write");
    fwrite($handle, $results['Error trace']->errorTraceRaw)
      or die("Can't write raw error trace to the file '$errorTraceRawFile'");
    fclose($handle);

    // Write file names and source code directly to the file.
    $sourceCodeFile = APPLICATION_PATH . "/../data/trace/src";
    $handle = fopen($sourceCodeFile, 'w')
      or die("Can't open the file '$sourceCodeFile' for write");
    $fileSeparator = '-------';
    foreach ($results['Error trace']->sourceCodeFiles as $fileName => $sourceCode) {
      fwrite($handle, "$fileSeparator$fileName$fileSeparator\n$sourceCode\n")
        or die("Can't write source code to the file '$sourceCodeFile'");
    }
    fclose($handle);

    // Obtain the path to the error trace visualizer script.
    $etvConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'error-trace-visualizer');
    $etv = $etvConfig->script;

    $errorTraceFile = APPLICATION_PATH . "/../data/trace/processed";
    $engine = $results['Error trace']->engine;

    // Make error trace visualization.
    exec("LDV_DEBUG=30 $etv --engine=$engine --report=$errorTraceRawFile --report-out=$errorTraceFile --src-files=$sourceCodeFile 2>&1", $output, $retCode);

    // Store log to see it for debug.
    $this->view->entries = array();
    $this->view->entries['ETV log'] = $output;

    if ($retCode) {
      $error = "<h1>The error trace visualizer fails!!!</h1>";
      $this->view->error = $error;
      return;
    }

    // Store the html representation of error trace and source code.
    $errorTrace = file_get_contents($errorTraceFile)
      or die("Can't read processed error trace from the file '$errorTraceFile'");

    $results['Error trace']->setOptions(array('errorTrace' => $errorTrace));

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
    // To return just a new task description prevent layout printing.
    $this->_helper->layout->disableLayout();

    $params = $this->_getAllParams();

    $statsMapper = new Application_Model_StatsMapper();
    $results = $statsMapper->updateTaskDescription($this->_profileInfo, $params);

    $this->view->entries = $results;
  }
}
