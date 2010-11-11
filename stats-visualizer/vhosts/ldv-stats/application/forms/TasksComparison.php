<?php

class Application_Form_TasksComparison extends Zend_Form
{
  public function init()
  {
    $this->setMethod('post');

    // Select task ids.
    $this->addElement('text', 'SSTaskIds', array(
      'label'    => "Enter separated with commas or spaces task ids to be compared. The first task will be used as the referenced one.",
      'required' => true
    ));

    // Add the submit buttons.
    $this->addElement('submit', 'submit', array(
      'ignore'   => true,
      'label'    => 'Compare tasks'
    ));
  }
}
