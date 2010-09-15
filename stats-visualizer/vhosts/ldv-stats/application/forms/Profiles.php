<?php

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
 
    // Select user name.
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
