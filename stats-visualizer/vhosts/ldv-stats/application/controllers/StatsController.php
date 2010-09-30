<?php

class StatsController extends Zend_Controller_Action
{
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

    // Make a form for the tasks comparisson.
    $request = $this->getRequest();
    $form = new Application_Form_TasksComparisson();
    $this->view->taskids = null;

    if ($this->getRequest()->isPost()) {
      if ($form->isValid($request->getPost())) {
        $this->view->taskids = $form->getValue('taskids');
        $form->reset();
      }
    }

    $this->view->form = $form;
  }
}
