<?php

class Application_Model_Stats
{
    protected $_driverId;
    protected $_driverName;
    protected $_kernelId;
    protected $_kernelName;
    protected $_modelId;
    protected $_modelName;
    protected $_toolsetId;
    protected $_toolsetName;
    protected $_scenarioId;
    protected $_moduleName;
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

    public function setDriver($driverId, $driverName)
    {
        $this->_driverId = (string)$driverId;
        $this->_driverName = (string)$driverName;
        return $this;
    }

    public function getDriverId()
    {
        return $this->_driverId;
    }

    public function getDriverName()
    {
        return $this->_driverName;
    }    
    
    public function setKernel($kernelId, $kernelName)
    {
        $this->_kernelId = (string)$kernelId;
        $this->_kernelName = (string)$kernelName;
        return $this;
    }

    public function getKernelId()
    {
        return $this->_kernelId;
    }

    public function getKernelName()
    {
        return $this->_kernelName;
    }  
    
    public function setModel($modelId, $modelName)
    {
        $this->_modelId = (string)$modelId;
        $this->_modelName = (string)$modelName;
        return $this;
    }

    public function getModelId()
    {
        return $this->_modelId;
    }

    public function getModelName()
    {
        return $this->_modelName;
    }    
    
    public function setToolset($toolsetId, $toolsetName)
    {
        $this->_toolsetId = (string)$toolsetId;
        $this->_toolsetName = (string)$toolsetName;
        return $this;
    }

    public function getToolsetId()
    {
        return $this->_toolsetId;
    }

    public function getToolsetName()
    {
        return $this->_toolsetName;
    }    
    
    public function setScenario($scenarioId, $moduleName, $environmentModel)
    {
        $this->_scenarioId = (string)$scenarioId;
        $this->_moduleName = (string)$moduleName;
        $this->_environmentModel = (string)$environmentModel;
        return $this;
    }

    public function getScenarioId()
    {
        return $this->_scenarioId;
    }

    public function getModuleName()
    {
        return $this->_moduleName;
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

