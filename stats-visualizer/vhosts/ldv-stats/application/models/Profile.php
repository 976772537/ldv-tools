<?php

class Application_Model_Profile extends Application_Model_General
{
  protected $_profileId;
  protected $_profileName;
  protected $_profileUser;
  protected $_dbHost;
  protected $_dbName;
  protected $_dbUser;
  protected $_dbPassword;
  protected $_pages;

  public function setProfileId($id)
  {
    $this->_profileId = (int) $id;
    return $this;
  }

  public function getProfileId()
  {
    return $this->_profileId;
  }

  public function setProfileUser($user)
  {
    $this->_profileUser = (string) $user;
    return $this;
  }

  public function getProfileUser()
  {
    return $this->_profileUser;
  }

  public function setProfileName($name)
  {
    $this->_profileName = (string) $name;
    return $this;
  }

  public function getProfileName()
  {
    return $this->_profileName;
  }

  public function setDbHost($host)
  {
    $this->_dbHost = (string) $host;
    return $this;
  }

  public function getDbHost()
  {
    return $this->_dbHost;
  }

  public function setDbName($name)
  {
    $this->_dbName = (string) $name;
    return $this;
  }

  public function getDbName()
  {
    return $this->_dbName;
  }

  public function setDbUser($user)
  {
    $this->_dbUser = (string) $user;
    return $this;
  }

  public function getDbUser()
  {
    return $this->_dbUser;
  }

  public function setDbPassword($password)
  {
    $this->_dbPassword = (string) $password;
    return $this;
  }

  public function getDbPassword()
  {
    return $this->_dbPassword;
  }

  public function setPageName($name)
  {
    $page = new Application_Model_Page();
    $this->_pages[$name] = $page;
    return $page;
  }

  public function getPages()
  {
    return $this->_pages;
  }

  public function getPageNames()
  {
    $pageNames = array();
    foreach (array_keys($this->_pages) as $pageName) {
      $pageNames[$pageName] = 1;
    }
    return $pageNames;
  }

  public function getPage($name)
  {
    return $this->_pages[$name];
  }
}

