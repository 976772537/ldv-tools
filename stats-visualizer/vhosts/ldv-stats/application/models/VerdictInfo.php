<?php

class Application_Model_VerdictInfo extends Application_Model_GeneralStats
{
  protected $_verdictName;

  public function setVerdictName($name)
  {
    $this->_verdictName = (string) $name;
    return $this;
  }

  public function getVerdictName()
  {
    return $this->_verdictName;
  }
}
