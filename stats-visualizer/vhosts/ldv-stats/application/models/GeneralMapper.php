<?php

class Application_Model_GeneralMapper
{
  protected $_logger;
  
  public function __construct()
  {
    // Use the default logger.
    $this->_logger = Zend_Registry::get('logger');
  }
 
  public function getDbTable($tableName, $adapter = null)
  {
    if (is_string($tableName)) {
      if ($adapter) {
        $dbTable = new $tableName(array('db' => $adapter));
      }
      else {
        $dbTable = new $tableName();
      }
    }

    if (!$dbTable instanceof Zend_Db_Table_Abstract) {
      throw new Exception('Invalid table data gateway provided');
    }

    return $dbTable;
  }
}
