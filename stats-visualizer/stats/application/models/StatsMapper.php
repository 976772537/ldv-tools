<?php

class Application_Model_StatsMapper
{
    protected $db;
//    protected $_dbTable;
    
    public function __construct(array $options = null)
    {
        if (is_array($options)) 
        {
            $this->setOptions($options);
        }
    }

 
     public function setOptions(array $options)
    {
        $methods = get_class_methods($this);
        foreach ($options as $key => $value) 
        {
            $method = 'set' . ucfirst($key);

            if (in_array($method, $methods)) 
            {
                $this->$method($value);
            }
            else
            {
				throw new Exception('Invalid option is passed');
			}
        }
        return $this;
    }   
    
    public function setDb($db)
    {
		$this->db = $db;
        return $this;
	}
	
    public function getDb()
    {
        return $this->db;
	}	
/*
    public function setDbTable($dbTable)
    {
        if (is_string($dbTable)) {
            $dbTable = new $dbTable(array('name' => 'drivers'));
        }
        if (!$dbTable instanceof Zend_Db_Table_Abstract) {
            throw new Exception('Invalid table data gateway provided');
        }
        $this->_dbTable = $dbTable;

        return $this;
    }

    public function getDbTable()
    {
        if (null === $this->_dbTable) {
            $this->setDbTable('Application_Model_DbTable_Drivers');
        }
        return $this->_dbTable;
    }
*/
/*
    public function save(Application_Model_Guestbook $guestbook)
    {
        $data = array(
            'email'   => $guestbook->getEmail(),
            'comment' => $guestbook->getComment(),
            'created' => date('Y-m-d H:i:s'),
        );

        if (null === ($id = $guestbook->getId())) {
            unset($data['id']);
            $this->getDbTable()->insert($data);
        } else {
            $this->getDbTable()->update($data, array('id = ?' => $id));
        }
    }

    public function find($id, Application_Model_Guestbook $guestbook)
    {
        $result = $this->getDbTable()->find($id);
        if (0 == count($result)) {
            return;
        }
        $row = $result->current();
        $guestbook->setId($row->id)
                  ->setEmail($row->email)
                  ->setComment($row->comment)
                  ->setCreated($row->created);
    }
*/
    public function fetchAll()
    {
      $sql = 'SELECT drivers.id AS \'Driver id\'' . 
               ', drivers.name AS \'Driver name\'' .
               ', environments.id AS \'Kernel id\'' .
               ', environments.version AS \'Kernel name\'' .
               ', rule_models.id AS \'Model id\'' .
               ', rule_models.name AS \'Model name\'' .
               ', toolsets.id AS \'Toolset id\'' .
               ', toolsets.version AS \'Toolset name\'' .
               ', scenarios.id AS \'Scenario id\'' .
               ', scenarios.executable AS \'Module name\'' .
               ', scenarios.main AS \'Environment model\'' .
               ', traces.id AS \'Trace id\'' .
               ', traces.result AS Verdict' .
               ' FROM launches LEFT JOIN drivers ON launches.driver_id=drivers.id LEFT JOIN environments ON launches.environment_id=environments.id LEFT JOIN rule_models ON launches.rule_model_id=rule_models.id LEFT JOIN toolsets ON launches.toolset_id=toolsets.id LEFT JOIN scenarios ON launches.scenario_id=scenarios.id LEFT JOIN traces ON launches.trace_id=traces.id' .
               ' ORDER BY toolsets.version, rule_models.name';
//print($sql);
//exit;
      $result_set = $this->getDb()->fetchAll($sql);
      $entries = array();
      foreach ($result_set as $row)
      {
	    $entry = new Application_Model_Stats();
	    $entry->setDriver($row['Driver id'], $row['Driver name']);
	    $entry->setKernel($row['Kernel id'], $row['Kernel name']);
	    $entry->setModel($row['Model id'], $row['Model name']);
	    $entry->setToolset($row['Toolset id'], $row['Toolset name']);
	    $entry->setScenario($row['Scenario id'], $row['Module name'], $row['Environment model']);
	    $entry->setVerdict($row['Verdict']);
	    
	    $sql2 = 'SELECT stats.success as \'Build status\', stats.id as \'Build id\' FROM traces LEFT JOIN stats ON traces.build_id=stats.id WHERE traces.id=' . $row['Trace id'] ;
        $result_set2 = $this->getDb()->fetchAll($sql2);
        $build_status = $result_set2[0]['Build status'];
        $build_id = $result_set2[0]['Build id'];
        $entry->setBuildStatus($build_status);

        if (isset($build_id))
        {
	      $sql2 = 'SELECT problems.name as \'Build problems\' FROM problems_stats LEFT JOIN problems ON problems_stats.problem_id=problems.id WHERE problems_stats.stats_id=' . $result_set2[0]['Build id'];
          $result_set2 = $this->getDb()->fetchAll($sql2);
          
          $problems = array();
          foreach($result_set2 as $problem)
          {
			 $problems[] = $problem['Build problems'];
		  }
          
          if (!$build_status)
          {
			$entry->setBuildProblems($problems);
	      }
        }   	    
	    
	    $sql2 = 'SELECT stats.success as \'Maingen status\', stats.id as \'Maingen id\'  FROM traces LEFT JOIN stats ON traces.maingen_id=stats.id WHERE traces.id=' . $row['Trace id'] ;
        $result_set2 = $this->getDb()->fetchAll($sql2);
        $maingen_status = $result_set2[0]['Maingen status'];
        $maingen_id = $result_set2[0]['Maingen id'];
        $entry->setMaingenStatus($maingen_status);

        if (isset($maingen_id))
        {
	      $sql2 = 'SELECT problems.name as \'Maingen problems\' FROM problems_stats LEFT JOIN problems ON problems_stats.problem_id=problems.id WHERE problems_stats.stats_id=' . $result_set2[0]['Maingen id'];
          $result_set2 = $this->getDb()->fetchAll($sql2);
          
          $problems = array();
          foreach($result_set2 as $problem)
          {
			 $problems[] = $problem['Maingen problems'];
		  }
          
          if (!$maingen_status)
          {
			$entry->setMaingenProblems($problems);
	      }
        }   

	    $sql2 = 'SELECT stats.success as \'DSCV status\', stats.id as \'DSCV id\'  FROM traces LEFT JOIN stats ON traces.dscv_id=stats.id WHERE traces.id=' . $row['Trace id'] ;
        $result_set2 = $this->getDb()->fetchAll($sql2);
        $dscv_status = $result_set2[0]['DSCV status'];
        $dscv_id = $result_set2[0]['DSCV id'];
        $entry->setDscvStatus($dscv_status);

        if (isset($dscv_id))
        {
	      $sql2 = 'SELECT problems.name as \'DSCV problems\' FROM problems_stats LEFT JOIN problems ON problems_stats.problem_id=problems.id WHERE problems_stats.stats_id=' . $result_set2[0]['DSCV id'];
          $result_set2 = $this->getDb()->fetchAll($sql2);
          
          $problems = array();
          foreach($result_set2 as $problem)
          {
			 $problems[] = $problem['DSCV problems'];
		  }
          
          if (!$dscv_status)
          {
			$entry->setDscvProblems($problems);
	      }
        }         
	    
	    $sql2 = 'SELECT stats.success as \'RI status\', stats.id as \'RI id\'  FROM traces LEFT JOIN stats ON traces.ri_id=stats.id WHERE traces.id=' . $row['Trace id'] ;
        $result_set2 = $this->getDb()->fetchAll($sql2);
        $ri_status = $result_set2[0]['RI status'];
        $ri_id = $result_set2[0]['RI id'];
        $entry->setRiStatus($ri_status);

        if (isset($ri_id))
        {
	      $sql2 = 'SELECT problems.name as \'RI problems\' FROM problems_stats LEFT JOIN problems ON problems_stats.problem_id=problems.id WHERE problems_stats.stats_id=' . $result_set2[0]['RI id'];
          $result_set2 = $this->getDb()->fetchAll($sql2);
          
          $problems = array();
          foreach($result_set2 as $problem)
          {
			 $problems[] = $problem['RI problems'];
		  }
          
          if (!$ri_status)
          {
			$entry->setRiProblems($problems);
	      }
        }   
        	    
	    $sql2 = 'SELECT stats.success as \'RCV status\', stats.id as \'RCV id\' FROM traces LEFT JOIN stats ON traces.rcv_id=stats.id WHERE traces.id=' . $row['Trace id'] ;
        $result_set2 = $this->getDb()->fetchAll($sql2);
        $rcv_status = $result_set2[0]['RCV status'];
        $rcv_id = $result_set2[0]['RCV id'];
        $entry->setRcvStatus($rcv_status);

        if (isset($rcv_id))
        {
	      $sql2 = 'SELECT problems.name as \'RCV problems\' FROM problems_stats LEFT JOIN problems ON problems_stats.problem_id=problems.id WHERE problems_stats.stats_id=' . $result_set2[0]['RCV id'];
          $result_set2 = $this->getDb()->fetchAll($sql2);
          
          $problems = array();
          foreach($result_set2 as $problem)
          {
			 $problems[] = $problem['RCV problems'];
		  }
          
          if (!$rcv_status)
          {
			$entry->setRcvProblems($problems);
	      }
        }        
/*
        // Add problem db.
        $sql2 = 'SELECT problems.name as \'Fail\' FROM problems, problems_traces WHERE problems_traces.trace_id=' . $row['Trace id'] . ' AND problems_traces.problem_id=problems.id';
        $result_set2 = $this->getDb()->fetchAll($sql2);
        foreach($result_set2 as $fail)
        {
          $entry->setProblem($fail['Fail']);
		}
		// Add unmatched problems.
        $sql2 = 'SELECT count(*) as \'Unmatched fails\' FROM traces WHERE traces.id=' . $row['Trace id'] .' AND result=\'unknown\' AND traces.id IN (SELECT DISTINCT problems_traces.trace_id FROM problems_traces)';//problems_traces.trace_id=' . $row['Trace id'] . ' AND problems_traces.problem_id=problems.id';
        $result_set2 = $this->getDb()->fetchAll($sql2);
        $entry->setProblemUnmatched($result_set2[0]['Unmatched fails']);	
*/
        
	    $entries[] = $entry;
	  }
//exit;
      return $entries;
    }
    
    public function getErrorTrace($driverId, $kernelId, $modelId, $toolsetId, $scenarioId)
    {
	  $sql = "SELECT launches.trace_id as 'Trace id' FROM launches WHERE launches.driver_id=$driverId and launches.environment_id=$kernelId and launches.rule_model_id=$modelId and launches.toolset_id=$toolsetId and launches.scenario_id=$scenarioId";
      $result_set = $this->getDb()->fetchAll($sql);
      foreach ($result_set as $row)
      {
		/* That is trace id that must be unique for the given launch! */  
	    $entry = $row['Trace id'];
	    $sql = "SELECT traces.error_trace as 'Error trace' FROM traces WHERE traces.id = $entry";
        $result_set = $this->getDb()->fetchAll($sql);
        foreach ($result_set as $row)
        {
		  /* That is trace id that must be unique for the given launch! */  
	      $entry = $row['Error trace'];
	      return $entry;	    
	    }
      }
	}    
}

