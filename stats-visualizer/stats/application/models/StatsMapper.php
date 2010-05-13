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
      $sql = 'SELECT drivers.name as Driver, environments.version as Kernel, rule_models.name as Model, toolsets.version as Toolset, scenarios.executable as Module, scenarios.main as \'Environment model\', traces.result as Verdict, traces.error_trace as \'Error trace\' FROM launches LEFT JOIN drivers ON launches.driver_id=drivers.id LEFT JOIN environments ON launches.environment_id=environments.id LEFT JOIN rule_models ON launches.rule_model_id=rule_models.id LEFT JOIN toolsets ON launches.toolset_id=toolsets.id LEFT JOIN scenarios ON launches.scenario_id=scenarios.id LEFT JOIN traces ON launches.trace_id=traces.id';

      $result_set = $this->getDb()->fetchAll($sql);
      $entries = array();
      foreach ($result_set as $row)
      {
	    $entry = new Application_Model_Stats();
	    $entry->setDriver($row['Driver']);
	    $entry->setKernel($row['Kernel']);
	    $entry->setModel($row['Model']);
	    $entry->setToolset($row['Toolset']);
	    $entry->setModule($row['Module']);
	    $entry->setEnvironmentModel($row['Environment model']);
	    $entry->setVerdict($row['Verdict']);
	    $entry->setErrorTrace($row['Error trace']);
	    $entries[] = $entry;
	  }

      return $entries;
    }
}

