<?php
/*
 * Copyright 2010-2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
