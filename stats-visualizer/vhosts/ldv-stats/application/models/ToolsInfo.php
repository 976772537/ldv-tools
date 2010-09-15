<?php

class Application_Model_ToolsInfo extends Application_Model_General
{
  protected $_toolsInfoName;
  protected $_tools;

  public function setToolOrder($order)
  {
    $filter = new Application_Model_ToolInfo();
    $this->_tools[$order] = $filter;
    return $filter;
  }
 
  public function getTools()
  {
    return $this->_tools;
  }  
  
  public function setToolsInfoName($name)
  {
    $this->_toolsInfoName = (string) $name;
    return $this;
  }
 
  public function getToolsInfoName()
  {
    return $this->_toolsInfoName;
  }
}
