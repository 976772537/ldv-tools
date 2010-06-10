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
/*		$this->_dbName = $this->_getParam('name');
		$this->_dbUser = $this->_getParam('user');
		$this->_dbHost = $this->_getParam('host');
		$this->_dbUserPassword = $this->_getParam('password');

		if (!empty($this->_dbHost))
		{
	        // Create the corresponding to user request database adapter.	
            $this->_db = new Zend_Db_Adapter_Pdo_Mysql(array(
                'host'     => $this->_dbHost,
                'username' => $this->_dbUser,
                'password' => $this->_dbUserPassword,
                'dbname'   => $this->_dbName
            ));
	    }
*/	    

		global $mysession;
			
		if ($mysession->db_host == 'localhost' && $mysession->db_username == 'joker' && $mysession->db_dbname == 'ldvreports')
		{		
		  echo "<br><font color=red size=+2>Statistics server shows its default layout. Choose the your one if you want (see link to the form above)!</font><br>";
        }

        $this->_db = new Zend_Db_Adapter_Pdo_Mysql(array(
          'host'     => $mysession->db_host,
          'username' => $mysession->db_username,
          'password' => $mysession->db_password,
          'dbname'   => $mysession->db_dbname
        ));
$profiler = new Zend_Db_Profiler_Firebug('All DB Queries');
$profiler->setEnabled(true);
$this->_db->setProfiler($profiler);
        $statistics = new Application_Model_StatsMapper(array('db' => $this->_db));
        $this->view->entries = array('stats' => $statistics->fetchAll());
    }
    public function errortraceAction()
    {
		$driverId = $this->_getParam('driver id');
		$kernelId = $this->_getParam('kernel id');
		$modelId = $this->_getParam('model id');
		$toolsetId = $this->_getParam('toolset id');
		$scenarioId = $this->_getParam('scenario id');		

		global $mysession;
			
		if ($mysession->db_host == 'localhost' && $mysession->db_username == 'joker' && $mysession->db_dbname == 'ldvreports')
		{		
		  echo "<br><font color=red size=+2>Statistics server shows its default layout. Choose the your one if you want (see link to the form above)!</font><br>";
        }

        $this->_db = new Zend_Db_Adapter_Pdo_Mysql(array(
          'host'     => $mysession->db_host,
          'username' => $mysession->db_username,
          'password' => $mysession->db_password,
          'dbname'   => $mysession->db_dbname
        ));

        $statistics = new Application_Model_StatsMapper(array('db' => $this->_db));
        $errorTrace = $statistics->getErrorTrace($driverId, $kernelId, $modelId, $toolsetId, $scenarioId);

$this->view->entries = array('stats' => $errorTrace);
return;

$myFile = APPLICATION_PATH . "/files/testFile.txt";
$fh = fopen($myFile, 'w') or die("can't open file");
fwrite($fh, $errorTrace);
fclose($fh);
$outFile = APPLICATION_PATH . "/files/test.txt";
$output = array();
exec("LDV_DEBUG=100 /home/joker/work/14_driver/test_ldv_tools/bin/error-trace-visualizer.pl --engine=blast --report=$myFile --report-out=$outFile 2>&1", $output);

#$fh = fopen($outFile, 'r') or die("can't open file");
echo "<pre>";
readfile($outFile) or die("can't read file");
echo "</pre>";
foreach ($output as $line)
{
 echo "$line<br>";
}
#fclose($fh);

//        $this->view->entries = array('stats' => $errorTrace);

    }
  
    
    public function errordescAction()
    {
		$kernelId = $this->_getParam('kernel id');
		$modelId = $this->_getParam('model id');
		$toolsetId = $this->_getParam('toolset id');
        $problemName = $this->_getParam('problem');
        $tool = $this->_getParam('tool');

		global $mysession;
			
		if ($mysession->db_host == 'localhost' && $mysession->db_username == 'joker' && $mysession->db_dbname == 'ldvreports')
		{		
		  echo "<br><font color=red size=+2>Statistics server shows its default layout. Choose the your one if you want (see link to the form above)!</font><br>";
        }

        $this->_db = new Zend_Db_Adapter_Pdo_Mysql(array(
          'host'     => $mysession->db_host,
          'username' => $mysession->db_username,
          'password' => $mysession->db_password,
          'dbname'   => $mysession->db_dbname
        ));

        $statistics = new Application_Model_StatsMapper(array('db' => $this->_db));
        $this->view->entries = $statistics->getErrorDesc($kernelId, $modelId, $toolsetId, $problemName, $tool);
    }

    public function showsafeunsafeAction()
    {
		$kernelId = $this->_getParam('kernel id');
		$modelId = $this->_getParam('model id');
		$toolsetId = $this->_getParam('toolset id');
        $show = $this->_getParam('show');
        
		global $mysession;
			
		if ($mysession->db_host == 'localhost' && $mysession->db_username == 'joker' && $mysession->db_dbname == 'ldvreports')
		{		
		  echo "<br><font color=red size=+2>Statistics server shows its default layout. Choose the your one if you want (see link to the form above)!</font><br>";
        }

        $this->_db = new Zend_Db_Adapter_Pdo_Mysql(array(
          'host'     => $mysession->db_host,
          'username' => $mysession->db_username,
          'password' => $mysession->db_password,
          'dbname'   => $mysession->db_dbname
        ));

        $statistics = new Application_Model_StatsMapper(array('db' => $this->_db));
        $this->view->entries = $statistics->getSafeUnsafeDesc($kernelId, $modelId, $toolsetId, $show);
    }
    
    
    public function signdbAction()
    {
	
        $request = $this->getRequest();
        $form    = new Application_Form_Db();
        if ($this->getRequest()->isPost()) 
        {
            if ($form->isValid($request->getPost())) 
            {
				$database_connection = $form->getValues();
                
                global $mysession;
                $mysession->db_host = $database_connection['host'];
				$mysession->db_username = $database_connection['user'];
				$mysession->db_password = $database_connection['user password'];
				$mysession->db_dbname = $database_connection['name'];             

                return $this->_helper->redirector('index');
            }
        }

        $this->view->form = $form;
    }
}



