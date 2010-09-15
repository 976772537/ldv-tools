<?php

class Application_Model_ToolInfo extends Application_Model_General
{
  protected $_toolName;
  
  public function setToolName($name)
  {
    $this->_toolName = (string) $name;
    return $this;
  }
 
  public function getToolName()
  {
    return $this->_toolName;
  }
}
