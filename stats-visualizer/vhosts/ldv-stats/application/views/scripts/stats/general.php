<?php
/*
 * Copyright (C) 2010-2012
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
  return (returnProfile($info) == 'git');
}

// Print data from some array to the screen in the CSV format.
function printCSV($data) {
  foreach ($data as $row) {
    echo implode(';', $row);
    echo "<br>";
  }
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
  printPageSize();
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

// Print size for a given page.
function printPageSize() {
  echo "<div class='SSInfoHeader'>Page size is <span id='PageSize'></span> bytes</div>";
  // !!!! Print show/hide plugin for auxiliary information. By default it's shown.
  echo "<script type='text/javascript'>
          $(document).ready(function() {
            $('#PageSize').append(number_format($('html').html().length, 0, '', ' '));
          });
          function number_format (number, decimals, dec_point, thousands_sep) {
            // http://kevin.vanzonneveld.net
            // +   original by: Jonas Raoni Soares Silva (http://www.jsfromhell.com)
            // +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
            // +     bugfix by: Michael White (http://getsprink.com)
            // +     bugfix by: Benjamin Lupton
            // +     bugfix by: Allan Jensen (http://www.winternet.no)
            // +    revised by: Jonas Raoni Soares Silva (http://www.jsfromhell.com)
            // +     bugfix by: Howard Yeend
            // +    revised by: Luke Smith (http://lucassmith.name)
            // +     bugfix by: Diogo Resende
            // +     bugfix by: Rival
            // +      input by: Kheang Hok Chin (http://www.distantia.ca/)
            // +   improved by: davook
            // +   improved by: Brett Zamir (http://brett-zamir.me)
            // +      input by: Jay Klehr
            // +   improved by: Brett Zamir (http://brett-zamir.me)
            // +      input by: Amir Habibi (http://www.residence-mixte.com/)
            // +     bugfix by: Brett Zamir (http://brett-zamir.me)
            // +   improved by: Theriault
            // +      input by: Amirouche
            // +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
            // *     example 1: number_format(1234.56);
            // *     returns 1: '1,235'
            // *     example 2: number_format(1234.56, 2, ',', ' ');
            // *     returns 2: '1 234,56'
            // *     example 3: number_format(1234.5678, 2, '.', '');
            // *     returns 3: '1234.57'
            // *     example 4: number_format(67, 2, ',', '.');
            // *     returns 4: '67,00'
            // *     example 5: number_format(1000);
            // *     returns 5: '1,000'
            // *     example 6: number_format(67.311, 2);
            // *     returns 6: '67.31'
            // *     example 7: number_format(1000.55, 1);
            // *     returns 7: '1,000.6'
            // *     example 8: number_format(67000, 5, ',', '.');
            // *     returns 8: '67.000,00000'
            // *     example 9: number_format(0.9, 0);
            // *     returns 9: '1'
            // *    example 10: number_format('1.20', 2);
            // *    returns 10: '1.20'
            // *    example 11: number_format('1.20', 4);
            // *    returns 11: '1.2000'
            // *    example 12: number_format('1.2000', 3);
            // *    returns 12: '1.200'
            // *    example 13: number_format('1 000,50', 2, '.', ' ');
            // *    returns 13: '100 050.00'
            // Strip all characters but numerical ones.
            number = (number + '').replace(/[^0-9+\-Ee.]/g, '');
            var n = !isFinite(+number) ? 0 : +number,
              prec = !isFinite(+decimals) ? 0 : Math.abs(decimals),
              sep = (typeof thousands_sep === 'undefined') ? ',' : thousands_sep,
              dec = (typeof dec_point === 'undefined') ? '.' : dec_point,
              s = '',
              toFixedFix = function (n, prec) {
                var k = Math.pow(10, prec);
                return '' + Math.round(n * k) / k;
              };
            // Fix for IE parseFloat(0.55).toFixed(0) = 0;
            s = (prec ? toFixedFix(n, prec) : '' + Math.round(n)).split('.');
            if (s[0].length > 3) {
              s[0] = s[0].replace(/\B(?=(?:\d{3})+(?!\d))/g, sep);
            }
            if ((s[1] || '').length < prec) {
              s[1] = s[1] || '';
              s[1] += new Array(prec - s[1].length + 1).join('0');
            }
            return s.join(dec);
          }
        </script>";
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

// Return profile used.
function returnProfile($info) {
  if (array_key_exists('Profile', $info)) {
    $profileOptions = $info['Profile'];
    return $profileOptions['name'];
  }

  return '';
}

?>
