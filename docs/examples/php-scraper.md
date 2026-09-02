# PHP API scraping example

A 000000book crawler and basic GML parser by Filipe Cruz ("ps / TPOLM",
<http://tpolm.org/~ps/>).

Kept verbatim as contributed. It targets a long-obsolete PHP and uses the
removed `mysql_*` functions, so treat it as a worked example of walking the
`/data/{id}.gml` endpoint rather than as code to run.

```php
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd">
<HTML>
<HEAD>
<TITLE>GML crawl</TITLE>
</HEAD>
<BODY BGCOLOR=#FFFFFF>
<?php


//include_once('parser_php5.php');

include_once('loader.php');

require('auth.php');

$dbl = mysql_connect($db['host'], $db['user'], $db['password']);
if(!$dbl) {
	die('SQL error...');
}
mysql_select_db($db['database'],$dbl);

//$query = "delete from gml";
mysql_query($query);

echo 'hello world<br /><br />';

function get_url_contents($url){
        $crl = curl_init();
        $timeout = 5;
        curl_setopt ($crl, CURLOPT_URL,$url);
        curl_setopt ($crl, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt ($crl, CURLOPT_CONNECTTIMEOUT, $timeout);
        $ret = curl_exec($crl);
        curl_close($crl);
        return $ret;
}


$ourarray = Array();

if (($_GET['startid']) && ($_GET['endid'])) {

for ($i = $_GET['startid']; $i < $_GET['endid']; $i++)
//$i = 16847;
{

	$thisone = get_url_contents("http://000000book.com/data/".$i.".gml");
	/*$myFile = $i.".gml";
	$fh = fopen($myFile, 'w') or die("can't open file");
	$stringData = "Bobby Bopper\n";
	fwrite($fh, $thisone);
	fclose($fh);*/
		
	/*$some_file = $i.'.gml';
	$fp = fopen($some_file, "r");
	$thisone = fread($fp, filesize($some_file));
	fclose($fp);*/

	$string = explode('<keywords>',$thisone);
	$keywords = explode('</keywords>',$string[1]);
	echo $keywords[0];
	//$ourarray[$i]['keywords'] = $keywords[0];

	$string2 = explode('<location>',$thisone);
	$location = explode('</location>',$string2[1]);
	//echo $keywords[0];
	
	$string3 = explode('<username>',$thisone);
	$username = explode('</username>',$string3[1]);
	//echo $keywords[0];

	$string4 = explode('<author>',$thisone);
	$author = explode('</author>',$string4[1]);

	$query = "update gml set id=".$i.", keywords='".$keywords[0]."', location='".$location[0]."', username='".$username[0]."', author='".$author[0]."' where id=".$i;
	mysql_query($query);
	
	$query = "insert into gml set id=".$i.", keywords='".$keywords[0]."', location='".$location[0]."', username='".$username[0]."', author='".$author[0]."'";
	mysql_query($query);
	
	//dump it on mysql db
}

}

if ($dbl) mysql_close($dbl);

?>
```
