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

// Get url.
$linuxtesting = new Zend_Config_Ini(APPLICATION_PATH . '/configs/data.ini', 'linuxtesting');
$GLOBALS['url'] = $linuxtesting->link;
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

 /*
  * Function returns name of the user if user has logged into the linuxtesting in current session and FALSE otherwise.
  */
  function checkIfLogin($cookie)
  {
  	$url = $GLOBALS['url'];
  	$result = curlGetRequestByCookie($url . "user", $cookie);
  	if (!preg_match("/My account/", $result, $array))
	{
		return "";
	}
	if (preg_match("/<title>(.+) \| Linux Verification Center<\/title>/", $result, $array))
	{
		return $array[1];
	}
	return "";
  }

 /*
  * Checks if current user is editor.
  */
  function checkUserRights($name, $cookie)
  {
  	$url = $GLOBALS['url'];

  	// Check first page.
  	$result = curlGetRequestByCookie($url . "user_list/4");
  	if (preg_match("/$name/", $result, $array))
	{
		return TRUE;
	}

	// Check next pages.
	while (preg_match("/<li class=\"pager-next\"><a href=\"(.+)\" title=\"Go to next page\"/", $result, $array))
	{
		$url_tmp = $array[1];
		$result = curlGetRequestByCookie($url_tmp);
		if (preg_match("/$name/", $result, $array))
		{
			return TRUE;
		}
	}
	return FALSE;
  }

 /*
  * Function executes curl GET request for selected url and known cookie.
  * Returns content of url after executing GET request.
  */
  function curlGetRequestByCookie($url, $cookie)
  {
    // Init curl.
	$curl = curl_init();

	// Set parameters.
	curl_setopt($curl, CURLOPT_URL, $url);
	curl_setopt($curl, CURLOPT_COOKIESESSION, FALSE);
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, TRUE);
	curl_setopt($curl, CURLOPT_COOKIEJAR, "cookie.txt");
	curl_setopt($curl, CURLOPT_COOKIEFILE, 'cookie.txt');
	curl_setopt($curl, CURLOPT_COOKIE, "$cookie");
	// Execute request.
	$result = curl_exec($curl);

	// Close connection.
	curl_close($curl);

	return $result;
  }

 /*
  * Function logins on selected url by POST curl request.
  * In case of success returns Success and sets cookie field.
  * Otherwise returns error message.
  */
  function curlLogin($name, $pass)
  {
  	$url = $GLOBALS['url'];
  	// Init curl.
  	$curl = curl_init();

	$data = array('name' => $name, 'pass' => $pass, 'form_id' => 'user_login');
	$processedData = http_build_query($data);

  	// Set parameters.
	curl_setopt($curl, CURLOPT_URL, $url . "user/login");  
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, true); 
	curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1);
	curl_setopt($curl, CURLOPT_COOKIEJAR, "cookie.txt");
	curl_setopt($curl, CURLOPT_COOKIEFILE, 'cookie.txt');
	curl_setopt($curl, CURLOPT_POST, 1);
	curl_setopt($curl, CURLOPT_POSTFIELDS, "$processedData");
	curl_setopt($curl, CURLOPT_HEADER, TRUE);
	curl_setopt($curl, CURLOPT_COOKIESESSION, FALSE);

	// Execute curl POST request.
	$result = curl_exec($curl);

	// Close connection.
	curl_close($curl);

	// Check for errors.
	if (preg_match("/Sorry, unrecognized username or password./", $result, $array))
	{
		return "Unrecognized username or password";
	}
	elseif (preg_match("/(\w+) field is required/", $result, $array))
	{
		return "$array[1] field is required";
	}
	elseif (!preg_match("/My account/", $result, $array))
	{
		return "Cannot connect to $url/user/login";
	}

	// Login successful.

	// Get cookie.
	$cookie = "";
	if (preg_match_all("/Set-Cookie: (.+); expires=/", $result, $matches))
	{
		foreach ($matches[1] as $val)
		{
			$cookie = $val;
		}
	}

	// Create global cookie.
	$_SESSION['cookie'] = $cookie;

	return "Success";
  }

 /*
  * Function logouts current user.
  */
  function curlLogout($cookie)
  {
  	$url = $GLOBALS['url'];

  	// Init curl.
  	$curl = curl_init();
  	
  	// Set parameters.
	curl_setopt($curl, CURLOPT_URL, $url . "logout");  
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, true); 
	curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1);
	curl_setopt($curl, CURLOPT_COOKIEJAR, "cookie.txt");
	curl_setopt($curl, CURLOPT_COOKIEFILE, 'cookie.txt');
	curl_setopt($curl, CURLOPT_POST, 1);
	curl_setopt($curl, CURLOPT_COOKIESESSION, FALSE);
	curl_setopt($curl, CURLOPT_COOKIE, "$cookie");
	// Execute curl POST request.
	$result = curl_exec($curl);
	
	// Close connection.
	curl_close($curl);

	// Remove global cookie.
	unset ($_SESSION['cookie']);

  }

// Get cookie from Session global variable.
if (isset($_SESSION['cookie']))
{
	$cookie = $_SESSION['cookie'];
}

// Get page URI.
$ADDR_SELF = $_SERVER['REQUEST_URI'];

// Check if there were any POST requests for login/logout.
if (isset($_POST['authorization_action']))
	$authorization_action = $_POST['authorization_action'];

// Get error message (in case it exists).
$errorMessage = '';
if (isset($_GET['error']))
{
	$errorMessage = $_GET['error'];
	$ADDR_SELF = substr($ADDR_SELF, 0, strpos($ADDR_SELF, "?error=")); // Delete error from page's address.
}

// Logout authorization_action.
if (isset($authorization_action) && $authorization_action == "logout")
{
	curlLogout($cookie);
	header("Location: $ADDR_SELF");
}

// Login authorization_action.
if (isset($authorization_action) && $authorization_action == "login")
{
	$name = $_POST['name'];
	$pass = $_POST['pass'];
	$result = curlLogin($name, $pass);
	if ($result == "Success")
	{
		$result = checkUserRights($name, $_SESSION['cookie']);
		if ($result)
		{
			header("Location: $ADDR_SELF");
		}
		else
		{
			$error = "User '$name' is not an Editor on linuxtesting";
			unset ($_SESSION['cookie']);
			header("Location: $ADDR_SELF?error=$error");
		}
	}
	else
	{
		header("Location: $ADDR_SELF?error=$result");
	}
}

function loginForm($errorMessage)
{
	global $ADDR_SELF;
	?>
	<form authorization_action="<?php print($ADDR_SELF); ?>" method="post" enctype="multipart/form-data">
	<table>
	<?php if ($errorMessage) { ?>
	<p>
	<tr>
		<td align=middle colspan=1><b>Error: </b></td>
		<td><b><?php print($errorMessage); ?></b></td>
	</tr>
	</p>
	<?php } ?>
	<tr>
	<p>
		<td><b>Username: </b></td>
		<td><input type="name" name="name" value="" size=30></td>
		<td><b>Password: </b></td>
		<td><input type="password" name="pass" value="" size=30></td>
		<td>
			<input type="submit" name="authorization_action" value="login" />
		</td>
	</tr>
	</p>
	</table>
	</form>	
	<?php
}

function logoutForm($user)
{
	global $ADDR_SELF;
	?>
	<form authorization_action="<?php print($ADDR_SELF); ?>" method="post" enctype="multipart/form-data">
	<table>
	<p>
	<tr>
		<td><b>Linuxtesting user: <?php print($user); ?></b></td>
		<td align=middle colspan=3>
			<input type="submit" name="authorization_action" value="logout" />
		</td>
	</tr>
	</p>
	</table>
	</form>	
	<?php
}

// Print login/logout form.
$user = '';
if (isset($cookie))
{
	$user = checkIfLogin($cookie);
	if ($user)
	{
		logoutForm($user);
	}
	else
	{
		loginForm($errorMessage);
	}
}
else
{
	loginForm($errorMessage);
}


?>
