<?php

class Application_Model_AuxInfo extends Application_Model_GeneralStats
{
  protected $_auxInfoPresence;
  protected $_auxInfoRequireUniqueKey;

  public function setAuxInfoPresence($name)
  {
    $this->_auxInfoPresence = (string) $name;
    return $this;
  }

  public function getAuxInfoPresence()
  {
    return $this->_auxInfoPresence;
  }

  public function setAuxInfoRequireUniqueKey($value)
  {
    $this->_auxInfoRequireUniqueKey = $value;
    return $this;
  }

  public function getAuxInfoRequireUniqueKey()
  {
    return $this->_auxInfoRequireUniqueKey;
  }
}
