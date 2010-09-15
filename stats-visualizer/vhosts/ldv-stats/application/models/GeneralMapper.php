<?php

class Application_Model_GeneralMapper
{
  protected $_logger;
  
  public function __construct()
  {
    // Use the default logger.
    $this->_logger = Zend_Registry::get('logger');
  }
 
  public function getDbTable($tableName)
  {
    if (is_string($tableName)) {
      $dbTable = new $tableName();
    }

    if (!$dbTable instanceof Zend_Db_Table_Abstract) {
      throw new Exception('Invalid table data gateway provided');
    }

    return $dbTable;
  }
}
