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

class Application_Form_Profiles extends Zend_Form
{
  public function init()
  {
    // Get available profiles.
    $profileMapper = new Application_Model_ProfileMapper();
    $profiles = $profileMapper->getProfiles();
    $values = array();
    foreach ($profiles as $profile) {
      $values[$profile->profileId] = "$profile->profileUser - $profile->profileName";
    }

    $this->setMethod('post');

    // Select user and profile names.
    $this->addElement('select', 'profile', array(
      'label' => 'Plese select the profile (i.e. the pair \'profile user\', \'profile name\'):',
      'multiOptions' => $values,
      'required' => true
    ));

    // Add the submit buttons.
    $this->addElement('submit', 'stats', array(
      'ignore'   => true,
      'value' => 'stats',
      'label'    => 'Show statistics'
    ));

    $this->addElement('submit', 'edit', array(
      'ignore'   => true,
      'value' => 'edit',
      'label'    => 'Edit profile'
    ));
  }
}
