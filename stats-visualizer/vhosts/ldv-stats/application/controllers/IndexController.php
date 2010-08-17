<?php

class IndexController extends Zend_Controller_Action
{
  public function init()
  {
  }

  public function indexAction()
  {
    $request = $this->getRequest();
    $form = new Application_Form_Profiles();

    if ($this->getRequest()->isPost()) {
      if ($form->isValid($request->getPost())) {
        $profileCurrent = $form->getValues();
        $profileModel = new Application_Model_Profile(array('id' => $profileCurrent['profile']));
        $profileMapper = new Application_Model_ProfileMapper();
        $profileMapper->setProfileCurrent($profileModel);
        
        if ($form->getElement('stats')->isChecked()) {
          return $this->_helper->redirector('index', 'stats');
        }
        else if ($form->getElement('edit')->isChecked()) {
          return $this->_helper->redirector('edit', 'profiles');
        }
      }
    }

    $this->view->form = $form;
  }
}
