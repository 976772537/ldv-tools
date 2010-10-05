<?php

class Application_Model_General
{
  protected $_auxInfo;
  
  public function __construct(array $options = null)
  {
    if (is_array($options)) {
      $this->setOptions($options);
    }
  }
 
  public function __set($name, $value)
  {
    $method = 'set' . $name;
    if (('mapper' == $name) || !method_exists($this, $method)) {
      throw new Exception("Invalid property: $name");
    }
    $this->$method($value);
  }
 
  public function __get($name)
  {
    $method = 'get' . $name;
    if (('mapper' == $name) || !method_exists($this, $method)) {
      throw new Exception("Invalid property: $name");
    }
    return $this->$method();
  }
 
  public function setOptions(array $options)
  {
    $methods = get_class_methods($this);
    foreach ($options as $key => $value) {
      $method = 'set' . ucfirst($key);
      if (in_array($method, $methods)) {
        $this->$method($value);
      }
      else
      {
        throw new Exception("Invalid property: $key");
      }
    }
    return $this;
  }
  
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
