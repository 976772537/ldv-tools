<?php

// Count the number of tree leaves for a given array.
function count_leaves($array) {
  if (is_null($array)) {
    return 0;
  }

  // Reach a leaf.
  if (!count(array_keys($array))) {
    return 1;
  }

  // Count the number of subtree leaves.
  $subtreeSize = 0;
  foreach ($array as $value) {
    $subtreeSize += count_leaves($value);
  }

  return $subtreeSize;
}

// Says whether the git profile is used.
function isGit($info) {
  if (array_key_exists('Profile', $info)) {
    $profileOptions = $info['Profile'];
    return ($profileOptions['name'] == 'git');
  }

  return false;
}

// Print information on a current database connection.
function printDbInfo($dbConnectionOptions) {
  echo "<h3>Current database connection options</h3>";
  foreach ($dbConnectionOptions as $option => $value) {
    if ($option != 'profiler') {
      echo "$option = '$value'<br>";
    }
  }
}

// Print different auxiliary info for a given page.
function printInfo($info) {
  if (array_key_exists('Restrictions', $info)) {
    printRestrictionsInfo($info['Restrictions']);
  }
  if (array_key_exists('Profile', $info)) {
    printProfileInfo($info['Profile']);
  }
  if (array_key_exists('Database connection', $info)) {
    printDbInfo($info['Database connection']);
  }
  printPageGenerationTime();
  printPageMemoryUsage();
}

// Obtain a time when a page was created and find a page generation time.
function printPageGenerationTime() {
  $endtime = explode(' ', microtime());
  $global = new Zend_Session_Namespace();
  $totaltime = $endtime[0] +  $endtime[1] - $global->startTime;
  printf('<h3>Page generated in %.1f seconds (the maximum execution time is %.1f seconds)</h3>',  $totaltime, ini_get('max_execution_time'));
}

// Obtain the session peak application memory usage and compare it with the
// memory limit.
function printPageMemoryUsage() {
  echo "<h3>Application peak memory usage through the given session is " . number_format(memory_get_peak_usage(), 0, ',', ' ') . " bytes (the memory limit is " . number_format(return_bytes(ini_get('memory_limit')), 0, ',', ' ') . " bytes)</h3>";
}

// Print information on a current profile.
function printProfileInfo($profileOptions) {
  echo "<h3>Current profile</h3>";
  foreach ($profileOptions as $option => $value) {
    echo "$option = '$value'<br>";
  }
}

// Print restrictions for a given page if so.
function printRestrictionsInfo($restrictions) {
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
