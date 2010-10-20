<?php

class Application_Model_FilterInfo extends Application_Model_GeneralStats
{
  protected $_filterName;
  protected $_filterValue;

  public function setFilterName($name)
  {
    $this->_filterName = (string) $name;
    return $this;
  }

  public function getFilterName()
  {
    return $this->_filterName;
  }

  public function setFilterValue($value)
  {
    $this->_filterValue = (string) $value;
    return $this;
  }

  public function getFilterValue()
  {
    return $this->_filterValue;
  }
}
