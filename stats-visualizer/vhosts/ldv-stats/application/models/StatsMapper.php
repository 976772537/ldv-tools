<?php

class Application_Model_StatsMapper extends Application_Model_GeneralMapper
{
  public function getPageStats($profile, $pageName)
  {
    print_r($profile->getPage($pageName));
    
  }
}
