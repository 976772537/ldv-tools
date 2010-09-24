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

    // Get information for the index page of the given profile.
    $statsMapper = new Application_Model_StatsMapper();
    $this->view->entries = $statsMapper->getPageStats($profileCurrentInfo, 'Index');
  }
}
