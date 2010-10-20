<?php

class Application_Model_Page extends Application_Model_GeneralStats
{
  protected $_launchInfo;
  protected $_verificationInfo;
  protected $_toolsInfo;

  public function setToolsInfoOrder($order)
  {
    $toolsInfo = new Application_Model_ToolsInfo();
    $this->_toolsInfo[$order] = $toolsInfo;
    return $toolsInfo;
  }

  public function getToolsInfo()
  {
    return $this->_toolsInfo;
  }

  public function setLaunchInfoOrder($order)
  {
    $launchInfo = new Application_Model_LaunchInfo();
    $this->_launchInfo[$order] = $launchInfo;
    return $launchInfo;
  }

  public function getLaunchInfo()
  {
    return $this->_launchInfo;
  }

  public function setVerificationInfoOrder($order)
  {
    $verificationInfo = new Application_Model_VerificationInfo();
    $this->_verificationInfo[$order] = $verificationInfo;
    return $verificationInfo;
  }

  public function getVerificationInfo()
  {
    return $this->_verificationInfo;
  }
}
