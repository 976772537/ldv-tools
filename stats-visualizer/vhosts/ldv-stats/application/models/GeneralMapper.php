<?php
/*
 * Copyright (C) 2010-2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
