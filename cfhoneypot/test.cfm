<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title>&lt;cfhoneypot> test page</title>
</head>
<body>
	<p style="border:1px solid #000;padding:10px;margin: 10px 5px;font-size:14px;">
		This file is part of the <a href="http://www.coldfusiondeveloper.nl/post.cfm/9AD987CC-4DD1-4AFF-8682B02DC9125C46" style="font-size:14px;"><strong>&lt;cfhoneypot&gt;</strong></a> test project.
		<br />Created by <a href="http://www.coldfusiondeveloper.nl/" style="font-size:14px;">Paul Klinkenberg</a>
	</p>
	
	<h3>CreateLink</h3>
	<cfhoneypot action="createLink"
	variable="linkhtml"
	url="http://www.fff.nl/dfff.cfm"
	/>
	
	<p>Output:</p>
	<pre><cfoutput>#htmleditformat(linkhtml)#</cfoutput></pre>
	
	<hr />
	<h3>GetThreatRating</h3>
	<cfhoneypot action="getThreatRating"
	httpblkey="ascv"
	ip="93.174.93.58"
	variable="structname"
	/>
	<p>Output:</p>
	<cfdump var="#structname#" />
	<br />
	
	<hr />
	<h3>IsThreat</h3>
	<cfhoneypot action="isThreat"
	httpblkey="ascv"
	ip="93.174.93.58"
	variable="structname"
	threatnrs="4,5,6,7"
	maxdaysago="20"
	minimalThreatIndex="5"
	/>
	<p>Output:</p>
	<cfdump var="#structname#" />
	<br />
	
	<hr />
	<h3>BlockThreat</h3>
	<!--- test address: 93.174.93.58 --->
	<cfhoneypot action="BlockThreat"
	httpblkey="ascv"
	ip="#cgi.remote_addr#"
	threatnrs="4,5,6,7"
	maxdaysago="20"
	minimumThreatIndex="5"
	blocktext="you are locked out of this website due to spamming"
	/>
	<p>This text is only shown since your ip was not blocked.
		<br />If you would have been blocked, you would only have seen the block text "<em>you are locked out of this website due to spamming</em>".
	</p>
</body>
</html>