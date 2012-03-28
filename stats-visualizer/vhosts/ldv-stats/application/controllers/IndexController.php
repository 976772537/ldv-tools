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
        $profileModel = new Application_Model_Profile(array('profileId' => $profileCurrent['profile']));
        $global = new Zend_Session_Namespace('Statistics globals');
        $global->profileCurrentId = $profileModel->profileId;

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
