<?php

class Application_Form_TasksComparison extends Zend_Form
{
  public function init()
  {
    $this->setMethod('post');

    // Select task ids.
    $el = $this->addElement('text', 'taskids', array(
      'label'    => "Enter separated with commas task ids to be compared with the choosen one",
      'required' => true
    ));

    // Add the submit buttons.
    $this->addElement('submit', 'submit', array(
      'ignore'   => true,
      'label'    => 'Compare tasks'
    ));
  }
}
