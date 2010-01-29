
<h2>Duplicating a page</h2>

<cfif cgi.REQUEST_METHOD eq "POST">
	<cfinvoke component="#application.backpack_obj#" method="duplicatePage" returnvariable="page_xml">
		<cfinvokeargument name="id" value="#url.id#" />
	</cfinvoke>
	
	<cfoutput>
		<strong>The page has been duplicated!</strong>
		<br />
		Check it out: <a href="#cgi.script_name#?fuseaction=show_page&amp;id=#page_xml.response.page.xmlAttributes.id#">#page_xml.response.page.xmlAttributes.title#</a>
	</cfoutput>
<cfelse>
	<cfoutput>
		<form action="#cgi.script_name#?fuseaction=#url.fuseaction#&amp;id=#url.id#" method="post">
			Are you sure you want to duplicate/copy the page?
			<table>
				<tr><td>&nbsp;</td><td><input type="submit" value="go" /></td></tr>
			</table>
		</form>
	</cfoutput>
</cfif>