<?php

// Count the number of tree leaves for a given array.
function countLeaves($array) {
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
    $subtreeSize += countLeaves($value);
  }

  return $subtreeSize;
}

// Format bytes text.
function formatBytes($bytes) {
  return number_format($bytes, 0, '', ' ');
}

// Format loc text.
function formatLoc($loc) {
  return number_format($loc, 0, '', ' ');
}

// Format time text.
function formatTime($time) {
  return number_format(($time / 1000), 2, ',', ' ');
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
  echo "<div class='SSInfoHeader'>Current database connection options</div>";
  echo "<div class='SSInfoBody'>";
  foreach ($dbConnectionOptions as $option => $value) {
    if ($option != 'profiler') {
      echo "$option = '$value'<br />";
    }
  }
  echo "</div>";
}

// Print different auxiliary info for a given page.
function printInfo($info) {
  // Print show/hide plugin for auxiliary information. By default it's shown.
  echo "<script type='text/javascript'>
          $(document).ready(function() {
            $('#SSInfoShowHideLink').toggle(function() {
              $('#SSInfo').hide();
              return false;
            }, function() {
              $('#SSInfo').show();
              return false;
            });
          });
        </script>";

  echo "<div id='SSInfoShowHide'><a href='#' id='SSInfoShowHideLink'>Auxiliary information</a></div>";

  echo "<div id='SSInfo'>";

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
  echo "</div>";
}

// Obtain a time when a page was created and find a page generation time.
function printPageGenerationTime() {
  $endtime = explode(' ', microtime());
  $global = new Zend_Session_Namespace();
  $totaltime = $endtime[0] +  $endtime[1] - $global->startTime;
  printf("<div class='SSInfoHeader'>Page generated in %.1f seconds (the maximum execution time is %.1f seconds)</div>",  $totaltime, ini_get('max_execution_time'));
}

// Obtain the session peak application memory usage and compare it with the
// memory limit.
function printPageMemoryUsage() {
  echo "<div class='SSInfoHeader'>Application peak memory usage through the given session is " . formatBytes(memory_get_peak_usage()) . " bytes (the memory limit is " . formatBytes(returnBytes(ini_get('memory_limit'))) . " bytes)</div>";
}

// Print information on a current profile.
function printProfileInfo($profileOptions) {
  echo "<div class='SSInfoHeader'>Current profile</div>";
  echo "<div class='SSInfoBody'>";
  foreach ($profileOptions as $option => $value) {
    echo "$option = '$value'<br />";
  }
  echo "</div>";
}

// Print restrictions for a given page if so.
function printRestrictionsInfo($restrictions) {
  if (count($restrictions)) {
    echo "<div class='SSInfoHeader'>Current page restrictions</div>";
    echo "<div class='SSInfoBody'>";
    foreach ($restrictions as $restriction => $value) {
      echo "$restriction = '$value'<br />";
    }
    echo "</div>";
  }
}

// Convert kilo, mega, giga bytes simply to bytes.
function returnBytes($val) {
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
