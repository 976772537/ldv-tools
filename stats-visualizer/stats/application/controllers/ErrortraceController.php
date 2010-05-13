<?php

class ErrortraceController extends Zend_Controller_Action
{
	public $_errorTrace;
	
    public function init()
    {
        /* Initialize action controller here */
    }

    public function indexAction()
    {
		$ref = $this->_getParam('ref');
		print($ref);
		print("HIE");
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



