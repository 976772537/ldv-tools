<?php

// Print information on a current database connection.
function print_db_info($dbConnectionOptions) {
  echo "<h3>Current database connection options</h3>";
  foreach ($dbConnectionOptions as $option => $value) {
    if ($option != 'profiler') {
      echo "$option = '$value'<br>";
    }
  }
}

// Print different auxiliary info for a given page.
function print_info($info) {
  if (array_key_exists('Restrictions', $info)) {
    print_restrictions_info($info['Restrictions']);
  }
  if (array_key_exists('Profile', $info)) {
    print_profile_info($info['Profile']);
  }
  if (array_key_exists('Database connection', $info)) {
    print_db_info($info['Database connection']);
  }
  print_page_generation_time();
  print_page_memory_usage();
}

// Obtain a time when a page was created and find a page generation time.
function print_page_generation_time() {
  $endtime = explode(' ', microtime());
  $global = new Zend_Session_Namespace();
  $totaltime = $endtime[0] +  $endtime[1] - $global->startTime;
  printf('<h3>Page generated in %.1f seconds (the maximum execution time is %.1f seconds)</h3>',  $totaltime, ini_get('max_execution_time'));
}

// Obtain the session peak application memory usage and compare it with the
// memory limit.
function print_page_memory_usage() {
  echo "<h3>Application peak memory usage through the given session is " . number_format(memory_get_peak_usage(), 0, ',', ' ') . " bytes (the memory limit is " . number_format(return_bytes(ini_get('memory_limit')), 0, ',', ' ') . " bytes)</h3>";
}

// Print information on a current profile.
function print_profile_info($profileOptions) {
  echo "<h3>Current profile</h3>";
  foreach ($profileOptions as $option => $value) {
    echo "$option = '$value'<br>";
  }
}

// Print restrictions for a given page if so.
function print_restrictions_info($restrictions) {
  if (count($restrictions)) {
    echo "<h3>Current page restrictions</h3>";
    foreach ($restrictions as $restriction => $value) {
      echo "$restriction = '$value'<br>";
    }
}
}

// Convert kilo, mega, giga bytes simply to bytes.
function return_bytes($val) {
  $val = trim($val);
  $last = strtolower($val[strlen($val) - 1]);

  switch ($last) {
    case 'g':
      $val *= 1024;
    case 'm':
      $val *= 1024;
    case 'k':
      $val *= 1024;
  }

  return $val;
}

?>
