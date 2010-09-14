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
    $table->update($data, '');

    // Make the specified by id profile current.
    $data = array('current' => 'true');
    $where = array('id = ?' => $profileCurrent->getId());
    $table->update($data, $where);
  }
   
  public function getProfileCurrentInfo()
  {
    $profilePages = $this->getDbTable('Application_Model_DbTable_ProfilesPages');
    $profilePagesResultSet = $profilePages->fetchAll($profilePages
      ->select()->setIntegrityCheck(false)
      ->from(array('PRPA' => 'profiles_pages'), 
          array('Profile name' => 'PR.name', 
                'Profile user' => 'PR.user', 
                'Page id' => 'PA.id',
                'Page name' => 'PA.name'))
      ->joinLeft(array('PR' => 'profiles'), 'PRPA.profile_id=PR.id')
      ->joinLeft(array('PA' => 'pages'), 'PRPA.page_id=PA.id')
      ->where('current = ?', 'true'));

    foreach($profilePagesResultSet as $profilePagesRow) {
      echo $profilePagesRow['Profile name'], " ", $profilePagesRow['Profile user'], " ", $profilePagesRow['Page name'], " ", $profilePagesRow['Page id'], "<br>";
    
      // Get information on pages.
      $pagesLaunchInfo = $this->getDbTable('Application_Model_DbTable_PagesLaunchInfo');
      $pagesLaunchInfoResultSet = $pagesLaunchInfo->fetchAll($pagesLaunchInfo
        ->select()->setIntegrityCheck(false)
        ->from(array('PALA' => 'pages_launch_info'),
            array('Launch info name' => 'LA.name',
                  'Presence' => 'AU.presence'))
        ->joinLeft(array('LA' => 'launch_info'), 'PALA.launch_info_id=LA.id')
        ->joinLeft(array('AU' => 'aux_info'), 'LA.aux_info_id=AU.id')
        ->where('pages_id = ?', $profilePagesRow['Page id'])
        ->order('AU.order'));
        
      foreach($pagesLaunchInfoResultSet as $pagesLaunchInfoRow) {
        echo "*", $pagesLaunchInfoRow['Launch info name'], " ", $pagesLaunchInfoRow['Presence'], "<br>";
      }   
       
      // Get information on verification.
      $pagesVerificationInfo = $this->getDbTable('Application_Model_DbTable_PagesVerificationInfo');
      $pagesVerificationInfoResultSet = $pagesVerificationInfo->fetchAll($pagesVerificationInfo
        ->select()->setIntegrityCheck(false)
        ->from(array('PAVE' => 'pages_verification_info'),
            array('Name' => 'VE.name',
                  'Id' => 'VE.id',
                  'Presence' => 'AU.presence'))
        ->joinLeft(array('VE' => 'verification_info'), 'PAVE.verification_info_id=VE.id')
        ->joinLeft(array('AU' => 'aux_info'), 'VE.aux_info_id=AU.id')
        ->where('pages_id = ?', $profilePagesRow['Page id'])
        ->order('AU.order'));

      foreach($pagesVerificationInfoResultSet as $pagesVerificationInfoRow) {
        echo "_", $pagesVerificationInfoRow['Name'], " ", $pagesVerificationInfoRow['Presence'], "<br>";
        
        // Get information on verification result.
        if ($pagesVerificationInfoRow['Name'] == 'Result') {
          $verificationResultInfo = $this->getDbTable('Application_Model_DbTable_VerificationResultInfo');
          $verificationResultInfoResultSet = $verificationResultInfo->fetchAll($verificationResultInfo
            ->select()->setIntegrityCheck(false)
            ->from(array('VERE' => 'verification_result_info'),
              array('Name' => 'RE.name',
                    'Presence' => 'AU.presence'))
            ->joinLeft(array('RE' => 'result_info'), 'VERE.result_info_id=RE.id')
            ->joinLeft(array('AU' => 'aux_info'), 'RE.aux_info_id=AU.id')
            ->where('verification_info_id = ?', $pagesVerificationInfoRow['Id'])
            ->order('AU.order'));
        
          foreach($verificationResultInfoResultSet as $verificationResultInfoRow) {
            echo "__", $verificationResultInfoRow['Name'], " ", $verificationResultInfoRow['Presence'], "<br>";
          }
        }
      }

      // Get information on tools in general.
      $pagesToolsInfo = $this->getDbTable('Application_Model_DbTable_PagesToolsInfo');
      $pagesToolsInfoResultSet = $pagesToolsInfo->fetchAll($pagesToolsInfo
        ->select()->setIntegrityCheck(false)
        ->from(array('PATO' => 'pages_tools_info'),
            array('Name' => 'TOO.name',
                  'Id' => 'TOO.id',
                  'Presence' => 'AU.presence'))
        ->joinLeft(array('TOO' => 'tools_info'), 'PATO.tools_info_id=TOO.id')
        ->joinLeft(array('AU' => 'aux_info'), 'TOO.aux_info_id=AU.id')
        ->where('pages_id = ?', $profilePagesRow['Page id'])
        ->order('AU.order'));
        
      foreach($pagesToolsInfoResultSet as $pagesToolsInfoRow) {
        echo "+", $pagesToolsInfoRow['Name'], " ", $pagesToolsInfoRow['Presence'], "<br>";
        
        // Get information on every tool.
        $toolsToolInfo = $this->getDbTable('Application_Model_DbTable_ToolsToolInfo');
        $toolsToolInfoResultSet = $toolsToolInfo->fetchAll($toolsToolInfo
          ->select()->setIntegrityCheck(false)
          ->from(array('TOTO' => 'tools_tool_info'),
            array('Name' => 'TOO.name',
                  'Presence' => 'AU.presence'))
          ->joinLeft(array('TOO' => 'tool_info'), 'TOTO.tool_info_id=TOO.id')
          ->joinLeft(array('AU' => 'aux_info'), 'TOO.aux_info_id=AU.id')
          ->where('tools_info_id = ?', $pagesToolsInfoRow['Id'])
          ->order('AU.order'));
        
        foreach($toolsToolInfoResultSet as $toolsToolInfoRow) {
          echo "++", $toolsToolInfoRow['Name'], " ", $toolsToolInfoRow['Presence'], "<br>";
        }
      }
    }
  }
}

