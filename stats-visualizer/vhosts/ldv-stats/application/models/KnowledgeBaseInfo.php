<?php

class Application_Model_KnowledgeBaseInfo extends Application_Model_GeneralStats
{
  protected $_knowledgeBaseInfoName;
  protected $_verdicts;

  public function setVerdictOrder($order)
  {
    $verdict = new Application_Model_VerdictInfo();
    $this->_verdicts[$order] = $verdict;
    return $verdict;
  }

  public function getVerdicts()
  {
    return $this->_verdicts;
  }

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
