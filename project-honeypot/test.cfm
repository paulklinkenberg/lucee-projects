<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title>Project Honeypot LinkGenerator tester</title>
	<style type="text/css">
		.border { border:1px solid #00F; padding:5px; }
	</style>
</head>
<body>
	<p style="border:1px solid #000;padding:10px;margin: 10px 5px;text-align:center; font:12px Arial;">
		<cfoutput>This test file is part of the Project Honeypot Coldfusion Link generator.<br /><br /></cfoutput>
		<strong>Project page:</strong> <a href="http://www.coldfusiondeveloper.nl/post.cfm/link-generator-coldfusion-project-honeypot"><strong>Project Honeypot Coldfusion Link generator</strong></a><br /><br />
	</p>

	<cfinvoke component="LinkGenerator" method="init" returnvariable="variables.oLinkGenerator">
		<cfinvokeargument name="honeyPotURL" value="http://yoursitegoeshere.com/page.cfm" />
	</cfinvoke>
	<cfoutput>
		<cfloop from="1" to="10" index="i">
			<cfset sHTML = variables.oLinkGenerator.getHTML() />
			Returned html:
			<pre class="border">#htmleditformat(sHTML)#</pre>
			Underneath, the html is added into the page. But since it should be invisible to regular users, you will see nothing...
			<div class="border">#sHTML#</div>
			<hr />
			<br /><br />
		</cfloop>
	</cfoutput>
</body>
</html>