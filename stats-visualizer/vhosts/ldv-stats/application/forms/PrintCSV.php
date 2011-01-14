<?php

class Application_Form_PrintCSV extends Zend_Form
{
  public function init()
  {
    $this->setMethod('post');

    // Add the submit buttons.
    $this->addElement('submit', 'submit', array(
      'ignore'   => true,
      'label'    => 'Print CSV'
    ));
  }
}
