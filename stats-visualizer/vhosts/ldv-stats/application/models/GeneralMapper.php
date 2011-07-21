<?php

class Application_Model_GeneralMapper
{
  protected $_logger;
  
  public function __construct()
  {
    // Use the default logger.
    $this->_logger = Zend_Registry::get('logger');
  }
 
  public function getDbTable($tableName, $dbName, $dbAdapter = NULL)
  {
		if (is_string($tableName)) {
			if (is_string($dbName)) {
		    $global = new Zend_Session_Namespace();
		    if (!$global->$dbName) {
			    throw new Exception("Specified database '$dbName' hasn't corresponding adapter");
		    }
        $dbTable = new $tableName(array('db' => $global->$dbName));
      }
      else 
        $dbTable = new $tableName(array('db' => $dbAdapter));
    }

    if (!$dbTable instanceof Zend_Db_Table_Abstract) {
      throw new Exception('Invalid table data gateway provided');
    }

    return $dbTable;
  }
}
