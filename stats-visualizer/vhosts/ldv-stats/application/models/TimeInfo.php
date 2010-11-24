<?php

class Application_Model_TimeInfo extends Application_Model_GeneralStats
{
  protected $_timeName;

  public function setTimeName($name)
  {
    $this->_timeName = (string) $name;
    return $this;
  }

  public function getTimeName()
  {
    return $this->_timeName;
  }
}
