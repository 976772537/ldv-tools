<?php

class Application_Model_Errortrace extends Application_Model_Stats
{
    protected $_errorTrace;
    
    public function setErrorTrace($errorTrace)
    {
        $this->_errorTrace = $errorTrace;
        return $this;
    }    
}

