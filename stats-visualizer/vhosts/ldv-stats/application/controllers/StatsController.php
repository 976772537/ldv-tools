<?php

class StatsController extends Zend_Controller_Action
{
  public function init()
  {    
  }

  public function indexAction()
  {
    // Get information on the current profile.
    $profileMapper = new Application_Model_ProfileMapper();
    $profileCurrentInfo = $profileMapper->getProfileCurrentInfo();
    
    // Get information for the index page of the given profile.
    $statsMapper = new Application_Model_StatsMapper();
    $statsMapper->getPageStats($profileCurrentInfo, 'Index');
    # $this->view->entries = array('user name' => $profileCurrent->profileUser, 'profile name' => $profileCurrent->profileName);
  }
}
