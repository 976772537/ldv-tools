<?php

class Application_Model_StatsMapper extends Application_Model_GeneralMapper
{
  protected $_db;
  protected $_launchInfoNameTableColumnMapper = array(
    'Task name' => array('table' => 'tasks', 'column' => 'name'),
    'Task description' => array('table' => 'tasks', 'column' => 'description'),
    'Task user name' => array('table' => 'tasks', 'column' => 'username'),
    'Task timestamp' => array('table' => 'tasks', 'column' => 'timestamp'),
    'Toolset version' => array('table' => 'toolsets', 'column' => 'version'),
    'Toolset verifier' => array('table' => 'toolsets', 'column' => 'verifier'),
    'Driver name' => array('table' => 'drivers', 'column' => 'name'),
    'Driver origin' => array('table' => 'drivers', 'column' => 'origin'),
    'Environment version' => array('table' => 'environments', 'column' => 'version'),
    'Environment kind' => array('table' => 'environments', 'column' => 'kind'),
    'Rule name' => array('table' => 'rule_models', 'column' => 'name'),
    'Module' => array('table' => 'scenarios', 'column' => 'executable'),
    'Entry point' => array('table' => 'scenarios', 'column' => 'main'));
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
    'LOC' => array('table' => 'stats', 'column' => 'loc'),
    'Problems' => array('table' => 'problems', 'column' => 'name'));
  protected $_tableMapper = array(
    'drivers' => 'DR',
    'environments' => 'EN',
    'launches' => 'LA',
    'problems' => 'PR',
    'problems_stats' => 'PRST',
    'rule_models' => 'RU',
    'scenarios' => 'SC',
    'stats' => 'ST',
    'tasks' => 'TA',
    'traces' => 'TR');
  protected $_tableLaunchMapper = array(
    'drivers' => 'driver_id',
    'environments' => 'environment_id',
    'rule_models' => 'rule_model_id',
    'scenarios' => 'scenario_id',
    'tasks' => 'task_id',
    'toolsets' => 'toolset_id',
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

  public function getPageStats($profile, $pageName)
  {
    $page = $profile->getPage($pageName);
    $this->connectToDb($profile->dbHost, $profile->dbName, $profile->dbUser, $profile->dbPassword);

    // Obtain the launch info columns. They will be selected as statistics key,
    // joined and by them groupping by and ordering will be done. Note that they
    // are already ordered.
    $launchInfo = array();
    $joins = array();
    $groupBy = array();
    $orderBy = array();
    foreach ($page->launchInfo as $info) {
    $name = $info->launchInfoName;
    $tableColumn = $this->getTableColumn($this->_launchInfoNameTableColumnMapper[$name]);
      $launchInfo[$name] = $groupBy[] = $orderBy[] = "$tableColumn[tableShort].$tableColumn[column]";
      $joins[$tableColumn['table']] = 1;
    }
    $statsKey = array_keys($launchInfo);

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
        else if ($name == 'Time' || $name == 'LOC') {
          $tableColumn = $this->getTableColumn($this->_toolInfoNameTableColumnMapper[$name]);
          $toolsInfo["$toolName $name"] = "SUM(`$tableColumn[tableShort]_$toolName`.`$tableColumn[column]`)";
        }
      }
      $tools[$toolName] = 1;
    }

    $launches = $this->getDbTable('Application_Model_DbTable_Launches', $this->_db);

    // Prepare query to the statistics database to collect launch and
    // verification info.
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
    foreach ($groupBy as $group) {
      $select = $select->group($group);
    }

    // Order by the launch information.
    foreach ($orderBy as $order) {
      $select = $select->order($order);
    }

#print_r($select->assemble());
#exit;
#->where('pages_id = ?', $profilePagesRow['Id'])

    $launchesResultSet = $launches->fetchAll($select);

#    foreach($launchesResultSet as $launchesRow) {
#      echo  "<br>", $launchesRow['Rule name'], "  ", $launchesRow['Driver name'], "  ", $launchesRow['Entry point'], "  ", $launchesRow['Safe'], "  ", $launchesRow['Unsafe'], "  ", $launchesRow['Unknown'], "  ", $launchesRow['RCV Time'], "  ", $launchesRow['RCV Ok'];
#    }

    // Foreach specified tool collect its problems.
    $toolProblems = array();
    foreach ($page->toolsInfo as $info) {
      $toolName = $info->toolsInfoName;
      foreach ($info->tools as $toolInfo) {
        $name = $toolInfo->toolName;
        if ($name == 'Problems') {
          $select = $launches
            ->select()->setIntegrityCheck(false);

          $problemsTableColumn = $this->getTableColumn($this->_toolInfoNameTableColumnMapper[$name]);
          $problemsColumn = "$problemsTableColumn[tableShort].$problemsTableColumn[column]";
          $problemsGroupBy = $groupBy;
          $problemsGroupBy[] = $problemsColumn;

          $select = $select
            ->from(array($this->_tableMapper[$tableMain] => $tableMain),
                array_merge($launchInfo, array("$toolName Problems" => $problemsColumn)));

          // Join launches with related with statistics key tables. Note that
          // traces is always joined.
          foreach (array_keys($joins) as $table) {
          $select = $select
            ->joinLeft(array($this->_tableMapper[$table] => $table),
              '`' . $this->_tableMapper[$tableMain] . '`.`' . $this->_tableLaunchMapper[$table] . '`=`' . $this->_tableMapper[$table] . '`.`id`');
          }

          // Join tool table.
          $tableColumn = $this->getTableColumn($this->_toolsInfoNameTableColumnMapper[$toolName]);
          $tableStat = "$tableColumn[tableShort]_$toolName";
          $select = $select
            ->joinLeft(array($tableStat => $tableColumn['table']),
              '`' . $this->_tableMapper[$tableAux] . '`.`' . $tableColumn['column'] . "`=`$tableStat`.`id`");

          // Join problems tool relating table.
          $tableStatProblems = 'problems_stats';
          $select = $select
            ->joinLeft(array($this->_tableMapper[$tableStatProblems] => $tableStatProblems),
              '`' . $this->_tableMapper[$tableStatProblems] . "`.`stats_id`=`$tableStat`.`id`");


          // Join problems table.
          $tableProblems = 'problems';
          $select = $select
            ->joinLeft(array($this->_tableMapper[$tableProblems] => $tableProblems),
              '`' . $this->_tableMapper[$tableStatProblems] . '`.`problem_id`=`' . $this->_tableMapper[$tableProblems] . '`.`id`');

          // Laucnhes without problems mustn't be taken into consideration.'
          $select = $select->where("`$problemsTableColumn[tableShort]`.`id` IS NOT NULL");

          // Group by the launch information.
          foreach ($problemsGroupBy as $group) {
            $select = $select->group($group);
          }

          // Order by the launch information.
          foreach ($orderBy as $order) {
            $select = $select->order($order);
          }

#print_r($select->assemble());
#exit;

          $launchesProblemsResultSet= $launches->fetchAll($select);

          foreach ($launchesProblemsResultSet as $launchesProblemsRow) {
#echo  "<br>", $launchesProblemsRow['Rule name'], "  ", $launchesProblemsRow['Driver name'], "  ", $launchesProblemsRow['Entry point'], "  ", $launchesProblemsRow["$toolName Problems"];
            $statsValues = array();
            foreach ($statsKey as $statsKeyPart) {
              $statsValues[] = $launchesProblemsRow[$statsKeyPart];
            }
            $statsValuesStr = join(';', $statsValues);
            $toolProblems["$toolName Problems"][$statsValuesStr][] = $launchesProblemsRow["$toolName Problems"];
          }
        }
      }
    }
#echo "<br><br>";
    // Merge launch, verification and problems information.
    $result = array();
    $verificationKey = array_merge(array_keys($verificationInfo), array_keys($verificationResultInfo));
    $toolsKey = array_keys($toolsInfo);

    foreach ($launchesResultSet as $launchesRow) {
      $resultPart = array();
      $statsValues = array();

      foreach ($statsKey as $statsKeyPart) {
        $resultPart['Stats key'][$statsKeyPart] = $launchesRow[$statsKeyPart];
        $statsValues[] = $launchesRow[$statsKeyPart];
      }

      $statsValuesStr = join(';', $statsValues);

      foreach ($verificationKey as $verificationKeyPart) {
        $resultPart['Verification info'][$verificationKeyPart] = $launchesRow[$verificationKeyPart];
      }

      foreach ($toolsKey as $toolsKeyPart) {
        $resultPart['Tools info'][$toolsKeyPart] = $launchesRow[$toolsKeyPart];
      }

      foreach ($toolProblems as $toolProblemsName => $toolProblemsKey) {
        if (array_key_exists($statsValuesStr, $toolProblemsKey)) {
          $resultPart['Tools problems'][$toolProblemsName] = $toolProblemsKey[$statsValuesStr];
        }
      }

      $result[] = $resultPart;
    }

#    foreach ($result as $res) {
#      echo "<br>";print_r($res);
#    }

    return $result;
  }
}
