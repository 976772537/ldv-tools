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

class Bootstrap extends Zend_Application_Bootstrap_Bootstrap
{
  protected function _initDoctype()
  {
    $this->_logger = Zend_Registry::get('logger');

    $this->bootstrap('view');
    $view = $this->getResource('view');
    $view->doctype('XHTML1_STRICT');

    $global = new Zend_Session_Namespace();
    // Relate models with rules just one time for a given session. This can be
    // done due to these relations are unlikely to be changed frequently.
    if (!$global->isrelate_models_with_rules)
    {
      $global->models = array();

      // Obtain rules xml representation.
      $rulesConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'rule-database');
      $rulesFile = $rulesConfig->file;
      $rulesText = file_get_contents($rulesFile)
        or die("Can't read rules from the file '$rulesFile'");
      $rulesXml = new SimpleXMLElement($rulesText);

      // Obtain some rules information related with their ids.
      $rules = array();
      foreach ($rulesXml->RULE_ERROR as $rule)
      {
        $rules["$rule->ID"] = array(
          'name' => "$rule->NAME",
          'title' => "$rule->TITLE",
          'summary' => "$rule->SUMMARY");
      }

      // Obtain models xml representation.
      $modelsConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'model-database');
      $modelsFile = $modelsConfig->file;
      $modelsText = file_get_contents($modelsFile)
        or die("Can't read models from the file '$modelsFile'");
      $modelsXml = new SimpleXMLElement($modelsText);

      // Relate models with rules with help of model id.
      foreach ($modelsXml->model as $model)
      {
        if (array_key_exists("$model->rule", $rules))
        {
          $global->models["$model[id]"] = array(
            'rule id' => "$model->rule",
            'short' => (string)$rules["$model->rule"]['name'],
            'long' => (string)$rules["$model->rule"]['summary']);
        }
        else
        {
          $global->models["$model[id]"] = array(
            'rule id' => "$model->rule",
            'short' => 'Unknown',
            'long' => 'Unknown');
        }
      }

      $global->isrelate_models_with_rules = true;
    }
    // Read information on database connections and create corresponding
    // adapters also just one time per a session. This is done for profiles and
    // knowledge base databases since their options are constant.
    if (!$global->iscreate_db_adapters)
    {
      $this->_logger->log("Read information on database connections", Zend_Log::DEBUG);
      $databases = new Zend_Config_Ini(APPLICATION_PATH . '/configs/databases.ini');

      foreach($databases->db as $dbName => $dbOptions) {
        $this->_logger->log("Create adapter for database '$dbName'", Zend_Log::DEBUG);
        $global->$dbName = Zend_Db::factory($dbOptions->adapter, $dbOptions->config->toArray());
      }

      $global->iscreate_db_adapters = true;
    }
  }
}
