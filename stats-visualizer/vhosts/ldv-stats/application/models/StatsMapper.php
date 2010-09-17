<?php

class Application_Model_StatsMapper extends Application_Model_GeneralMapper
{
  protected $_db;
  protected $_launchInfoNameColumnMapper = array(
    'Task id' => 'TA.id',
    'Task name' => 'TA.name',
    'Rule' => array('table' => 'rule_models', 'column' => 'name'),
    'Driver' => array('table' => 'drivers', 'column' => 'name'));
    # Task description
    # Task user name
    # Task timestamp
    # Toolset version
    # Toolset verifier
    # Driver name
    # Driver origin
    # Environment version
    # Environment kind
    # Rule name
    # Module
    # Entry point
  protected $_verificationInfoNameColumnMapper = array(
    'Verifier' => 'TR.verifier',
    'Error trace' => 'TR.error_trace');
  protected $_verificationResultInfoNameColumnMapper = array(
    'Safe' => 'TR.result',
    'Unsafe' => 'TR.result',
    'Unknown' => 'TR.result');
  
  public function connectToDb($host, $name, $user, $passord) {
    $options = array(
      'host'     => 'localhost',
      'username' => $user,
      'password' => '',
      'dbname'   => $name,
      'profiler' => array(
        'enabled' => true, 
        'class' => 'Zend_Db_Profiler_Firebug'));
    
    // Password and host are optional settings.
    if (isset($password)) {
      $options['password'] = $password;
    }
    
    if (isset($host)) {
      $options['host'] = $host;
    }    
    
    $this->_db = new Zend_Db_Adapter_Pdo_Mysql($options);
  }
  
  public function leftJoin($name, $shortname, $cond)
  {
    return " LEFT JOIN `$name` AS `$shortname` ON $cond";
  }
  
  public function getPageStats($profile, $pageName)
  {
    $page = $profile->getPage($pageName);
    
#print_r($page);
    $this->connectToDb($profile->dbHost, $profile->dbName, $profile->dbUser, $profile->dbPassword);
    
    // Obtain the launch info columns. By them groupping by and ordering will be
    // done. Note that they are already ordered.
    $launchInfo = array();
    $groupby = array();
    $orderby = array();
    foreach ($page->launchInfo as $info) {
      $groupby[] = $orderby[] = $this->_launchInfoNameColumnMapper[$info->launchInfoName];
      $launchInfo[$info->launchInfoName] = $this->_launchInfoNameColumnMapper[$info->launchInfoName];
    }

    // Obtain the list of verification info columns. Note that they are already 
    // ordered.
    $verificationInfo = array();
    $verificationResultInfo = array();
    foreach ($page->verificationInfo as $info) {
      // The 'Result' is just union of 'Safe', 'Unsafe' and 'Unknown' statuses
      // that will be iterated below.
      if ($info->verificationInfoName == 'Result') {
        $verificationResultInfo = $info->results;
      }
      else
      {
        $verificationInfo[$info->verificationInfoName] = $this->_verificationInfoNameColumnMapper[$info->verificationInfoName];
      }
    }
/*    
    $launches = $this->getDbTable('Application_Model_DbTable_Launches', $this->_db);
 
    // Prepare queries to the stats db.
    $select = $launches
      ->select()->setIntegrityCheck(false);
      
    // Get data from the main launches table.
    $select = $select
      ->from(array('LA' => 'launches'), array_merge($launchInfo, $verificationInfo));
    
    // Join launches with related tables.
    $select = $select
      ->joinLeft(array('TA' => 'tasks'), 'LA.task_id=TA.id')
      ->joinLeft(array('TO' => 'toolsets'), 'LA.toolset_id=TO.id')
      ->joinLeft(array('DR' => 'drivers'), 'LA.driver_id=DR.id')
      ->joinLeft(array('EN' => 'environments'), 'LA.environment_id=EN.id')
      ->joinLeft(array('RU' => 'rule_models'), 'LA.rule_model_id=RU.id')
      ->joinLeft(array('SC' => 'scenarios'), 'LA.scenario_id=SC.id')
      ->joinLeft(array('TR' => 'traces'), 'LA.trace_id=TR.id');
    
    // Group by the launch information. 
    foreach ($groupby as $group) {
      $select = $select->group($group);
    }
     
    // Order by the launch information. 
    foreach ($orderby as $order) {
      $select = $select->order($order);
    }
    */ 
/*    
SELECT 
  `RU`.`name` AS `Rule`, 
  `DR`.`name` AS `Driver`, 
  `TR`.`verifier` AS `Verifier`, 
  `TR`.`error_trace` AS `Error trace`, 
  `TA`.*, `TO`.*, `DR`.*, `EN`.*, `RU`.*, `SC`.*, `TR`.* 
FROM `launches` AS `LA` 
LEFT JOIN `scenarios` AS `SC` ON LA.scenario_id=SC.id 
LEFT JOIN `traces` AS `TR` ON LA.trace_id=TR.id 
GROUP BY `RU`.`name`, `DR`.`name` 
ORDER BY `RU`.`name` ASC, `DR`.`name` ASC
*/
/*
    print_r($select->assemble());
    #exit;
        #->where('pages_id = ?', $profilePagesRow['Id'])
        
    $launchesResultSet = $launches->fetchAll($select);

    foreach($launchesResultSet as $launchesRow) {  
      echo  $launchesRow['Rule'], "  ", $launchesRow['Driver'], "  ", $launchesRow['Driver']; echo "<br>";
    }
*/    
       
      $stmt = $this->_db->query(
                  'SELECT * FROM environments'
              );
              
      $stmt->execute();
         
      #
$rows = $stmt->fetchAll();
    $sql = '';
    $sql .= $this->leftJoin('tasks',        'TA', '`LA`.`task_id`=`TA`.`id`');
    $sql .= $this->leftJoin('toolsets',     'TO', '`LA`.`toolset_id`=`TO`.`id`');
    $sql .= $this->leftJoin('drivers',      'DR', '`LA`.`driver_id`=`DR`.`id`');
    $sql .= $this->leftJoin('environments', 'EN', '`LA`.`environment_id`=`EN`.`id`');
    $sql .= $this->leftJoin('rule_models',  'TA', '`LA`.`rule_model_id`=`RU`.`id`');
    $sql .= $this->leftJoin('scenarios',    'SC', '`LA`.`scenario_id`=`SC`.`id`');
    $sql .= $this->leftJoin('traces',       'TR', '`LA`.`trace_id`=`TR`.`id`');
    
    print($sql);      
  }
}
