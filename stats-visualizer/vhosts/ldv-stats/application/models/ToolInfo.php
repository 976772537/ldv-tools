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

class Application_Model_ToolInfo extends Application_Model_GeneralStats
{
  protected $_toolName;
  protected $_time;

  public function setTimeOrder($order)
  {
    $time = new Application_Model_TimeInfo();
    $this->_time[$order] = $time;
    return $time;
  }

  public function getTime()
  {
    return $this->_time;
  }

  public function setToolName($name)
  {
    $this->_toolName = (string) $name;
    return $this;
  }

  public function getToolName()
  {
    return $this->_toolName;
  }
}
