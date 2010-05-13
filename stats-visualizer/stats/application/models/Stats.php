<?php

class Application_Model_Stats
{
    protected $_driver;
    protected $_kernel;
    protected $_model;
    protected $_toolset;
    protected $_module;
    protected $_environmentModel;
    protected $_verdict;
    protected $_errorTrace;
    
    public function __construct(array $options = null)
    {
        if (is_array($options)) 
        {
            $this->setOptions($options);
        }
    }

    public function __set($name, $value)
    {
        $method = 'set' . $name;
        
        if (('mapper' == $name) || !method_exists($this, $method)) 
        {
            throw new Exception('Invalid stats property');
        }
        
        $this->$method($value);
    }

    public function __get($name)
    {
        $method = 'get' . $name;
        
        if (('mapper' == $name) || !method_exists($this, $method)) 
        {
            throw new Exception('Invalid stats property');
        }
        
        return $this->$method();
    }

    public function setOptions(array $options)
    {
        $methods = get_class_methods($this);
        
        foreach ($options as $key => $value) 
        {
            $method = 'set' . ucfirst($key);
            
            if (in_array($method, $methods)) 
            {
                $this->$method($value);
            }
        }
        
        return $this;
    }

    public function setDriver($driver)
    {
        $this->_driver = (string)$driver;
        return $this;
    }

    public function getDriver()
    {
        return $this->_driver;
    }
    
    public function setKernel($kernel)
    {
        $this->_kernel = (string)$kernel;
        return $this;
    }

    public function getKernel()
    {
        return $this->_kernel;
    }
    
    public function setModel($model)
    {
        $this->_model = (string)$model;
        return $this;
    }

    public function getModel()
    {
        return $this->_model;
    }    
    
    public function setToolset($toolset)
    {
        $this->_toolset = (string)$toolset;
        return $this;
    }

    public function getToolset()
    {
        return $this->_toolset;
    }  
    
    public function setModule($module)
    {
        $this->_module = (string)$module;
        return $this;
    }

    public function getModule()
    {
        return $this->_module;
    }  
    
    public function setEnvironmentModel($environmentModel)
    {
        $this->_environmentModel = (string)$environmentModel;
        return $this;
    }

    public function getEnvironmentModel()
    {
        return $this->_environmentModel;
    }  
    
    public function setVerdict($verdict)
    {
        $this->_verdict = (string)$verdict;
        return $this;
    }

    public function getVerdict()
    {
        return $this->_verdict;
    }  
    
    public function setErrorTrace($errorTrace)
    {
		$errorTrace = new Application_Model_Errortrace(array('errorTrace' => $errorTrace));
        $this->_errorTrace = array('1' => $errorTrace);
        return $this;
    }

    public function getErrorTrace()
    {
        return $this->_errorTrace;
    }  
}

