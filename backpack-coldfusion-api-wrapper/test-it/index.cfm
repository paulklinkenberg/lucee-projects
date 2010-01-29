<cfparam name="url.fuseaction" default="" />
<cfparam name="url.id" default="" />

<cfcontent reset="yes" type="text/html; charset=utf-8" /><!---

---><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>Coldfusion BackPack app</title>
	<link rel="stylesheet" type="text/css" href="styles/screen.css" />
</head>
<body>
	<div id="holder">
		<div id="header" style="background-color:#E8E8E8;border-bottom:1px solid #999;">
			<a href="http://www.coldfusiondeveloper.nl/" title="Code created and donated by Paul Klinkenberg, Ongevraagd Advies"><img src="images/logo-Ongevraagd-Advies.png" style="float:right;margin:5px 15px 0 0;" alt="Logo Ongevraagd Advies" /></a>
			<a href="http://www.backpackit.com/" title="Go to backpack homepage"><img src="images/backpacklogo-small.png" style="float:left;margin:20px 0 0 15px;" alt="Logo Backpack" /></a>
			<h1>Coldfusion backpack API<br />example files</h1>
		</div>
		
		<div id="content">
			<cfif fileExists(expandPath("actionFiles/#url.fuseaction#.cfm"))>
				<cfinclude template="actionFiles/#url.fuseaction#.cfm" />
			<cfelse>
				<cfinclude template="dsp_home.cfm" />
			</cfif>
		</div>
	
		<div id="nav">
	
			<h2>Links</h2>
			<cfoutput>
				<ul>
					<li><a href="http://www.coldfusiondeveloper.nl/post.cfm/backpack-api-wrapper-for-coldfusion">View project blog post</a></li>
					<li><a href="#cgi.script_name#">Home</a></li>
					<li><a href="#cgi.script_name#?fuseaction=showEverything">Show all pages</a></li>
					<li><a href="#cgi.script_name#?fuseaction=list_all_pages">List all page titles</a></li>
					<li><a href="index.cfm?fuseaction=create_new_page">Create new page</a></li>
					<li><a href="index.cfm?fuseaction=search_pages">Search within pages</a></li>
					<cfif len(url.id)>
						<li style="border-bottom:none"><strong>With current page:</strong></li>
						<li><a href="index.cfm?fuseaction=edit_page&amp;id=#url.id#">Edit page</a></li>
						<li><a href="index.cfm?fuseaction=edit_title&amp;id=#url.id#">Edit title</a></li>
						<li><a href="index.cfm?fuseaction=destroy_page&amp;id=#url.id#">Delete page</a></li>
						<li><a href="index.cfm?fuseaction=duplicate_page&amp;id=#url.id#">Duplicate page</a></li>
						<li><a href="index.cfm?fuseaction=share_page&amp;id=#url.id#">Share page</a></li>
						<li><a href="index.cfm?fuseaction=email_page&amp;id=#url.id#">Email page</a></li>
					</cfif>
				</ul>
			</cfoutput>
	
			<h2>Projects</h2>
			<cftry>
				<cfinclude template="dsp_project_list.cfm" />
				<cfcatch>
					<cfif url.fuseaction eq "">
						<cfset variables.includeSettingsWarning_bool = 1 />
						<ul><li class="error">Projects could not be loaded!</li></ul>
					<cfelse>
						<cfrethrow />
					</cfif>
				</cfcatch>
			</cftry>
	
		</div>
	
		<!--- <comment author="P. Klinkenberg">
			Using development mode?
			Then we'll output some debug info here.
		</comment> --->
		<cfif application.backPack.useDevelopmentMode>
			<br clear="all" />
			<div style="clear:both; border-top: 3px dashed Red; margin-top:10px" align="center">
				<br />
				<strong class="warning">Development mode is on</strong>
				<br />
	
				<cfoutput>
					<cfloop from="1" to="#arrayLen(request.cfhttpRequests_arr)#" index="arrIndex">
						<h3>Request #arrIndex#: #request.cfhttpRequests_arr[arrIndex].url#</h3>
						<pre><strong>request xml</strong><!---
							---><code>#htmleditformat(request.cfhttpRequests_arr[arrIndex].request_xml)#</code><!---
						---></pre>
						<pre><strong>response xml</strong><!---
							---><code>#htmleditformat(request.cfhttpRequests_arr[arrIndex].response_xml)#</code><!---
						---></pre>
						<hr />
					</cfloop>
				</cfoutput>
	
				<br />
	
				<!---<cfif structKeyExists(variables, "page_xml")>
					<h1>page xml:</h1>
					<cfdump var="#page_xml#" expand="no" />
				</cfif>--->
			</div>
		</cfif>
		
		<br clear="all" />
	</div>
</body>
</html>