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

class Application_Model_Page extends Application_Model_GeneralStats
{
  protected $_launchInfo;
  protected $_verificationInfo;
  protected $_knowledgeBaseInfo;
  protected $_toolsInfo;

  public function setToolsInfoOrder($order)
  {
    $toolsInfo = new Application_Model_ToolsInfo();
    $this->_toolsInfo[$order] = $toolsInfo;
    return $toolsInfo;
  }

  public function getToolsInfo()
  {
    return $this->_toolsInfo;
  }

  public function setLaunchInfoOrder($order)
  {
    $launchInfo = new Application_Model_LaunchInfo();
    $this->_launchInfo[$order] = $launchInfo;
    return $launchInfo;
  }

  public function getLaunchInfo()
  {
    return $this->_launchInfo;
  }

  public function setVerificationInfoOrder($order)
  {
    $verificationInfo = new Application_Model_VerificationInfo();
    $this->_verificationInfo[$order] = $verificationInfo;
    return $verificationInfo;
  }

  public function getVerificationInfo()
  {
    return $this->_verificationInfo;
  }

  public function setKnowledgeBaseInfoOrder($order)
  {
    $knowledgeBaseInfo = new Application_Model_KnowledgeBaseInfo();
    $this->_knowledgeBaseInfo[$order] = $knowledgeBaseInfo;
    return $knowledgeBaseInfo;
  }

  public function getKnowledgeBaseInfo()
  {
    return $this->_knowledgeBaseInfo;
  }
}
