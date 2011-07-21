<?php

class Application_Model_KnowledgeBaseInfo extends Application_Model_GeneralStats
{
  protected $_knowledgeBaseInfoName;

  public function setKnowledgeBaseInfoName($name)
  {
    $this->_knowledgeBaseInfoName = (string) $name;
    return $this;
  }

  public function getKnowledgeBaseInfoName()
  {
    return $this->_knowledgeBaseInfoName;
  }
}
