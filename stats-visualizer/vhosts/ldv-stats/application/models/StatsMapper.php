<?php

class Application_Model_StatsMapper extends Application_Model_GeneralMapper
{
  protected $_db;
  protected $_launchInfoNameTableColumnMapper = array(
    'Task id' => array('table' => 'tasks', 'column' => 'id'),
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
    'Time' => array('table' => 'processes', 'column' => 'time_average'),
    'Children time' => array('table' => 'processes', 'column' => 'time_average'),
    'LOC' => array('table' => 'stats', 'column' => 'loc'),
    'Problems' => array('table' => 'problems', 'column' => 'name'));
  protected $_tableMapper = array(
    'drivers' => 'DR',
    'environments' => 'EN',
    'launches' => 'LA',
    'problems' => 'PR',
    'processes' => 'PRO',
    'problems_stats' => 'PRST',
    'rule_models' => 'RU',
    'scenarios' => 'SC',
    'stats' => 'ST',
    'tasks' => 'TA',
    'toolsets' => 'TO',
    'traces' => 'TR');
  protected $_tableLaunchMapper = array(
    'drivers' => 'driver_id',
    'environments' => 'environment_id',
    'rule_models' => 'rule_model_id',
    'scenarios' => 'scenario_id',
    'tasks' => 'task_id',
    'toolsets' => 'toolset_id',
    'traces' => 'trace_id');
  protected $_tableToolMapper = array(
    'build-cmd-extractor' => 'BCE',
    'drv-env-gen' => 'DEG',
    'dscv' => 'DSCV',
    'rule-instrumentor' => 'RI',
    'rcv' => 'RCV');

  public function connectToDb($host, $name, $user, $password = 'no') {
    // Override the profile database connection settings with the specified
    // through the page address ones if so.
    $global = new Zend_Session_Namespace('Statistics globals');

    if ($global->dbName) {
      $name = $global->dbName;
    }
    if ($global->dbUser) {
      $user = $global->dbUser;
    }
    if ($global->dbHost) {
      $host = $global->dbHost;
    }
    if ($global->dbPassword) {
      $password = $global->dbPassword;
    }

    if ($password == 'no') {
      $password = '';
    }

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
#print_r($options);exit;
    $this->_db = new Zend_Db_Adapter_Pdo_Mysql($options);

    return $options;
  }

  public function getTableColumn($tableColumn)
  {
    $table = $tableColumn['table'];
    $tableShort = $this->_tableMapper[$table];
    $column = $tableColumn['column'];
    return array('table' => $table, 'tableShort' => $tableShort, 'column' => $column);
  }

  public function getPageStats($profile, $params)
  {
    // Get information for the specified if so or the default page of a current
    // profile.
    $pageName = 'Index';
    if (array_key_exists('page', $params)) {
      $pageName = $params['page'];
    }

    // Some more information on a given page.
    $value = '';
    if (array_key_exists('value', $params)) {
      $value = $params['value'];
    }

    // Get task ids for the comparison mode.
    $taskids = '';
    if (array_key_exists('task ids', $params)) {
      $taskids = $params['task ids'];
    }

    // Use another page name for the comparison mode.
    if ($taskids != '') {
      $pageNameMode = "$pageName (the comparison mode)";
    }
    else {
      $pageNameMode = $pageName;
    }

    // Here all information to be shown will be written.
    $result = array();

    // Get information on statistics entities to be displayed on the given page.
    $page = $profile->getPage($pageNameMode);
    $result['Page'] = $pageNameMode;

    // Connect to the profile database and remember connection settings.
    $result['Database connection'] = $this->connectToDb($profile->dbHost, $profile->dbName, $profile->dbUser, $profile->dbPassword);

    // Gather all statistics key restrictions if so comming throuth the
    // parameters.
    $statKeysRestrictions = array();
    foreach (array_keys($this->_launchInfoNameTableColumnMapper) as $statKey) {
      if (array_key_exists($statKey, $params)) {
        $statKeysRestrictions[$statKey] = $params[$statKey];
      }
    }

    // Obtain the launch info columns. They will be selected as statistics key,
    // joined and by them groupping by and ordering will be done. Note that they
    // are already ordered.
    $launchInfo = array();
    $launchInfoScreened = array();
    $joins = array();
    $groupBy = array();
    $orderBy = array();

    if (null !== $page->launchInfo) {
      foreach ($page->launchInfo as $info) {
        $name = $info->launchInfoName;
        $tableColumn = $this->getTableColumn($this->_launchInfoNameTableColumnMapper[$name]);
          $launchInfo[$name] = $groupBy[] = $orderBy[] = "$tableColumn[tableShort].$tableColumn[column]";
          $launchInfoScreened[$name] = "`$tableColumn[tableShort]`.`$tableColumn[column]`";
          $joins[$tableColumn['table']] = 1;
      }
    }
    $statsKey = array_keys($launchInfo);

    // Obtain the list of verification info columns. They will be selected. Note
    // that they are already ordered.
    $verificationInfo = array();
    $verificationResultInfo = array();
    $verificationKey = array();
    if (null !== $page->verificationInfo) {
      foreach ($page->verificationInfo as $info) {
        // The 'Result' is just union of 'Safe', 'Unsafe' and 'Unknown' statuses
        // that will be iterated below.
        if ($info->verificationInfoName == 'Result') {
          foreach ($info->results as $resultInfo) {
            $name = $resultInfo->resultName;
            $tableColumnCond = $this->_verificationResultInfoNameTableColumnMapper[$name];
            $tableColumn = $this->getTableColumn($tableColumnCond);
            $verificationResultInfo[$name] = "SUM(IF(`$tableColumn[tableShort]`.`$tableColumn[column]`='$tableColumnCond[cond]', 1, 0))";
            $verificationKey[] = $name;
          }
        }
        else
        {
          $name = $info->verificationInfoName;
          $tableColumn = $this->getTableColumn($this->_verificationInfoNameTableColumnMapper[$name]);
          $verificationInfo[$name] = "$tableColumn[tableShort].$tableColumn[column]";
          $verificationKey[] = $name;
        }
      }
    }

    // Obtain the list of tools info columns.
    $tools = array();
    $toolsInfo = array();
    $isTimeNeeded = false;
    $toolsTime = array();
    if (null !== $page->toolsInfo) {
      foreach ($page->toolsInfo as $info) {
        $toolName = $info->toolsInfoName;
        if (null !== $info->tools) {
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
            else if ($name == 'LOC') {
              $tableColumn = $this->getTableColumn($this->_toolInfoNameTableColumnMapper[$name]);
              $toolsInfo["$toolName $name"] = "SUM(`$tableColumn[tableShort]_$toolName`.`$tableColumn[column]`)";
            }
            else if ($name == 'Time' || $name == 'Children time') {
              $isTimeNeeded = true;
              $toolsTime[$toolName][] = $name;
            }
          }
        }
        $tools[$toolName] = 1;
      }
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

    // For result (safe, unsafe and unknown) pages restrict the selected result
    // both to the corresponding result and to the corresponding launch
    // information key values. In the comparison mode the given restriction is
    // unneeded.
    if ($taskids == '' && ($pageName == 'Safe' || $pageName == 'Unsafe' || $pageName == 'Unknown')) {
      $select = $select
        ->where('`' . $this->_tableMapper[$tableAux] . '`.`result` = ?', $pageName);
    }

    // For tools execution status (ok or fail) and tools problems pages restrict
    // the selected result both to the corresponding result and to the
    // corresponding launch information key values.
    $isToolRestrict = false;
    $tableTool = 'stats';
    foreach (array_keys($this->_toolsInfoNameTableColumnMapper) as $toolName) {
      if (preg_match("/$toolName/", $pageName)) {
        $toolNameInfo = preg_split('/ /', $pageName);

        // Ok corresponds to the true. Fail corresponds to the false.
        $status = 1;
        if ($toolNameInfo[1] == 'Fail' || $toolNameInfo[1] == 'Problems') {
          $status = 0;
        }

        $select = $select
          ->where('`' . $this->_tableMapper[$tableTool] . '_' . $toolNameInfo[0] . '`.`success` = ?', $status);
        $isToolRestrict = true;
        break;
      }
    }

    if ($pageName == 'Safe' || $pageName == 'Unsafe' || $pageName == 'Unknown' || $isToolRestrict) {
      foreach ($statKeysRestrictions as $statKey => $statKeyValue) {
        if ($statKeyValue == '__EMPTY') {
          $statKeyValue = '';
        }

        if ($statKeyValue == '__NULL') {
          $select = $select
            ->where("$launchInfoScreened[$statKey] IS NULL");
        }
        else
        {
          // In the task comparison mode restrict task ids to the corresponding
          // set.
          if ($taskids != '' && $statKey == 'Task id') {
            $select = $select
              ->where("$launchInfoScreened[$statKey] IN ($statKeyValue, $taskids)");
          }
          // Ignore other task attribute restrictions in the task comparison
          // mode. In the noncomparison mode just restrict a given statistics
          // key with the corresponding value.
          else if (($taskids != '' && !preg_match('/^Task/', $statKey)) || $taskids == '') {
            $select = $select
              ->where("$launchInfoScreened[$statKey] = ?", $statKeyValue);
          }
        }
      }
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

    $launchesResultSet = $launches->fetchAll($select);

#    foreach($launchesResultSet as $launchesRow) {
#      echo  "<br>", $launchesRow['Rule name'], "  ", $launchesRow['Driver name'], "  ", $launchesRow['Entry point'], "  ", $launchesRow['Safe'], "  ", $launchesRow['Unsafe'], "  ", $launchesRow['Unknown'], "  ", $launchesRow['RCV Time'], "  ", $launchesRow['RCV Ok'];
#    }

    // Foreach specified tool collect its problems.
    $toolProblems = array();
    if (null !== $page->toolsInfo) {
      foreach ($page->toolsInfo as $info) {
        $toolName = $info->toolsInfoName;
        if (null !== $info->tools) {
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
                    array_merge($launchInfo, array(
                      "$toolName Problems" => $problemsColumn,
                      "$toolName Problems number" => 'COUNT(*)')));

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

              // For tools problems pages restrict the selected result both to
              // the corresponding problem name.
              foreach (array_keys($this->_toolsInfoNameTableColumnMapper) as $toolNameForRestrict) {
                if (preg_match("/$toolNameForRestrict/", $pageName)) {
                  $toolNameProblems = preg_split('/ /', $pageName);
                  $select = $select
                    ->where('`' . $this->_tableMapper[$tableProblems] . '`.`name` = ?', $value);
                  break;
                }
              }

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
                $statsValues = array();
                foreach ($statsKey as $statsKeyPart) {
                  $statsValues[] = $launchesProblemsRow[$statsKeyPart];
                }
                $statsValuesStr = join(';', $statsValues);

                $toolProblems["$toolName Problems"][$statsValuesStr][] = array('Problem name' => $launchesProblemsRow["$toolName Problems"], 'Problem number' => $launchesProblemsRow["$toolName Problems number"]);
              }
            }
          }
        }
      }
    }

    // Collect information on a tools and their children execution time.
    $toolsTimes = array();
    if ($isTimeNeeded) {
      $select = $launches
        ->select()->setIntegrityCheck(false);
      // Tool time and tool children time have the same table-column.
      $name = 'Time';

      $timeTableColumn = $this->getTableColumn($this->_toolInfoNameTableColumnMapper[$name]);
      $timeGroupBy = $groupBy;
      $timeGroupBy[] = "$timeTableColumn[tableShort].name";
      $timeGroupBy[] = "$timeTableColumn[tableShort].pattern";
      $timeOrderBy = $orderBy;
      $timeOrderBy[] = "$timeTableColumn[tableShort].name";
      $timeOrderBy[] = "$timeTableColumn[tableShort].pattern";

      $select = $select
        ->from(array($this->_tableMapper[$tableMain] => $tableMain),
          array_merge($launchInfo, array(
            'Tool name' => "$timeTableColumn[tableShort].name",
            'Process pattern' => "$timeTableColumn[tableShort].pattern",
            "$name Average" => "SUM(`$timeTableColumn[tableShort]`.`$timeTableColumn[column]`)")));

      // Join launches with related with statistics key tables. Note that
      // traces is always joined.
      foreach (array_keys($joins) as $table) {
      $select = $select
        ->joinLeft(array($this->_tableMapper[$table] => $table),
          '`' . $this->_tableMapper[$tableMain] . '`.`' . $this->_tableLaunchMapper[$table] . '`=`' . $this->_tableMapper[$table] . '`.`id`');
      }

      // Join time table.
      $select = $select
        ->joinLeft(array($timeTableColumn['tableShort'] => $timeTableColumn['table']),
          '`' . $this->_tableMapper[$tableAux] . "`.`id`=`$timeTableColumn[tableShort]`.`trace_id`");

      // Laucnhes without time mustn't be taken into consideration.'
      $select = $select->where("`$timeTableColumn[tableShort]`.`trace_id` IS NOT NULL");

      // Group by the launch information.
      foreach ($timeGroupBy as $group) {
        $select = $select->group($group);
      }

      // Order by the launch information.
      foreach ($timeOrderBy as $order) {
        $select = $select->order($order);
      }

#print_r($select->assemble());
#exit;

      $launchesTimeResultSet= $launches->fetchAll($select);

      $patternItself = '__ITSELF';
      foreach ($launchesTimeResultSet as $launchesTimeRow) {
        $statsValues = array();
        foreach ($statsKey as $statsKeyPart) {
          $statsValues[] = $launchesTimeRow[$statsKeyPart];
        }
        $statsValuesStr = join(';', $statsValues);
        $timeToolName = $this->_tableToolMapper[$launchesTimeRow['Tool name']];

        // Understand what time is needed.
        foreach ($toolsTime as $toolName => $toolTime) {
          // Get time just for a given tool.
          if ($timeToolName == $toolName) {
            // Save time just for specified kinds (either tool itself or its
            // children) in depend on a given pattern ('ALL' and !'ALL'
            // correspondingly).
            foreach ($toolTime as $toolTimeKind) {
              $pattern = $launchesTimeRow['Process pattern'];
              if ($toolTimeKind == 'Time' && $pattern == 'ALL') {
                $toolsTimes["$toolName Time"][$statsValuesStr][$patternItself]['Time'] = $launchesTimeRow['Time Average'];
              }
              else if ($toolTimeKind == 'Children time' && $pattern != 'ALL') {
                $toolsTimes["$toolName Time"][$statsValuesStr][$pattern][] = array('Time' => $launchesTimeRow['Time Average']);
              }
            }
          }
        }
      }
#print_r($toolsTimes);
#exit;
    }

    // Merge launch, verification and problems information.
    $toolsKey = array_keys($toolsInfo);
    // Remember all tool names.
    $result['Stats']['All tool names'] = array();
    // Collect all set of problems for a given tool that will be used in
    // visualization.
    $result['Stats']['All tool problems'] = array();
    // Collect all set of children for a given tool that will be used in
    // visualization.
    $result['Stats']['All tool children'] = array();
    // Remember what tool has a time.
    $result['Stats']['All tool time'] = array();
    // Here the data will be placed.
    $result['Stats']['Row info'] = array();

    foreach ($launchesResultSet as $launchesRow) {
      $resultPart = array();
      $statsValues = array();

      $resultPart['Stats key'] = array();
      foreach ($statsKey as $statsKeyPart) {
        $resultPart['Stats key'][$statsKeyPart] = $launchesRow[$statsKeyPart];
        $statsValues[] = $launchesRow[$statsKeyPart];
      }
      $statsValuesStr = join(';', $statsValues);

      $resultPart['Verification info'] = array();
      foreach ($verificationKey as $verificationKeyPart) {
        $resultPart['Verification info'][$verificationKeyPart] = $launchesRow[$verificationKeyPart];
      }

      $resultPart['Tools info'] = array();
      foreach ($toolsKey as $toolsKeyPart) {
        $resultPart['Tools info'][$toolsKeyPart] = $launchesRow[$toolsKeyPart];
        $toolNameInfo = preg_split('/ /', $toolsKeyPart);
        $result['Stats']['All tool names'][$toolNameInfo[0]] = 1;
      }

      $resultPart['Tool problems'] = array();
      foreach ($toolProblems as $toolProblemsName => $toolProblemsKey) {
        if (array_key_exists($statsValuesStr, $toolProblemsKey)) {
          $problems = $toolProblemsKey[$statsValuesStr];
          $resultPart['Tool problems'][$toolProblemsName] = $problems;
          foreach ($problems as $problem) {
            $result['Stats']['All tool problems'][$toolProblemsName][$problem['Problem name']] = 1;
          }
          $toolNameProblems = preg_split('/ /', $toolProblemsName);
          $result['Stats']['All tool names'][$toolNameProblems[0]] = 1;
        }
      }

      $resultPart['Tool time'] = array();
      $resultPart['Tool children time'] = array();
      foreach ($toolsTimes as $toolsTimesName => $toolsTimesKey) {
        $toolNameTime = preg_split('/ /', $toolsTimesName);
        if (array_key_exists($statsValuesStr, $toolsTimesKey)) {
          $times = $toolsTimesKey[$statsValuesStr];
          foreach ($times as $pattern => $time) {
            if ($pattern == $patternItself) {
              $resultPart['Tool time'][$toolsTimesName] = $time;
              $result['Stats']['All tool time'][$toolNameTime[0]] = 1;
            }
            else {
              $resultPart['Tool children time'][$toolsTimesName][$pattern] = $time[0];
            }
          }
          foreach (array_keys($times) as $pattern) {
            if ($pattern != $patternItself) {
              $result['Stats']['All tool children'][$toolsTimesName][$pattern] = 1;
            }
          }
          $result['Stats']['All tool names'][$toolNameTime[0]] = 1;
        }
      }

      $result['Stats']['Row info'][] = $resultPart;
    }

#foreach ($result as $res) {
#  echo "<br>";print_r($res);
#}
#exit;
    return $result;
  }
}
