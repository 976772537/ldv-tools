<?php

class Application_Model_GeneralStats extends Application_Model_General
{
  protected $_auxInfo;

  public function setAuxInfo(array $options)
  {
    $this->_auxInfo = new Application_Model_AuxInfo($options);
    return $this;
  }

  public function getAuxInfoPresence()
  {
    return $this->_auxInfo->auxInfoPresence;
  }

  public function getAuxInfoRequireUniqueKey()
  {
    return $this->_auxInfo->auxInfoRequireUniqueKey;
  }
}
