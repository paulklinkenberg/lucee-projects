<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title>Webserver2Tomconfig file to get it's settings fromcatVHostCopier test page</title>
	<style type="text/css">
		body { font-size:12px; font-family:Verdana, Geneva, sans-serif; }
		pre { background-color:#eee; padding:5px; width:auto; }
	</style>
</head>
<body>
	<h1>Test page for the Webserver2TomcatVHostCopier</h1>

	<cfif structKeyExists(form, "configdata")>
		<h3>Your test results</h3>
		<cfif fileExists('parserLog.log')>
			<cfset fileDelete('parserLog.log') />
			<em>parser log was cleared</em><br />
		</cfif>
		<cfset fileWrite('config.conf', form.configdata) />
		<cfset new Webserver2TomcatVHostCopier().copyWebserverVHosts2Tomcat(testOnly=true) />
		<br />--&gt; Don't forget to look at the parser log underneath this page!
	</cfif>
	
	<h3>Test it</h3>
	<p>The VHostCopier uses a config file to read the settings from.<br />
	If you want to test the functionality, then please edit the following config file, and press "TEST".</p>
	
	<form method="post" action="test.cfm">
		<textarea cols="60" rows="8" name="configdata"><cfif fileExists('config.conf')><cfoutput>#fileRead('config.conf')#</cfoutput></cfif></textarea>
		<br /><input type="submit" value="TEST" />
	</form>
	
	<h3>Example config</h3>
	<pre>
webservertype=IIS7 (or IIS6 or Apache)
httpdfile=/private/etc/apache2/httpd.conf
IIS7File=%systemroot%\System32\inetsrv\config\applicationHost.config
IIS6File=%systemroot%\System32\inetsrv\Metabase.xml
tomcatrootpath=/Applications/tomcat/
tomcatport=8080
hostmanagerusername=NAME
hostmanagerpassword=PASSWORD</pre>
	<em>(which lines are actually used depends on the first line, 'webservertype'):</em>
	
	<h3>Parser log</h3>
	<cfif fileExists('parserLog.log')>
		<cfoutput><textarea cols="100" rows="8">#fileRead('parserLog.log')#</textarea></cfoutput>
	<cfelse>
		<em>no log created</em>
	</cfif>

	<h3>Requirements</h3>
	<ul>
		<li>The tomcat hostmanager must be enabled and running. Check this by going to http://localhost:8080/host-manager/html (or your own custom tomcat port)</li>
		<li>You must have a valid user for the host-manager: add or edit the file {tomcat installation directory}/conf/tomcat-users.xml to contain the following:<br />
			&lt;tomcat-users&gt;&lt;role rolename=&quot;manager&quot;/&gt;&lt;role rolename=&quot;admin&quot;/&gt;&lt;user name=&quot;SOME NAME&quot; password=&quot;SOME PASSWORD&quot; roles=&quot;admin,manager&quot;/&gt;&lt;/tomcat-users&gt;</li>
		<li>createObject() function must be allowed (not sandboxed)</li>
		<li>&lt;cfinvoke&gt; tag must be allowed (not sandboxed)</li>
		<li>Railo must have read access to the Apache or IIS config files (you will supply the paths in the next step, so you will know what paths to allow)</li>
		<li>Railo must have write access to Tomcat's server.xml file</li>
	</ul>
</body>
</html>