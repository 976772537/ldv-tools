<?php
/*
 * Copyright 2010-2012
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

class Application_Model_ToolsInfo extends Application_Model_GeneralStats
{
  protected $_toolsInfoName;
  protected $_tools;

  public function setToolOrder($order)
  {
    $filter = new Application_Model_ToolInfo();
    $this->_tools[$order] = $filter;
    return $filter;
  }

  public function getTools()
  {
    return $this->_tools;
  }

  public function setToolsInfoName($name)
  {
    $this->_toolsInfoName = (string) $name;
    return $this;
  }

  public function getToolsInfoName()
  {
    return $this->_toolsInfoName;
  }
}
