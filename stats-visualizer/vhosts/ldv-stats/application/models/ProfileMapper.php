<?php

class Application_Model_ProfileMapper
{
#  protected $_dbTable;
 
/*  public function setDbTable($dbTable)
  {
    if (is_string($dbTable)) {
      $dbTable = new $dbTable();
    }
    if (!$dbTable instanceof Zend_Db_Table_Abstract) {
      throw new Exception('Invalid table data gateway provided');
    }
    $this->_dbTable = $dbTable;
    return $this;
  }
*/ 
  public function getDbTable($tableName)
  {
    if (is_string($tableName)) {
      $dbTable = new $tableName();
    }
    if (!$dbTable instanceof Zend_Db_Table_Abstract) {
      throw new Exception('Invalid table data gateway provided');
    }
    return $dbTable;
#    if (null === $this->_dbTable) {
#      $this->setDbTable('Application_Model_DbTable_Profiles');
#    }
#    return $this->_dbTable;
  }

  public function getProfiles()
  {
    print_r($this->getDbTable('Application_Model_DbTable_Profiles'));
    exit;
    $resultSet = $this->getDbTable('Application_Model_DbTable_Profiles')->_db->select()->order('user')->order('name');
    $entries = array();
    foreach ($resultSet as $row) {
      $entry = new Application_Model_Profile();;
      $entry->setId($row->id);
      $entry->setUserName($row->user);
      $entry->setProfileName($row->name);
      $entries[] = $entry;
    }
    
    return $entries;
  }
  
  public function getProfileCurrent()
  {
    $resultSet = $this->getDbTable()->fetchAll($this->getDbTable()->select()->where('current = ?', 'true'));
    foreach ($resultSet as $row) {
      $entry = new Application_Model_Profile();;
      $entry->setId($row->id);
      $entry->setUserName($row->user);
      $entry->setProfileName($row->name);
      return $entry;
    }
  }
  
  public function setProfileCurrent($profileCurrent)
  {
    // Reset "all" current profiles..
    $data = array('current' => 'false');
    $this->getDbTable()->update($data);

    // Make the specified by id profile current.
    $data = array('current' => 'true');
    $where = array('id = ?' => $profileCurrent->getId());
    $this->getDbTable()->update($data, $where);
  }
   
  public function getProfileCurrentInfo()
  {
    print_r($this->getDbTable('Application_Model_DbTable_Profiles'));
    exit;
    $resultSet = $this->getDbTable()->fetchAll($this->getDbTable()
      ->select()
      ->joinLeft('profiles', 'profiles_pages.profile.id=profiles.id')
      ->joinLeft('pages', 'profiles_pages.page_id=pages.id'));
    print_r($resultSet);
  }
}

