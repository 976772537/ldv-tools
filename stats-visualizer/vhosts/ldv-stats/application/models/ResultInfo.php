<?php

class Application_Model_ResultInfo extends Application_Model_General
{
  protected $_resultName;
  
  public function setResultName($name)
  {
    $this->_resultName = (string) $name;
    return $this;
  }
 
  public function getResultName()
  {
    return $this->_resultName;
  }
}
