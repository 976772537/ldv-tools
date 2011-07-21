<?php

class Application_Model_ProfileMapper extends Application_Model_GeneralMapper
{
	public function getProfilesDbTable($tableName)
	{
	  return $this->getDbTable($tableName, 'profiles');
	}
	
  public function getProfiles()
  {
    $profiles = $this->getProfilesDbTable('Application_Model_DbTable_Profiles');
    $resultSet = $profiles->fetchAll($profiles
      ->select()
      ->order('user')
      ->order('name'));

    $entries = array();
    foreach ($resultSet as $row) {
      $entry = new Application_Model_Profile(array(
        'profileId' => $row->id,
        'profileUser' => $row->user,
        'profileName' => $row->name));;
      $entries[] = $entry;
    }

    return $entries;
  }

  public function getProfile($name = 'default', $user = 'default')
  {
    $profiles = $this->getProfiles();

    foreach ($profiles as $profile) {
      if ($profile->profileName == $name and $profile->profileUser == $user) {
        return $profile;
      }
    }

    throw new Exception("The profile having name '$name' and user '$user' can't be found");
  }

  public function getProfileInfo($profile = null)
  {
    // Get the default profile if no one is specified.
    if (null === $profile) {
      $profile = $this->getProfile();
    }

    // Add information from db for the current profile.
    // Obtain information on the database connection.
    $profileDatabases = $this->getProfilesDbTable('Application_Model_DbTable_ProfilesDatabases');
    $profileDatabasesRow = $profileDatabases->fetchRow($profileDatabases
      ->select()->setIntegrityCheck(false)
      ->from(array('PRDA' => 'profiles_databases'),
          array('Host' => 'DA.host',
                'Name' => 'DA.dbname',
                'User' => 'DA.username',
                'Password' => 'DA.password'))
      ->joinLeft(array('PR' => 'profiles'), 'PRDA.profile_id=PR.id', array())
      ->joinLeft(array('DA' => 'databases'), 'PRDA.database_id=DA.id', array())
      ->where('PR.id = ?', $profile->profileId));
    $profile->setOptions(array(
      'dbHost' => $profileDatabasesRow['Host'],
      'dbName' => $profileDatabasesRow['Name'],
      'dbUser' => $profileDatabasesRow['User'],
      'dbPassword' => $profileDatabasesRow['Password']));
    $this->_logger->log("The current profile database connection: $profileDatabasesRow[Host] (host), $profileDatabasesRow[Name] (name), $profileDatabasesRow[User] (user), $profileDatabasesRow[Password] (password)", Zend_Log::DEBUG);

    // Get the current profile pages.
    $profilePages = $this->getProfilesDbTable('Application_Model_DbTable_ProfilesPages');
    $profilePagesResultSet = $profilePages->fetchAll($profilePages
      ->select()->setIntegrityCheck(false)
      ->from(array('PRPA' => 'profiles_pages'),
          array('Id' => 'PA.id',
                'Name' => 'PA.name'))
      ->joinLeft(array('PR' => 'profiles'), 'PRPA.profile_id=PR.id', array())
      ->joinLeft(array('PA' => 'pages'), 'PRPA.page_id=PA.id', array())
      ->where('PR.id = ?', $profile->profileId));

    foreach($profilePagesResultSet as $profilePagesRow) {
      $profilePage = $profile->setPageName($profilePagesRow['Name']);
      $this->_logger->log("The current profile page: $profilePagesRow[Name]", Zend_Log::DEBUG);

      // Get information on the page.
      $pagesLaunchInfo = $this->getProfilesDbTable('Application_Model_DbTable_PagesLaunchInfo');
      $pagesLaunchInfoResultSet = $pagesLaunchInfo->fetchAll($pagesLaunchInfo
        ->select()->setIntegrityCheck(false)
        ->from(array('PALA' => 'pages_launch_info'),
            array('Name' => 'LA.name',
                  'Id' => 'La.id',
                  'Order' => 'AU.order',
                  'Presence' => 'AU.presence'))
        ->joinLeft(array('LA' => 'launch_info'), 'PALA.launch_info_id=LA.id', array())
        ->joinLeft(array('AU' => 'aux_info'), 'LA.aux_info_id=AU.id', array())
        ->where('pages_id = ?', $profilePagesRow['Id'])
        ->order('AU.order'));

      foreach($pagesLaunchInfoResultSet as $pagesLaunchInfoRow) {
        $profilePageLaunchInfo = $profilePage->setLaunchInfoOrder($pagesLaunchInfoRow['Order']);

        $profilePageLaunchInfo->setOptions(array(
          'launchInfoName' => $pagesLaunchInfoRow['Name'],
          'auxInfo' => array('auxInfoPresence' => $pagesLaunchInfoRow['Presence'])));
        $this->_logger->log("The launch information: $pagesLaunchInfoRow[Name]", Zend_Log::DEBUG);

        // Get information on filters.
        $launchFiltersInfo = $this->getProfilesDbTable('Application_Model_DbTable_LaunchFiltersInfo');
        $launchFiltersInfoResultSet = $launchFiltersInfo->fetchAll($launchFiltersInfo
          ->select()->setIntegrityCheck(false)
          ->from(array('LAFI' => 'launch_filters_info'),
            array('Name' => 'FI.name',
                  'Value' => 'FI.value',
                  'Order' => 'AU.order',
                  'Presence' => 'AU.presence'))
          ->joinLeft(array('FI' => 'filters_info'), 'LAFI.filter_info_id=FI.id', array())
          ->joinLeft(array('AU' => 'aux_info'), 'FI.aux_info_id=AU.id', array())
          ->where('launch_info_id = ?', $pagesLaunchInfoRow['Id'])
          ->order('AU.order'));

        foreach($launchFiltersInfoResultSet as $launchFiltersInfoRow) {
          $profilePageLaunchInfoFilter = $profilePageLaunchInfo->setFilterOrder($launchFiltersInfoRow['Order']);
          $profilePageLaunchInfoFilter->setOptions(array(
            'filterName' => $launchFiltersInfoRow['Name'],
            'filterValue' => $launchFiltersInfoRow['Value'],
            'auxInfo' => array('auxInfoPresence' => $pagesLaunchInfoRow['Presence'])));
          $this->_logger->log("The filter: $launchFiltersInfoRow[Name] (name), $launchFiltersInfoRow[Value] (value)", Zend_Log::DEBUG);
        }
      }

      // Get information on verification.
      $pagesVerificationInfo = $this->getProfilesDbTable('Application_Model_DbTable_PagesVerificationInfo');
      $pagesVerificationInfoResultSet = $pagesVerificationInfo->fetchAll($pagesVerificationInfo
        ->select()->setIntegrityCheck(false)
        ->from(array('PAVE' => 'pages_verification_info'),
            array('Name' => 'VE.name',
                  'Id' => 'VE.id',
                  'Order' => 'AU.order',
                  'Presence' => 'AU.presence'))
        ->joinLeft(array('VE' => 'verification_info'), 'PAVE.verification_info_id=VE.id', array())
        ->joinLeft(array('AU' => 'aux_info'), 'VE.aux_info_id=AU.id', array())
        ->where('pages_id = ?', $profilePagesRow['Id'])
        ->order('AU.order'));

      foreach($pagesVerificationInfoResultSet as $pagesVerificationInfoRow) {
        $profilePageVerificationInfo = $profilePage->setVerificationInfoOrder($pagesVerificationInfoRow['Order']);
        $profilePageVerificationInfo->setOptions(array(
          'verificationInfoName' => $pagesVerificationInfoRow['Name'],
          'auxInfo' => array('auxInfoPresence' => $pagesLaunchInfoRow['Presence'])));
        $this->_logger->log("The verification information: $pagesVerificationInfoRow[Name]", Zend_Log::DEBUG);

        // Get information on verification result.
        if ($pagesVerificationInfoRow['Name'] == 'Result') {
          $verificationResultInfo = $this->getProfilesDbTable('Application_Model_DbTable_VerificationResultInfo');
          $verificationResultInfoResultSet = $verificationResultInfo->fetchAll($verificationResultInfo
            ->select()->setIntegrityCheck(false)
            ->from(array('VERE' => 'verification_result_info'),
              array('Name' => 'RE.name',
                    'Order' => 'AU.order',
                    'Presence' => 'AU.presence'))
            ->joinLeft(array('RE' => 'result_info'), 'VERE.result_info_id=RE.id', array())
            ->joinLeft(array('AU' => 'aux_info'), 'RE.aux_info_id=AU.id', array())
            ->where('verification_info_id = ?', $pagesVerificationInfoRow['Id'])
            ->order('AU.order'));

          foreach($verificationResultInfoResultSet as $verificationResultInfoRow) {
            $profilePageVerificationInfoResult = $profilePageVerificationInfo->setResultOrder($verificationResultInfoRow['Order']);
            $profilePageVerificationInfoResult->setOptions(array(
              'resultName' => $verificationResultInfoRow['Name'],
              'auxInfo' => array('auxInfoPresence' => $pagesLaunchInfoRow['Presence'])));
            $this->_logger->log("The verification result information: $verificationResultInfoRow[Name]", Zend_Log::DEBUG);
          }
        }
      }

      // Get information on knowledge base.
      $pagesKnowledgeBaseInfo = $this->getProfilesDbTable('Application_Model_DbTable_PagesKnowledgeBaseInfo');
      $pagesKnowledgeBaseInfoResultSet = $pagesKnowledgeBaseInfo->fetchAll($pagesKnowledgeBaseInfo
        ->select()->setIntegrityCheck(false)
        ->from(array('PAKB' => 'pages_kb_info'),
            array('Name' => 'KB.name',
                  'Id' => 'KB.id',
                  'Order' => 'AU.order',
                  'Presence' => 'AU.presence'))
        ->joinLeft(array('KB' => 'kb_info'), 'PAKB.kb_info_id=KB.id', array())
        ->joinLeft(array('AU' => 'aux_info'), 'KB.aux_info_id=AU.id', array())
        ->where('pages_id = ?', $profilePagesRow['Id'])
        ->order('AU.order'));

      foreach($pagesKnowledgeBaseInfoResultSet as $pagesKnowledgeBaseInfoRow) {
        $profilePageKnowledgeBaseInfo = $profilePage->setKnowledgeBaseInfoOrder($pagesKnowledgeBaseInfoRow['Order']);
        $profilePageKnowledgeBaseInfo->setOptions(array(
          'knowledgeBaseInfoName' => $pagesKnowledgeBaseInfoRow['Name'],
          'auxInfo' => array('auxInfoPresence' => $pagesLaunchInfoRow['Presence'])));
        $this->_logger->log("The knowledge base information: $pagesKnowledgeBaseInfoRow[Name]", Zend_Log::DEBUG);
      }

      // Get information on tools in general.
      $pagesToolsInfo = $this->getProfilesDbTable('Application_Model_DbTable_PagesToolsInfo');
      $pagesToolsInfoResultSet = $pagesToolsInfo->fetchAll($pagesToolsInfo
        ->select()->setIntegrityCheck(false)
        ->from(array('PATO' => 'pages_tools_info'),
            array('Name' => 'TOO.name',
                  'Id' => 'TOO.id',
                  'Order' => 'AU.order',
                  'Presence' => 'AU.presence'))
        ->joinLeft(array('TOO' => 'tools_info'), 'PATO.tools_info_id=TOO.id', array())
        ->joinLeft(array('AU' => 'aux_info'), 'TOO.aux_info_id=AU.id', array())
        ->where('pages_id = ?', $profilePagesRow['Id'])
        ->order('AU.order'));

      foreach($pagesToolsInfoResultSet as $pagesToolsInfoRow) {
        $profilePageToolsInfo = $profilePage->setToolsInfoOrder($pagesToolsInfoRow['Order']);
        $profilePageToolsInfo->setOptions(array(
          'toolsInfoName' => $pagesToolsInfoRow['Name'],
          'auxInfo' => array('auxInfoPresence' => $pagesLaunchInfoRow['Presence'])));
        $this->_logger->log("The tools information: $pagesToolsInfoRow[Name]", Zend_Log::DEBUG);

        // Get information on every tool.
        $toolsToolInfo = $this->getProfilesDbTable('Application_Model_DbTable_ToolsToolInfo');
        $toolsToolInfoResultSet = $toolsToolInfo->fetchAll($toolsToolInfo
          ->select()->setIntegrityCheck(false)
          ->from(array('TOTO' => 'tools_tool_info'),
            array('Name' => 'TOO.name',
                  'Id' => 'TOO.id',
                  'Order' => 'AU.order',
                  'Presence' => 'AU.presence'))
          ->joinLeft(array('TOO' => 'tool_info'), 'TOTO.tool_info_id=TOO.id', array())
          ->joinLeft(array('AU' => 'aux_info'), 'TOO.aux_info_id=AU.id', array())
          ->where('tools_info_id = ?', $pagesToolsInfoRow['Id'])
          ->order('AU.order'));

        foreach($toolsToolInfoResultSet as $toolsToolInfoRow) {
          $profilePageToolsInfoTool = $profilePageToolsInfo->setToolOrder($toolsToolInfoRow['Order']);
          $profilePageToolsInfoTool->setOptions(array(
            'toolName' => $toolsToolInfoRow['Name'],
            'auxInfo' => array('auxInfoPresence' => $pagesLaunchInfoRow['Presence'])));
          $this->_logger->log("The tools tool information: $toolsToolInfoRow[Name]", Zend_Log::DEBUG);

          // Get information on tool time.
          if ($toolsToolInfoRow['Name'] == 'Time') {
            $toolTimeInfo = $this->getProfilesDbTable('Application_Model_DbTable_ToolTimeInfo');
            $toolTimeInfoResultSet = $toolTimeInfo->fetchAll($toolTimeInfo
              ->select()->setIntegrityCheck(false)
              ->from(array('TOTI' => 'tool_time_info'),
                array('Name' => 'TI.name',
                      'Order' => 'AU.order',
                      'Presence' => 'AU.presence'))
              ->joinLeft(array('TI' => 'time_info'), 'TOTI.time_info_id=TI.id', array())
              ->joinLeft(array('AU' => 'aux_info'), 'TI.aux_info_id=AU.id', array())
              ->where('tool_info_id = ?', $toolsToolInfoRow['Id'])
              ->order('AU.order'));

            foreach($toolTimeInfoResultSet as $toolTimeInfoRow) {
              $profilePageToolInfoTime = $profilePageToolsInfoTool->setTimeOrder($toolTimeInfoRow['Order']);
              $profilePageToolInfoTime->setOptions(array(
                'timeName' => $toolTimeInfoRow['Name'],
                'auxInfo' => array('auxInfoPresence' => $toolTimeInfoRow['Presence'])));
              $this->_logger->log("The tool time information: $toolTimeInfoRow[Name]", Zend_Log::DEBUG);
            }
          }
        }
      }
    }

#print_r($profile);exit;

    return $profile;
  }
}

