<?php

@apache_setenv('no-gzip', 1);
@ini_set('zlib.output_compression', 0);
@ini_set('implicit_flush', 1);

/*
 *
 * Prior to running this script it is important that you have built ../apps/boot-str at least once
 * 
 * this script modifys the name and then performs an upload, it does not build anything
 * 
 * we log who site names updated withthis script and the admin name to log.txt so we can checkout their sites
 * this file is also used as a lock, as only one upload may happen at a time.
 * 
 * You can find a working version of this script with hopefully the latest version of boot-str and aelua
 * http://www.wetgenes.com/bootstrapp.php
 * 
 * So really this is all hax tbh, pleaze no use :)
 *
 */

if(isset($_POST['name']))
{



$fp = fopen("log.txt", "a");

if($fp && flock($fp, LOCK_EX | LOCK_NB)) { // exclusive file access

$names=explode(",",$_POST['name']);

foreach($names as $k => $name)
{
        
$name=substr($name,0,64);
$email=substr($_POST['email'],0,64);
$pass=substr($_POST['pass'],0,64);

$allow="/[^A-Za-z0-9\.\@\-\_\+]/"; // very restrictive
$name =preg_replace($allow,"",$name);
$email=preg_replace($allow,"",$email);
$pass =preg_replace($allow,"",$pass);


echo("name:".$name."<br/>");
echo("email:".$email."<br/>");
//echo("pass:".$pass."<br/>");
echo("pass:*hidden*<br/>");

$fpc=fopen("../apps/boot-str/.war/WEB-INF/appengine-web.xml","w");
if($fpc)
{
	fwrite($fpc,"<appengine-web-app xmlns='http://appengine.google.com/ns/1.0'>
	  <application>$name</application>
	  <version>1</version>
      <threadsafe>true</threadsafe>
	</appengine-web-app>
	");
	fclose($fpc);
}
else
{
    die("<pre>something went wrong please notify the admin</pre>");
}

$output = shell_exec("cd ../apps/boot-str/ ; echo '$pass' | ../../appengine-java-sdk/bin/appcfg.sh --email=$email update .war");
echo "<pre>$output</pre>";

echo "If everything went OK above then visit <a href='http://$name.appspot.com/'>http://$name.appspot.com/</a> to continue your setup.<br/><br/>";

$time=date('Y-m-d H:i:s');
fwrite($fp,"$name updated by $email on $time\n");
flush();
}

    flock($fp, LOCK_UN); // release the lock
    
} else {
	
    die("<pre>we are busy please try again in a minute</pre>");
}

fclose($fp);

}
else
{

// display a bad html form
?>
<html>
<head>

<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/> 
	
		<title>Bootstrapping BootStrApp</title> 
		
		<link rel="stylesheet" type="text/css" href="http://boot-str.appspot.com/css/base/aelua.css" /> 
		<link rel="stylesheet" type="text/css" href="http://boot-str.appspot.com/.css" />
		
</head>
<body>
<a name="top"></a><div id="menu"><ul><li><a href="http://boot-str.appspot.com/" class="menubutt">Welcome</a></li><li><a href="http://boot-str.appspot.com/about" class="menubutt">About</a></li><li><a href="http://boot-str.appspot.com/install" class="menubutt">Install</a></li><li><a href="http://boot-str.appspot.com/directory" class="menubutt">Directory</a></li></ul><div class="clear"></div></div>

<div class="cont">
	This convenience script will install <a href="http://boot-str.appspot.com/">BootStrApp</a> to an appengine app remotely. Removing the need for you to setup the java JDK and the appengine SDK on a local machine.
<br /><br />
	<b>If you feel you could manage this yourself then please do not use this script!</b>
<br /><br />
	We need to know the app-name, as in app-name.appspot.com, this is a unique identifier of an app.<br /><br />
	We also need to know an email and password for a google account that has the power to update this app.<br /><br />
	We strongly suggest making a temporary account with this power and then changing its password after you use this form. We do not store the password but using this form is not a secure act.
<br /><br />
	After submiting the form, you will probably have to wait a minute or so while the app uploads before being told that everything went fine, so please be patient and watch that spinning mouse pointer. This length of time depends on appengine and can be many minutes.
<br /><br />

<form action="" method="post">
    app-name:  <input type="text" name="name" /><br />
    email: <input type="text" name="email" /><br />
    password:  <input type="password" name="pass" /><br />
    <input type="submit" name="submit" value="update" />
</form>
</div>
</body>
<?php

}
