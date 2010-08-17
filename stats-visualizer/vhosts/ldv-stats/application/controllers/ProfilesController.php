<?php

class ProfilesController extends Zend_Controller_Action
{
  public function init()
  {
  }

  public function indexAction()
  {
  }

  public function editAction()
  {
    $request = $this->getRequest();
    $form = new Application_Form_ProfileEdit();
    $this->view->form = $form;
  }
}
