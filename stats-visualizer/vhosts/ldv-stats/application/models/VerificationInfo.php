<?php

class Application_Model_VerificationInfo extends Application_Model_GeneralStats
{
  protected $_verificationInfoName;
  protected $_results;

  public function setResultOrder($order)
  {
    $filter = new Application_Model_ResultInfo();
    $this->_results[$order] = $filter;
    return $filter;
  }

  public function getResults()
  {
    return $this->_results;
  }

  public function setVerificationInfoName($name)
  {
    $this->_verificationInfoName = (string) $name;
    return $this;
  }

  public function getVerificationInfoName()
  {
    return $this->_verificationInfoName;
  }
}
