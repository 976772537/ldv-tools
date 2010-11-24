<?php

class Application_Model_ToolInfo extends Application_Model_GeneralStats
{
  protected $_toolName;
  protected $_time;

  public function setTimeOrder($order)
  {
    $time = new Application_Model_TimeInfo();
    $this->_time[$order] = $time;
    return $time;
  }

  public function getTime()
  {
    return $this->_time;
  }

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
