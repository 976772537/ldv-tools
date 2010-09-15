<?php

class Application_Model_LaunchInfo extends Application_Model_General
{
  protected $_launchInfoName;
  protected $_filters;

  public function setFilterOrder($order)
  {
    $filter = new Application_Model_FilterInfo();
    $this->_filters[$order] = $filter;
    return $filter;
  }
 
  public function getFilters()
  {
    return $this->_filters;
  }  
  
  public function setLaunchInfoName($name)
  {
    $this->_launchInfoName = (string) $name;
    return $this;
  }
 
  public function getLaunchInfoName()
  {
    return $this->_launchInfoName;
  }
}
