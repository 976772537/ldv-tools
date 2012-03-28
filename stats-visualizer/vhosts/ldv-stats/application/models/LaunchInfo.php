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

class Application_Model_LaunchInfo extends Application_Model_GeneralStats
{
  protected $_launchInfoName;
  protected $_filters;
  protected $_auxInfo;

  public function setFilterOrder($order)
  {
    $filter = new Application_Model_FilterInfo();
    $this->_filters[$order] = $filter;
    return $filter;
  }

  public function getFilters()
  {
    return $this->_filters;
  }

  public function setLaunchInfoName($name)
  {
    $this->_launchInfoName = (string) $name;
    return $this;
  }

  public function getLaunchInfoName()
  {
    return $this->_launchInfoName;
  }
}
