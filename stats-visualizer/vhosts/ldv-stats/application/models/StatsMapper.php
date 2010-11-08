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
    'Result' => array('table' => 'traces', 'column' => 'id'),
    // Verdict is similar to result except it's a result name nor a result itself..
    'Verdict' => array('table' => 'traces', 'column' => 'result'),
    // Don't load huge error traces. Just select their ids.
    'Error trace' => array('table' => 'traces', 'column' => 'id'));
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
    'In' => array('table' => 'stats', 'column' => 'id'),
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

  public function connectToDb($host, $name, $user, $password = 'no', $params = array()) {
    // Override the profile database connection settings with the specified
    // through the page address ones if so.
    if (array_key_exists('name', $params)) {
      $name = $params['name'];
    }
    if (array_key_exists('user', $params)) {
      $user = $params['user'];
    }
    if (array_key_exists('host', $params)) {
      $host = $params['host'];
    }
    if (array_key_exists('password', $params)) {
      $password = $params['password'];
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

  public function getPageStats($profile, $params = array())
  {
    // Get information for the specified if so or the default page of a current
    // profile.
    $pageName = 'Index';
    if (array_key_exists('page', $params)) {
      $pageName = $params['page'];
    }

    // Get a tool name and its feature if so are presented in a page name.
    $toolNameFeature = preg_split('/ /', $pageName);

    // Some more information on a given page.
    $value = '';
    if (array_key_exists('value', $params)) {
      $value = $params['value'];
    }

    // Obtain task names from parameters.
    $tasks = array();
    for ($i = 1; array_key_exists("task$i", $params) and ($tasks[] = $params["task$i"]); $i++) {
      ;
    }
    $isTaskNameNeeded = count($tasks) ? true : false;

    // Here all information to be shown will be written.
    $result = array();

    // In general there is no restriction at all.
    $result['Restrictions'] = array();

    // Get information on statistics entities to be displayed on the given page.
    $page = $profile->getPage($pageName);
    $result['Page'] = $pageName;

    // Connect to the profile database and remember connection settings.
    $result['Database connection'] = $this->connectToDb($profile->dbHost, $profile->dbName, $profile->dbUser, $profile->dbPassword, $params);

    // Gather all statistics key restrictions if so comming through the
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

        if ($name == 'Task name') {
          $isTaskNameNeeded = false;
        }
      }
    }
    if ($isTaskNameNeeded) {
      $name = 'Task name';
      $tableColumn = $this->getTableColumn($this->_launchInfoNameTableColumnMapper[$name]);
      $launchInfo[$name] = $groupBy[] = $orderBy[] = "$tableColumn[tableShort].$tableColumn[column]";
      $launchInfoScreened[$name] = "`$tableColumn[tableShort]`.`$tableColumn[column]`";
      $joins[$tableColumn['table']] = 1;
    }
    $statsKey = array_keys($launchInfo);

    // Obtain the list of verification info columns. They will be selected. Note
    // that they are already ordered.
    $verificationInfo = array();
    $verificationResultInfo = array();
    $verificationKey = array();
    if (null !== $page->verificationInfo) {
      foreach ($page->verificationInfo as $info) {
        $name = $info->verificationInfoName;
        $tableColumn = $this->getTableColumn($this->_verificationInfoNameTableColumnMapper[$name]);
        $verificationInfo[$name] = "$tableColumn[tableShort].$tableColumn[column]";

        // For 'Result' count the total number of grouped launches.
        if ($name == 'Result') {
          $verificationInfo[$name] = "COUNT($verificationInfo[$name])";
        }

        $verificationKey[] = $name;

        // The 'Result' is just union of 'Safe', 'Unsafe' and 'Unknown' statuses
        // that will be iterated below.
        if ($name == 'Result') {
          foreach ($info->results as $resultInfo) {
            $nameResult = $resultInfo->resultName;
            $tableColumnCond = $this->_verificationResultInfoNameTableColumnMapper[$nameResult];
            $tableColumn = $this->getTableColumn($tableColumnCond);
            $verificationResultInfo[$nameResult] = "SUM(IF(`$tableColumn[tableShort]`.`$tableColumn[column]`='$tableColumnCond[cond]', 1, 0))";
            $verificationKey[] = $nameResult;
          }
        }

        // For error trace additionally specify wether error trace is presented.
        if ($name == 'Error trace') {
            $nameAux = 'Error trace presence';
            $verificationInfo[$nameAux] = "IF(`$tableColumn[tableShort]`.`error_trace` IS NULL, 0, 1)";
            $verificationKey[] = $nameAux;
        }
      }
    }
#print_r($verificationInfo);exit;
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
              // For 'Ok' and 'Fail' automatically count the total number of
              // tool inputs.
              $tool_in = 'In';
              if (!array_key_exists("$toolName $tool_in", $toolsInfo)) {
                $tableColumnCond = $this->_toolInfoNameTableColumnMapper[$tool_in];
                $tableColumn = $this->getTableColumn($tableColumnCond);
                $toolsInfo["$toolName $tool_in"] = "COUNT(`$tableColumn[tableShort]_$toolName`.`$tableColumn[column]`)";
              }

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
      ->joinLeft(array($this->_tableMapper[$table] => $table)
        , '`' . $this->_tableMapper[$tableMain] . '`.`' . $this->_tableLaunchMapper[$table] . '`=`' . $this->_tableMapper[$table] . '`.`id`'
        , array());
    }

    // Join tools tables.
    foreach (array_keys($tools) as $tool) {
      $tableColumn = $this->getTableColumn($this->_toolsInfoNameTableColumnMapper[$tool]);
      $tableStat = "$tableColumn[tableShort]_$tool";
      $select = $select
        ->joinLeft(array($tableStat => $tableColumn['table'])
          , '`' . $this->_tableMapper[$tableAux] . '`.`' . $tableColumn['column'] . "`=`$tableStat`.`id`"
          , array());
    }

    // For result (safe, unsafe and unknown) pages restrict the selected result
    // both to the corresponding result and to the corresponding launch
    // information key values.
    if ($pageName == 'Safe' || $pageName == 'Unsafe' || $pageName == 'Unknown') {
      $select = $select
        ->where('`' . $this->_tableMapper[$tableAux] . '`.`result` = ?', $pageName);
      $result['Restrictions']['Result'] = $pageName;
    }

    // For tools execution status (ok or fail) and tools problems pages restrict
    // the selected result both to the corresponding result and to the
    // corresponding launch information key values.
    $isToolRestrict = false;
    $tableTool = 'stats';
    foreach (array_keys($this->_toolsInfoNameTableColumnMapper) as $toolName) {
      if (preg_match("/$toolName/", $pageName)) {
        // Statistics key values must be restricted for a given tool.
        $isToolRestrict = true;

        $toolNameInfo = preg_split('/ /', $pageName);
        // Inputs don't require the given restriction.
        if ($toolNameInfo[1] == 'In') {
          break;
        }

        // Ok corresponds to the true. Fail corresponds to the false.
        $status = 1;
        if ($toolNameInfo[1] == 'Fail' || $toolNameInfo[1] == 'Problems') {
          $status = 0;
        }

        $select = $select
          ->where('`' . $this->_tableMapper[$tableTool] . '_' . $toolNameInfo[0] . '`.`success` = ?', $status);
        $result['Restrictions']['Status'] = $status == 0 ? 'Fail' : 'Ok';

        break;
      }
    }

    if ($pageName == 'Launches' || $pageName == 'Result' || $pageName == 'Safe' || $pageName == 'Unsafe' || $pageName == 'Unknown' || $isToolRestrict) {
      foreach ($statKeysRestrictions as $statKey => $statKeyValue) {
        // A given page may not contain a given key at all.
        if (!array_key_exists($statKey, $launchInfoScreened)) {
          continue;
        }

        if ($statKeyValue == '__EMPTY') {
          $statKeyValue = '';
        }

        if ($statKeyValue == '__NULL') {
          $select = $select
            ->where("$launchInfoScreened[$statKey] IS NULL");
          $result['Restrictions'][$statKey] = 'NULL';
        }
        else {
          $select = $select
            ->where("$launchInfoScreened[$statKey] = ?", $statKeyValue);
          $result['Restrictions'][$statKey] = $statKeyValue;
        }
      }
    }

    // Restrict to the necessary task names.
    if (count($tasks)) {
      $select = $select
        ->where($launchInfoScreened['Task name'] . " IN ('" . join("','", $tasks) . "')");
    }

    // Group by the launch information.
    foreach ($groupBy as $group) {
      $select = $select->group($group);
    }

    // Order by the launch information.
    foreach ($orderBy as $order) {
      $select = $select->order($order);
    }

#print_r($select->assemble());exit;

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
                ->joinLeft(array($this->_tableMapper[$table] => $table)
                  , '`' . $this->_tableMapper[$tableMain] . '`.`' . $this->_tableLaunchMapper[$table] . '`=`' . $this->_tableMapper[$table] . '`.`id`'
                  , array());
              }

              // Join tool table.
              $tableColumn = $this->getTableColumn($this->_toolsInfoNameTableColumnMapper[$toolName]);
              $tableStat = "$tableColumn[tableShort]_$toolName";
              $select = $select
                ->joinLeft(array($tableStat => $tableColumn['table'])
                  , '`' . $this->_tableMapper[$tableAux] . '`.`' . $tableColumn['column'] . "`=`$tableStat`.`id`"
                  , array());

              // Join problems tool relating table.
              $tableStatProblems = 'problems_stats';
              $select = $select
                ->joinLeft(array($this->_tableMapper[$tableStatProblems] => $tableStatProblems)
                  , '`' . $this->_tableMapper[$tableStatProblems] . "`.`stats_id`=`$tableStat`.`id`"
                  , array());


              // Join problems table.
              $tableProblems = 'problems';
              $select = $select
                ->joinLeft(array($this->_tableMapper[$tableProblems] => $tableProblems)
                  , '`' . $this->_tableMapper[$tableStatProblems] . '`.`problem_id`=`' . $this->_tableMapper[$tableProblems] . '`.`id`'
                  , array());

              // Consider just laucnhes that finished badly (either with
              // problems or without).
              $select = $select->where("`$tableStat`.`success` = FALSE");

              // For tools problems pages restrict the selected result both to
              // the corresponding problem name.
              foreach (array_keys($this->_toolsInfoNameTableColumnMapper) as $toolNameForRestrict) {
                if (preg_match("/$toolNameForRestrict/", $pageName)) {
                  $toolNameProblems = preg_split('/ /', $pageName);
                  if ($value == 'Unmatched') {
                    $select = $select
                      ->where('`' . $this->_tableMapper[$tableProblems] . '`.`name` IS NULL');
                  }
                  else {
                    $select = $select
                      ->where('`' . $this->_tableMapper[$tableProblems] . '`.`name` = ?', $value);
                  }
                  $result['Restrictions']['Problem name'] = $value;
                  break;
                }
              }

              if ($pageName == 'Launches' || $pageName == 'Result' || $pageName == 'Safe' || $pageName == 'Unsafe' || $pageName == 'Unknown' || $isToolRestrict) {
                foreach ($statKeysRestrictions as $statKey => $statKeyValue) {
                  // A given page may not contain a given key at all.
                  if (!array_key_exists($statKey, $launchInfoScreened)) {
                    continue;
                  }

                  if ($statKeyValue == '__EMPTY') {
                    $statKeyValue = '';
                  }

                  if ($statKeyValue == '__NULL') {
                    $select = $select
                      ->where("$launchInfoScreened[$statKey] IS NULL");
                  }
                  else {
                    $select = $select
                      ->where("$launchInfoScreened[$statKey] = ?", $statKeyValue);
                  }
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

                $problemName = $launchesProblemsRow["$toolName Problems"];
                // Use special class fot the unmatched problems.
                if (null == $problemName) {
                  $problemName = 'Unmatched';
                }

                $toolProblems["$toolName Problems"][$statsValuesStr][] = array('Problem name' => $problemName, 'Problem number' => $launchesProblemsRow["$toolName Problems number"]);
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
        ->joinLeft(array($this->_tableMapper[$table] => $table)
          , '`' . $this->_tableMapper[$tableMain] . '`.`' . $this->_tableLaunchMapper[$table] . '`=`' . $this->_tableMapper[$table] . '`.`id`'
          , array());
      }

      // Join time table.
      $select = $select
        ->joinLeft(array($timeTableColumn['tableShort'] => $timeTableColumn['table'])
          , '`' . $this->_tableMapper[$tableAux] . "`.`id`=`$timeTableColumn[tableShort]`.`trace_id`"
          , array());

      // Laucnhes without time mustn't be taken into consideration.'
      $select = $select->where("`$timeTableColumn[tableShort]`.`trace_id` IS NOT NULL");

      if ($pageName == 'Launches' || $pageName == 'Result' || $pageName == 'Safe' || $pageName == 'Unsafe' || $pageName == 'Unknown' || $isToolRestrict) {
        foreach ($statKeysRestrictions as $statKey => $statKeyValue) {
          // A given page may not contain a given key at all.
          if (!array_key_exists($statKey, $launchInfoScreened)) {
            continue;
          }

          if ($statKeyValue == '__EMPTY') {
            $statKeyValue = '';
          }

          if ($statKeyValue == '__NULL') {
            $select = $select
              ->where("$launchInfoScreened[$statKey] IS NULL");
          }
          else {
            $select = $select
              ->where("$launchInfoScreened[$statKey] = ?", $statKeyValue);
          }
        }
      }

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
    // Collect the whole launches statisitc.
    $result['Stats'] = array();
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
#print_r($launchesRow);exit;
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

      // Don't consider rows that doesn't have'a certain problem if problems
      // must be shown.
      if (array_key_exists(1, $toolNameFeature)
        && $toolNameFeature[1] == 'Problems'
        && !count($resultPart['Tool problems'])) {
        continue;
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

  public function getErrorTrace($profile, $params) {
    if (array_key_exists('page', $params)) {
      $pageName = $params['page'];
    }
    else {
      throw new Exception('Page name is not specified');
    }

    // Get a corresponding trace id.
    if (array_key_exists('value', $params)) {
      $trace_id = $params['value'];
    }
    else {
      throw new Exception('Trace id is not specified');
    }

    // Connect to the profile database and remember connection settings.
    $result['Database connection'] = $this->connectToDb($profile->dbHost, $profile->dbName, $profile->dbUser, $profile->dbPassword, $params);

    $traces = $this->getDbTable('Application_Model_DbTable_Traces', $this->_db);

    // Prepare query to the statistics database to obtrain a error trace.
    $select = $traces
      ->select()->setIntegrityCheck(false);

    // Get data from the traces table.
    $tableMain = 'traces';
    $select = $select
      ->from($tableMain,
        array($pageName => "$tableMain.error_trace", 'Engine' => "$tableMain.verifier"));
    $select = $select
      ->where("$tableMain.id = ?", $trace_id);

#print_r($select->assemble());
#exit;

    $errorTraceRow = $traces->fetchRow($select);
    $errorTrace = new Application_Model_ErrorTrace(array('errorTraceRaw' => $errorTraceRow[$pageName], 'engine' => $errorTraceRow['Engine']));

    $sources = $this->getDbTable('Application_Model_DbTable_Sources', $this->_db);

    // Prepare query to the statistics database to obtrain source code files
    // corresponding to a given error trace.
    $select = $sources
      ->select()->setIntegrityCheck(false);

    // Get data from the sources table.
    $tableMain = 'sources';
    $select = $select
      ->from($tableMain,
        array('File name' => "$tableMain.name", 'Source code' => "$tableMain.contents"));
    $select = $select
      ->where("$tableMain.trace_id = ?", $trace_id);

#print_r($select->assemble());
#exit;

    $sourcesResultSet= $sources->fetchAll($select);

    // Store source code files in array where keys are file names and values are
    // source code itself.
    $sourceCodeFiles = array();
    foreach ($sourcesResultSet as $sourcesRow) {
      $sourceCodeFiles[$sourcesRow['File name']] = $sourcesRow['Source code'];
    }

    $errorTrace = $errorTrace->setOptions(array('errorTraceRaw' => $errorTraceRow[$pageName], 'sourceCodeFiles' => $sourceCodeFiles));

    $result['Error trace'] = $errorTrace;

    // Gather all statistics key restrictions comming through the parameters.
    // For error trace they are always presented.
    foreach (array_keys($this->_launchInfoNameTableColumnMapper) as $statKey) {
      if (array_key_exists($statKey, $params)) {
        $result['Restrictions'][$statKey] = $params[$statKey];
      }
    }

    return $result;
  }

  public function getComparisonStats($profile, $params)
  {
    $pageName = 'Index (comparison mode)';

    // Get task ids for the comparison mode.
    if (array_key_exists('task ids', $params)) {
      $taskIdsStr = $params['task ids'];
    }
    else {
      throw new Exception('Task ids are not specified');
    }
    $taskIds = preg_split('/[, ]/', $taskIdsStr);

    // Here all information to be shown will be written.
    $result = array();

    // Get information on statistics entities to be displayed on the given page.
    $page = $profile->getPage($pageName);
    $result['Page'] = $pageName;

    // Connect to the profile database and remember connection settings.
    $result['Database connection'] = $this->connectToDb($profile->dbHost, $profile->dbName, $profile->dbUser, $profile->dbPassword, $params);

    // Obtain the launch info columns. They will be selected as statistics key,
    // joined and by them and ordering will be done. Note that they are already
    // ordered.
    $launchInfo = array();
    $launchInfoScreened = array();
    $joins = array();
    $orderBy = array();

    if (null !== $page->launchInfo) {
      foreach ($page->launchInfo as $info) {
        $name = $info->launchInfoName;
        $tableColumn = $this->getTableColumn($this->_launchInfoNameTableColumnMapper[$name]);
        $launchInfo[$name] = $orderBy[] = "$tableColumn[tableShort].$tableColumn[column]";
        $launchInfoScreened[$name] = "`$tableColumn[tableShort]`.`$tableColumn[column]`";
        $joins[$tableColumn['table']] = 1;
      }
    }

    // This's a part of launch information that wiil be used in matching. So it
    // must be selected as well as the grouping part.
    $launchInfoForComparison = array('Rule name' => 1, 'Module' => 1, 'Entry point' => 1);
    // Some part of launch information may be used or not in matching in depend
    // on problems with matching (i.e. when key values are the same).
    $launchInfoForComparisonPossible = array('Environment version' => 1);
    $launchInfoComparison = array();
    $joinsComparison = array();

    foreach (array_merge(array_keys($launchInfoForComparison), array_keys($launchInfoForComparisonPossible)) as $name) {
      // Skip comparison launch information if it's already selected while grouping.
      if (array_key_exists($name, $launchInfo)) {
        continue;
      }

      $tableColumn = $this->getTableColumn($this->_launchInfoNameTableColumnMapper[$name]);
      $launchInfoComparison[$name] = $orderBy[] = "$tableColumn[tableShort].$tableColumn[column]";
      $joinsComparison[$tableColumn['table']] = 1;
    }

    // As for verification info then just take verdict into consideration..
    $verificationInfo = array();
    $verificationInfoName = 'Verdict';
    $tableColumn = $this->getTableColumn($this->_verificationInfoNameTableColumnMapper[$verificationInfoName]);
    $verificationInfo[$verificationInfoName] = "$tableColumn[tableShort].$tableColumn[column]";

    $launches = $this->getDbTable('Application_Model_DbTable_Launches', $this->_db);

    // Prepare query to the statistics database to collect launch and
    // verification info.
    $select = $launches
      ->select()->setIntegrityCheck(false);

    // Get data from the main launches table.
    $tableMain = 'launches';
    $select = $select
      ->from(array($this->_tableMapper[$tableMain] => $tableMain),
        array_merge($launchInfo, $launchInfoComparison, $verificationInfo));

    // Join launches with related with statistics key tables. Note that traces
    // is always joined.
    $tableAux = 'traces';
    $joins[$tableAux] = 1;
    foreach (array_merge(array_keys($joins), array_keys($joinsComparison)) as $table) {
      $select = $select
        ->joinLeft(array($this->_tableMapper[$table] => $table)
          , '`' . $this->_tableMapper[$tableMain] . '`.`' . $this->_tableLaunchMapper[$table] . '`=`' . $this->_tableMapper[$table] . '`.`id`'
          , array());
    }

    // Restrict to the necessary task ids.
    $select = $select
      ->where($launchInfoScreened['Task id'] . " IN ('" . join("','", $taskIds) . "')");

    // Order by the launch information.
    foreach ($orderBy as $order) {
      $select = $select->order($order);
    }

#print_r($select->assemble());exit;

    $launchesResultSet = $launches->fetchAll($select);

    // Find out quickly whether additional part of key must be used in matching
    // for a given task id.
    $launchInfoAdditional = array();
    $tasksKernels = array();
    foreach ($launchesResultSet as $launchesRow) {
      $taskId = $launchesRow['Task id'];
      $kernelName = $launchesRow['Environment version'];
      $tasksKernels[$taskId][$kernelName] = 1;
    }
    foreach ($tasksKernels as $taskKernels) {
      // Use additional part of key when task con
      if (count($taskKernels) > 1) {
        // At the moment use the whole addons but may be it won't be so in future.
        $launchInfoAdditional = $launchInfoForComparisonPossible;
      }
    }
#print_r($tasksKernels);exit;
    $launchInfoForComparison = array_merge($launchInfoForComparison, $launchInfoAdditional);

    // Collect the whole raw launches statisitc assigning to corresponding task
    // id and comparison launch information key string.
    $statsCmp = array();

    foreach ($launchesResultSet as $launchesRow) {
      $statsPart = array();
      $statsCmpValues = array();
      $taskId = $launchesRow['Task id'];

      if (!array_key_exists($taskId, $statsCmp)) {
        $statsCmp[$taskId] = array();
      }

      foreach (array_keys(array_merge($launchInfo, $launchInfoComparison, $verificationInfo)) as $statsKeyPart) {
        $statsPart[$statsKeyPart] = $launchesRow[$statsKeyPart];

        if (array_key_exists($statsKeyPart, $launchInfoForComparison)) {
          $statsCmpValues[] = $launchesRow[$statsKeyPart];
        }
      }
      $statsCmpValuesStr = join(';', $statsCmpValues);

      // For build errors there is no module is specified for a set of launches
      // related with the same task. Don't take these launches into consideration.
      if ($launchesRow['Module'] != '' and array_key_exists($statsCmpValuesStr, $statsCmp[$taskId])) {
        throw new Exception("Comparison launch information key string is duplicated ('$statsCmpValuesStr')");
      }

      $statsCmp[$taskId][$statsCmpValuesStr] = $statsPart;
    }

    // Add special key to be used when no matching will be established. At the
    // beginning a value is an empty array.
    $deleted = '__DELETED';
    foreach (array_keys($statsCmp) as $taskId) {
      $statsCmp[$taskId][$deleted] = array();
    }

    // Match tasks launches with each other. The first task id is used as the
    // referenced one. For matching use the special regexp.
    $statsCmpMatchPattern = '/^([^_;]+)[^;]+;([^;]+);ldv_main(\d+)/';
    $statsCmpMatch = array();
    $taskIdCmpRef = $taskIds[0];
    foreach (array_slice($taskIds, 1) as $taskIdCmp) {
      // Foreach task to be compared use its own referenced first task copy.
      $statsCmpRef = $statsCmp[$taskIdCmpRef];
      $statsCmpMatch[$taskIdCmp] = array();

      foreach ($statsCmp[$taskIdCmp] as $statsCmpValuesStr => $statsPart) {
        foreach ($statsCmpRef as $statsCmpRefValuesStr => $statsRefPart) {
          // All as possible is already matched.
          if ($statsCmpValuesStr == $deleted and $statsCmpRefValuesStr == $deleted) {
            break;
          }

          // Check are there unmatched launches in the referenced task at the end.
          if ($statsCmpValuesStr == $deleted) {
            $statsCmpMatch[$taskIdCmp][$statsCmpValuesStr][] = $statsCmpRefValuesStr;
            continue;
          }

          // No launch from referenced task is matched.
          if ($statsCmpRefValuesStr == $deleted) {
            $statsCmpMatch[$taskIdCmp][$statsCmpValuesStr] = array('match' => $deleted, 'stats' => $statsPart);
            break;
          }

          preg_match($statsCmpMatchPattern, $statsCmpValuesStr, $statsCmpValuesParts);
          preg_match($statsCmpMatchPattern, $statsCmpRefValuesStr, $statsCmpRefValuesParts);

          // Launches are matched to each other.
          if (!count(array_diff_assoc(array_slice($statsCmpValuesParts, 1), array_slice($statsCmpRefValuesParts, 1)))) {
            $statsCmpMatch[$taskIdCmp][$statsCmpValuesStr] = array('match' => $statsCmpRefValuesStr, 'stats' => $statsPart);
            unset($statsCmpRef[$statsCmpRefValuesStr]);
            // Note that other matches aren't checked.'
            break;
          }
        }
      }
    }

#    print_r($statsCmpMatch);
#    exit;
    $result['Comparison stats'] = array();
    $result['Comparison stats']['All changes'] = array();
    $result['Comparison stats']['Row info'] = array();

    // Count the number of needed transitions with grouping by the corresponding
    // launch information statistics keys.
    foreach (array_slice($taskIds, 1) as $taskIdCmp) {
      foreach ($statsCmpMatch[$taskIdCmp] as $statsCmpValuesStr => $matchStats) {
        $resultPart = array();
        $resultPart['Stats key'] = array();
        $resultPart['Stats key matched'] = array();
        $resultPart['Verdict changes'] = array();
        $resultPart['Total changes'] = 0;
        $statsRefVerdicts = array();
        $driver = array();
        $driversMatched = array();

        if ($statsCmpValuesStr == $deleted) {
          $statsVerdict = $deleted;
          $statsRefVerdicts = array();

          foreach ($matchStats as $statsCmpRefValuesStr) {
            $statsRefVerdicts[] = $statsCmp[$taskIdCmpRef][$statsCmpRefValuesStr]['Verdict'];

            // Pass launch statistics key with matched driver since there a lot
            // of them.
            $driverMatched = array();
            foreach (array_keys($launchInfo) as $statsKeyPart) {
              $driverMatched['Stats key matched'][$statsKeyPart] = $statsCmp[$taskIdCmpRef][$statsCmpRefValuesStr][$statsKeyPart];
            }
            foreach (array_keys($launchInfoForComparison) as $statsKeyPart) {
              if (!array_key_exists($statsKeyPart, $driverMatched['Stats key matched'])) {
                $driverMatched[$statsKeyPart] = $statsCmp[$taskIdCmpRef][$statsCmpRefValuesStr][$statsKeyPart];
              }
            }
            $driversMatched[] = $driverMatched;
          }
        }
        else {
          foreach (array_keys($launchInfo) as $statsKeyPart) {
            $resultPart['Stats key'][$statsKeyPart] = $matchStats['stats'][$statsKeyPart];
          }

          foreach (array_keys($launchInfoForComparison) as $statsKeyPart) {
            if (!array_key_exists($statsKeyPart, $resultPart['Stats key'])) {
              $driver[$statsKeyPart] = $matchStats['stats'][$statsKeyPart];
            }
          }

          // Get verdicts from the task compared and the referenced task.
          $statsVerdict = $matchStats['stats']['Verdict'];

          $driverMatched = array();

          if ($matchStats['match'] == $deleted) {
            $statsRefVerdicts[] = $deleted;
          }
          else {
            $statsRefVerdicts[] = $statsCmp[$taskIdCmpRef][$matchStats['match']]['Verdict'];

            foreach (array_keys($launchInfo) as $statsKeyPart) {
              $resultPart['Stats key matched'][$statsKeyPart] = $statsCmp[$taskIdCmpRef][$matchStats['match']][$statsKeyPart];
            }

            foreach (array_keys($launchInfoForComparison) as $statsKeyPart) {
              if (!array_key_exists($statsKeyPart, $resultPart['Stats key matched'])) {
                $driverMatched[$statsKeyPart] = $statsCmp[$taskIdCmpRef][$matchStats['match']][$statsKeyPart];
              }
            }
          }

          $driversMatched[] = $driverMatched;
        }

        // Either group with the last created row (note that they are ordered)
        // or add a new row.
        if (!($last = end($result['Comparison stats']['Row info']))
          or count(array_diff_assoc($last['Stats key'], $resultPart['Stats key']))) {
            $result['Comparison stats']['Row info'][] = $resultPart;
        }

        // Add corresponding change of verdict to the last inserted value.
        $last = array_pop($result['Comparison stats']['Row info']);

        // Fill the matched statistics key if it isn't done.
        if (!count($last['Stats key matched'])) {
          $last['Stats key matched'] = $resultPart['Stats key matched'];
        }

        foreach ($statsRefVerdicts as $statsRefVerdict) {
          $driverMatched = array_shift($driversMatched);

          if (!array_key_exists($statsRefVerdict, $last['Verdict changes'])) {
            $last['Verdict changes'][$statsRefVerdict] = array();
          }

          if (array_key_exists($statsVerdict, $last['Verdict changes'][$statsRefVerdict])) {
            $last['Verdict changes'][$statsRefVerdict][$statsVerdict]['numb']++;
          }
          else {
            $last['Verdict changes'][$statsRefVerdict][$statsVerdict]['numb'] = 1;
          }

          $last['Verdict changes'][$statsRefVerdict][$statsVerdict]['drivers'][] = array('driver' => $driver, 'matched driver' => $driverMatched);

          if ($statsRefVerdict != $statsVerdict) {
            $last['Total changes']++;
          }

          $result['Comparison stats']['All changes'][$statsRefVerdict][$statsVerdict] = 1;
        }

        array_push($result['Comparison stats']['Row info'], $last);
      }
    }
#print_r($result);
#exit;
    return $result;
  }
}
