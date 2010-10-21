<?php

class StatsController extends Zend_Controller_Action
{
  protected $_params;

  public function init()
  {
    // Get the current session database connection settings from the address to
    // be used instead of the current profile ones.
    $global = new Zend_Session_Namespace('Statistics globals');

    if ($this->_hasParam('name')) {
      $global->dbName =  $this->_getParam('name');
    }
    if ($this->_hasParam('user')) {
      $global->dbUser =  $this->_getParam('user');
    }
    if ($this->_hasParam('host')) {
      $global->dbHost =  $this->_getParam('host');
    }
    if ($this->_hasParam('password')) {
      $global->dbPassword =  $this->_getParam('password');
    }

    // Remember the time where the page processing was begin.
    $starttime = explode(' ', microtime());
    $starttime =  $starttime[1] + $starttime[0];
    $global->startTime = $starttime;

    // Obtain profile name from parameters.
    if ($this->_hasParam('profilename')) {
      $this->_params['profilename'] = $this->_getParam('profilename');
    }
  }

  public function indexAction()
  {
    // Get information on the current profile.
    $profileMapper = new Application_Model_ProfileMapper();
    $profileCurrentInfo = $profileMapper->getProfileCurrentInfo();

    // Get all parameters including page name, statistics key names and values
    // and so on.
    $params = $this->_getAllParams();

    $statsMapper = new Application_Model_StatsMapper();
    $this->view->entries = $statsMapper->getPageStats($profileCurrentInfo, $params);
    $this->view->entries['Profile pages'] = $profileCurrentInfo->getPageNames();

    // Make a form for the tasks comparison.
    $request = $this->getRequest();
    $form = new Application_Form_TasksComparison();

    if ($this->getRequest()->isPost()) {
      if ($form->isValid($request->getPost())) {
        $taskIdsStr = $form->getValue('taskids');
        return $this->_helper->redirector->gotoSimple(
          'comparison'
          , 'stats'
          , null
          , array('task ids' => $taskIdsStr));
      }
    }

    $this->view->form = $form;
  }

  public function errortraceAction()
  {
    // Get information on the current profile.
    $profileMapper = new Application_Model_ProfileMapper();
    $profileCurrentInfo = $profileMapper->getProfileCurrentInfo();

    // Get all parameters including page name, trace id and so on.
    $params = $this->_getAllParams();

    $statsMapper = new Application_Model_StatsMapper();
    $results = $statsMapper->getErrorTrace($profileCurrentInfo, $params);

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
    $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/scripts.ini', 'error-trace-visualizer');
    $etv = $config->script;

    $errorTraceFile = APPLICATION_PATH . "/../data/trace/processed";
    $engine = $results['Error trace']->engine;

    // Make error trace visualization.
    exec("LDV_DEBUG=20 $etv --engine=$engine --report=$errorTraceRawFile --report-out=$errorTraceFile --src-files=$sourceCodeFile 2>&1", $output, $retCode);

    echo "<div>Error trace visualizer log<pre>" . implode('<br>', $output) . "</pre></div>";

    if ($retCode) {
      $error = "<h1>The error trace visualizer fails!!!</h1>";
      $this->view->error = $error;
      return;
    }

    // Store the html representation of error trace and source code.
    $errorTrace = file_get_contents($errorTraceFile)
      or die("Can't read processed error trace from the file '$errorTraceFile'");

    $results['Error trace']->setOptions(array('errorTrace' => $errorTrace));

    $this->view->entries = $results;
  }

  public function comparisonAction()
  {
    // Get information on the current profile.
    $profileMapper = new Application_Model_ProfileMapper();
    $profileCurrentInfo = $profileMapper->getProfileCurrentInfo();

    // Get all parameters including page name, statistics key names and values
    // and so on.
    $params = $this->_getAllParams();

    $statsMapper = new Application_Model_StatsMapper();
    $this->view->entries = $statsMapper->getComparisonStats($profileCurrentInfo, $params);
  }
}
