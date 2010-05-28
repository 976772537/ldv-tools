<?php
// Define path to application directory
defined('APPLICATION_PATH')
    || define('APPLICATION_PATH', realpath(dirname(__FILE__) . '/../application'));

// Define application environment
defined('APPLICATION_ENV')
    || define('APPLICATION_ENV', (getenv('APPLICATION_ENV') ? getenv('APPLICATION_ENV') : 'development'));

// Ensure library/ is on include_path
set_include_path(implode(PATH_SEPARATOR, array(
    realpath(APPLICATION_PATH . '/../library'),
    get_include_path(),
)));

/** Zend_Application */
require_once 'Zend/Application.php';

// Create application, bootstrap, and run
$application = new Zend_Application(
    APPLICATION_ENV,
    APPLICATION_PATH . '/configs/application.ini'
);


// TO BE DELETED!!!
// Information about the server default database connection that may be
// override by the user session settings.
$mysession = new Zend_Session_Namespace('mysession');
if (!isset($mysession->db_host)) 
{
//        $databases = new Zend_Config_Ini(APPLICATION_PATH . '/configs/config.ini', 'databases');
//        $dbAdapters = array();
        
//        foreach($databases->db as $config_name => $db)
//        {
//            $dbAdapters[$config_name] = Zend_Db::factory($db->adapter, $db->config->toArray());
//        }
	
  $mysession->db_host = 'localhost';
  $mysession->db_username = 'joker';
  $mysession->db_password = '';
  $mysession->db_dbname = 'ldvreports';
} 

$application->bootstrap()
            ->run();
?>
