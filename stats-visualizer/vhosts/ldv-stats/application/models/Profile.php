<?php

class Application_Model_Profile
{  
  protected $_id;
  protected $_userName;
  protected $_profileName;
 
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
      throw new Exception('Invalid guestbook property');
    }
    $this->$method($value);
  }
 
  public function __get($name)
  {
    $method = 'get' . $name;
    if (('mapper' == $name) || !method_exists($this, $method)) {
      throw new Exception('Invalid guestbook property');
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
    }
    return $this;
  }

  public function setId($id)
  {
    $this->_id = (int) $id;
    return $this;
  }
 
  public function getId()
  {
    return $this->_id;
  }
  
  public function setUserName($userName)
  {
    $this->_userName = (string) $userName;
    return $this;
  }
 
  public function getUserName()
  {
    return $this->_userName;
  }
  
  public function setProfileName($profileName)
  {
    $this->_profileName = (string) $profileName;
    return $this;
  }
 
  public function getProfileName()
  {
    return $this->_profileName;
  }
}

