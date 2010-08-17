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
    $table = $this->getDbTable('Application_Model_DbTable_Profiles');
 
    $resultSet = $table->fetchAll($table->select()->order('user')->order('name'));
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
    $table = $this->getDbTable('Application_Model_DbTable_Profiles');
    
    $resultSet = $table->fetchAll($table->select()->where('current = ?', 'true'));
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
    $table = $this->getDbTable('Application_Model_DbTable_Profiles');
    
    // Reset "all" current profiles..
    $data = array('current' => 'false');
    $table->update($data);

    // Make the specified by id profile current.
    $data = array('current' => 'true');
    $where = array('id = ?' => $profileCurrent->getId());
    $table->update($data, $where);
  }
   
  public function getProfileCurrentInfo()
  {
    $table = $this->getDbTable('Application_Model_DbTable_ProfilesPages');

    $resultSet = $table->fetchAll($table
      ->select()->setIntegrityCheck(false)
      ->from(array('PRPA' => 'profiles_pages'), 
          array('Profile name' => 'PR.name', 
                'Profile user' => 'PR.user', 
                'Page name' => 'PA.name'))
      ->joinLeft(array('PR' => 'profiles'), 'PRPA.profile_id=PR.id')
      ->joinLeft(array('PA' => 'pages'), 'PRPA.page_id=PA.id')
      ->where('current = ?', 'true'));

    foreach($resultSet as $row) {
      echo $row['Profile name'], $row['Profile user'], $row['Page name'], "<br>";
    }
  }
}

