<?php

class StatsController extends Zend_Controller_Action
{
    protected $_dbName;
    protected $_dbUser;
    protected $_dbHost;
    protected $_dbUserPassword;
    protected $_db;
    
    public function init()
    {
        /* Initialize action controller here */
    }

    public function indexAction()
    {
		$this->_dbName = $this->_getParam('name');
		$this->_dbUser = $this->_getParam('user');
		$this->_dbHost = $this->_getParam('host');
		$this->_dbUserPassword = $this->_getParam('password');

        $databases = new Zend_Config_Ini(APPLICATION_PATH . '/configs/config.ini', 'databases');
        $dbAdapters = array();
        
        foreach($databases->db as $config_name => $db)
        {
            $dbAdapters[$config_name] = Zend_Db::factory($db->adapter, $db->config->toArray());
        }
	
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
            $this->_db = new Zend_Db_Adapter_Pdo_Mysql(array(
                'host'     => $this->_dbHost,
                'username' => $this->_dbUser,
                'password' => $this->_dbUserPassword,
                'dbname'   => $this->_dbName
            ));
		
            $statistics = new Application_Model_StatsMapper(array('db' => $this->_db));
            $this->view->entries = array('stats' => $statistics->fetchAll());		
	    }
	    else
	    {			echo "<br><font color=red size=+2>Statistics server shows its default layout. Choose the your one if you want (see form above)!</font><br>";
            $statistics = new Application_Model_StatsMapper(array('db' => $dbAdapters['server_default_db']));
            
            $this->view->entries = array('stats' => $statistics->fetchAll());	
		}
    }
    public function errortraceAction()
    {
		$driverId = $this->_getParam('driver id');
		$kernelId = $this->_getParam('kernel id');
		$modelId = $this->_getParam('model id');
		$toolsetId = $this->_getParam('toolset id');
		$scenarioId = $this->_getParam('scenario id');		


        $databases = new Zend_Config_Ini(APPLICATION_PATH . '/configs/config.ini', 'databases');
        $dbAdapters = array();
        
        foreach($databases->db as $config_name => $db)
        {
            $dbAdapters[$config_name] = Zend_Db::factory($db->adapter, $db->config->toArray());
        }


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
            $this->_db = new Zend_Db_Adapter_Pdo_Mysql(array(
                'host'     => $this->_dbHost,
                'username' => $this->_dbUser,
                'password' => $this->_dbUserPassword,
                'dbname'   => $this->_dbName
            ));
            $statistics = new Application_Model_StatsMapper(array('db' => $this->_db));
            $this->view->entries = array('stats' => $statistics->getErrorTrace($driverId, $kernelId, $modelId, $toolsetId, $scenarioId));
        }
	    else
	    {
			echo "<br><font color=red size=+2>Statistics server shows its default layout. Choose the your one if you want (see form above)!</font><br>";
            $statistics = new Application_Model_StatsMapper(array('db' => $dbAdapters['server_default_db']));

            $errorTrace = $statistics->getErrorTrace($driverId, $kernelId, $modelId, $toolsetId, $scenarioId);
   

$myFile = APPLICATION_PATH . "/files/testFile.txt";
$fh = fopen($myFile, 'w') or die("can't open file");
fwrite($fh, $errorTrace);
fclose($fh);
$outFile = APPLICATION_PATH . "/files/test.txt";
		$output = array();
		exec("/home/joker/work/14_driver/test_ldv_tools/bin/error-trace-visualizer.pl --engine=blast --report=$myFile --reqs-out=$outFile 2>&1", $output);
		foreach ($output as $line)
		{
		  echo "$line<br>";
		}
 
                        $this->view->entries = array('stats' => $errorTrace);
		}
    }
    public function signdbAction()
    {
        $request = $this->getRequest();
        $form    = new Application_Form_Db();
        if ($this->getRequest()->isPost()) {
            if ($form->isValid($request->getPost())) {
				$this->view->entries = $form->getValues();
//                $comment = new Application_Model_Guestbook($form->getValues());
//                $mapper  = new Application_Model_GuestbookMapper();
//                $mapper->save($comment);

                return $this->_helper->redirector('index');
            }
        }

        $this->view->form = $form;
    }
}



