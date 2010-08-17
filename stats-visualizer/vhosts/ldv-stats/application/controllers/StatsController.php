<?php

class StatsController extends Zend_Controller_Action
{
  public function init()
  {
    $profileMapper = new Application_Model_ProfileMapper();
    $profileCurrent = $profileMapper->getProfileCurrent();
    $this->view->entries = array('user name' => $profileCurrent->userName, 'profile name' => $profileCurrent->profileName);
  }

  public function indexAction()
  {
  }
}
