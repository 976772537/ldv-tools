<?php

class Bootstrap extends Zend_Application_Bootstrap_Bootstrap
{
  protected function _initDoctype()
  {
    $this->bootstrap('view');
    $view = $this->getResource('view');
    $view->doctype('XHTML1_STRICT');

    # Relate models with rules just one time for a given session.
    $global = new Zend_Session_Namespace();
    if (!$global->isread_models)
    {
      $global->models = array();

      # Obtain rules xml representation.
      $rulesConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'rule-database');
      $rulesFile = $rulesConfig->file;
      $rulesText = file_get_contents($rulesFile)
        or die("Can't read rules from the file '$rulesFile'");
      $rulesXml = new SimpleXMLElement($rulesText);

      # Obtain some rules information related with their ids.
      $rules = array();
      foreach ($rulesXml->RULE_ERROR as $rule)
      {
        $rules["$rule->ID"] = array(
          'name' => "$rule->NAME",
          'title' => "$rule->TITLE",
          'summary' => "$rule->SUMMARY");
      }

      # Obtain models xml representation.
      $modelsConfig = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'model-database');
      $modelsFile = $modelsConfig->file;
      $modelsText = file_get_contents($modelsFile)
        or die("Can't read models from the file '$modelsFile'");
      $modelsXml = new SimpleXMLElement($modelsText);

      # Relate models with rules with help of model id.
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

      $global->isread_models = true;
    }
  }
}
