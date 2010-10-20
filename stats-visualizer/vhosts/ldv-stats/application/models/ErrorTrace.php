<?php

class Application_Model_ErrorTrace extends Application_Model_General
{
  protected $_errorTraceRaw;
  protected $_sourceCodeFiles;
  protected $_engine;
  protected $_errorTrace;

  public function setErrorTraceRaw($errorTrace)
  {
    $this->_errorTraceRaw = $errorTrace;
    return $this;
  }

  public function getErrorTraceRaw()
  {
    return $this->_errorTraceRaw;
  }

  public function setErrorTrace($errorTrace)
  {
    $this->_errorTrace = $errorTrace;
    return $this;
  }

  public function getErrorTrace()
  {
    return $this->_errorTrace;
  }

  public function setSourceCodeFiles($sourceCodeFiles)
  {
    $this->_sourceCodeFiles = $sourceCodeFiles;
    return $this;
  }

  public function getSourceCodeFiles()
  {
    return $this->_sourceCodeFiles;
  }

  public function setEngine($engine)
  {
    $this->_engine = $engine;
    return $this;
  }

  public function getEngine()
  {
    return $this->_engine;
  }
}
