<h2>Emailing a page to yourself (the page's owner)</h2>

<cfinvoke component="#application.backpack_obj#" method="emailPage" returnvariable="page_xml">
	<cfinvokeargument name="id" value="#url.id#" />
</cfinvoke>
	
<cfoutput>
	<strong>The page has been mailed!</strong>
	<br />
	<a href="#cgi.script_name#?fuseaction=show_page&amp;id=#url.id#">Go to the page</a>
</cfoutput>