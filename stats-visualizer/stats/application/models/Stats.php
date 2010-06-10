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
    protected $_buildStatus;
    protected $_buildProblems;
    protected $_maingenStatus;
    protected $_maingenProblems;
    protected $_dscvStatus;
    protected $_dscvProblems;
    protected $_riStatus;
    protected $_riProblems;
    protected $_rcvStatus;
    protected $_rcvProblems;
        
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
        $this->_modelId = $modelId;
        if (!isset($modelId))
        {
		  $this->_modelName = 'Sorry, i\'m not a key...';	
		}
		else
		{
          $this->_modelName = (string)$modelName;
        }
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
        $this->_verdict = $verdict;
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
        
    public function setBuildStatus($buildStatus)
    {
        $this->_buildStatus = $buildStatus;
        return $this;
    }

    public function getBuildStatus()
    {
        return $this->_buildStatus;
    }  
        
    public function setBuildProblems($buildProblems)
    {
        $this->_buildProblems = $buildProblems;
        return $this;
    }

    public function getBuildProblems()
    {
        return $this->_buildProblems;
    }         
        
    public function setMaingenStatus($maingenStatus)
    {
        $this->_maingenStatus = $maingenStatus;
        return $this;
    }

    public function getMaingenStatus()
    {
        return $this->_maingenStatus;
    }  
        
    public function setMaingenProblems($maingenProblems)
    {
        $this->_maingenProblems = $maingenProblems;
        return $this;
    }

    public function getMaingenProblems()
    {
        return $this->_maingenProblems;
    }         
        
    public function setDscvStatus($dscvStatus)
    {
        $this->_dscvStatus = $dscvStatus;
        return $this;
    }

    public function getDscvStatus()
    {
        return $this->_dscvStatus;
    }               
        
    public function setDscvProblems($dscvProblems)
    {
        $this->_dscvProblems = $dscvProblems;
        return $this;
    }

    public function getDscvProblems()
    {
        return $this->_dscvProblems;
    }         
        
    public function setRiStatus($riStatus)
    {
        $this->_riStatus = $riStatus;
        return $this;
    }

    public function getRiStatus()
    {
        return $this->_riStatus;
    }               
        
    public function setRiProblems($riProblems)
    {
        $this->_riProblems = $riProblems;
        return $this;
    }

    public function getRiProblems()
    {
        return $this->_riProblems;
    }         
        
    public function setRcvStatus($rcvStatus)
    {
        $this->_rcvStatus = $rcvStatus;
        return $this;
    }

    public function getRcvStatus()
    {
        return $this->_rcvStatus;
    }         
        
    public function setRcvProblems($rcvProblems)
    {
        $this->_rcvProblems = $rcvProblems;
        return $this;
    }

    public function getRcvProblems()
    {
        return $this->_rcvProblems;
    }         

        
/*
    public function setProblem($problem)
    {
        $this->_problem[] = $problem;
        return $this;
    }

    public function getProblem()
    {
        return $this->_problem;
    }   
        
    public function setProblemUnmatched($problemUnmatched)
    {
        $this->_problemUnmatched = $problemUnmatched;
        return $this;
    }

    public function getProblemUnmatched()
    {
        return $this->_problemUnmatched;
    } 
*/
}

