<?php

class Application_Model_StatsMapper extends Application_Model_GeneralMapper
{
  protected $_db;
  protected $_launchInfoNameTableColumnMapper = array(
    'Rule name' => array('table' => 'rule_models', 'column' => 'name'),
    'Driver name' => array('table' => 'drivers', 'column' => 'name'));
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
  protected $_verificationInfoNameTableColumnMapper = array(
    'Verifier' => array('table' => 'traces', 'column' => 'verifier'),
    'Error trace' => array('table' => 'traces', 'column' => 'error_trace'));
  protected $_verificationResultInfoNameTableColumnMapper = array(
    'Safe' => array('table' => 'traces', 'column' => 'result', 'cond' => 'Safe'),
    'Unsafe' => array('table' => 'traces', 'column' => 'result', 'cond' => 'Unsafe'),
    'Unknown' => array('table' => 'traces', 'column' => 'result', 'cond' => 'Unknown'));
  protected $_toolsInfoNameTableColumnMapper = array(
    'BCE' => array('table' => 'stats', 'column' => 'build_id'),
    'DEG' => array('table' => 'stats', 'column' => 'maingen_id'),
    'DSCV' => array('table' => 'stats', 'column' => 'dscv_id'),
    'RI' => array('table' => 'stats', 'column' => 'ri_id'),
    'RCV' => array('table' => 'stats', 'column' => 'rcv_id'));
  protected $_toolInfoNameTableColumnMapper = array(
    'Ok' => array('table' => 'stats', 'column' => 'success', 'cond' => 'TRUE'),
    'Fail' => array('table' => 'stats', 'column' => 'success', 'cond' => 'FALSE'),
    'Description' => array('table' => 'stats', 'column' => 'description'),
    'Time' => array('table' => 'stats', 'column' => 'time'),
    'LOC' => array('table' => 'stats', 'column' => 'loc'));
  protected $_tableMapper = array(
    'drivers' => 'DR',
    'launches' => 'LA',
    'rule_models' => 'RU',
    'stats' => 'ST',
    'traces' => 'TR');   
  protected $_tableLaunchMapper = array(
    'drivers' => 'driver_id',
    'rule_models' => 'rule_model_id',
    'traces' => 'trace_id');   
  
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
  
  public function getTableColumn($tableColumn)
  {
    $table = $tableColumn['table'];
    $tableShort = $this->_tableMapper[$table];
    $column = $tableColumn['column'];
    return array('table' => $table, 'tableShort' => $tableShort, 'column' => $column);
  }
  
  public function groupBy($tableName, $columnName)
  {
    return " `$tableName`.`$columnName`";
  }
     
  public function from($name, $shortName = '')
  {
	if ($shortName) {
      return " FROM `$name` AS `$shortName`";
    }
    else {
      return " FROM `$name`";
	}
  }
    
  public function leftJoin($name, $shortName, $cond)
  {
    return " LEFT JOIN `$name` AS `$shortName` ON $cond";
  }
    
  public function leftJoinUsing($name, $using)
  {
	$sql = " LEFT JOIN `$name` USING (";
	$using_all = join(', ', $using);
	$sql .= $using_all;
	$sql .= ')';
    return $sql;
  }
      
  public function orderBy($tableName, $columnName)
  {
    return " `$tableName`.`$columnName`";
  }
        
  public function select($tableName, $columnName, $shortName, $isCount = false)
  {
	if ($isCount) {
	  $sql = ' COUNT(';
	}
	else {
	  $sql = ' ';
	}
	
	$sql .= "`" . $this->_tableMapper[$tableName] . "`.`$columnName`";
	
	if ($isCount) {
	  $sql .= ')';
	}
	
	$sql .= " AS `$shortName`";
	
    return $sql;
  }
      
  public function where($tableName, $columnName, $cond)
  {
    return "`" . $this->_tableMapper[$tableName] . "`.`$columnName`='$cond'";
  }
             
  public function createTemporaryTable($tableName,
    $selectGeneral, $fromGeneral, $joinGeneral, $whereGeneral, $groupByGeneral, $orderByGeneral,
    $select = '', $from = '', $join = '', $where = '', $groupBy = '', $orderBy = '')
  {
    // Merge the general queries parts with the specific ones.
    $select = $selectGeneral . $select;
    $from = $fromGeneral . $from;
    $join = $joinGeneral . $join;
    $where = $whereGeneral . $where;
    $groupBy = $groupByGeneral . $groupBy;
    $orderBy = $orderByGeneral . $orderBy;
    
    return "CREATE TEMPORARY TABLE IF NOT EXISTS `$tableName` $select $from $join $where $groupBy $orderBy";
  }
        
  public function getPageStats($profile, $pageName)
  {
    $page = $profile->getPage($pageName);
    $this->connectToDb($profile->dbHost, $profile->dbName, $profile->dbUser, $profile->dbPassword);

    // Obtain the launch info columns. They will be selected as statistics key, 
    // joined and by them groupping by and ordering will be done. Note that they 
    // are already ordered.
    $launchInfo = array();
    $joins = array();
    $groupby = array();
    $orderby = array();
    foreach ($page->launchInfo as $info) {
	  $name = $info->launchInfoName;
	  $tableColumn = $this->getTableColumn($this->_launchInfoNameTableColumnMapper[$name]);
      $launchInfo[$name] = $groupby[] = $orderby[] = "$tableColumn[tableShort].$tableColumn[column]";
      $joins[$tableColumn['table']] = 1;
    }

    // Obtain the list of verification info columns. They will be selected. Note 
    // that they are already ordered.
    $verificationInfo = array();
    $verificationResultInfo = array();
    foreach ($page->verificationInfo as $info) {
      // The 'Result' is just union of 'Safe', 'Unsafe' and 'Unknown' statuses
      // that will be iterated below.
      if ($info->verificationInfoName == 'Result') {
        foreach ($info->results as $resultInfo) {
	      $name = $resultInfo->resultName;
	      $tableColumnCond = $this->_verificationResultInfoNameTableColumnMapper[$name];
	      $tableColumn = $this->getTableColumn($tableColumnCond);
          $verificationResultInfo[$name] = "SUM(IF(`$tableColumn[tableShort]`.`$tableColumn[column]`='$tableColumnCond[cond]', 1, 0))";
		}
      }
      else
      {
	    $name = $info->verificationInfoName;
	    $tableColumn = $this->getTableColumn($this->_verificationInfoNameTableColumnMapper[$name]);
        $verificationInfo[$name] = "$tableColumn[tableShort].$tableColumn[column]";
      }
    }
   
    // Obtain the list of tools info columns.
    $tools = array();
    $toolsInfo = array();
    foreach ($page->toolsInfo as $info) {
	  $toolName = $info->toolsInfoName;
	  foreach ($info->tools as $toolInfo) {
	    $name = $toolInfo->toolName;
	    if ($name == 'Ok' || $name == 'Fail') {
	      $tableColumnCond = $this->_toolInfoNameTableColumnMapper[$name];
	      $tableColumn = $this->getTableColumn($tableColumnCond);
          $toolsInfo["$toolName $name"] = "SUM(IF(`$tableColumn[tableShort]_$toolName`.`$tableColumn[column]`=$tableColumnCond[cond], 1, 0))";
	    }
	    else if ($name == 'Description') {
	      $tableColumn = $this->getTableColumn($this->_toolInfoNameTableColumnMapper[$name]);
		  $toolsInfo["$toolName $name"] = "$tableColumn[tableShort]_$toolName.$tableColumn[column]";
		}
		else {	    
	      $tableColumn = $this->getTableColumn($this->_toolInfoNameTableColumnMapper[$name]);
		  $toolsInfo["$toolName $name"] = "SUM(`$tableColumn[tableShort]_$toolName`.`$tableColumn[column]`)";  
		}
	  }
	  $tools[$toolName] = 1;
	}
   
    $launches = $this->getDbTable('Application_Model_DbTable_Launches', $this->_db);
 
    // Prepare queries to the stats db.
    $select = $launches
      ->select()->setIntegrityCheck(false);
      
    // Get data from the main launches table.
    $tableMain = 'launches';
    $select = $select
      ->from(array($this->_tableMapper[$tableMain] => $tableMain), 
        array_merge($launchInfo, $verificationInfo, $verificationResultInfo, $toolsInfo));
    
    // Join launches with related with statistics key tables. Note that traces 
    // is always joined.
    $tableAux = 'traces';
    $joins[$tableAux] = 1;
    foreach (array_keys($joins) as $table) {
	  $select = $select
	    ->joinLeft(array($this->_tableMapper[$table] => $table), 
	      '`' . $this->_tableMapper[$tableMain] . '`.`' . $this->_tableLaunchMapper[$table] . '`=`' . $this->_tableMapper[$table] . '`.`id`'); 
	}

    // Join tools tables.
    foreach (array_keys($tools) as $tool) {	    
	  $tableColumn = $this->getTableColumn($this->_toolsInfoNameTableColumnMapper[$tool]);
	  $tableStat = "$tableColumn[tableShort]_$tool";
	  $select = $select
	    ->joinLeft(array($tableStat => $tableColumn['table']), 
	      '`' . $this->_tableMapper[$tableAux] . '`.`' . $tableColumn['column'] . "`=`$tableStat`.`id`"); 
	}

    // Group by the launch information. 
    foreach ($groupby as $group) {
      $select = $select->group($group);
    }
     
    // Order by the launch information. 
    foreach ($orderby as $order) {
      $select = $select->order($order);
    }

print_r($select->assemble());
#exit;
#->where('pages_id = ?', $profilePagesRow['Id'])
        
    $launchesResultSet = $launches->fetchAll($select);

#    foreach($launchesResultSet as $launchesRow) {  
#      echo  $launchesRow['Rule name'], "  ", $launchesRow['Driver name'], "  ", $launchesRow['Safe'], "  ", $launchesRow['Unsafe'], "  ", $launchesRow['Unknown'], "  ", $launchesRow['RCV Time'], "  ", $launchesRow['RCV Ok']; echo "<br>";
#    }

   
#for problems!!!!!!!!!!!!!!!
/*
SELECT 
  `RU`.`name` AS `Rule`, 
  `DR`.`name` AS `Driver`, 
  PR.name FROM `launches` AS `LA` 
LEFT JOIN `rule_models` AS `RU` ON `LA`.`rule_model_id`=`RU`.`id` 
LEFT JOIN `drivers` AS `DR` ON `LA`.`driver_id`=`DR`.`id` 
LEFT JOIN `traces` AS `TR` ON `LA`.`trace_id`=`TR`.`id` 
LEFT JOIN `stats` as ST1 on TR.rcv_id=ST1.id 
LEFT JOIN problems_stats AS PRST ON ST1.id=PRST.stats_id 
left join problems AS PR on PR.id=PRST.problem_id 
GROUP BY `RU`.`name`, `DR`.`name`, PR.name 
ORDER BY `RU`.`name`, `DR`.`name` ;
*/    
    
exit;    

    // Build the needed SQL queries. First of all prepare the general parts of 
    // all queries.
    $selectGeneral = 'SELECT';
    
    // Also remember the name aliases to select them below.
    $selectAliases = array();
    
    // Select the following columns.
    $columns = array();
    foreach ($page->launchInfo as $info) {
      $tableColumn = $this->_launchInfoNameColumnMapper[$info->launchInfoName];
      $columns[] = $this->select($tableColumn['table'], $tableColumn['column'], $info->launchInfoName);
      $selectAliases[] = $info->launchInfoName;
    }
    foreach ($page->verificationInfo as $info) {
      if ($info->verificationInfoName == 'Result') {
        continue;
      }
      
      $tableColumn = $this->_verificationInfoNameColumnMapper[$info->verificationInfoName];
      $columns[] = $this->select($tableColumn['table'], $tableColumn['column'], $info->verificationInfoName);
      $selectAliases[] = $info->verificationInfoName;
    }
    $selectGeneral .= join(', ', $columns);
    
    // Always select from the general table launches.
    $fromGeneral = $this->from('launches', 'LA');
    
    // Join the needed tables.
    $joinGeneral = '';
    foreach ($page->launchInfo as $info) {
      $tableColumn = $this->_launchInfoNameColumnMapper[$info->launchInfoName];
      $table = $tableColumn['table'];
      $tableShort = $this->_tableMapper[$table];
      
      switch ($table) {
        case 'tasks':
          $cond = '`LA`.`task_id`=`%s`.`id`';          
          break;
        case 'toolsets':
          $cond = '`LA`.`toolset_id`=`%s`.`id`';    
          break;
        case 'drivers':
          $cond = '`LA`.`driver_id`=`%s`.`id`'; 
          break;
        case 'environments':
          $cond = '`LA`.`environment_id`=`%s`.`id`';     
          break;
        case 'rule_models':
          $cond = '`LA`.`rule_model_id`=`%s`.`id`';         
          break;
        case 'scenarios':
          $cond = '`LA`.`scenario_id`=`%s`.`id`';      
          break;
        default:
          throw new Exception("No table corresponds to the lauch info name: $info->launchInfoName");
      }
      
      $cond = sprintf($cond, $tableShort);
      $joinGeneral .= $this->leftJoin($table, $tableShort, $cond);
    }
    // Always join the traces table.
    $tableTraces = 'traces';
    $tableTracesShort = $this->_tableMapper[$tableTraces];
    $joinGeneral .= $this->leftJoin($tableTraces, $tableTracesShort, '`LA`.`trace_id`=`' . $tableTracesShort . '`.`id`');
    
    // Create general where.
    $whereGeneral = ' ';
    
    // Group by the launch info columns.
    $groupByGeneral = ' GROUP BY';
    $groupBys = array();
    foreach ($page->launchInfo as $info) {
      $tableColumn = $this->_launchInfoNameColumnMapper[$info->launchInfoName];
      $groupBys[] = $this->groupBy($this->_tableMapper[$tableColumn['table']], $tableColumn['column']);
    }
    $groupByGeneral .= join(', ', $groupBys);
    
    // Order by the launch info columns.
    $orderByGeneral = ' ORDER BY';
    $orderBys = array();
    foreach ($page->launchInfo as $info) {
      $tableColumn = $this->_launchInfoNameColumnMapper[$info->launchInfoName];
      $orderBys[] = $this->orderBy($this->_tableMapper[$tableColumn['table']], $tableColumn['column']);
    }
    $orderByGeneral .= join(', ', $orderBys);

    // Foreach result create the corresponding temporary table.       
    $temporaryTables = array();
    $temporaryTableNames = array();
    foreach ($page->verificationInfo as $info) {
      if ($info->verificationInfoName == 'Result') {
        foreach ($info->results as $resultInfo) {
		  $select = ', ';
		  $select .= $this->select('traces', 'id', $resultInfo->resultName, true);	
          $where = "WHERE " . $this->where('traces', 'result', $resultInfo->resultName);
          $temporaryTables[] = $this->createTemporaryTable($resultInfo->resultName, 
            $selectGeneral, $fromGeneral, $joinGeneral, $whereGeneral, $groupByGeneral, $orderByGeneral,
            $select, '', '', $where);
          $temporaryTableNames[] = $resultInfo->resultName;
          $selectAliases[] = $resultInfo->resultName;
        }
      }
    }
   
print_r($temporaryTables);
#exit;
    $sql = join('; ', $temporaryTables);
    // Execute the general SQL query. Note that this fails in using different
    // prepare methods so use exec.
    $this->_db->exec($sql);
#print($sql);
#select * from rcv_ok left join rcv_fail using(Toolset, Environment,
#Rule) left join total_safe using(Toolset, Environment, Rule);
#print_r();
    $sql = "SELECT";
    $selectColumns = join(', ', $selectAliases);
    $sql .= " $selectColumns";
    $sql .= $this->from($temporaryTableNames[0]);
    
    $using = array();
    foreach ($page->launchInfo as $info) {
      $using[] = $info->launchInfoName;
    }
    
    for ($i = 1; $i < count($temporaryTableNames); $i++) {
	  $sql .= $this->leftJoinUsing($temporaryTableNames[$i], $using);
	}
    
print_r($sql);
          $stmt = $this->_db->query("select * from Safe");
     $stmt->execute();
      $rows = $stmt->fetchAll();
 print_r($rows);
      foreach ($rows as $row) {
;
   #   echo ($row['Rule'] . "  " . $row['Driver'] . "  " . $row['Safe'] . "  " . $row['Unsafe'] . "  " . $row['Unknown'] . "<br>");  
  } 
exit;
#    $stmt = $this->_db->query($sql . ';');
#    $stmt->execute();
  #  $rows = $stmt->fetchAll();
  #  $rows = $this->_db->fetchAll($sql . ';');
    #$aaa[] = 'drop table if exists D';
    $aaa[] = 'create temporary table D select 1';
    foreach ($aaa as $t) {
      echo $t;#break;
    #  $launches = $this->getDbTable('Application_Model_DbTable_Launches', $this->_db);
    #  $stmt = $this->_db->query($t);
    #  $stmt->execute();
    $res = $this->_db->exec($t);
    print_r($res);
    #  $rows = $stmt->fetchAll();
    #  print_r($rows);
      break;
    }
      $stmt = $this->_db->query("select * from D");
     $stmt->execute();
      $rows = $stmt->fetchAll();
      print_r($rows);   
      echo "aaa";
    $this->_db->closeConnection();
  }
}
