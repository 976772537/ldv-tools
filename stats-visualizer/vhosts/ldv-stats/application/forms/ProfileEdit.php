<?php

class Application_Form_ProfileEdit extends Zend_Form
{
  public function init()
  {
    // Get information on the current profile.
    $profileMapper = new Application_Model_ProfileMapper();
  }
}
