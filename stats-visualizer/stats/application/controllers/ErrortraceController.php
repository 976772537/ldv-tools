<?php

class ErrortraceController extends Zend_Controller_Action
{
    protected $_dbName;
    protected $_dbUser;
    protected $_dbHost;
    protected $_dbUserPassword;
    	
    public function init()
    {
        /* Initialize action controller here */
    }

    public function indexAction()
    {
		$driverId = $this->_getParam('driver id');
		$kernelId = $this->_getParam('kernel id');
		$modelId = $this->_getParam('model id');
		$toolsetId = $this->_getParam('toolset id');
		$scenarioId = $this->_getParam('scenario id');				
        $request = $this->getRequest();
        
        $form    = new Application_Form_Db();
        if ($this->getRequest()->isPost()) {
            if ($form->isValid($request->getPost())) 
            {
				$formValues = $form->getValues();

				$this->_dbName = $formValues['name'];
				$this->_dbUser = $formValues['user'];
				$this->_dbHost = $formValues['host'];
				$this->_dbUserPassword = $formValues['user password'];

               // return $this->_helper->redirector('index');
            }
        }

        $this->view->form = $form;		

		if (!empty($this->_dbHost))
		{
	        /* Create the database adapter. */	
            $db = new Zend_Db_Adapter_Pdo_Mysql(array(
                'host'     => $this->_dbHost,
                'username' => $this->_dbUser,
                'password' => $this->_dbUserPassword,
                'dbname'   => $this->_dbName
            ));
		
            $statistics = new Application_Model_StatsMapper(array('db' => $db));
            $this->view->entries = array('stats' => $statistics->getErrorTrace($driverId, $kernelId, $modelId, $toolsetId, $scenarioId));
	    }
    }
    

//    public function __call($method, $args)
//    {
//		print($args);
//		exit;
/*        if ('Action' == substr($method, -6)) {
            // If the action method was not found, render the error
            // template
            return $this->render('error');
        }
 
        // all other methods throw an exception
        throw new Exception('Invalid method "'
                            . $method
                            . '" called',
                            500);
*/
//    }    

}



