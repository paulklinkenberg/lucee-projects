<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title>Codecoloring test file</title>
	<style type="text/css">
		body { font-size:12px; font-family:Verdana, Geneva, sans-serif}
	</style>
</head>

<body>
	<form action="test.cfm" method="post">
		The text to colorcode:<br />
		<textarea cols="60" rows="20" name="text"><cfif structKeyExists(form, "text")><cfoutput>#htmleditformat(form.text)#</cfoutput></cfif></textarea>
		<br />
		<input type="submit" value="Color it" />
	</form>
	
	<cfif structKeyExists(form, "text") and len(form.text)>
		<cfset coloredCode = createObject("component", "CodeColoring").cachedColorString(form.text) />
		<cfoutput>#coloredCode#</cfoutput>
	</cfif>
</body>
</html>
