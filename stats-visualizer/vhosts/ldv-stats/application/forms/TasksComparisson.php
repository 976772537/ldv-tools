<?php

class Application_Form_TasksComparisson extends Zend_Form
{
  public function init()
  {
    $this->setMethod('post');

    // Select task ids.
    $el = $this->addElement('text', 'taskids', array(
      'label'    => "Enter separated with commas task ids to be compared (type 'no' to leave the comparisson mode)",
      'required' => true
    ));

    // Add the submit buttons.
    $this->addElement('submit', 'submit', array(
      'ignore'   => true,
      'label'    => 'Compare tasks'
    ));
  }
}
