#!/usr/bin/php
<?
	/*
		Call as:
			./writerss.php <versionfile> <build means> <downloadfile> <username> <password> <buildNum>
			
		Ex.:
			./writerss.php build/Stacksmith.app/Contents/Info.plist nightly build/Stacksmith.tgz jeff s3kr1t 21
	*/
	
	date_default_timezone_set('Europe/Berlin');
	$updatemessage = '';
	$buildsinlist = 0;
	$desirednumbuilds = date("N");
	
	for( $x = 0; $buildsinlist < $desirednumbuilds; $x++ )
	{
		$fullurl = str_replace("http://","http://".urlencode($argv[4]).':'.urlencode($argv[5])."@",$_ENV['BUILD_URL'])."/api/xml?wrapper=changes&xpath=//changeSet//comment";
		$matches = array();
		preg_match( "/\\/([0-9]+)\\//", $fullurl, $matches, PREG_OFFSET_CAPTURE );
		$newbuildno = ($matches[1][0] -$x);
		$endoffs = $matches[1][1] +strlen($matches[1][0]);
		$fullurl = substr( $fullurl, 0, $matches[1][1] ).$newbuildno.substr( $fullurl, $endoffs, strlen($fullurl) -$endoffs );
		
		$commitmessages = file_get_contents($fullurl);
		if( strlen($commitmessages) > 0 && strcmp($commitmessages, "<changes/>") != 0 )
		{
			$commitmessages = str_replace("<changes>","&lt;ul&gt;",$commitmessages);
			$commitmessages = str_replace("</changes>","&lt;/ul&gt;",$commitmessages);
			$commitmessages = str_replace("<comment>","&lt;li&gt;",$commitmessages);
			$commitmessages = str_replace("</comment>","&lt;/li&gt;",$commitmessages);
			
			$updatemessage .= "<h3>Build $newbuildno</h3>\n".$commitmessages;
			$buildsinlist++;
		}
		if( $newbuildno == 1 )
			break;
	}
	
	$infoplist = file_get_contents(dirname($argv[0]).'/'.$argv[1]);
	$matches = array();
	preg_match( '/<key>CFBundleVersion<\\/key>[\r\n]*/', $infoplist, $matches, PREG_OFFSET_CAPTURE );
	$newoffs = $matches[0][1] +strlen($matches[0][0]);
	preg_match( '/<string>(.*)?<\\/string>/', $infoplist, $matches, 0, $newoffs );
	$theversion = $matches[1];
	
	$actualversion = $theversion;
	$feedstr = "<?xml version=\"1.0\"?>
<rss version=\"2.0\" 
	xmlns:sparkle=\"http://sparkle.andymatuschak.org/rss/1.0/modules/sparkle/\">
  <channel>
    <title>Stacksmith ".$argv[2]." Appcast</title>
    <link>http://stacksmith.org/</link>
    <description>Updates for Stacksmith</description>
    <item>
       <title>Stacksmith $actualversion</title>
       <link>http://stacksmith.org/nightlies/".basename($argv[3])."</link>
       <description>".$updatemessage."</description>
       <enclosure url=\"http://stacksmith.org/nightlies/".basename($argv[3])."\" length=\"".filesize(dirname($argv[0]).'/'.$argv[3])."\" type=\"application/octet-stream\" />
       <sparkle:version>$actualversion</sparkle:version>
     </item>
  </channel>
</rss>";
	
	$fpath = dirname($argv[0]).'/build/'.$argv[2].'_feed.rss';
	$fd = fopen($fpath,"w");
	fwrite($fd,$feedstr);
	fclose($fd);
?>